package durak

import "testing"

func TestBeats(t *testing.T) {
	trump := Clubs
	cases := []struct {
		a, b Card
		want bool
	}{
		{Card{10, Hearts}, Card{9, Hearts}, true},
		{Card{9, Hearts}, Card{10, Hearts}, false},
		{Card{14, Hearts}, Card{6, Diamonds}, false},
		{Card{6, Clubs}, Card{14, Hearts}, true},
		{Card{6, Hearts}, Card{6, Clubs}, false},
		{Card{12, Clubs}, Card{11, Clubs}, true},
	}
	for i, c := range cases {
		if got := c.a.Beats(c.b, trump); got != c.want {
			t.Fatalf("#%d %v beats %v (trump=%v) = %v, want %v", i, c.a, c.b, trump, got, c.want)
		}
	}
}

func TestLeadTrumpIsLowestOfAttacker(t *testing.T) {
	st, err := New([]string{"a", "b"}, 36, ModePodkidnoi, 42)
	if err != nil {
		t.Fatalf("new: %v", err)
	}
	got := st.LeadTrump()
	var want *Card
	for _, c := range st.Hands[st.AttackerIndex] {
		if c.Suit != st.Trump {
			continue
		}
		if want == nil || c.Rank < want.Rank {
			cc := c
			want = &cc
		}
	}
	if want == nil {
		if got != nil {
			t.Fatalf("LeadTrump=%v, want nil", *got)
		}
		return
	}
	if got == nil || got.Rank != want.Rank || got.Suit != want.Suit {
		t.Fatalf("LeadTrump=%v, want %v", got, *want)
	}
}

func TestNewDeal(t *testing.T) {
	st, err := New([]string{"a", "b"}, 36, ModePodkidnoi, 42)
	if err != nil {
		t.Fatalf("new: %v", err)
	}
	if got := len(st.Hands[0]); got != 6 {
		t.Fatalf("hand[0] = %d, want 6", got)
	}
	if got := len(st.Deck); got != 24 {
		t.Fatalf("deck = %d, want 24 (36-12)", got)
	}
	if st.TrumpCard.Suit != st.Trump {
		t.Fatalf("trump mismatch")
	}
}

func TestAttackDefendBito(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Hearts}, {8, Spades}},
			{{7, Hearts}, {9, Clubs}},
		},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{6, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase = %v, want defend", st.Phase)
	}
	if err := st.Defend(1, Card{7, Hearts}, -1); err != nil {
		t.Fatalf("defend: %v", err)
	}
	// Атакующему нечего подкинуть — пауза показа стола, затем отбой.
	if st.Phase != PhaseBitoReveal {
		t.Fatalf("phase after defend = %v, want bito_reveal", st.Phase)
	}
	if len(st.Table) != 1 || st.Table[0].Defense == nil {
		t.Fatalf("table should stay visible during reveal: %v", st.Table)
	}
	if err := st.FinishBitoReveal(); err != nil {
		t.Fatalf("FinishBitoReveal: %v", err)
	}
	if len(st.Table) != 0 || len(st.BitoPile) != 2 {
		t.Fatalf("bito state: table=%v bito=%v", st.Table, st.BitoPile)
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase after reveal = %v, want attack", st.Phase)
	}
	if st.AttackerIndex != 1 {
		t.Fatalf("next attacker = %d, want 1", st.AttackerIndex)
	}
}

func TestAutoBitoWhenDefenderEmpty(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Hearts}, {8, Spades}},
			{{7, Hearts}}, // единственная карта — отбил и рука пуста
		},
		Deck: []Card{
			{9, Hearts}, {10, Hearts}, {11, Hearts}, {12, Hearts},
			{9, Spades}, {10, Spades}, {11, Spades}, {12, Spades},
			{9, Clubs}, {10, Clubs},
		},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{6, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if err := st.Defend(1, Card{7, Hearts}, -1); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase after auto-bito = %v, want attack", st.Phase)
	}
	if len(st.Table) != 0 || len(st.BitoPile) != 2 {
		t.Fatalf("auto-bito table/bito: table=%d bito=%d", len(st.Table), len(st.BitoPile))
	}
	if st.AttackerIndex != 1 {
		t.Fatalf("next attacker = %d, want 1 (бывший защитник)", st.AttackerIndex)
	}
	if st.Status != StatusActive {
		t.Fatalf("status = %v, want active", st.Status)
	}
	// Добор после бито: у бывшего защитника снова есть карты.
	if len(st.Hands[1]) == 0 {
		t.Fatalf("defender should refill after auto-bito")
	}
}

// Защитник отбил часть, рука пуста, осталась неотбитая атака —
// бита для отбитых, неотбитая возвращается атакующему (не «взять»).
func TestDefenderEmptyReturnsUnbeatenToAttacker(t *testing.T) {
	king := Card{13, Spades}
	tenH := Card{10, Hearts}
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{8, Spades}},
			{tenH},
		},
		Table: []Pair{
			{Attack: Card{9, Hearts}}, // бьём последней картой
			{Attack: king},            // остаётся неотбитым
		},
		Deck: []Card{
			{6, Hearts}, {7, Hearts}, {8, Hearts}, {12, Hearts},
			{6, Spades}, {7, Spades}, {9, Spades}, {10, Spades},
			{6, Clubs}, {7, Clubs},
		},
		Trump:         Clubs,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Defend(1, tenH, 0); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if len(st.Table) != 0 {
		t.Fatalf("table should be cleared, got %d pairs", len(st.Table))
	}
	if len(st.BitoPile) != 2 {
		t.Fatalf("bito = %d, want 2 (9♥+10♥)", len(st.BitoPile))
	}
	foundKing := false
	for _, c := range st.Hands[0] {
		if c == king {
			foundKing = true
			break
		}
	}
	if !foundKing {
		t.Fatalf("king should return to attacker; hand=%v", st.Hands[0])
	}
	if st.AttackerIndex != 1 {
		t.Fatalf("attacker = %d, want 1 (бывший защитник)", st.AttackerIndex)
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase = %v, want attack", st.Phase)
	}
	if st.LastWasTake {
		t.Fatalf("must not be take")
	}
}

