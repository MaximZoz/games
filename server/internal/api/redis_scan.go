package api

import (
	"context"

	"github.com/redis/go-redis/v9"
)

// scanRedisKeys собирает ключи по паттерну через SCAN (не блокирует Redis как KEYS).
func scanRedisKeys(ctx context.Context, rdb *redis.Client, pattern string) ([]string, error) {
	if rdb == nil {
		return nil, nil
	}
	var (
		cursor uint64
		out    []string
	)
	for {
		keys, next, err := rdb.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return out, err
		}
		out = append(out, keys...)
		cursor = next
		if cursor == 0 {
			break
		}
	}
	return out, nil
}
