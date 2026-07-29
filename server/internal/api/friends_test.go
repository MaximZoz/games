package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"multigames/server/internal/store"

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

func TestFriendUserToItem_OmitsEmailInJSON(t *testing.T) {
	displayName := "PlayerOne"
	avatarValue := "2"
	age := 27
	gender := "female"
	about := "about text"

	item := friendUserToItem(store.FriendUser{
		ID:          uuid.New(),
		Email:       "private@example.com",
		DisplayName: &displayName,
		AvatarKind:  "preset",
		AvatarValue: &avatarValue,
		Age:         &age,
		Gender:      &gender,
		About:       &about,
	})

	if item.Email != "" {
		t.Fatalf("email must be empty, got %q", item.Email)
	}
	if item.DisplayName == nil || *item.DisplayName != displayName {
		t.Fatalf("display_name mismatch: got %v, want %q", item.DisplayName, displayName)
	}

	raw, err := json.Marshal(item)
	if err != nil {
		t.Fatalf("marshal json: %v", err)
	}
	if strings.Contains(string(raw), "private@example.com") {
		t.Fatalf("json unexpectedly contains private email: %s", string(raw))
	}

	var payload map[string]any
	if err := json.Unmarshal(raw, &payload); err != nil {
		t.Fatalf("unmarshal json: %v", err)
	}
	if _, exists := payload["email"]; exists {
		t.Fatalf("email field must be omitted due to omitempty, got payload=%v", payload)
	}
}

func TestWriteFriendError_StatusCodes(t *testing.T) {
	cases := []struct {
		name string
		err  error
		want int
	}{
		{name: "cannot friend yourself", err: store.ErrCannotFriendYourself, want: http.StatusBadRequest},
		{name: "already friends", err: store.ErrAlreadyFriends, want: http.StatusConflict},
		{name: "request already sent", err: store.ErrFriendRequestAlreadySent, want: http.StatusConflict},
		{name: "request already pending", err: store.ErrFriendRequestAlreadyPending, want: http.StatusConflict},
		{name: "user blocked", err: store.ErrUserBlocked, want: http.StatusForbidden},
		{name: "forbidden", err: store.ErrFriendForbidden, want: http.StatusForbidden},
		{name: "not found", err: store.ErrFriendNotFound, want: http.StatusNotFound},
		{name: "internal default", err: errors.New("unexpected"), want: http.StatusInternalServerError},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/", nil)
			rec := httptest.NewRecorder()
			writeFriendError(rec, req, tc.err)
			if rec.Code != tc.want {
				t.Fatalf("status = %d, want %d", rec.Code, tc.want)
			}
		})
	}
}

func TestFriends_Search_EmptyQuery_ReturnsEmptyUsers(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodGet, "/api/friends/search?q=%20%20%20", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Search(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}

	var payload struct {
		Users []any `json:"users"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("invalid JSON response: %v; body=%q", err, rec.Body.String())
	}
	if len(payload.Users) != 0 {
		t.Fatalf("users len = %d, want 0; body=%q", len(payload.Users), rec.Body.String())
	}
}

func TestFriends_Search_InvalidLimit(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodGet, "/api/friends/search?q=abc&limit=bad", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Search(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}

func TestFriends_Search_InvalidOffset(t *testing.T) {
	h := friendsHandlerForValidation()
	req := httptest.NewRequest(http.MethodGet, "/api/friends/search?q=abc&offset=bad", nil)
	req = withUserID(req)
	rec := httptest.NewRecorder()

	h.Search(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
	}
}