func TestHealDefenderEmptyStuck(t *testing.T) {
	king := Card{13, Spades}
	defCard := Card{12, Hearts}
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{8, Spades}},
			{}, // пустая рука, стол ещё лежит
		},
		Table: []Pair{
			{Attack: Card{9, Hearts}, Defense: &defCard},
			{Attack: king},
		},
		Deck: []Card{
			{6, Hearts}, {7, Hearts}, {8, Hearts}, {10, Hearts},
			{6, Spades}, {7, Spades}, {9, Spades}, {10, Spades},
			{6, Clubs}, {7, Clubs},
		},
		Trump:         Clubs,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	st.HealDefenderEmpty()
	if len(st.Table) != 0 {
		t.Fatalf("table=%d", len(st.Table))
	}
	found := false
	for _, c := range st.Hands[0] {
		if c == king {
			found = true
		}
	}
	if !found {
		t.Fatalf("unbeaten king not returned: %v", st.Hands[0])
	}
	if len(st.BitoPile) != 2 {
		t.Fatalf("bito=%d want 2", len(st.BitoPile))
	}
}

func TestAttackManySameRank(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{9, Hearts}, {9, Spades}, {10, Clubs}},
			{{6, Hearts}, {7, Hearts}, {8, Hearts}, {9, Clubs}, {10, Hearts}, {11, Hearts}},
		},
		Trump:         Diamonds,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.AttackMany(0, []Card{{9, Hearts}, {9, Spades}}); err != nil {
		t.Fatalf("attack many: %v", err)
	}
	if len(st.Table) != 2 {
		t.Fatalf("table = %d, want 2", len(st.Table))
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase = %v, want defend", st.Phase)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase = %v", st.Phase)
	}
	// Во время защиты можно подкинуть карту того же ранга → снова defend.
	st.Hands[0] = append(st.Hands[0], Card{9, Diamonds}, Card{9, Clubs})
	if err := st.AttackMany(0, []Card{{9, Diamonds}}); err != nil {
		t.Fatalf("throw-in during defend: %v", err)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase after throw-in=%v want defend", st.Phase)
	}
	if len(st.Table) != 3 {
		t.Fatalf("table after throw-in = %d, want 3", len(st.Table))
	}
	// Чужой ранг — нельзя.
	if err := st.AttackMany(0, []Card{{10, Clubs}}); err == nil {
		t.Fatalf("expected error for wrong rank during defend")
	}
}

func TestPlaceShareNumerators(t *testing.T) {
	if got := PlaceShareNumerators(3); len(got) != 2 || got[0] != 2 || got[1] != 1 {
		t.Fatalf("3p shares=%v want [2 1]", got)
	}
	if got := PlaceShareNumerators(4); len(got) != 3 || got[0] != 2 || got[1] != 1 || got[2] != 1 {
		t.Fatalf("4p shares=%v want [2 1 1]", got)
	}
	if CreditForPlace(10, 3, 0) != 20 || CreditForPlace(10, 3, 1) != 10 {
		t.Fatalf("3p credits want 20/10, got %d/%d", CreditForPlace(10, 3, 0), CreditForPlace(10, 3, 1))
	}
	if CreditForPlace(10, 4, 0) != 20 || CreditForPlace(10, 4, 1) != 10 || CreditForPlace(10, 4, 2) != 10 {
		t.Fatalf("4p credits want 20/10/10")
	}
}

func TestWinnerPlaceOrderFinishedSequence(t *testing.T) {
	st := &State{
		PlayerIDs:       []string{"a", "b", "c"},
		Hands:           [][]Card{{}, {}, {{6, Hearts}}},
		FinishedIndices: []int{1, 0}, // b вышел первым, a — вторым
		LoserIndex:      2,
		Status:          StatusOver,
		Deck:            nil,
	}
	got := st.WinnerPlaceOrder()
	if len(got) != 2 || got[0] != 1 || got[1] != 0 {
		t.Fatalf("place order=%v want [1 0]", got)
	}
}

// Один сдался, двое доиграли: 1-е и 2-е места (дурак среди оставшихся — 2-е), сдавшийся вне списка.
func TestWinnerPlaceOrderAfterEliminate(t *testing.T) {
	st := &State{
		PlayerIDs:         []string{"a", "b", "c"},
		Hands:             [][]Card{{}, {{6, Hearts}}, {}},
		FinishedIndices:   []int{0}, // a вышел в ноль
		LoserIndex:        1,        // b — дурак
		EliminatedIndices: []int{2}, // c сдался раньше
		Status:            StatusOver,
		Deck:              nil,
	}
	got := st.WinnerPlaceOrder()
	if len(got) != 2 || got[0] != 0 || got[1] != 1 {
		t.Fatalf("place order=%v want [0 1] (1st + 2nd; eliminated out)", got)
	}
	// Доли банка 3p: 2/3 и 1/3 — без roll-up всего банка первому.
	if c1, c2 := CreditForPlace(2, 3, 0), CreditForPlace(2, 3, 1); c1 != 4 || c2 != 2 {
		t.Fatalf("credits want 4/2, got %d/%d", c1, c2)
	}
}

// Два выхода «в ноль» одной волной → TiedLeaders=2 (ничья 1–2).
func TestTiedLeadersOnSimultaneousFinish(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{},
			{},
			{{6, Hearts}, {7, Hearts}},
		},
		Deck:          nil,
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	st.checkOver()
	if st.TiedLeaders != 2 {
		t.Fatalf("TiedLeaders=%d want 2", st.TiedLeaders)
	}
	if st.Status != StatusOver || st.LoserIndex != 2 {
		t.Fatalf("status=%s loser=%d want over/2", st.Status, st.LoserIndex)
	}
	if len(st.FinishedIndices) != 2 {
		t.Fatalf("finished=%v want 2", st.FinishedIndices)
	}
}

// Пока партия active — loser_index = -1 (0 не должен считаться «дураком»).
func TestNewLoserIndexUnset(t *testing.T) {
	st, err := New([]string{"a", "b", "c"}, 36, ModePodkidnoi, 1)
	if err != nil {
		t.Fatal(err)
	}
	if st.LoserIndex != -1 {
		t.Fatalf("LoserIndex=%d want -1", st.LoserIndex)
	}
	raw, err := Encode(st)
	if err != nil {
		t.Fatal(err)
	}
	// Симулируем старый сейв без поля / с нулём.
	st2, err := Decode(`{"player_ids":["a","b"],"hands":[[],[]],"status":"active","loser_index":0,"phase":"attack","hand_size":6,"max_attacks":6,"attacker_index":0}`)
	if err != nil {
		t.Fatalf("Decode: %v", err)
	}
	if st2.LoserIndex != -1 {
		t.Fatalf("Decode active LoserIndex=%d want -1 (was %q)", st2.LoserIndex, raw)
	}
}

