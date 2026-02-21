package api

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

func friendsHandlerForValidation() *FriendsHandler {
	return &FriendsHandler{Pool: (*pgxpool.Pool)(nil)}
}

func withUserID(req *http.Request) *http.Request {
	ctx := context.WithValue(req.Context(), UserIDKey, uuid.New())
	return req.WithContext(ctx)
}

func TestFriends_List_MethodNotAllowed(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/friends", nil)
	rec := httptest.NewRecorder()

	h.List(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestFriends_Search_MethodNotAllowed(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/friends/search?q=a", nil)
	rec := httptest.NewRecorder()

	h.Search(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
}

func TestFriends_SendRequest_InvalidJSON(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/friends/request", bytes.NewReader([]byte("{")))
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.SendRequest(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestFriends_AcceptRequest_InvalidUUID(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/friends/accept", bytes.NewReader([]byte(`{"request_id":"bad"}`)))
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.AcceptRequest(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestFriends_RemoveFriend_InvalidUUID(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodPost, "/api/friends/remove", bytes.NewReader([]byte(`{"friend_user_id":"bad"}`)))
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.RemoveFriend(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}
