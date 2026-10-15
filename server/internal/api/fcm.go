package api

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"unicode/utf16"

	"multigames/server/internal/store"

	"github.com/google/uuid"
	"golang.org/x/oauth2/google"
)

const fcmScope = "https://www.googleapis.com/auth/firebase.messaging"

type fcmServiceAccount struct {
	ProjectID string `json:"project_id"`
}

type fcmMessageRequest struct {
	Message fcmMessage `json:"message"`
}

type fcmMessage struct {
	Token        string            `json:"token"`
	Notification *fcmNotification  `json:"notification,omitempty"`
	Data         map[string]string `json:"data,omitempty"`
	Android      *fcmAndroid       `json:"android,omitempty"`
	APNS         *fcmAPNS          `json:"apns,omitempty"`
}

type fcmAPNS struct {
	Headers map[string]string `json:"headers,omitempty"`
	Payload *fcmAPNSPayload   `json:"payload,omitempty"`
}

type fcmAPNSPayload struct {
	Aps *fcmAps `json:"aps,omitempty"`
}

type fcmAps struct {
	Alert    *fcmApsAlert `json:"alert,omitempty"`
	Sound    string       `json:"sound,omitempty"`
	ThreadID string       `json:"thread-id,omitempty"`
}

type fcmApsAlert struct {
	Title string `json:"title,omitempty"`
	Body  string `json:"body,omitempty"`
}

type fcmNotification struct {
	Title string `json:"title,omitempty"`
	Body  string `json:"body,omitempty"`
}

type fcmAndroid struct {
	Priority     string                  `json:"priority,omitempty"`
	Notification *fcmAndroidNotification `json:"notification,omitempty"`
}

type fcmAndroidNotification struct {
	ChannelID   string `json:"channel_id,omitempty"`
	Icon        string `json:"icon,omitempty"`
	Tag         string `json:"tag,omitempty"`
	ClickAction string `json:"click_action,omitempty"`
	Sound       string `json:"sound,omitempty"`
	Color       string `json:"color,omitempty"`
}

type fcmErrorBody struct {
	Error struct {
		Status  string `json:"status"`
		Message string `json:"message"`
		Details []struct {
			ErrorCode string `json:"errorCode"`
		} `json:"details"`
	} `json:"error"`
}

func buildFCMMessage(token string, payload PushPayload) fcmMessage {
	thread := strings.TrimSpace(payload.Tag)
	aps := &fcmAps{
		Alert: &fcmApsAlert{Title: payload.Title, Body: payload.Body},
		Sound: "default",
	}
	if thread != "" {
		aps.ThreadID = thread
	}
	return fcmMessage{
		Token: token,
		Notification: &fcmNotification{
			Title: payload.Title,
			Body:  payload.Body,
		},
		Data: fcmDataFromPayload(payload),
		Android: &fcmAndroid{
			Priority: "high",
			Notification: &fcmAndroidNotification{
				ChannelID:   "zozu_events",
				Icon:        "ic_stat_notify",
				Tag:         payload.Tag,
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
				Sound:       "default",
				Color:       "#6366F1",
			},
		},
		APNS: &fcmAPNS{
			Headers: map[string]string{"apns-priority": "10"},
			Payload: &fcmAPNSPayload{Aps: aps},
		},
	}
}

func fcmDataFromPayload(payload PushPayload) map[string]string {
	data := map[string]string{}
	if payload.Title != "" {
		data["title"] = payload.Title
	}
	if payload.Body != "" {
		data["body"] = payload.Body
	}
	if payload.URL != "" {
		data["url"] = payload.URL
	}
	if payload.Tag != "" {
		data["tag"] = payload.Tag
	}
	if payload.Kind != "" {
		data["kind"] = payload.Kind
	}
	if payload.ChatID != "" {
		data["chat_id"] = payload.ChatID
	}
	return data
}

func utf16LEToString(b []byte) string {
	if len(b) < 2 {
		return ""
	}
	if b[0] == 0xFF && b[1] == 0xFE {
		b = b[2:]
	}
	if len(b)%2 == 1 {
		b = b[:len(b)-1]
	}
	u := make([]uint16, 0, len(b)/2)
	for i := 0; i+1 < len(b); i += 2 {
		u = append(u, uint16(b[i])|uint16(b[i+1])<<8)
	}
	return string(utf16.Decode(u))
}

func nulCount(b []byte) int {
	n := 0
	for _, c := range b {
		if c == 0 {
			n++
		}
	}
	return n
}

