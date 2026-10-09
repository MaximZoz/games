package api

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"multigames/server/internal/store"

	"github.com/alicebob/miniredis/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

func TestRejectIfFrozen(t *testing.T) {
	prev := isUserFrozenFn
	t.Cleanup(func() { isUserFrozenFn = prev })

	isUserFrozenFn = func(context.Context, *pgxpool.Pool, uuid.UUID) (bool, error) {
		return true, nil
	}
	var pool pgxpool.Pool
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/api/me", nil)
	if !rejectIfFrozen(rec, req, &pool, uuid.New()) {
		t.Fatal("expected frozen rejection")
	}
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}

	isUserFrozenFn = func(context.Context, *pgxpool.Pool, uuid.UUID) (bool, error) {
		return false, nil
	}
	rec = httptest.NewRecorder()
	if rejectIfFrozen(rec, req, &pool, uuid.New()) {
		t.Fatal("active user must pass")
	}
	if rejectIfFrozen(rec, req, nil, uuid.New()) {
		t.Fatal("nil pool skips the check")
	}
}

func TestRateLimitMemoryWindow(t *testing.T) {
	lim := NewRateLimiter(nil)
	for i := 0; i < 3; i++ {
		ok, _ := lim.Allow(context.Background(), "login:1.1.1.1", 3, time.Minute)
		if !ok {
			t.Fatalf("hit %d should pass", i)
		}
	}
	ok, retry := lim.Allow(context.Background(), "login:1.1.1.1", 3, time.Minute)
	if ok || retry <= 0 {
		t.Fatalf("4th hit ok=%v retry=%s", ok, retry)
	}
	ok, _ = lim.Allow(context.Background(), "login:2.2.2.2", 3, time.Minute)
	if !ok {
		t.Fatal("other ip should pass")
	}
}

func TestRateLimitRedisShared(t *testing.T) {
	mr := miniredis.RunT(t)
	rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
	t.Cleanup(func() { _ = rdb.Close() })
	a := NewRateLimiter(rdb)
	b := NewRateLimiter(rdb)
	ctx := context.Background()
	if ok, _ := a.Allow(ctx, "register:10.0.0.1", 2, time.Minute); !ok {
		t.Fatal("first")
	}
	if ok, _ := b.Allow(ctx, "register:10.0.0.1", 2, time.Minute); !ok {
		t.Fatal("second replica should share the counter")
	}
	if ok, _ := a.Allow(ctx, "register:10.0.0.1", 2, time.Minute); ok {
		t.Fatal("third hit must be limited across replicas")
	}
}

func TestGameLockSerializesMoves(t *testing.T) {
	mr := miniredis.RunT(t)
	rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
	t.Cleanup(func() { _ = rdb.Close() })
	h := &GamesHandler{Rdb: rdb}
	started := make(chan struct{})
	release := make(chan struct{})
	var wg sync.WaitGroup
	wg.Add(2)
	order := make(chan int, 2)
	go func() {
		defer wg.Done()
		_ = h.withGameLock(context.Background(), "g1", func(context.Context) error {
			order <- 1
			close(started)
			<-release
			return nil
		})
	}()
	go func() {
		defer wg.Done()
		<-started
		_ = h.withGameLock(context.Background(), "g1", func(context.Context) error {
			order <- 2
			return nil
		})
	}()
	<-started
	select {
	case n := <-order:
		if n != 1 {
			t.Fatalf("first finisher %d", n)
		}
	case <-time.After(time.Second):
		t.Fatal("first lock did not start")
	}
	select {
	case <-order:
		t.Fatal("second move ran before the first released the lock")
	case <-time.After(80 * time.Millisecond):
	}
	close(release)
	wg.Wait()
	if n := <-order; n != 2 {
		t.Fatalf("second = %d", n)
	}
}

func TestOAuthStateRoundTripRedis(t *testing.T) {
	mr := miniredis.RunT(t)
	rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
	t.Cleanup(func() { _ = rdb.Close() })
	cfg := &OAuthConfig{Rdb: rdb}
	state, err := cfg.putState("google", "/games", "ref", true)
	if err != nil || state == "" {
		t.Fatal(err)
	}
	if !cfg.peekFromPWA(state) {
		t.Fatal("peek FromPWA")
	}
	got, ok := cfg.takeState(state)
	if !ok || got.Provider != "google" || got.Redirect != "/games" || !got.FromPWA {
		t.Fatalf("take %+v ok=%v", got, ok)
	}
	if _, ok := cfg.takeState(state); ok {
		t.Fatal("state must be one-time")
	}
	cfg.putResult(state, oauthResult{AccessToken: "a", RefreshToken: "r", Redirect: "/games"})
	res, ok := cfg.takeResult(state)
	if !ok || res.AccessToken != "a" || res.RefreshToken != "r" {
		t.Fatalf("result %+v ok=%v", res, ok)
	}
}

func TestLobbyIndexSkipsFullScan(t *testing.T) {
	mr := miniredis.RunT(t)
	rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
	t.Cleanup(func() { _ = rdb.Close() })
	h := &GamesHandler{Rdb: rdb}
	ctx := context.Background()
	if err := rdb.Set(ctx, lobbyIndexReady, "1", 0).Err(); err != nil {
		t.Fatal(err)
	}
	h.rememberLobby("lobby-a")
	if err := rdb.HSet(ctx, "lobby:lobby-a", "status", "waiting_matchmake").Err(); err != nil {
		t.Fatal(err)
	}
	keys, err := h.lobbyHashKeys(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(keys) != 1 || keys[0] != "lobby:lobby-a" {
		t.Fatalf("keys = %v", keys)
	}
	h.forgetLobby("lobby-a")
	keys, err = h.lobbyHashKeys(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(keys) != 0 {
		t.Fatalf("after forget keys = %v", keys)
	}
}

func TestRealtimeFanoutDoesNotDeliverLocally(t *testing.T) {
	hub := NewRealtimeHub()
	var got []uuid.UUID
	hub.SetFanout(func(ids []uuid.UUID, all bool, payload any) bool {
		got = append(got, ids...)
		if all {
			t.Fatal("expected targeted fanout")
		}
		return true
	})
	id := uuid.New()
	hub.PublishToUsers([]uuid.UUID{id}, map[string]any{"type": "chat"})
	if len(got) != 1 || got[0] != id {
		t.Fatalf("fanout ids = %v", got)
	}
	hub.DeliverLocal([]uuid.UUID{id}, map[string]any{"type": "chat"})
}

func TestUserIsFrozenHelper(t *testing.T) {
	u := &store.User{}
	if u.IsFrozen() {
		t.Fatal("nil frozen_at is active")
	}
	now := time.Now()
	u.FrozenAt = &now
	if !u.IsFrozen() {
		t.Fatal("frozen_at set")
	}
}
