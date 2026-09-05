package api

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/redis/go-redis/v9"
)

func TestServeHTTPDispatchesCheckersLobby(t *testing.T) {
	h := &GamesHandler{
		Rdb: redis.NewClient(&redis.Options{Addr: "127.0.0.1:1"}),
	}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(
		http.MethodPost,
		"/api/games/checkers/lobby",
		strings.NewReader(`{"mode":"invite","game_mode":"russian","turn_time_sec":60,"stake_bronze":2}`),
	)
	h.ServeHTTP(rec, req)
	if rec.Code == http.StatusNotFound {
		t.Fatalf("checkers lobby must not fall through to tictactoe 404, body=%s", rec.Body.String())
	}
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("code=%d want 401 without auth, body=%s", rec.Code, rec.Body.String())
	}
}
