package api

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// iosTestFlightReleaseKey — последняя сборка, которую CI залил в TestFlight.
// Не серверный BUILD_ID: деплой API без новой IPA не должен звать на обновление.
const iosTestFlightReleaseKey = "ios:testflight:release"

// IOSTestFlightRelease — сборка, которую iPhone может поставить из TestFlight.
type IOSTestFlightRelease struct {
	BuildID     string `json:"build_id"`
	BuildNumber int    `json:"build_number"`
	AppleID     string `json:"apple_id"`
}

// LoopbackRequest — запрос с самой машины (fly ssh), не из интернета.
func LoopbackRequest(remoteAddr string) bool {
	host := strings.TrimSpace(remoteAddr)
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	ip := net.ParseIP(strings.Trim(host, "[]"))
	return ip != nil && ip.IsLoopback()
}

// ParseIOSTestFlightRelease проверяет тело, которым CI сообщает о залитой IPA.
func ParseIOSTestFlightRelease(body []byte) (IOSTestFlightRelease, error) {
	var rel IOSTestFlightRelease
	if err := json.Unmarshal(body, &rel); err != nil {
		return IOSTestFlightRelease{}, err
	}
	rel.BuildID = strings.TrimSpace(rel.BuildID)
	rel.AppleID = strings.TrimSpace(rel.AppleID)
	if rel.BuildID == "" || len(rel.BuildID) > 40 {
		return IOSTestFlightRelease{}, errors.New("build_id required")
	}
	for _, r := range rel.BuildID {
		if (r < '0' || r > '9') && (r < 'a' || r > 'z') && (r < 'A' || r > 'Z') {
			return IOSTestFlightRelease{}, errors.New("build_id required")
		}
	}
	if rel.BuildNumber <= 0 {
		return IOSTestFlightRelease{}, errors.New("build_number required")
	}
	if rel.AppleID != "" {
		for _, r := range rel.AppleID {
			if r < '0' || r > '9' {
				return IOSTestFlightRelease{}, errors.New("apple_id required")
			}
		}
	}
	return rel, nil
}

func LoadIOSTestFlightRelease(ctx context.Context, rdb *redis.Client) (IOSTestFlightRelease, bool) {
	if rdb == nil {
		return IOSTestFlightRelease{}, false
	}
	raw, err := rdb.Get(ctx, iosTestFlightReleaseKey).Result()
	if err != nil || strings.TrimSpace(raw) == "" {
		return IOSTestFlightRelease{}, false
	}
	rel, err := ParseIOSTestFlightRelease([]byte(raw))
	if err != nil {
		return IOSTestFlightRelease{}, false
	}
	return rel, true
}

func SaveIOSTestFlightRelease(ctx context.Context, rdb *redis.Client, rel IOSTestFlightRelease) error {
	if rdb == nil {
		return errors.New("redis unavailable")
	}
	raw, err := json.Marshal(rel)
	if err != nil {
		return err
	}
	// Сборка TestFlight живёт 90 дней; ключ чуть дольше, чтобы не звать на протухшую.
	return rdb.Set(ctx, iosTestFlightReleaseKey, raw, 120*24*time.Hour).Err()
}

// IOSTestFlightReleaseHandler принимает запись о залитой IPA только с localhost.
type IOSTestFlightReleaseHandler struct {
	Rdb    *redis.Client
	Notify func()
}

func (h *IOSTestFlightReleaseHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if !LoopbackRequest(r.RemoteAddr) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if h == nil || h.Rdb == nil {
		http.Error(w, "redis unavailable", http.StatusServiceUnavailable)
		return
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, 4096))
	if err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	rel, err := ParseIOSTestFlightRelease(body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if err := SaveIOSTestFlightRelease(r.Context(), h.Rdb, rel); err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if h.Notify != nil {
		h.Notify()
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(rel)
}