// Втроём добор должен дать карты всем, включая «среднего» между атакующим и защитником.
func TestRefillThreePlayersAllGetCards(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{9, Clubs}, {10, Clubs}, {11, Clubs}, {12, Clubs}},     // atk: 4
			{{9, Hearts}, {10, Hearts}},                             // def: 2
			{{9, Spades}, {10, Spades}, {11, Spades}, {12, Spades}}, // mid: 4
		},
		Deck: []Card{
			{6, Clubs}, {7, Clubs}, {8, Clubs}, {6, Hearts}, {7, Hearts}, {8, Hearts},
			{6, Spades}, {7, Spades}, {8, Spades}, {6, Diamonds}, {7, Diamonds},
			{8, Diamonds}, {9, Diamonds}, {10, Diamonds}, {11, Diamonds}, {12, Diamonds},
		},
		Trump:         Diamonds,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		RoundEnded:    true,
	}
	order := st.refillOrder()
	// atk=0, def=1 → [0, 2, 1]
	if len(order) != 3 || order[0] != 0 || order[1] != 2 || order[2] != 1 {
		t.Fatalf("refillOrder=%v want [0 2 1]", order)
	}
	st.refill()
	for i, h := range st.Hands {
		if len(h) != 6 {
			t.Fatalf("hand[%d]=%d want 6 (deck left=%d)", i, len(h), len(st.Deck))
		}
	}
	// 4+2+4=10, need 2+4+2=8 from deck → 16-8=8 left
	if len(st.Deck) != 8 {
		t.Fatalf("deck=%d want 8", len(st.Deck))
	}
}

// После «взял» втроём следующий атакующий тоже добирает до 6.
func TestRefillAfterTakeThreePlayers(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{9, Clubs}, {10, Clubs}}, // atk thrown
			{{11, Hearts}},            // def will take
			{{9, Spades}, {10, Spades}, {11, Spades}, {12, Spades}}, // 4 — раньше не добирал
		},
		Table: []Pair{
			{Attack: Card{7, Clubs}},
			{Attack: Card{7, Spades}},
		},
		Deck: []Card{
			{6, Clubs}, {7, Hearts}, {8, Hearts}, {6, Spades}, {7, Diamonds},
			{8, Diamonds}, {9, Diamonds}, {10, Diamonds}, {11, Diamonds},
			{12, Diamonds}, {6, Hearts}, {8, Clubs}, {12, Clubs}, {13, Clubs},
			{14, Clubs}, {6, Diamonds},
		},
		Trump:         Diamonds,
		AttackerIndex: 0,
		Phase:         PhaseTakeFollow,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		ThrowerIndex:  0,
		RoundEnded:    true,
	}
	if err := st.Done(0); err != nil {
		t.Fatalf("Done: %v", err)
	}
	if st.Phase != PhaseTakeReveal {
		t.Fatalf("phase=%s want take_reveal", st.Phase)
	}
	if err := st.FinishTakeReveal(); err != nil {
		t.Fatalf("FinishTakeReveal: %v", err)
	}
	// Защитник взял → ход следующему (c=2).
	if st.AttackerIndex != 2 {
		t.Fatalf("attacker=%d want 2", st.AttackerIndex)
	}
	for i, h := range st.Hands {
		if i == 1 {
			// взял 2 со стола + добор
			if len(h) < 6 {
				t.Fatalf("defender hand[%d]=%d want >=6", i, len(h))
			}
			continue
		}
		if len(h) != 6 {
			t.Fatalf("hand[%d]=%d want 6", i, len(h))
		}
	}
}

// Первый отбой без флага FirstRound (потерянный JSON) — всё равно лимит 5.
func TestFirstRoundCapWithoutFlag(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{6, Clubs}, {6, Spades}, {9, Clubs}, {10, Clubs}, {11, Clubs}, {12, Clubs}},
			{{7, Hearts}, {8, Hearts}, {9, Hearts}, {10, Hearts}, {11, Hearts}, {12, Hearts}},
			{{6, Diamonds}, {7, Diamonds}, {8, Diamonds}, {9, Diamonds}, {10, Diamonds}, {11, Diamonds}},
		},
		Trump:         Hearts,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		FirstRound:    false, // флаг потерян
		Mode:          ModePerevodnoi,
		Table: []Pair{
			{Attack: Card{9, Spades}},
			{Attack: Card{9, Diamonds}},
			{Attack: Card{10, Spades}},
			{Attack: Card{10, Diamonds}},
			{Attack: Card{11, Spades}},
		},
	}
	if !st.isFirstRoundActive() {
		t.Fatal("want isFirstRoundActive with empty bito")
	}
	if got := st.MaxAttacksThisRound(); got != 5 {
		t.Fatalf("MaxAttacksThisRound=%d want 5", got)
	}
	if err := st.AttackMany(0, []Card{{11, Clubs}}); err == nil {
		t.Fatal("expected ErrBadAttack for 6th card without FirstRound flag")
	}
}

// Защитник вышел «в ноль» при пустой колоде — ход не на нём, он в finished.
func TestDefenderEmptyPassesTurnWhenFinished(t *testing.T) {
	ace := Card{14, Hearts}
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{9, Clubs}, {10, Clubs}},
			{ace}, // последняя карта защитника
			{{8, Spades}, {9, Spades}, {10, Spades}},
		},
		Deck:          nil, // колода пуста — выход считается
		Trump:         Clubs,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		Table: []Pair{
			{Attack: Card{7, Hearts}},
		},
		FirstRound: false,
	}
	st.BitoPile = []Card{{6, Clubs}} // не первый отбой
	if err := st.Defend(1, ace, 0); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Status != StatusActive {
		t.Fatalf("status=%v want active (ещё двое играют)", st.Status)
	}
	if len(st.FinishedIndices) == 0 || st.FinishedIndices[0] != 1 {
		t.Fatalf("finished=%v want [1]", st.FinishedIndices)
	}
	if st.AttackerIndex == 1 {
		t.Fatal("attacker must not stay on finished defender")
	}
	if !st.isAlive(st.AttackerIndex) {
		t.Fatalf("attacker=%d must be alive", st.AttackerIndex)
	}
	// Бывший защитник вышел → ход следующему после него (c = 2), либо a если nextAliveAfter(1)=2.
	if st.AttackerIndex != 2 {
		t.Fatalf("attacker=%d want 2 (next after finished defender)", st.AttackerIndex)
	}
}

