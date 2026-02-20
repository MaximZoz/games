package store

import (
	"context"
	"database/sql"
	"time"

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

func ListAppLogs(ctx context.Context, pool *pgxpool.Pool, limit, offset int) ([]AppLog, error) {
	rows, err := pool.Query(ctx, `
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
		ORDER BY event_time DESC
		LIMIT $1 OFFSET $2
	`, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]AppLog, 0, limit)
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