// NormalizeFCMServiceAccountJSON чинит BOM / UTF-16 с Windows и отбрасывает «-».
func NormalizeFCMServiceAccountJSON(raw string) string {
	if raw == "" {
		return ""
	}
	b := []byte(raw)
	if (len(b) >= 2 && b[0] == 0xFF && b[1] == 0xFE) ||
		(len(b) > 8 && nulCount(b) > len(b)/4) {
		if s := utf16LEToString(b); s != "" {
			raw = s
		}
	}
	s := strings.TrimSpace(raw)
	s = strings.TrimPrefix(s, "\uFEFF")
	s = strings.TrimSpace(s)
	if len(s) >= 2 && s[0] == '"' && s[len(s)-1] == '"' {
		if u, err := strconv.Unquote(s); err == nil {
			s = strings.TrimSpace(u)
		}
	}
	if s == "" || s == "-" {
		return ""
	}
	return s
}

func parseFCMProjectID(raw string) string {
	n := NormalizeFCMServiceAccountJSON(raw)
	var sa fcmServiceAccount
	if err := json.Unmarshal([]byte(n), &sa); err != nil {
		return ""
	}
	return strings.TrimSpace(sa.ProjectID)
}

// FCMSecretStatus — причина для лога, без содержимого ключа.
func FCMSecretStatus(raw string) (ok bool, reason string) {
	trimmed := strings.TrimSpace(raw)
	if raw == "" || trimmed == "" {
		return false, "empty"
	}
	if trimmed == "-" {
		return false, "literal-dash (Windows stdin not read)"
	}
	n := NormalizeFCMServiceAccountJSON(raw)
	if n == "" {
		return false, fmt.Sprintf("unreadable len=%d", len(raw))
	}
	if parseFCMProjectID(n) == "" {
		if !json.Valid([]byte(n)) {
			return false, fmt.Sprintf("invalid-json len=%d", len(n))
		}
		return false, "no-project_id"
	}
	return true, "ok"
}

func shouldDropFCMToken(status int, body []byte) bool {
	if status == http.StatusNotFound {
		return true
	}
	var parsed fcmErrorBody
	if err := json.Unmarshal(body, &parsed); err != nil {
		return false
	}
	if parsed.Error.Status == "NOT_FOUND" || parsed.Error.Status == "UNREGISTERED" {
		return true
	}
	for _, d := range parsed.Error.Details {
		code := strings.ToUpper(d.ErrorCode)
		if code == "UNREGISTERED" || code == "NOT_FOUND" {
			return true
		}
	}
	return false
}

func (s *WebPushSender) FCMEnabled() bool {
	return s != nil &&
		s.Pool != nil &&
		parseFCMProjectID(s.FCMServiceAccountJSON) != ""
}

func (s *WebPushSender) CanNotify() bool {
	return s != nil && s.Pool != nil && (s.Enabled() || s.FCMEnabled())
}

func (s *WebPushSender) sendFCM(ctx context.Context, userIDs []uuid.UUID, payload PushPayload) {
	tokens, err := store.ListDevicePushTokensForUsers(ctx, s.Pool, userIDs)
	if err != nil {
		log.Printf("fcm: list tokens: %v", err)
		return
	}
	if len(tokens) == 0 {
		return
	}

	saJSON := NormalizeFCMServiceAccountJSON(s.FCMServiceAccountJSON)
	creds, err := google.CredentialsFromJSON(ctx, []byte(saJSON), fcmScope)
	if err != nil {
		log.Printf("fcm: credentials: %v", err)
		return
	}
	projectID := parseFCMProjectID(saJSON)
	url := "https://fcm.googleapis.com/v1/projects/" + projectID + "/messages:send"
	client := s.HTTPClient
	if client == nil {
		client = http.DefaultClient
	}

	const maxParallel = 8
	sem := make(chan struct{}, maxParallel)
	var wg sync.WaitGroup
	for _, tok := range tokens {
		tok := tok
		if strings.TrimSpace(tok.Token) == "" {
			continue
		}
		wg.Add(1)
		sem <- struct{}{}
		go func() {
			defer wg.Done()
			defer func() { <-sem }()
			oauthTok, err := creds.TokenSource.Token()
			if err != nil {
				log.Printf("fcm: token: %v", err)
				return
			}
			body, err := json.Marshal(fcmMessageRequest{
				Message: buildFCMMessage(tok.Token, payload),
			})
			if err != nil {
				return
			}
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
			if err != nil {
				return
			}
			req.Header.Set("Authorization", "Bearer "+oauthTok.AccessToken)
			req.Header.Set("Content-Type", "application/json")
			resp, err := client.Do(req)
			if err != nil {
				log.Printf("fcm: send: %v", err)
				return
			}
			respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
			_ = resp.Body.Close()
			if resp.StatusCode >= 200 && resp.StatusCode < 300 {
				return
			}
			if shouldDropFCMToken(resp.StatusCode, respBody) {
				log.Printf("fcm: drop stale token %s status=%d body=%q", tok.ID, resp.StatusCode, string(respBody))
				_ = store.DeleteDevicePushTokenByValue(ctx, s.Pool, tok.Token)
				return
			}
			log.Printf("fcm: unexpected status %d for %s body=%q", resp.StatusCode, tok.ID, string(respBody))
		}()
	}
	wg.Wait()
}
