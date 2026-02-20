package applog

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Importer переносит события из файла в PostgreSQL.
type Importer struct {
	pool            *pgxpool.Pool
	logPath         string
	statePath       string
	interval        time.Duration
	retention       time.Duration
	cleanupInterval time.Duration
	lastCleanupAt   time.Time

	mu sync.Mutex
}

func NewImporter(
	pool *pgxpool.Pool,
	logPath, statePath string,
	interval, retention, cleanupInterval time.Duration,
) *Importer {
	if interval <= 0 {
		interval = 5 * time.Second
	}
	if cleanupInterval <= 0 {
		cleanupInterval = time.Hour
	}
	return &Importer{
		pool:            pool,
		logPath:         logPath,
		statePath:       statePath,
		interval:        interval,
		retention:       retention,
		cleanupInterval: cleanupInterval,
	}
}

func (i *Importer) Start(ctx context.Context) {
	ticker := time.NewTicker(i.interval)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				_ = i.SyncNow(ctx)
			}
		}
	}()
}

func (i *Importer) SyncNow(ctx context.Context) error {
	i.mu.Lock()
	defer i.mu.Unlock()

	offset, err := i.readOffset()
	if err != nil {
		return err
	}

	f, err := os.Open(i.logPath)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	defer f.Close()

	stat, err := f.Stat()
	if err != nil {
		return err
	}
	if offset > stat.Size() {
		offset = 0 // файл был ротирован/перезаписан
	}

	if _, err := f.Seek(offset, io.SeekStart); err != nil {
		return err
	}

	reader := bufio.NewReader(f)
	current := offset
	for {
		line, readErr := reader.ReadBytes('\n')
		if len(line) > 0 {
			if line[len(line)-1] != '\n' {
				// не завершённая строка в конце — подождём следующей итерации
				break
			}

			trimmed := bytes.TrimSpace(line)
			if len(trimmed) == 0 {
				current += int64(len(line))
			} else {
				advance, err := i.persistLine(ctx, trimmed)
				if err != nil {
					return err
				}
				if advance {
					current += int64(len(line))
				}
			}
		}

		if errors.Is(readErr, io.EOF) {
			break
		}
		if readErr != nil {
			return readErr
		}
	}

	if err := i.writeOffset(current); err != nil {
		return err
	}

	return i.cleanupOldLogsIfNeeded(ctx)
}

func (i *Importer) persistLine(ctx context.Context, line []byte) (bool, error) {
	var payload Event
	if err := json.Unmarshal(line, &payload); err != nil {
		// Битую строку пропускаем, чтобы импорт не "застрял".
		return true, nil
	}

	if payload.EventID == "" {
		payload.EventID = uuid.NewString()
	}
	if payload.Source == "" {
		payload.Source = "unknown"
	}
	if payload.MethodName == "" {
		payload.MethodName = "unspecified"
	}
	if payload.Level == "" {
		if payload.StatusCode != nil && *payload.StatusCode >= 400 {
			payload.Level = "error"
		} else {
			payload.Level = "info"
		}
	}

	eventTime := time.Now().UTC()
	if payload.EventTime != "" {
		if t, err := time.Parse(time.RFC3339Nano, payload.EventTime); err == nil {
			eventTime = t.UTC()
		}
	}

	var userID any
	if payload.UserID != "" {
		if id, err := uuid.Parse(payload.UserID); err == nil {
			userID = id
		}
	}

	var metadataRaw any
	if payload.Metadata != nil {
		b, err := json.Marshal(payload.Metadata)
		if err == nil {
			metadataRaw = b
		}
	}

	_, err := i.pool.Exec(ctx, `
		INSERT INTO app_logs (
			event_id, event_time, source, method_name,
			http_method, path, status_code, duration_ms,
			user_id, ip, user_agent, level, message,
			metadata, raw_payload
		) VALUES (
			$1, $2, $3, $4,
			$5, $6, $7, $8,
			$9, $10, $11, $12, $13,
			$14, $15
		)
		ON CONFLICT (event_id) DO NOTHING
	`,
		payload.EventID,
		eventTime,
		payload.Source,
		payload.MethodName,
		nullableString(payload.HTTPMethod),
		nullableString(payload.Path),
		payload.StatusCode,
		payload.DurationMS,
		userID,
		nullableString(payload.IP),
		nullableString(payload.UserAgent),
		payload.Level,
		nullableString(payload.Message),
		metadataRaw,
		line,
	)
	if err != nil {
		return false, err
	}

	return true, nil
}

func nullableString(v string) any {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	return v
}

func (i *Importer) readOffset() (int64, error) {
	raw, err := os.ReadFile(i.statePath)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	s := strings.TrimSpace(string(raw))
	if s == "" {
		return 0, nil
	}
	n, err := strconv.ParseInt(s, 10, 64)
	if err != nil || n < 0 {
		return 0, nil
	}
	return n, nil
}

func (i *Importer) writeOffset(offset int64) error {
	if err := os.MkdirAll(filepath.Dir(i.statePath), 0o755); err != nil {
		return err
	}
	return os.WriteFile(i.statePath, []byte(strconv.FormatInt(offset, 10)), 0o644)
}

func (i *Importer) cleanupOldLogsIfNeeded(ctx context.Context) error {
	if i.retention <= 0 {
		return nil
	}

	now := time.Now().UTC()
	if !i.lastCleanupAt.IsZero() && now.Sub(i.lastCleanupAt) < i.cleanupInterval {
		return nil
	}

	threshold := now.Add(-i.retention)
	if _, err := i.pool.Exec(ctx, `DELETE FROM app_logs WHERE event_time < $1`, threshold); err != nil {
		return err
	}
	i.lastCleanupAt = now
	return nil
}
