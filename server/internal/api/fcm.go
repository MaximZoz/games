package api

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"

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
	Token        string               `json:"token"`
	Notification *fcmNotification     `json:"notification,omitempty"`
	Data         map[string]string    `json:"data,omitempty"`
	Android      *fcmAndroid          `json:"android,omitempty"`
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

func parseFCMProjectID(raw string) string {
	var sa fcmServiceAccount
	if err := json.Unmarshal([]byte(strings.TrimSpace(raw)), &sa); err != nil {
		return ""
	}
	return strings.TrimSpace(sa.ProjectID)
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
		strings.TrimSpace(s.FCMServiceAccountJSON) != "" &&
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

	creds, err := google.CredentialsFromJSON(ctx, []byte(s.FCMServiceAccountJSON), fcmScope)
	if err != nil {
		log.Printf("fcm: credentials: %v", err)
		return
	}
	projectID := parseFCMProjectID(s.FCMServiceAccountJSON)
	url := "https://fcm.googleapis.com/v1/projects/" + projectID + "/messages:send"
	client := s.HTTPClient
	if client == nil {
		client = http.DefaultClient
	}

	data := fcmDataFromPayload(payload)

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
			body, err := json.Marshal(fcmMessageRequest{Message: fcmMessage{
				Token: tok.Token,
				Notification: &fcmNotification{
					Title: payload.Title,
					Body:  payload.Body,
				},
				Data: data,
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
			}})
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
