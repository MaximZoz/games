package applog

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Event хранит единый формат события для фронтенда и бэкенда.
type Event struct {
	EventID    string                 `json:"event_id"`
	EventTime  string                 `json:"event_time"`
	Source     string                 `json:"source"`
	MethodName string                 `json:"method_name"`
	HTTPMethod string                 `json:"http_method,omitempty"`
	Path       string                 `json:"path,omitempty"`
	StatusCode *int                   `json:"status_code,omitempty"`
	DurationMS *int64                 `json:"duration_ms,omitempty"`
	UserID     string                 `json:"user_id,omitempty"`
	IP         string                 `json:"ip,omitempty"`
	UserAgent  string                 `json:"user_agent,omitempty"`
	Level      string                 `json:"level,omitempty"`
	Message    string                 `json:"message,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// FileWriter пишет события в JSONL файл (один JSON на строку).
type FileWriter struct {
	mu   sync.Mutex
	file *os.File
}

func NewFileWriter(path string) (*FileWriter, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, err
	}
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return nil, err
	}
	return &FileWriter{file: f}, nil
}

func (w *FileWriter) Append(event Event) error {
	if event.EventID == "" {
		event.EventID = uuid.NewString()
	}
	if event.EventTime == "" {
		event.EventTime = time.Now().UTC().Format(time.RFC3339Nano)
	}
	if event.Source == "" {
		event.Source = "unknown"
	}
	if event.MethodName == "" {
		event.MethodName = "unspecified"
	}
	if event.Level == "" {
		if event.StatusCode != nil && *event.StatusCode >= 400 {
			event.Level = "error"
		} else {
			event.Level = "info"
		}
	}

	raw, err := json.Marshal(event)
	if err != nil {
		return err
	}

	w.mu.Lock()
	defer w.mu.Unlock()
	_, err = w.file.Write(append(raw, '\n'))
	return err
}

func (w *FileWriter) Close() error {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.file.Close()
}
