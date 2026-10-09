package api

import (
	"strconv"
	"testing"
)

func TestChessClockBudgetMs(t *testing.T) {
	cases := map[string]struct {
		base int64
		inc  int64
	}{
		"classic": {60 * 60 * 1000, 0},
		"rapid":   {10 * 60 * 1000, 0},
		"blitz":   {5 * 60 * 1000, 0},
		"bullet":  {3 * 60 * 1000, 2 * 1000},
	}
	for mode, want := range cases {
		base, inc := chessClockBudgetMs(mode)
		if base != want.base || inc != want.inc {
			t.Errorf("%s: got base=%d inc=%d, want base=%d inc=%d",
				mode, base, inc, want.base, want.inc)
		}
	}
	// Неизвестный режим — как классика.
	if base, inc := chessClockBudgetMs("???"); base != 60*60*1000 || inc != 0 {
		t.Errorf("unknown mode fallback wrong: base=%d inc=%d", base, inc)
	}
}

func TestChessClockInitFields(t *testing.T) {
	fields := chessClockInitFields("bullet")
	m := map[string]string{}
	for i := 0; i+1 < len(fields); i += 2 {
		m[fields[i].(string)] = fields[i+1].(string)
	}
	if m["clock_ms_0"] != "180000" || m["clock_ms_1"] != "180000" {
		t.Errorf("bullet base wrong: %v", m)
	}
	if m["clock_inc_ms"] != "2000" {
		t.Errorf("bullet inc wrong: %v", m)
	}
	if !chessClockPresent(m) {
		t.Error("clock should be present after init")
	}
}

func TestChessApplyMoveClock(t *testing.T) {
	// Старт хода в t0, ход сделан через 5 секунд; прибавка 2с.
	t0 := int64(1_000_000)
	m := map[string]string{
		"clock_ms_0":   "180000",
		"clock_ms_1":   "180000",
		"clock_inc_ms": "2000",
		"clock_ts":     strconv.FormatInt(t0, 10),
	}
	fields := chessApplyMoveClock(m, 0, t0+5000)
	if fields == nil {
		t.Fatal("expected fields")
	}
	// 180000 - 5000 + 2000 = 177000
	if m["clock_ms_0"] != "177000" {
		t.Errorf("clock_ms_0 = %s, want 177000", m["clock_ms_0"])
	}
	// Часы соперника не изменились, отметка времени перенесена.
	if m["clock_ms_1"] != "180000" {
		t.Errorf("clock_ms_1 = %s, want 180000", m["clock_ms_1"])
	}
	if m["clock_ts"] != strconv.FormatInt(t0+5000, 10) {
		t.Errorf("clock_ts not advanced: %s", m["clock_ts"])
	}
}

func TestChessApplyMoveClockNoUnderflow(t *testing.T) {
	t0 := int64(1_000_000)
	m := map[string]string{
		"clock_ms_0":   "1000",
		"clock_ms_1":   "1000",
		"clock_inc_ms": "0",
		"clock_ts":     strconv.FormatInt(t0, 10),
	}
	// Думал 10 секунд при остатке 1с — не уходит в минус.
	chessApplyMoveClock(m, 0, t0+10000)
	if m["clock_ms_0"] != "0" {
		t.Errorf("clock_ms_0 = %s, want 0 (clamped)", m["clock_ms_0"])
	}
}

func TestChessApplyMoveClockNoClock(t *testing.T) {
	m := map[string]string{"state": "x"}
	if fields := chessApplyMoveClock(m, 0, 123); fields != nil {
		t.Error("expected nil fields when no clock present")
	}
}