// Decode восстанавливает first_round, если биты ещё не было.
func TestDecodeHealsFirstRound(t *testing.T) {
	raw := `{"player_ids":["a","b"],` +
		`"hands":[[{"rank":6,"suit":"c"},{"rank":9,"suit":"c"}],` +
		`[{"rank":7,"suit":"h"},{"rank":8,"suit":"h"},{"rank":9,"suit":"h"},` +
		`{"rank":10,"suit":"h"},{"rank":11,"suit":"h"},{"rank":12,"suit":"h"}]],` +
		`"trump":"h","attacker_index":0,"phase":"defend","hand_size":6,"max_attacks":6,` +
		`"status":"active","table":[{"attack":{"rank":9,"suit":"h"}}],"bito":[]}`
	st, err := Decode(raw)
	if err != nil {
		t.Fatalf("Decode: %v", err)
	}
	if !st.FirstRound {
		t.Fatal("want FirstRound=true after Decode heal")
	}
	if got := st.MaxAttacksThisRound(); got != 5 {
		t.Fatalf("MaxAttacksThisRound=%d want 5", got)
	}
	// После take-флага — не лечим как первый отбой.
	raw2 := `{"player_ids":["a","b"],` +
		`"hands":[[{"rank":6,"suit":"c"}],[{"rank":7,"suit":"h"}]],` +
		`"trump":"h","attacker_index":0,"phase":"attack","hand_size":6,"max_attacks":6,` +
		`"status":"active","table":[],"bito":[],"last_was_take":true}`
	st2, err := Decode(raw2)
	if err != nil {
		t.Fatalf("Decode2: %v", err)
	}
	if st2.FirstRound {
		t.Fatal("want FirstRound=false when last_was_take")
	}
}

// Первый отбой: пачка до 5 карт (лимит), «Все»/авто — потом отбой.
func TestFirstRoundThrowInBatchMaxFive(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Clubs}, {6, Spades}, {6, Diamonds}, {6, Hearts}, {6, Spades}, {9, Clubs}},
			{{7, Clubs}, {8, Clubs}, {9, Hearts}, {10, Hearts}, {11, Hearts}, {12, Hearts}},
		},
		Trump:         Hearts,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		FirstRound:    true,
	}
	// Две 6♠ в руке — AttackMany/remove снимает по одной.
	st.Hands[0] = []Card{
		{6, Clubs}, {6, Spades}, {6, Diamonds}, {6, Hearts},
		{9, Clubs}, {10, Clubs},
	}
	if err := st.Attack(0, Card{6, Clubs}); err != nil {
		t.Fatalf("attack1: %v", err)
	}
	// Сразу defend — доп. карты того же ранга подкидываются уже в defend.
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after first card", st.Phase)
	}
	for _, c := range []Card{{6, Spades}, {6, Diamonds}, {6, Hearts}} {
		if err := st.Attack(0, c); err != nil {
			t.Fatalf("throw %v: %v", c, err)
		}
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after throw-ins", st.Phase)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after throw reveal", st.Phase)
	}
	if len(st.Table) != 4 {
		t.Fatalf("table=%d want 4", len(st.Table))
	}

	// Явно: 5-я карта ок, 6-я на первом отбое — нет.
	st = &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Clubs}, {9, Diamonds}},
			{{7, Hearts}, {8, Hearts}, {9, Hearts}, {10, Hearts}, {11, Hearts}, {12, Hearts}},
		},
		Table: []Pair{
			{Attack: Card{6, Spades}}, {Attack: Card{6, Diamonds}},
			{Attack: Card{6, Hearts}}, {Attack: Card{6, Clubs}},
		},
		Trump:         Clubs,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseThrowIn,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		FirstRound:    true,
	}
	// Перезапишем стол/руку: 4 атаки, в руке ещё одна 6 и лишняя.
	st.Table = []Pair{
		{Attack: Card{6, Spades}}, {Attack: Card{6, Diamonds}},
		{Attack: Card{6, Hearts}}, {Attack: Card{9, Spades}},
	}
	st.Hands[0] = []Card{{6, Clubs}, {9, Diamonds}}
	if got := st.MaxAttacksThisRound(); got != 5 {
		t.Fatalf("MaxAttacksThisRound=%d want 5", got)
	}
	if err := st.Attack(0, Card{6, Clubs}); err != nil {
		t.Fatalf("5th card: %v", err)
	}
	if len(st.Table) != 5 {
		t.Fatalf("table=%d want 5", len(st.Table))
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after hitting first-round cap", st.Phase)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after throw reveal", st.Phase)
	}
	st.Phase = PhaseThrowIn
	st.ThrowerIndex = 0
	st.Hands[0] = []Card{{9, Diamonds}}
	if err := st.Attack(0, Card{9, Diamonds}); err == nil {
		t.Fatal("expected ErrBadAttack for 6th card on first round")
	}
}

// Первый отбой: всего не больше 5 карт на столе (включая первую атаку).
func TestFirstRoundMaxFiveAttacks(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Clubs}, {6, Spades}, {6, Diamonds}, {9, Clubs}, {10, Clubs}, {11, Clubs}},
			{{6, Hearts}, {7, Hearts}, {8, Hearts}, {9, Hearts}, {10, Hearts}, {11, Hearts}},
		},
		Trump:         Hearts,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		FirstRound:    true,
	}
	if got := st.MaxAttacksThisRound(); got != 5 {
		t.Fatalf("MaxAttacksThisRound=%d, want 5 on first round", got)
	}
	// Пустой стол: три шестёрки разом — ок.
	if err := st.AttackMany(0, []Card{{6, Clubs}, {6, Spades}, {6, Diamonds}}); err != nil {
		t.Fatalf("3 sixes: %v", err)
	}
	// Добить стол до 5 неотбитых того же ранга нельзя без защиты — имитируем лимит напрямую.
	st.Table = []Pair{
		{Attack: Card{9, Hearts}},
		{Attack: Card{9, Diamonds}},
		{Attack: Card{9, Clubs}},
		{Attack: Card{9, Spades}},
		{Attack: Card{10, Hearts}},
	}
	st.Phase = PhaseDefend
	st.Hands[0] = []Card{{10, Clubs}, {11, Clubs}}
	if got := st.MaxAttacksThisRound(); got != 5 {
		t.Fatalf("with 5 on table MaxAttacksThisRound=%d, want 5", got)
	}
	if err := st.AttackMany(0, []Card{{10, Clubs}}); err == nil {
		t.Fatalf("expected ErrBadAttack for 6th card on first round")
	}
	// После первого отбоя лимит 5 снимается.
	st.Table = nil
	st.Phase = PhaseAttack
	st.clearFirstRound()
	st.BitoPile = []Card{{6, Hearts}} // раунд закрыт
	st.Hands[0] = []Card{{6, Spades}, {7, Spades}, {8, Spades}, {9, Spades}, {10, Spades}, {11, Spades}}
	st.Hands[1] = []Card{{6, Diamonds}, {7, Diamonds}, {8, Diamonds}, {9, Diamonds}, {10, Diamonds}, {11, Diamonds}}
	if got := st.MaxAttacksThisRound(); got != 6 {
		t.Fatalf("after first round MaxAttacksThisRound=%d, want 6", got)
	}
}

