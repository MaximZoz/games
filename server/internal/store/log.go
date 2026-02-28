package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type AppLog struct {
	EventID    string
	EventTime  string
	Source     string
	MethodName string
	HTTPMethod *string
	Path       *string
	StatusCode *int
	DurationMS *int64
	UserID     *string
	IP         *string
	UserAgent  *string
	Level      string
	Message    *string
	Metadata   []byte
}

type ListAppLogsParams struct {
	Limit      int
	Offset     int
	UserID     *uuid.UUID
	Source     *string
	MethodName *string
	From       *time.Time
	To         *time.Time
}

func ListAppLogs(ctx context.Context, pool *pgxpool.Pool, p ListAppLogsParams) ([]AppLog, error) {
	if p.Limit <= 0 {
		p.Limit = 100
	}
	if p.Limit > 2000 {
		p.Limit = 2000
	}
	if p.Offset < 0 {
		p.Offset = 0
	}

	query := `
		SELECT
			event_id,
			event_time,
			source,
			method_name,
			http_method,
			path,
			status_code,
			duration_ms,
			user_id::text,
			ip,
			user_agent,
			level,
			message,
			metadata
		FROM app_logs
	`
	args := make([]any, 0, 5)
	conds := make([]string, 0, 4)

	if p.UserID != nil {
		args = append(args, *p.UserID)
		conds = append(conds, fmt.Sprintf("user_id = $%d", len(args)))
	}
	if p.Source != nil && strings.TrimSpace(*p.Source) != "" {
		args = append(args, strings.TrimSpace(*p.Source))
		conds = append(conds, fmt.Sprintf("source = $%d", len(args)))
	}
	if p.MethodName != nil && strings.TrimSpace(*p.MethodName) != "" {
		args = append(args, strings.TrimSpace(*p.MethodName))
		conds = append(conds, fmt.Sprintf("method_name = $%d", len(args)))
	}
	if p.From != nil {
		args = append(args, p.From.UTC())
		conds = append(conds, fmt.Sprintf("event_time >= $%d", len(args)))
	}
	if p.To != nil {
		args = append(args, p.To.UTC())
		conds = append(conds, fmt.Sprintf("event_time <= $%d", len(args)))
	}
	if len(conds) > 0 {
		query += " WHERE " + strings.Join(conds, " AND ")
	}

	args = append(args, p.Limit)
	limitPos := len(args)
	args = append(args, p.Offset)
	offsetPos := len(args)
	query += fmt.Sprintf(" ORDER BY event_time DESC LIMIT $%d OFFSET $%d", limitPos, offsetPos)

	rows, err := pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]AppLog, 0, p.Limit)
	for rows.Next() {
		var item AppLog
		var eventTime time.Time
		var httpMethod sql.NullString
		var path sql.NullString
		var statusCode sql.NullInt64
		var durationMS sql.NullInt64
		var userID sql.NullString
		var ip sql.NullString
		var userAgent sql.NullString
		var message sql.NullString
		var metadata []byte

		if err := rows.Scan(
			&item.EventID,
			&eventTime,
			&item.Source,
			&item.MethodName,
			&httpMethod,
			&path,
			&statusCode,
			&durationMS,
			&userID,
			&ip,
			&userAgent,
			&item.Level,
			&message,
			&metadata,
		); err != nil {
			return nil, err
		}

		item.EventTime = eventTime.UTC().Format(time.RFC3339Nano)
		item.HTTPMethod = nullStringPtr(httpMethod)
		item.Path = nullStringPtr(path)
		item.StatusCode = nullIntPtr(statusCode)
		item.DurationMS = nullInt64Ptr(durationMS)
		item.UserID = nullStringPtr(userID)
		item.IP = nullStringPtr(ip)
		item.UserAgent = nullStringPtr(userAgent)
		item.Message = nullStringPtr(message)
		item.Metadata = metadata

		result = append(result, item)
	}

	return result, rows.Err()
}

// TruncateAppLogs удаляет все записи из app_logs.
func TruncateAppLogs(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `TRUNCATE app_logs`)
	return err
}

func nullStringPtr(v sql.NullString) *string {
	if !v.Valid {
		return nil
	}
	s := v.String
	return &s
}

func nullIntPtr(v sql.NullInt64) *int {
	if !v.Valid {
		return nil
	}
	n := int(v.Int64)
	return &n
}

func nullInt64Ptr(v sql.NullInt64) *int64 {
	if !v.Valid {
		return nil
	}
	n := v.Int64
	return &n
}

// InsertAppLogParams для прямой вставки в app_logs (обход файла).
type InsertAppLogParams struct {
	EventID    string
	EventTime  time.Time
	Source     string
	MethodName string
	UserID     *uuid.UUID
	Level      string
	Message    string
	Metadata   map[string]interface{}
	HTTPMethod *string
	Path       *string
	StatusCode *int
	DurationMS *int64
}

// InsertAppLog вставляет событие напрямую в БД. Используется для presence, когда файл может не работать.
func InsertAppLog(ctx context.Context, pool *pgxpool.Pool, p InsertAppLogParams) error {
	if p.EventID == "" {
		p.EventID = uuid.NewString()
	}
	if p.Source == "" {
		p.Source = "backend"
	}
	if p.MethodName == "" {
		p.MethodName = "unspecified"
	}
	if p.Level == "" {
		p.Level = "info"
	}
	if p.EventTime.IsZero() {
		p.EventTime = time.Now().UTC()
	}
	rawPayload := map[string]interface{}{
		"event_id":    p.EventID,
		"event_time":  p.EventTime.Format(time.RFC3339Nano),
		"source":      p.Source,
		"method_name": p.MethodName,
		"level":       p.Level,
		"message":     p.Message,
		"metadata":    p.Metadata,
	}
	if p.UserID != nil {
		rawPayload["user_id"] = p.UserID.String()
	}
	if p.HTTPMethod != nil {
		rawPayload["http_method"] = *p.HTTPMethod
	}
	if p.Path != nil {
		rawPayload["path"] = *p.Path
	}
	rawJSON, err := json.Marshal(rawPayload)
	if err != nil {
		return err
	}
	var userID any
	if p.UserID != nil {
		userID = *p.UserID
	}
	var metadataJSON []byte
	if p.Metadata != nil {
		metadataJSON, _ = json.Marshal(p.Metadata)
	}
	_, err = pool.Exec(ctx, `
		INSERT INTO app_logs (
			event_id, event_time, source, method_name,
			user_id, level, message, metadata, raw_payload,
			http_method, path, status_code, duration_ms
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		ON CONFLICT (event_id) DO NOTHING
	`, p.EventID, p.EventTime, p.Source, p.MethodName,
		userID, p.Level, p.Message, metadataJSON, rawJSON,
		p.HTTPMethod, p.Path, p.StatusCode, p.DurationMS)
	return err
}
