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
		t.Fatalf("phase = %v", st.Phase)
	}
	if err := st.Defend(1, Card{7, Hearts}, -1); err != nil {
		t.Fatalf("defend: %v", err)
	}
	if st.Phase != PhaseAttackFollow {
		t.Fatalf("phase after defend = %v", st.Phase)
	}
	if err := st.SayBito(0); err != nil {
		t.Fatalf("bito: %v", err)
	}
	if len(st.Table) != 0 || len(st.BitoPile) != 2 {
		t.Fatalf("bito state: %+v", st)
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
		t.Fatalf("phase = %v", st.Phase)
	}
	// Во время защиты можно подкинуть карту того же ранга.
	st.Hands[0] = append(st.Hands[0], Card{9, Diamonds})
	if err := st.AttackMany(0, []Card{{9, Diamonds}}); err != nil {
		t.Fatalf("throw-in during defend: %v", err)
	}
	if len(st.Table) != 3 {
		t.Fatalf("table after throw-in = %d, want 3", len(st.Table))
	}
	// Чужой ранг — нельзя.
	if err := st.AttackMany(0, []Card{{10, Clubs}}); err == nil {
		t.Fatalf("expected error for wrong rank during defend")
	}
}

// После нескольких отбитых пар подкид того же ранга всё ещё должен быть
// возможен, пока не упёрлись в MaxAttacks (а не в «только размер руки»).
func TestThrowInAfterBeatenPairs(t *testing.T) {
	st := &State{
		PlayerIDs: []string{"a", "b"},
		Hands: [][]Card{
			{{12, Clubs}, {12, Spades}}, // дамы для подкида
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
	if err := st.Take(1); err != nil {
		t.Fatalf("take: %v", err)
	}
	if st.Phase != PhaseTakeFollow {
		t.Fatalf("phase=%v, want take_follow", st.Phase)
	}
	if err := st.Attack(0, Card{9, Diamonds}); err != nil {
		t.Fatalf("throw-in after take: %v", err)
	}
	if st.Phase != PhaseTakeFollow {
		t.Fatalf("phase after throw-in=%v, want take_follow", st.Phase)
	}
	if len(st.Table) != 2 {
		t.Fatalf("table=%d, want 2", len(st.Table))
	}
	if err := st.Done(0); err != nil {
		t.Fatalf("done: %v", err)
	}
	if st.Phase != PhaseAttack {
		t.Fatalf("phase after done=%v, want attack", st.Phase)
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
