package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

func TestPublishToAllDeliversToConnectedClient(t *testing.T) {
	hub := NewRealtimeHub()
	userID := uuid.New()

	upgrader := websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			t.Errorf("upgrade: %v", err)
			return
		}
		hub.Register(userID, conn)
		// Держим соединение открытым.
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				hub.Unregister(userID, conn)
				_ = conn.Close()
				return
			}
		}
	}))
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http")
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer conn.Close()

	time.Sleep(50 * time.Millisecond)

	payload := map[string]any{
		"type":         "client_update_available",
		"latest_build": "abc1234",
	}
	hub.PublishToAll(payload)

	_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, raw, err := conn.ReadMessage()
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	var got map[string]any
	if err := json.Unmarshal(raw, &got); err != nil {
		t.Fatalf("json: %v", err)
	}
	if got["type"] != "client_update_available" {
		t.Fatalf("type=%v", got["type"])
	}
	if got["latest_build"] != "abc1234" {
		t.Fatalf("latest_build=%v", got["latest_build"])
	}
}
