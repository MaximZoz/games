// Package applinks отдаёт файлы, по которым Android и iOS связывают
// https://zozugames.com/games/…/lobby/… с установленным приложением.
// Без Team ID и отпечатков сертификата файлы не публикуются: HTML-заглушка
// SPA для этих путей ломает проверку и кэшируется.
package applinks

import (
	"encoding/json"
	"net/http"
	"os"
	"regexp"
	"strings"
)

const (
	defaultAndroidPackage = "com.zozugames.app"
	defaultAppleBundleID  = "com.zozugames.app"
)

var (
	teamIDPattern = regexp.MustCompile(`^[A-Z0-9]{10}$`)
	bundlePattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9.-]*$`)
	sha256Hex     = regexp.MustCompile(`^[0-9A-F]{64}$`)
)

// Config — что писать в assetlinks.json и apple-app-site-association.
type Config struct {
	AppleTeamID    string
	AppleBundleID  string
	AndroidPackage string
	AndroidSHA256  []string
}

// LoadConfig читает окружение процесса. Пустые отпечатки и Team ID
// оставляют соответствующий файл выключенным.
func LoadConfig() Config {
	return Config{
		AppleTeamID:    strings.TrimSpace(os.Getenv("APPLE_TEAM_ID")),
		AppleBundleID:  envOr("APPLE_APP_BUNDLE_ID", defaultAppleBundleID),
		AndroidPackage: envOr("ANDROID_APP_LINK_PACKAGE", defaultAndroidPackage),
		AndroidSHA256:  ParseSHA256List(os.Getenv("ANDROID_APP_LINK_SHA256")),
	}
}

func envOr(key, fallback string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback
	}
	return v
}

// ParseSHA256List принимает отпечатки через запятую, пробел или перевод строки.
// Двоеточия необязательны. Битые значения отбрасываются.
func ParseSHA256List(raw string) []string {
	parts := strings.FieldsFunc(raw, func(r rune) bool {
		return r == ',' || r == ';' || r == '\n' || r == '\r' || r == '\t' || r == ' '
	})
	out := make([]string, 0, len(parts))
	seen := map[string]struct{}{}
	for _, part := range parts {
		norm := normalizeSHA256(part)
		if norm == "" {
			continue
		}
		if _, ok := seen[norm]; ok {
			continue
		}
		seen[norm] = struct{}{}
		out = append(out, norm)
	}
	return out
}

func normalizeSHA256(raw string) string {
	hex := strings.ToUpper(strings.ReplaceAll(strings.TrimSpace(raw), ":", ""))
	if !sha256Hex.MatchString(hex) {
		return ""
	}
	var b strings.Builder
	b.Grow(len(hex) + len(hex)/2)
	for i := 0; i < len(hex); i += 2 {
		if i > 0 {
			b.WriteByte(':')
		}
		b.WriteString(hex[i : i+2])
	}
	return b.String()
}

// AndroidReady — можно отдать assetlinks.json.
func (c Config) AndroidReady() bool {
	return bundlePattern.MatchString(c.AndroidPackage) && len(c.AndroidSHA256) > 0
}

// AppleReady — можно отдать apple-app-site-association.
func (c Config) AppleReady() bool {
	return teamIDPattern.MatchString(c.AppleTeamID) && bundlePattern.MatchString(c.AppleBundleID)
}

// AssetLinksJSON — Digital Asset Links для Android App Links.
func (c Config) AssetLinksJSON() ([]byte, bool) {
	if !c.AndroidReady() {
		return nil, false
	}
	body := []assetLink{{
		Relation: []string{"delegate_permission/common.handle_all_urls"},
		Target: assetTarget{
			Namespace: "android_app",
			Package:   c.AndroidPackage,
			SHA256:    c.AndroidSHA256,
		},
	}}
	raw, err := json.Marshal(body)
	if err != nil {
		return nil, false
	}
	return raw, true
}

// AppleAppSiteAssociationJSON — Universal Links только на лобби и партию.
func (c Config) AppleAppSiteAssociationJSON() ([]byte, bool) {
	if !c.AppleReady() {
		return nil, false
	}
	body := appleAssociation{
		Applinks: appleApplinks{
			Apps: []string{},
			Details: []appleDetail{{
				AppID: c.AppleTeamID + "." + c.AppleBundleID,
				Paths: []string{
					"/games/*/lobby/*",
					"/games/*/game/*",
				},
			}},
		},
	}
	raw, err := json.Marshal(body)
	if err != nil {
		return nil, false
	}
	return raw, true
}

type assetLink struct {
	Relation []string    `json:"relation"`
	Target   assetTarget `json:"target"`
}

type assetTarget struct {
	Namespace string   `json:"namespace"`
	Package   string   `json:"package_name"`
	SHA256    []string `json:"sha256_cert_fingerprints"`
}

type appleAssociation struct {
	Applinks appleApplinks `json:"applinks"`
}

type appleApplinks struct {
	Apps    []string      `json:"apps"`
	Details []appleDetail `json:"details"`
}

type appleDetail struct {
	AppID string   `json:"appID"`
	Paths []string `json:"paths"`
}

// Serve отвечает на well-known пути. false — запрос не наш, его забирает SPA.
func Serve(w http.ResponseWriter, r *http.Request, cfg Config) bool {
	var payload []byte
	var ok bool
	switch r.URL.Path {
	case "/.well-known/assetlinks.json":
		payload, ok = cfg.AssetLinksJSON()
	case "/.well-known/apple-app-site-association", "/apple-app-site-association":
		payload, ok = cfg.AppleAppSiteAssociationJSON()
	default:
		return false
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		w.Header().Set("Allow", "GET, HEAD")
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return true
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	if !ok {
		http.NotFound(w, r)
		return true
	}
	w.WriteHeader(http.StatusOK)
	if r.Method != http.MethodHead {
		_, _ = w.Write(payload)
	}
	return true
}
