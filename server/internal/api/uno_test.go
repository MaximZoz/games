package api

import (
	"testing"

	"multigames/server/internal/uno"
)

func TestUnoBotPlaysLegalCardAndCallsUno(t *testing.T) {
	state := &uno.Game{
		Players: []uno.Player{
			{
				UserID: unoBotID,
				Seat:   0,
				Hand: []uno.Card{
					{ID: "red-5-test", Color: uno.ColorRed, Kind: uno.KindNumber, Number: 5},
					{ID: "blue-7-test", Color: uno.ColorBlue, Kind: uno.KindNumber, Number: 7},
				},
			},
			{
				UserID: "human",
				Seat:   1,
				Hand: []uno.Card{
					{ID: "yellow-2-test", Color: uno.ColorYellow, Kind: uno.KindNumber, Number: 2},
				},
			},
		},
		DiscardPile:             []uno.Card{{ID: "red-3-test", Color: uno.ColorRed, Kind: uno.KindNumber, Number: 3}},
		CurrentColor:            uno.ColorRed,
		Direction:               1,
		CurrentIndex:            0,
		Status:                  uno.StatusActive,
		TargetScore:             uno.DefaultTargetScore,
		Wild4PlayerIndex:        -1,
		ColorChooserIndex:       -1,
		UnoVulnerableIndex:      -1,
		PendingRoundWinnerIndex: -1,
	}

	if err := unoApplyBotAction(state); err != nil {
		t.Fatalf("bot action: %v", err)
	}
	if state.LastPlayedBy != unoBotID {
		t.Fatalf("last played by %q", state.LastPlayedBy)
	}
	if len(state.Players[0].Hand) != 1 || !state.Players[0].SaidUno {
		t.Fatalf("bot hand=%d saidUno=%v", len(state.Players[0].Hand), state.Players[0].SaidUno)
	}
	if state.CurrentIndex != 1 {
		t.Fatalf("current index=%d want 1", state.CurrentIndex)
	}
}

func TestValidateUnoActionActor(t *testing.T) {
	state, err := uno.NewGame([]string{"one", "two"}, 42)
	if err != nil {
		t.Fatal(err)
	}
	notCurrent := 1 - state.CurrentIndex
	if err := validateUnoActionActor(state, notCurrent, uno.Action{Type: uno.ActionDraw}); err == nil {
		t.Fatal("out-of-turn draw must be rejected")
	}
	if err := validateUnoActionActor(state, notCurrent, uno.Action{Type: uno.ActionForfeit}); err != nil {
		t.Fatalf("forfeit outside turn: %v", err)
	}
}
