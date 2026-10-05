package api

import (
	"context"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// Лимиты на публичные точки, которые иначе можно долбить с любой реплики.
const (
	RateLoginPerMinute     = 30
	RateRegisterPer15Min   = 5
	RateForgotPer15Min     = 5
	RateResetPer15Min      = 10
	RateResendPer15Min     = 5
	RateWSConnectPerMinute = 20
)

// rateLimitScript — фиксированное окно: INCR + PEXPIRE на первом хите.
// Возвращает {count, pttl_ms}.
var rateLimitScript = redis.NewScript(`
local n = redis.call('INCR', KEYS[1])
if n == 1 then
  redis.call('PEXPIRE', KEYS[1], ARGV[1])
end
local ttl = redis.call('PTTL', KEYS[1])
if ttl < 0 then
  redis.call('PEXPIRE', KEYS[1], ARGV[1])
  ttl = tonumber(ARGV[1])
end
return {n, ttl}
`)

type memBucket struct {
	count   int
	resetAt time.Time
}

// RateLimiter — общий счётчик. С Redis лимит общий для всех машин Fly,
// без Redis — в памяти процесса (dev и тесты).
type RateLimiter struct {
	rdb *redis.Client

	mu      sync.Mutex
	buckets map[string]*memBucket
}

func NewRateLimiter(rdb *redis.Client) *RateLimiter {
	return &RateLimiter{
		rdb:     rdb,
		buckets: make(map[string]*memBucket),
	}
}

// Allow сообщает, можно ли пропустить ключ. retryAfter > 0, если нельзя.
func (l *RateLimiter) Allow(ctx context.Context, key string, limit int, window time.Duration) (bool, time.Duration) {
	if l == nil || limit <= 0 || key == "" {
		return true, 0
	}
	if l.rdb != nil {
		return l.allowRedis(ctx, key, limit, window)
	}
	return l.allowMemory(key, limit, window)
}

func (l *RateLimiter) allowRedis(ctx context.Context, key string, limit int, window time.Duration) (bool, time.Duration) {
	ms := window.Milliseconds()
	if ms < 1 {
		ms = 1
	}
	res, err := rateLimitScript.Run(ctx, l.rdb, []string{"rl:" + key}, ms).Slice()
	if err != nil || len(res) < 2 {
		// Redis недоступен — не открывать периметр целиком.
		ok, retry := l.allowMemory(key, limit, window)
		return ok, retry
	}
	n, _ := toInt64(res[0])
	ttl, _ := toInt64(res[1])
	if n > int64(limit) {
		if ttl < 1 {
			ttl = ms
		}
		return false, time.Duration(ttl) * time.Millisecond
	}
	return true, 0
}

func (l *RateLimiter) allowMemory(key string, limit int, window time.Duration) (bool, time.Duration) {
	now := time.Now()
	l.mu.Lock()
	defer l.mu.Unlock()
	b := l.buckets[key]
	if b == nil || now.After(b.resetAt) {
		l.buckets[key] = &memBucket{count: 1, resetAt: now.Add(window)}
		return true, 0
	}
	if b.count >= limit {
		return false, time.Until(b.resetAt)
	}
	b.count++
	return true, 0
}

func toInt64(v any) (int64, bool) {
	switch n := v.(type) {
	case int64:
		return n, true
	case int:
		return int64(n), true
	case string:
		i, err := strconv.ParseInt(n, 10, 64)
		return i, err == nil
	default:
		return 0, false
	}
}

func (l *RateLimiter) Middleware(scope string, limit int, window time.Duration, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := clientIP(r)
		if ip == "" {
			ip = "unknown"
		}
		ok, retry := l.Allow(r.Context(), scope+":"+ip, limit, window)
		if !ok {
			sec := int(retry.Seconds())
			if sec < 1 {
				sec = 1
			}
			w.Header().Set("Retry-After", strconv.Itoa(sec))
			WriteErr(w, r, http.StatusTooManyRequests, "too many requests")
			return
		}
		next.ServeHTTP(w, r)
	})
}
