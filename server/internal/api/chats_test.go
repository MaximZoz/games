package api

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

func chatsHandlerForValidation() *ChatsHandler {
	return &ChatsHandler{Pool: (*pgxpool.Pool)(nil)}
}

func TestChats_List_MethodNotAllowed(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/chats", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.List(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestChats_Start_InvalidJSON(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/chats/start", bytes.NewReader([]byte("{")))
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Start(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestChats_Start_InvalidUUID(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(
		http.MethodPost,
		"/api/chats/start",
		bytes.NewReader([]byte(`{"target_user_id":"bad"}`)),
	)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Start(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestChats_Messages_MethodNotAllowed(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(http.MethodDelete, "/api/chats/messages", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Messages(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestChats_ListMessages_InvalidChatID(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(http.MethodGet, "/api/chats/messages?chat_id=bad", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Messages(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestChats_ListMessages_InvalidLimit(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(
		http.MethodGet,
		"/api/chats/messages?chat_id=550e8400-e29b-41d4-a716-446655440000&limit=bad",
		nil,
	)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Messages(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestChats_SendMessage_InvalidJSON(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/chats/messages", bytes.NewReader([]byte("{")))
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Messages(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestChats_SendMessage_InvalidChatID(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(
		http.MethodPost,
		"/api/chats/messages",
		bytes.NewReader([]byte(`{"chat_id":"bad","body":"hello"}`)),
	)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Messages(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestChats_Read_MethodNotAllowed(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(http.MethodGet, "/api/chats/read", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Read(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestChats_Read_InvalidChatID(t *testing.T) {
	h := chatsHandlerForValidation()
	req := httptest.NewRequest(
		http.MethodPost,
		"/api/chats/read",
		bytes.NewReader([]byte(`{"chat_id":"bad"}`)),
	)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Read(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}