// Неотбитые на столе учитываются: рука 5 + 2 неотбитых → подкид ещё не больше 3.
func TestThrowInLimitedByDefenderHandMinusUndefended(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{9, Diamonds}, {9, Clubs}, {9, Spades}, {10, Clubs}, {6, Spades}},
			{{6, Hearts}, {7, Hearts}, {8, Hearts}, {11, Hearts}, {12, Hearts}}, // 5
		},
		Trump:         Diamonds,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		Table: []Pair{
			{Attack: Card{9, Hearts}},
			{Attack: Card{10, Hearts}},
		},
	}
	if got := st.MaxAttacksThisRound(); got != 5 {
		t.Fatalf("MaxAttacksThisRound=%d, want 5 (beaten0+hand5)", got)
	}
	// 3 подкида — ок (стол станет 5).
	if err := st.AttackMany(0, []Card{{9, Diamonds}, {9, Clubs}, {9, Spades}}); err != nil {
		t.Fatalf("throw-in 3: %v", err)
	}
	if len(st.Table) != 5 {
		t.Fatalf("table=%d, want 5", len(st.Table))
	}
	// 4-й подкид — нельзя (защитник не сможет отбить).
	if err := st.AttackMany(0, []Card{{10, Clubs}}); err == nil {
		t.Fatalf("expected ErrBadAttack for 4th throw-in")
	}
}

// После нескольких отбитых пар подкид того же ранга всё ещё должен быть
// возможен: отбитые + рука, пока не упёрлись в MaxAttacks.
func TestThrowInAfterBeatenPairs(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{12, Clubs}, {12, Spades}},            // дамы для подкида
			{{14, Hearts}, {6, Clubs}, {7, Clubs}}, // 3 карты у защитника
		},
		Trump:         Hearts,
		AttackerIndex: 0,
		Phase:         PhaseAttackFollow,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
		Table: []Pair{
			{Attack: Card{10, Clubs}, Defense: &Card{13, Clubs}},
			{Attack: Card{10, Spades}, Defense: &Card{13, Spades}},
			{Attack: Card{13, Hearts}, Defense: &Card{12, Hearts}},
		},
	}
	legal := st.LegalAttackCards(0)
	if len(legal) != 2 {
		t.Fatalf("legal throw-in queens = %v, want 2", legal)
	}
	if err := st.AttackMany(0, []Card{{12, Clubs}}); err != nil {
		t.Fatalf("throw-in queen after beaten pairs: %v", err)
	}
}

// Атакующий и защитник выходят вместе (последняя карта отбита) — ничья.
func TestBothEmptyIsDraw(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{9, Hearts}},  // последняя атака
			{{10, Hearts}}, // последний отбой
		},
		Deck:          nil, // колода пуста
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{9, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if err := st.Defend(1, Card{10, Hearts}, -1); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Status != StatusOver {
		t.Fatalf("status = %v, want over", st.Status)
	}
	if st.LoserIndex != -1 {
		t.Fatalf("loser = %d, want -1 (ничья)", st.LoserIndex)
	}
	if len(st.Table) != 0 {
		t.Fatalf("table should be clear")
	}
}

func TestTakeAndFinish(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{11, Hearts}}, // атакующий бьёт защитника козырем нет — простая J♥ vs 6♦
			{{6, Diamonds}},
		},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{11, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if err := st.Take(1); err != nil {
		t.Fatalf("take: %v", err)
	}
	if st.Phase != PhaseTakeReveal {
		t.Fatalf("phase=%s want take_reveal after take", st.Phase)
	}
	if err := st.FinishTakeReveal(); err != nil {
		t.Fatalf("FinishTakeReveal: %v", err)
	}
	if st.Hands[1][0].Rank != 6 && st.Hands[1][1].Rank != 11 {
		// после сортировки: 6D 11H
		t.Logf("hand after take: %v", st.Hands[1])
	}
	if st.Status != StatusOver || st.LoserIndex != 1 {
		t.Fatalf("expected loser=1 game over, got status=%s loser=%d", st.Status, st.LoserIndex)
	}
}

// После «Беру» атакующий может подкинуть вдогонку, затем Done.
func TestThrowInAfterTake(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{9, Hearts}, {9, Diamonds}, {10, Clubs}},
			{{6, Spades}, {7, Clubs}, {8, Clubs}},
		},
		Deck:          nil,
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{9, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	// Ещё есть 9♦ — пачка throw_in; «Все» → отбой, затем «Беру».
	if st.Phase == PhaseThrowIn {
		if err := st.Done(0); err != nil {
			t.Fatalf("Все before take: %v", err)
		}
	}
	if err := st.Take(1); err != nil {
		t.Fatalf("take: %v", err)
	}
	if st.Phase != PhaseTakeFollow {
		t.Fatalf("phase=%v, want take_follow", st.Phase)
	}
	if err := st.Attack(0, Card{9, Diamonds}); err != nil {
		t.Fatalf("throw-in after take: %v", err)
	}
	// Больше подкидывать нечего — пауза показа стола, затем взятие.
	if st.Phase != PhaseTakeReveal {
		t.Fatalf("phase after throw-in=%v, want take_reveal", st.Phase)
	}
	if len(st.Table) == 0 {
		t.Fatalf("table should stay visible during take_reveal")
	}
	if err := st.FinishTakeReveal(); err != nil {
		t.Fatalf("FinishTakeReveal: %v", err)
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase after reveal=%v, want attack", st.Phase)
	}
	if len(st.Table) != 0 {
		t.Fatalf("table should be clear")
	}
	// Защитник забрал 2 девятки + свою руку.
	if len(st.Hands[1]) < 5 {
		t.Fatalf("defender hand=%v, want ≥5", st.Hands[1])
	}
	if !st.LastWasTake {
		t.Fatalf("LastWasTake should be set")
	}
}

