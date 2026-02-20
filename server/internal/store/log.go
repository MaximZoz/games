package store

import (
	"context"
	"database/sql"
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
	Limit  int
	Offset int
	UserID *uuid.UUID
	Source *string
	From   *time.Time
	To     *time.Time
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
