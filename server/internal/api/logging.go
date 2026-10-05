package api

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"strings"
	"time"

	"multigames/server/internal/applog"
	"multigames/server/internal/auth"
	"multigames/server/internal/store"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type statusRecorder struct {
	http.ResponseWriter
	statusCode int
}

func (w *statusRecorder) WriteHeader(code int) {
	w.statusCode = code
	w.ResponseWriter.WriteHeader(code)
}

// Hijack поддерживает WebSocket upgrade: делегирует к нижележащему ResponseWriter.
func (w *statusRecorder) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	if h, ok := w.ResponseWriter.(http.Hijacker); ok {
		return h.Hijack()
	}
	return nil, nil, fmt.Errorf("response writer does not support hijacking")
}

// RequestLogger логирует все HTTP-запросы бэкенда (в файл и/или напрямую в БД).
func RequestLogger(secret []byte, writer *applog.FileWriter, pool *pgxpool.Pool, directDB bool, next http.Handler) http.Handler {
	if writer == nil && !(pool != nil && directDB) {
		return next
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Health-check Fly не логируем — иначе InsertAppLog держит слот
		// concurrency и валит servicecheck при нагрузке (multi/poll).
		if r.URL.Path == "/api/start" {
			next.ServeHTTP(w, r)
			return
		}

		started := time.Now().UTC()
		rec := &statusRecorder{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(rec, r)

		status := rec.statusCode
		duration := time.Since(started).Milliseconds()

		metadata := map[string]interface{}{}
		if r.URL.RawQuery != "" {
			metadata["query"] = r.URL.RawQuery
		}

		event := applog.Event{
			Source:     "backend",
			MethodName: "http.request",
			HTTPMethod: r.Method,
			Path:       r.URL.Path,
			StatusCode: &status,
			DurationMS: &duration,
			IP:         clientIP(r),
			UserAgent:  r.UserAgent(),
			Metadata:   metadata,
		}
		if userID := userIDFromBearer(secret, r.Header.Get("Authorization")); userID != "" {
			event.UserID = userID
		}

		if writer != nil {
			_ = writer.Append(event)
		}
		var uid *uuid.UUID
		if event.UserID != "" {
			if parsed, err := uuid.Parse(event.UserID); err == nil {
				uid = &parsed
				// Обновляем last_seen при каждом auth-запросе (не только WebSocket)
				if pool != nil {
					go store.UpdateUserLastSeen(context.Background(), pool, parsed)
				}
			}
		}
		if pool != nil && directDB {
			// Асинхронно: иначе каждый HTTP-запрос ждёт Postgres и упирается
			// в Fly hard_limit concurrency (прокси перестаёт роутить на :8080).
			msg := r.Method + " " + r.URL.Path
			if r.URL.RawQuery != "" {
				msg += "?" + r.URL.RawQuery
			}
			path := r.URL.Path
			method := r.Method
			go func() {
				ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
				defer cancel()
				_ = store.InsertAppLog(ctx, pool, store.InsertAppLogParams{
					EventTime:  started,
					Source:     "backend",
					MethodName: "http.request",
					UserID:     uid,
					Level:      "info",
					Message:    msg,
					Metadata:   metadata,
					HTTPMethod: &method,
					Path:       &path,
					StatusCode: &status,
					DurationMS: &duration,
				})
			}()
		}
	})
}

type FrontendLogHandler struct {
	Writer       *applog.FileWriter
	JWTSecret    []byte
	Pool        *pgxpool.Pool
	DirectDB    bool
}

type frontendLogRequest struct {
	EventID    string                 `json:"event_id"`
	EventTime  string                 `json:"event_time"`
	MethodName string                 `json:"method_name"`
	HTTPMethod string                 `json:"http_method"`
	Path       string                 `json:"path"`
	StatusCode *int                   `json:"status_code"`
	DurationMS *int64                 `json:"duration_ms"`
	Level      string                 `json:"level"`
	Message    string                 `json:"message"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// Ingest принимает frontend-события и пишет их в файл и/или напрямую в БД.
func (h *FrontendLogHandler) Ingest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.Writer == nil && !(h.Pool != nil && h.DirectDB) {
		w.WriteHeader(http.StatusAccepted)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 64*1024)
	var req frontendLogRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}

	if req.MethodName == "" {
		req.MethodName = "frontend.request"
	}

	event := applog.Event{
		EventID:    req.EventID,
		EventTime:  req.EventTime,
		Source:     "frontend",
		MethodName: req.MethodName,
		HTTPMethod: req.HTTPMethod,
		Path:       req.Path,
		StatusCode: req.StatusCode,
		DurationMS: req.DurationMS,
		Level:      req.Level,
		Message:    req.Message,
		Metadata:   req.Metadata,
		IP:         clientIP(r),
		UserAgent:  r.UserAgent(),
	}

	if userID := userIDFromBearer(h.JWTSecret, r.Header.Get("Authorization")); userID != "" {
		event.UserID = userID
	}
	if event.UserID == "" && req.Metadata != nil {
		if v, ok := req.Metadata["user_id"].(string); ok {
			if _, err := uuid.Parse(v); err == nil {
				event.UserID = v
			}
		}
	}

	if h.Writer != nil {
		if err := h.Writer.Append(event); err != nil {
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
	}
	if h.Pool != nil && h.DirectDB {
		var uid *uuid.UUID
		if event.UserID != "" {
			if parsed, err := uuid.Parse(event.UserID); err == nil {
				uid = &parsed
			}
		}
		evTime := time.Now().UTC()
		if event.EventTime != "" {
			if t, err := time.Parse(time.RFC3339Nano, event.EventTime); err == nil {
				evTime = t.UTC()
			}
		}
		level := event.Level
		if level == "" {
			level = "info"
		}
		pool := h.Pool
		params := store.InsertAppLogParams{
			EventID:    event.EventID,
			EventTime:  evTime,
			Source:     "frontend",
			MethodName: event.MethodName,
			UserID:     uid,
			Level:      level,
			Message:    event.Message,
			Metadata:   event.Metadata,
			HTTPMethod: strPtr(event.HTTPMethod),
			Path:       strPtr(event.Path),
			StatusCode: event.StatusCode,
			DurationMS: event.DurationMS,
		}
		go func() {
			_ = store.InsertAppLog(context.Background(), pool, params)
		}()
	}
	w.WriteHeader(http.StatusAccepted)
}

func strPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func userIDFromBearer(secret []byte, header string) string {
	if len(secret) == 0 || strings.TrimSpace(header) == "" {
		return ""
	}
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	claims, err := auth.ParseJWT(secret, parts[1])
	if err != nil {
		return ""
	}
	if _, err := uuid.Parse(claims.UserID); err != nil {
		return ""
	}
	return claims.UserID
}

func clientIP(r *http.Request) string {
	if r == nil {
		return ""
	}
	if ip := strings.TrimSpace(r.Header.Get("Fly-Client-IP")); ip != "" {
		return ip
	}
	if forwarded := strings.TrimSpace(r.Header.Get("X-Forwarded-For")); forwarded != "" {
		parts := strings.Split(forwarded, ",")
		if len(parts) > 0 {
			return strings.TrimSpace(parts[0])
		}
	}
	if realIP := strings.TrimSpace(r.Header.Get("X-Real-IP")); realIP != "" {
		return realIP
	}
	host, _, err := net.SplitHostPort(strings.TrimSpace(r.RemoteAddr))
	if err == nil {
		return host
	}
	return strings.TrimSpace(r.RemoteAddr)
}