func TestTransferInPerevodnoi(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Hearts}, {9, Diamonds}, {10, Diamonds}},
			{{6, Diamonds}, {8, Spades}},
		},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		Mode:          ModePerevodnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{6, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if err := st.Transfer(1, Card{6, Diamonds}); err != nil {
		t.Fatalf("transfer: %v", err)
	}
	// Атакующим стал бывший защитник, атакует старый атакующий (следующий по кругу).
	if st.AttackerIndex != 1 {
		t.Fatalf("attacker after transfer = %d", st.AttackerIndex)
	}
	if st.DefenderIndex() != 0 {
		t.Fatalf("defender = %d", st.DefenderIndex())
	}
}

// Нельзя перевести, если у следующего защитника карт меньше, чем будет атак на столе.
func TestTransferBlockedWhenNextHasTooFewCards(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{7, Hearts}},                            // следующий защитник после перевода — 1 карта
			{{6, Diamonds}, {6, Spades}, {9, Clubs}}, // защитник
		},
		Table: []Pair{
			{Attack: Card{6, Clubs}},
			{Attack: Card{6, Hearts}}, // на столе уже 2; перевод → 3, у next только 1
		},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		Mode:          ModePerevodnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if got := st.LegalTransferCards(1); len(got) != 0 {
		t.Fatalf("LegalTransferCards=%v, want empty (next has 1 < 3)", got)
	}
	if err := st.Transfer(1, Card{6, Diamonds}); err == nil {
		t.Fatalf("expected ErrCannotTransfer when next hand too small")
	}
	// Отбить козырем всё ещё можно.
	if err := st.Defend(1, Card{6, Spades}, 0); err != nil {
		t.Fatalf("defend trump: %v", err)
	}
}

// Можно бить любую неотбитую атаку (не только первую), в т.ч. некозырем.
func TestDefendAnyUndefendedPair(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{},
			{{8, Clubs}, {10, Hearts}},
		},
		Table: []Pair{
			{Attack: Card{6, Diamonds}},
			{Attack: Card{6, Clubs}},
		},
		Trump:         Hearts,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	legal := st.LegalDefendCards(1)
	hasEight := false
	for _, c := range legal {
		if c == (Card{8, Clubs}) {
			hasEight = true
			break
		}
	}
	if !hasEight {
		t.Fatalf("8♣ should be legal vs 6♣, got %v", legal)
	}
	// 8♣ не бьёт первую (6♦) — но бьёт вторую по pair_index.
	if err := st.Defend(1, Card{8, Clubs}, 1); err != nil {
		t.Fatalf("defend pair 1: %v", err)
	}
	if st.Table[1].Defense == nil || *st.Table[1].Defense != (Card{8, Clubs}) {
		t.Fatalf("defense on pair 1 = %+v", st.Table[1].Defense)
	}
	if st.Table[0].Defense != nil {
		t.Fatalf("pair 0 should stay undefended")
	}
}

// Две последние атаки одного ранга — оба выходят после двух отбоев.
func TestBothEmptyAfterDoubleDefendIsDraw(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{9, Hearts}, {9, Diamonds}},
			{{10, Hearts}, {10, Diamonds}},
		},
		Deck:          nil,
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.AttackMany(0, []Card{{9, Hearts}, {9, Diamonds}}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if err := st.Defend(1, Card{10, Hearts}, 0); err != nil {
		t.Fatalf("defend1: %v", err)
	}
	if st.Status != StatusActive {
		t.Fatalf("after first defend status=%v, want active", st.Status)
	}
	if err := st.Defend(1, Card{10, Diamonds}, 1); err != nil {
		t.Fatalf("defend2: %v", err)
	}
	if st.Status != StatusOver {
		t.Fatalf("status=%v, want over", st.Status)
	}
	if st.LoserIndex != -1 {
		t.Fatalf("loser=%d, want -1", st.LoserIndex)
	}
}

// Подкидывание последней карты после отбоя — оба пусты → ничья.
func TestBothEmptyAfterThrowInIsDraw(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{8, Clubs}, {9, Hearts}}, // атака + подкид
			{{9, Clubs}, {10, Hearts}},
		},
		Deck:          nil,
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{8, Clubs}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	if err := st.Defend(1, Card{9, Clubs}, -1); err != nil {
		t.Fatalf("defend1: %v", err)
	}
	// Подкидываем последнюю.
	if err := st.Attack(0, Card{9, Hearts}); err != nil {
		t.Fatalf("throw-in: %v", err)
	}
	if err := st.Defend(1, Card{10, Hearts}, -1); err != nil {
		t.Fatalf("defend2: %v", err)
	}
	if st.Status != StatusOver || st.LoserIndex != -1 {
		t.Fatalf("status=%v loser=%d, want over/-1", st.Status, st.LoserIndex)
	}
}

// При 3 игроках во время отбоя подкидывает только атакующий; третий — после «Бито».
func TestThrowInThreePlayers(t *testing.T) {
	def7 := Card{9, Spades}
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{7, Hearts}, {8, Hearts}},  // attacker
			{{9, Spades}, {10, Clubs}},  // defender
			{{7, Diamonds}, {8, Clubs}}, // third
		},
		Table:         []Pair{{Attack: Card{7, Clubs}}},
		Trump:         Spades,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseDefend,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if st.CanThrowIn(2) {
		t.Fatal("player 2 must not throw during defend")
	}
	if !st.CanThrowIn(0) {
		t.Fatal("attacker should throw during defend")
	}
	if err := st.Defend(1, def7, 0); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Phase != PhaseAttackFollow {
		t.Fatalf("phase=%s", st.Phase)
	}
	// Атакующий жмёт «Бито» → ход третьему.
	if err := st.SayBito(0); err != nil {
		t.Fatalf("bito attacker: %v", err)
	}
	if st.ThrowerIndex != 2 {
		t.Fatalf("thrower=%d want 2", st.ThrowerIndex)
	}
	if !st.CanThrowIn(2) {
		t.Fatal("player 2 should throw after attacker bito")
	}
	if err := st.Attack(2, Card{7, Diamonds}); err != nil {
		t.Fatalf("throw-in: %v", err)
	}
	if len(st.Table) != 2 {
		t.Fatalf("table=%d", len(st.Table))
	}
}

