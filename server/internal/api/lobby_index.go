package api

import (
	"context"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// Индекс id лобби. SCAN по lobby:* обходит весь keyspace Redis
// (партии, presence, локи) и растёт вместе с числом столов.
const (
	lobbyIndexKey   = "idx:lobbies"
	lobbyIndexReady = "idx:lobbies:ready"
)

func rememberLobbyIndex(rdb *redis.Client, lobbyID string) {
	if rdb == nil {
		return
	}
	lobbyID = strings.TrimSpace(lobbyID)
	if lobbyID == "" || strings.Contains(lobbyID, ":") {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	_ = rdb.SAdd(ctx, lobbyIndexKey, lobbyID).Err()
}

func forgetLobbyIndex(rdb *redis.Client, lobbyID string) {
	if rdb == nil {
		return
	}
	lobbyID = strings.TrimSpace(lobbyID)
	if lobbyID == "" {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	_ = rdb.SRem(ctx, lobbyIndexKey, lobbyID).Err()
}

func (h *GamesHandler) rememberLobby(lobbyID string) {
	if h == nil {
		return
	}
	rememberLobbyIndex(h.Rdb, lobbyID)
}

func (h *GamesHandler) forgetLobby(lobbyID string) {
	if h == nil {
		return
	}
	forgetLobbyIndex(h.Rdb, lobbyID)
}

// lobbyHashKeys — ключи hash лобби (lobby:{id}), без lobby:{id}:invited.
func (h *GamesHandler) lobbyHashKeys(ctx context.Context) ([]string, error) {
	if h == nil || h.Rdb == nil {
		return nil, nil
	}
	ids, err := h.Rdb.SMembers(ctx, lobbyIndexKey).Result()
	if err != nil {
		return scanLobbyHashKeys(ctx, h.Rdb)
	}
	ready, _ := h.Rdb.Exists(ctx, lobbyIndexReady).Result()
	if len(ids) == 0 && ready == 0 {
		keys, scanErr := scanLobbyHashKeys(ctx, h.Rdb)
		if scanErr != nil {
			return nil, scanErr
		}
		for _, key := range keys {
			rememberLobbyIndex(h.Rdb, strings.TrimPrefix(key, "lobby:"))
		}
		_ = h.Rdb.Set(ctx, lobbyIndexReady, "1", 0).Err()
		return keys, nil
	}
	keys := make([]string, 0, len(ids))
	for _, id := range ids {
		id = strings.TrimSpace(id)
		if id == "" || strings.Contains(id, ":") {
			forgetLobbyIndex(h.Rdb, id)
			continue
		}
		key := "lobby:" + id
		n, err := h.Rdb.Exists(ctx, key).Result()
		if err != nil {
			keys = append(keys, key)
			continue
		}
		if n == 0 {
			forgetLobbyIndex(h.Rdb, id)
			continue
		}
		keys = append(keys, key)
	}
	return keys, nil
}

func scanLobbyHashKeys(ctx context.Context, rdb *redis.Client) ([]string, error) {
	keys, err := scanRedisKeys(ctx, rdb, "lobby:*")
	if err != nil && len(keys) == 0 {
		return nil, err
	}
	out := make([]string, 0, len(keys))
	for _, key := range keys {
		rest := strings.TrimPrefix(key, "lobby:")
		if rest == "" || strings.Contains(rest, ":") {
			continue
		}
		out = append(out, key)
	}
	return out, nil
}
