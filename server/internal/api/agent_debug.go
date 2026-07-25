package api

import (
	"encoding/json"
	"net/http"
	"os"
	"time"
)

const agentDebugLogPath = "/opt/cursor/logs/debug.log"

type agentDebugEntry struct {
	HypothesisID string         `json:"hypothesisId"`
	Location     string         `json:"location"`
	Message      string         `json:"message"`
	Data         map[string]any `json:"data"`
	Timestamp    int64          `json:"timestamp"`
}

func appendAgentDebugLog(entry agentDebugEntry) {
	if entry.Timestamp == 0 {
		entry.Timestamp = time.Now().UnixMilli()
	}
	raw, err := json.Marshal(entry)
	if err != nil {
		return
	}
	file, err := os.OpenFile(agentDebugLogPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return
	}
	defer file.Close()
	_, _ = file.Write(append(raw, '\n'))
}

func AgentDebugLogHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 16*1024)
	var entry agentDebugEntry
	if err := json.NewDecoder(r.Body).Decode(&entry); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	if entry.HypothesisID == "" || entry.Location == "" || entry.Message == "" {
		http.Error(w, "invalid debug entry", http.StatusBadRequest)
		return
	}
	appendAgentDebugLog(entry)
	w.WriteHeader(http.StatusAccepted)
}