// При 4 игроках подкид только у соседей; очередь: атакующий, потом правый после «Бито».
func TestThrowInFourPlayersNeighborsOnly(t *testing.T) {
	// seats: 0 attacker (left of def), 1 defender, 2 right, 3 opposite
	defCard := Card{10, Clubs} // бьёт 7♣ той же мастью
	st := &State{
		PlayerIDs: []string{"a", "b", "c", "d"},
		Hands: [][]Card{
			{{7, Hearts}, {8, Hearts}},
			{{9, Spades}, {10, Clubs}, {6, Diamonds}},
			{{7, Diamonds}, {8, Clubs}},
			{{7, Spades}, {9, Hearts}}, // opposite — нельзя
		},
		Table:         []Pair{{Attack: Card{7, Clubs}}},
		Trump:         Hearts,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseDefend,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if st.DefenderIndex() != 1 {
		t.Fatalf("defender=%d", st.DefenderIndex())
	}
	if !st.CanThrowIn(0) {
		t.Fatal("attacker (left) should throw in during defend")
	}
	if st.CanThrowIn(2) {
		t.Fatal("right neighbor waits for attacker bito")
	}
	if st.CanThrowIn(3) {
		t.Fatal("opposite must not throw in")
	}
	if err := st.Defend(1, defCard, 0); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if err := st.SayBito(0); err != nil {
		t.Fatalf("bito: %v", err)
	}
	if st.ThrowerIndex != 2 {
		t.Fatalf("thrower=%d want 2", st.ThrowerIndex)
	}
	if err := st.Attack(3, Card{7, Spades}); err == nil {
		t.Fatal("expected ErrNotYourTurn for opposite")
	}
	if err := st.Attack(2, Card{7, Diamonds}); err != nil {
		t.Fatalf("right throw-in: %v", err)
	}
}

// Подкид без «Все»: после каждой карты сразу ход защитнику; можно кинуть ещё в defend.
func TestThrowInGoesStraightToDefend(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Hearts}, {6, Diamonds}, {6, Clubs}, {9, Hearts}},
			{{7, Hearts}, {10, Clubs}, {11, Clubs}, {12, Clubs}, {8, Diamonds}, {7, Diamonds}},
		},
		Table: []Pair{
			{Attack: Card{6, Spades}, Defense: &Card{Rank: 7, Suit: Spades}},
		},
		Trump:         Clubs,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseAttackFollow,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{6, Hearts}); err != nil {
		t.Fatalf("throw1: %v", err)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after throw", st.Phase)
	}
	if st.LegalDefendCards(1) == nil {
		t.Fatal("defender should act immediately (no Все)")
	}
	if err := st.Attack(0, Card{6, Diamonds}); err != nil {
		t.Fatalf("throw2 during defend: %v", err)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend after second throw", st.Phase)
	}
	if len(st.LegalAttackCards(0)) == 0 {
		t.Fatal("want more throw-in cards available in defend")
	}
	if got := st.UndefendedIndex(); got < 0 {
		t.Fatal("table must have undefended attacks for defender")
	}
	if err := st.Defend(1, Card{7, Hearts}, -1); err != nil {
		t.Fatalf("defend: %v", err)
	}
}

// checkOver не должен помечать finished, пока карты ещё на столе.
func TestCheckOverSkipsWhileTableUnresolved(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{}, // атакующий уже выложил всё
			{{11, Hearts}},
		},
		Table:         []Pair{{Attack: Card{10, Hearts}}},
		Deck:          nil,
		Trump:         Clubs,
		AttackerIndex: 0,
		Phase:         PhaseDefend,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	st.checkOver()
	if len(st.FinishedIndices) != 0 {
		t.Fatalf("finished=%v want empty while table unresolved", st.FinishedIndices)
	}
	if st.Status != StatusActive {
		t.Fatalf("status=%s want active", st.Status)
	}
}

// Атакующий выложил последние карты — не «finished», пока отбой не закрыт.
// Если защитник тоже выходит в ноль — ничья, без промежуточной победы.
func TestAttackerEmptyNotFinishedUntilRoundEnds(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{10, Hearts}},
			{{11, Hearts}},
		},
		Deck:          nil,
		Trump:         Clubs,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseAttack,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{10, Hearts}); err != nil {
		t.Fatalf("attack last: %v", err)
	}
	if len(st.FinishedIndices) != 0 {
		t.Fatalf("finished=%v want empty while table unresolved", st.FinishedIndices)
	}
	if st.Status != StatusActive {
		t.Fatalf("status=%s want active", st.Status)
	}
	if err := st.Defend(1, Card{11, Hearts}, 0); err != nil {
		t.Fatalf("defend last: %v", err)
	}
	// Защитник тоже в ноль → resolveDefenderEmpty / bito path → draw.
	if st.Status != StatusOver {
		// После последнего отбоя может быть bito_reveal — дожимаем.
		if st.Phase == PhaseBitoReveal {
			if err := st.FinishBitoReveal(); err != nil {
				t.Fatalf("FinishBitoReveal: %v", err)
			}
		}
	}
	if st.Status != StatusOver {
		t.Fatalf("status=%s want over", st.Status)
	}
	if st.LoserIndex != -1 {
		t.Fatalf("loser=%d want -1 (draw)", st.LoserIndex)
	}
	if st.TiedLeaders < 2 && len(st.FinishedIndices) < 2 {
		t.Fatalf("want both finished / tied, finished=%v tied=%d",
			st.FinishedIndices, st.TiedLeaders)
	}
}

// Сдача при 3 игроках: выбывший — наблюдатель, партия продолжается.
func TestEliminateContinuesWithThreePlayers(t *testing.T) {
	st := &State{
		PlayerIDs:     []string{"a", "b", "c"},
		Hands:         [][]Card{{{6, Hearts}}, {{7, Hearts}}, {{8, Hearts}}},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if !st.Eliminate(0) {
		t.Fatal("want continue after first eliminate")
	}
	if st.Status != StatusActive {
		t.Fatalf("status=%s", st.Status)
	}
	if !st.IsEliminated(0) {
		t.Fatal("player 0 must be eliminated")
	}
	if st.aliveCount() != 2 {
		t.Fatalf("alive=%d", st.aliveCount())
	}
	// Второй сдаётся — остаётся один победитель.
	if st.Eliminate(1) {
		t.Fatal("want game over when one remains")
	}
	if st.Status != StatusOver || st.LoserIndex != 1 {
		t.Fatalf("status=%s loser=%d", st.Status, st.LoserIndex)
	}
}

// Нечего больше подкинуть — авто-переход к защитнику без «Все».
func TestThrowInAutoFinishWhenNoMoreCards(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{6, Hearts}, {9, Clubs}},
			{{7, Hearts}, {10, Clubs}, {11, Clubs}},
		},
		Table: []Pair{
			{Attack: Card{6, Spades}, Defense: &Card{Rank: 7, Suit: Spades}},
		},
		Trump:         Diamonds,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseAttackFollow,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{6, Hearts}); err != nil {
		t.Fatalf("throw: %v", err)
	}
	if st.Phase != PhaseDefend {
		t.Fatalf("phase=%s want defend (auto finish, no more 6s)", st.Phase)
	}
	if st.LegalDefendCards(1) == nil {
		t.Fatal("defender should act after throw-in")
	}
}

