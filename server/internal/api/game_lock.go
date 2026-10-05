package api

import (
	"context"
	"errors"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// errGameBusy — лок партии не удалось взять за отведённое время.
var errGameBusy = errors.New("game busy")

type gameLockCtxKey struct{}

// releaseGameLockScript снимает лок только если токен совпал.
var releaseGameLockScript = redis.NewScript(`
if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
end
return 0
`)

// withGameLock сериализует запись партии между репликами и горутинами ботов.
// Повторный вызов в том же запросе (вложенный heal/timeout) лок не берёт заново.
func (h *GamesHandler) withGameLock(ctx context.Context, gameID string, fn func(context.Context) error) error {
	if h == nil || h.Rdb == nil || gameID == "" {
		return fn(ctx)
	}
	if held, _ := ctx.Value(gameLockCtxKey{}).(string); held == gameID {
		return fn(ctx)
	}
	token := uuid.NewString()
	key := "gamelock:" + gameID
	deadline := time.Now().Add(5 * time.Second)
	var acquired bool
	for {
		ok, err := h.Rdb.SetNX(ctx, key, token, 15*time.Second).Result()
		if err != nil {
			return err
		}
		if ok {
			acquired = true
			break
		}
		if time.Now().After(deadline) {
			return errGameBusy
		}
		timer := time.NewTimer(20 * time.Millisecond)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}
	}
	if !acquired {
		return errGameBusy
	}
	locked := context.WithValue(ctx, gameLockCtxKey{}, gameID)
	defer func() {
		c, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		if _, err := releaseGameLockScript.Run(c, h.Rdb, []string{key}, token).Result(); err != nil {
			log.Printf("game lock release %s: %v", gameID, err)
		}
	}()
	return fn(locked)
}

// callGame держит лок на весь обработчик партии (ход, GET с таймаутом, сдача).
func (h *GamesHandler) callGame(w http.ResponseWriter, r *http.Request, gameID string, fn func(http.ResponseWriter, *http.Request)) {
	err := h.withGameLock(r.Context(), gameID, func(ctx context.Context) error {
		fn(w, r.WithContext(ctx))
		return nil
	})
	if err == nil {
		return
	}
	if errors.Is(err, errGameBusy) {
		WriteErr(w, r, http.StatusConflict, "move conflict")
		return
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return
	}
	log.Printf("game lock %s: %v", gameID, err)
	WriteErr(w, r, http.StatusServiceUnavailable, "temporarily unavailable")
}
