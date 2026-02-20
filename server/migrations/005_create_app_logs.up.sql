CREATE TABLE IF NOT EXISTS app_logs (
    event_id    TEXT PRIMARY KEY,
    event_time  TIMESTAMPTZ NOT NULL,
    source      TEXT NOT NULL,
    method_name TEXT NOT NULL,
    http_method TEXT,
    path        TEXT,
    status_code INTEGER,
    duration_ms BIGINT,
    user_id     UUID REFERENCES users (id) ON DELETE SET NULL,
    ip          TEXT,
    user_agent  TEXT,
    level       TEXT NOT NULL DEFAULT 'info',
    message     TEXT,
    metadata    JSONB,
    raw_payload JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_logs_event_time ON app_logs (event_time DESC);
CREATE INDEX IF NOT EXISTS idx_app_logs_source_time ON app_logs (source, event_time DESC);
CREATE INDEX IF NOT EXISTS idx_app_logs_user_time ON app_logs (user_id, event_time DESC);