// Если атакующему нечего подкинуть после отбоя — авто-пас, ход сразу третьему с картами.
func TestAutoSkipThrowerWithoutMatchingCards(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{10, Hearts}, {11, Hearts}}, // attacker — нет ранга 6
			{{7, Clubs}, {9, Spades}},    // defender (бьёт 6♣), карта в запасе
			{{6, Diamonds}, {8, Spades}}, // third — есть 6
		},
		Table:         []Pair{{Attack: Card{6, Clubs}}},
		Trump:         Spades,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseDefend,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Defend(1, Card{7, Clubs}, 0); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Phase != PhaseAttackFollow {
		t.Fatalf("phase=%s want attack_follow", st.Phase)
	}
	if st.ThrowerIndex != 2 {
		t.Fatalf("thrower=%d want 2 (attacker auto-skipped)", st.ThrowerIndex)
	}
	if !st.CanThrowIn(2) {
		t.Fatal("player 2 should be able to throw in")
	}
	if st.CanThrowIn(0) {
		t.Fatal("attacker without matching ranks must not show as thrower")
	}
}

// После «Беру», если никому нечего подкинуть — пауза показа стола, затем взятие.
func TestTakeAutoResolveWhenNothingToThrow(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{10, Hearts}, {11, Hearts}}, // нет ранга 6
			{{6, Diamonds}, {8, Clubs}},
			{{9, Spades}, {10, Clubs}}, // нет ранга 6
		},
		Trump:         Spades,
		AttackerIndex: 0,
		Phase:         PhaseAttack,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Attack(0, Card{10, Hearts}); err != nil {
		t.Fatalf("attack: %v", err)
	}
	// Подменим стол на 6, чтобы у атакующих не было подкида.
	st.Table = []Pair{{Attack: Card{6, Clubs}}}
	st.Hands[0] = []Card{{10, Hearts}, {11, Hearts}}
	if err := st.Take(1); err != nil {
		t.Fatalf("take: %v", err)
	}
	if st.Phase != PhaseTakeReveal {
		t.Fatalf("phase=%s want take_reveal", st.Phase)
	}
	if len(st.Table) == 0 {
		t.Fatalf("table should stay during take_reveal")
	}
	if err := st.FinishTakeReveal(); err != nil {
		t.Fatalf("FinishTakeReveal: %v", err)
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase=%s want attack after reveal", st.Phase)
	}
	if len(st.Table) != 0 {
		t.Fatalf("table should be cleared, got %d", len(st.Table))
	}
	if !st.LastWasTake {
		t.Fatal("LastWasTake should be set")
	}
}

// После «Беру» атакующий без карт ранга пропускается — ход сразу тому, кто может подкинуть.
func TestTakeFollowSkipsThrowerWithoutCards(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{10, Hearts}, {11, Hearts}}, // attacker — нет 7
			{{6, Diamonds}, {8, Clubs}},
			{{7, Diamonds}, {9, Spades}}, // third
		},
		Table:         []Pair{{Attack: Card{7, Clubs}}},
		Trump:         Spades,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseDefend,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Take(1); err != nil {
		t.Fatalf("take: %v", err)
	}
	if st.Phase != PhaseTakeFollow {
		t.Fatalf("phase=%s want take_follow", st.Phase)
	}
	if st.ThrowerIndex != 2 {
		t.Fatalf("thrower=%d want 2", st.ThrowerIndex)
	}
	if !st.CanThrowIn(2) {
		t.Fatal("player 2 should throw after take")
	}
}

// Очередь «Бито» по часовой → бита (у обоих есть чем подкинуть, но жмут бито).
func TestPassAllResolvesBito(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{6, Hearts}, {9, Spades}}, // может подкинуть, но жмёт бито
			{{10, Clubs}},
			{{6, Diamonds}, {8, Hearts}},
		},
		Table: []Pair{
			{Attack: Card{6, Clubs}, Defense: &Card{Rank: 7, Suit: Clubs}},
		},
		Trump:         Spades,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseAttackFollow,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.SayBito(0); err != nil {
		t.Fatalf("bito attacker: %v", err)
	}
	if st.Phase != PhaseAttackFollow || st.ThrowerIndex != 2 {
		t.Fatalf("phase=%s thrower=%d after first bito", st.Phase, st.ThrowerIndex)
	}
	if err := st.SayBito(2); err != nil {
		t.Fatalf("bito third: %v", err)
	}
	if st.Phase != PhaseBitoReveal {
		t.Fatalf("phase=%s want bito_reveal after all pass", st.Phase)
	}
	if err := st.FinishBitoReveal(); err != nil {
		t.Fatalf("FinishBitoReveal: %v", err)
	}
	if len(st.Table) != 0 {
		t.Fatalf("table should be cleared after reveal, got %d", len(st.Table))
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase=%s want attack", st.Phase)
	}
}

// После отбоя, если никому нечего подкинуть — пауза показа стола, потом отбой.
func TestAutoBitoWhenNobodyCanThrow(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b", "c"},
		Hands: [][]Card{
			{{10, Hearts}, {11, Hearts}},
			{{7, Clubs}, {9, Spades}},
			{{8, Diamonds}, {9, Hearts}},
		},
		Table:         []Pair{{Attack: Card{6, Clubs}}},
		Trump:         Spades,
		AttackerIndex: 0,
		ThrowerIndex:  0,
		Phase:         PhaseDefend,
		Mode:          ModePodkidnoi,
		HandSize:      6,
		MaxAttacks:    6,
		Status:        StatusActive,
	}
	if err := st.Defend(1, Card{7, Clubs}, 0); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Phase != PhaseBitoReveal {
		t.Fatalf("phase=%s want bito_reveal", st.Phase)
	}
	if len(st.Table) != 1 || st.Table[0].Defense == nil {
		t.Fatalf("table should stay for reveal, got %v", st.Table)
	}
	if err := st.FinishBitoReveal(); err != nil {
		t.Fatalf("FinishBitoReveal: %v", err)
	}
	if len(st.Table) != 0 {
		t.Fatalf("table should be cleared after reveal, got %d", len(st.Table))
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase=%s want attack", st.Phase)
	}
}
