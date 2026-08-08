package durak

import (
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"time"
)

// Mode — режим игры.
type Mode string

const (
	ModePodkidnoi  Mode = "podkidnoi"  // подкидной
	ModePerevodnoi Mode = "perevodnoi" // переводной
)

// ParseMode нормализует mode; по умолчанию — подкидной.
func ParseMode(s string) Mode {
	if s == string(ModePerevodnoi) {
		return ModePerevodnoi
	}
	return ModePodkidnoi
}

// TurnPhase — что должно произойти следующим шагом.
type TurnPhase string

const (
	PhaseAttack       TurnPhase = "attack"        // атакующий кладёт первую карту
	PhaseDefend       TurnPhase = "defend"        // защитник бьёт
	PhaseThrowIn      TurnPhase = "throw_in"      // очередь подкида: кладёт карты, затем «Все»
	PhaseAttackFollow TurnPhase = "attack_follow" // подкид после полного отбоя или «Бито»
	PhaseTakeFollow   TurnPhase = "take_follow"   // защитник берёт; атакующий может подкинуть вдогонку
)

// Status — статус партии.
type Status string

const (
	StatusActive Status = "active"
	StatusOver   Status = "over"
)

// Pair — пара «атака / защита» на столе.
type Pair struct {
	Attack  Card  `json:"attack"`
	Defense *Card `json:"defense,omitempty"`
}

// State — сериализуемое состояние партии (хранится в Redis game hash поле "durak").
type State struct {
	// Игроки в порядке рассадки; index в arrays соответствует индексу в PlayerIDs.
	PlayerIDs []string `json:"player_ids"`
	Hands     [][]Card `json:"hands"`
	Deck      []Card   `json:"deck"`
	BitoPile  []Card   `json:"bito"`
	Table     []Pair   `json:"table"`
	Trump     Suit     `json:"trump"`
	TrumpCard Card     `json:"trump_card"` // открытая козырная в основании

	AttackerIndex int       `json:"attacker_index"`
	Phase         TurnPhase `json:"phase"`
	Mode          Mode      `json:"mode"`
	DeckSize      int       `json:"deck_size"`
	HandSize      int       `json:"hand_size"`
	MaxAttacks    int       `json:"max_attacks"`

	Status     Status `json:"status"`
	LoserIndex int    `json:"loser_index,omitempty"` // «дурак»
	// Кто уже вышел успешно (рука пуста, колода пуста) — претендует на банк.
	FinishedIndices []int `json:"finished_indices,omitempty"`
	// Кто сдался / выбыл — наблюдатель, долю банка не получает.
	EliminatedIndices []int `json:"eliminated_indices,omitempty"`

	// Кто сейчас может подкидывать / жать «Бито» (очередь по часовой).
	ThrowerIndex int `json:"thrower_index"`
	// Кто уже пасанул в этой очереди подкида.
	Passed map[int]bool `json:"passed,omitempty"`
	// Помечает: последнее действие — take (для UI и разгона следующих ходов).
	LastWasTake bool `json:"last_was_take,omitempty"`
	// Первый отбой партии: на стол не больше 5 карт (включая первую атаку).
	// Без omitempty — иначе false/отсутствие поля путает клиент и лимит 5.
	FirstRound bool `json:"first_round"`
	// RoundEnded — уже был бито/взятие/закрытие раунда (надёжнее флага FirstRound).
	RoundEnded bool `json:"round_ended,omitempty"`
}

// DefenderIndex — следующий защитник по кругу.
func (s *State) DefenderIndex() int {
	return s.nextAliveAfter(s.AttackerIndex)
}

func (s *State) nextAliveAfter(idx int) int {
	n := len(s.Hands)
	for i := 1; i <= n; i++ {
		j := (idx + i) % n
		if s.isAlive(j) {
			return j
		}
	}
	return idx
}

// NextAliveAfter — следующий живой игрок по кругу (экспорт для API).
func (s *State) NextAliveAfter(idx int) int { return s.nextAliveAfter(idx) }

// IsAlive — не вышел «в ноль» и не сдался.
func (s *State) IsAlive(idx int) bool { return s.isAlive(idx) }

func (s *State) prevAliveBefore(idx int) int {
	n := len(s.Hands)
	for i := 1; i <= n; i++ {
		j := (idx - i + n) % n
		if s.isAlive(j) {
			return j
		}
	}
	return idx
}

func (s *State) isAlive(idx int) bool {
	for _, f := range s.FinishedIndices {
		if f == idx {
			return false
		}
	}
	for _, e := range s.EliminatedIndices {
		if e == idx {
			return false
		}
	}
	return true
}

// IsEliminated — сдался / выбыл (наблюдатель, без доли банка).
func (s *State) IsEliminated(idx int) bool {
	for _, e := range s.EliminatedIndices {
		if e == idx {
			return true
		}
	}
	return false
}

func appendUniqueIndex(dst []int, idx int) []int {
	for _, x := range dst {
		if x == idx {
			return dst
		}
	}
	return append(dst, idx)
}

func (s *State) aliveCount() int {
	n := 0
	for i := range s.Hands {
		if s.isAlive(i) {
			n++
		}
	}
	return n
}

func (s *State) clearPassed() {
	s.Passed = nil
}

func (s *State) resetThrowerToAttacker() {
	s.ThrowerIndex = s.AttackerIndex
	s.clearPassed()
}

// canThrowInSeat — место имеет право подкидывать (не защитник; при 4 живых — только соседи защитника).
func (s *State) canThrowInSeat(idx int) bool {
	if idx < 0 || idx >= len(s.Hands) || !s.isAlive(idx) {
		return false
	}
	if len(s.Hands[idx]) == 0 {
		return false
	}
	def := s.DefenderIndex()
	if idx == def {
		return false
	}
	// 4+ живых: подкид только слева и справа от защитника.
	if s.aliveCount() >= 4 {
		left := s.prevAliveBefore(def)
		right := s.nextAliveAfter(def)
		return idx == left || idx == right
	}
	// 2–3 игрока: все, кроме защитника.
	return true
}

// nextThrowerAfter — следующий по часовой среди имеющих право подкидывать (ещё не пасанул).
func (s *State) nextThrowerAfter(idx int) int {
	n := len(s.Hands)
	for i := 1; i <= n; i++ {
		j := (idx + i) % n
		if !s.canThrowInSeat(j) {
			continue
		}
		if s.Passed != nil && s.Passed[j] {
			continue
		}
		return j
	}
	return -1
}

// beginThrowerQueue — очередь подкида с атакующего; без карт — авто-пас дальше.
func (s *State) beginThrowerQueue() error {
	s.clearPassed()
	s.ThrowerIndex = s.AttackerIndex
	return s.skipThrowersWithoutCards()
}

// skipThrowersWithoutCards — если текущему нечего подкинуть, сразу «Бито»/пас
// и передача хода следующему (без показа «Подкид» / кнопки «Бито»).
func (s *State) skipThrowersWithoutCards() error {
	for hops := 0; hops <= len(s.Hands); hops++ {
		if s.Phase != PhaseAttackFollow && s.Phase != PhaseTakeFollow {
			return nil
		}
		eligible := s.canThrowInSeat(s.ThrowerIndex)
		hasCards := eligible && len(s.legalThrowInCards(s.ThrowerIndex)) > 0
		if hasCards {
			return nil
		}
		// Нет права / нечего класть — автопас (если место живое и не защитник), дальше по часовой.
		if eligible {
			if s.Passed == nil {
				s.Passed = map[int]bool{}
			}
			s.Passed[s.ThrowerIndex] = true
		}
		next := s.nextThrowerAfter(s.ThrowerIndex)
		if next < 0 {
			if s.Phase == PhaseTakeFollow {
				return s.resolveTake()
			}
			return s.resolveBito()
		}
		s.ThrowerIndex = next
	}
	if s.Phase == PhaseTakeFollow {
		return s.resolveTake()
	}
	return s.resolveBito()
}

// CanThrowIn — можно ли сейчас класть атаку/подкид (очередь + соседи при 4).
func (s *State) CanThrowIn(idx int) bool {
	if s.Status != StatusActive {
		return false
	}
	if len(s.Table) == 0 {
		return idx == s.AttackerIndex &&
			(s.Phase == PhaseAttack || s.Phase == PhaseAttackFollow)
	}
	if !s.canThrowInSeat(idx) {
		return false
	}
	if s.Passed != nil && s.Passed[idx] {
		return false
	}
	switch s.Phase {
	case PhaseDefend:
		// Пока защитник бьёт — подкид может начать только атакующий (первая очередь).
		return idx == s.AttackerIndex && len(s.legalThrowInCards(idx)) > 0
	case PhaseThrowIn, PhaseAttackFollow, PhaseTakeFollow:
		return idx == s.ThrowerIndex && len(s.legalThrowInCards(idx)) > 0
	default:
		return false
	}
}

func (s *State) allEligibleThrowersPassed() bool {
	for i := range s.Hands {
		if !s.canThrowInSeat(i) {
			continue
		}
		if s.Passed != nil && s.Passed[i] {
			continue
		}
		return false
	}
	return true
}

// advanceThrowerOrFinish — «Бито»/пас текущего: следующий по часовой или конец раунда.
func (s *State) advanceThrowerOrFinish() error {
	if s.Passed == nil {
		s.Passed = map[int]bool{}
	}
	s.Passed[s.ThrowerIndex] = true
	next := s.nextThrowerAfter(s.ThrowerIndex)
	if next < 0 {
		if s.Phase == PhaseTakeFollow {
			return s.resolveTake()
		}
		return s.resolveBito()
	}
	s.ThrowerIndex = next
	return s.skipThrowersWithoutCards()
}

// New — создать новую партию.
func New(playerIDs []string, deckSize int, mode Mode, seed int64) (*State, error) {
	if len(playerIDs) < 2 || len(playerIDs) > 4 {
		return nil, fmt.Errorf("player count must be 2..4, got %d", len(playerIDs))
	}
	if deckSize != 24 && deckSize != 36 && deckSize != 52 {
		return nil, fmt.Errorf("deck size must be 24/36/52, got %d", deckSize)
	}
	// Вдвоём — 24/36; втроём и вчетвером — 36/52.
	if deckSize == 24 && len(playerIDs) > 2 {
		return nil, fmt.Errorf("deck 24 supports only 2 players")
	}
	if deckSize == 52 && len(playerIDs) < 3 {
		return nil, fmt.Errorf("deck 52 requires 3 or 4 players")
	}
	src := rand.New(rand.NewSource(seed))
	deck := NewDeck(deckSize, src)
	// Козырь = последняя карта в колоде (открытая в основании).
	trumpCard := deck[len(deck)-1]

	handSize := 6
	hands := make([][]Card, len(playerIDs))
	for i := 0; i < handSize; i++ {
		for p := 0; p < len(playerIDs); p++ {
			hands[p] = append(hands[p], deck[0])
			deck = deck[1:]
		}
	}
	for _, h := range hands {
		SortHand(h, trumpCard.Suit)
	}

	// Стартовый атакующий: у кого младший козырь.
	starter := 0
	best := 100
	for p, h := range hands {
		for _, c := range h {
			if c.Suit == trumpCard.Suit && c.Rank < best {
				best = c.Rank
				starter = p
			}
		}
	}

	return &State{
		PlayerIDs:     append([]string(nil), playerIDs...),
		Hands:         hands,
		Deck:          deck, // включая козырь в конце
		Trump:         trumpCard.Suit,
		TrumpCard:     trumpCard,
		AttackerIndex: starter,
		ThrowerIndex:  starter,
		Phase:         PhaseAttack,
		Mode:          mode,
		DeckSize:      deckSize,
		HandSize:      handSize,
		MaxAttacks:    6,
		Status:        StatusActive,
		FirstRound:    true,
	}, nil
}

// TableRanks — множество рангов, лежащих на столе (для подкидываний).
func (s *State) TableRanks() map[int]bool {
	m := map[int]bool{}
	for _, p := range s.Table {
		m[p.Attack.Rank] = true
		if p.Defense != nil {
			m[p.Defense.Rank] = true
		}
	}
	return m
}

// UndefendedIndex — индекс первой неотбитой пары или -1.
func (s *State) UndefendedIndex() int {
	for i, p := range s.Table {
		if p.Defense == nil {
			return i
		}
	}
	return -1
}

// firstRoundAttackCap — жёсткий потолок атак в первом отбое.
const firstRoundAttackCap = 5

// isFirstRoundActive — первый отбой: ещё не закрывали раунд (бито/взятие/пусто).
// RoundEnded / бита / take — надёжные сигналы; FirstRound мог потеряться в JSON.
func (s *State) isFirstRoundActive() bool {
	if s == nil || s.Status != StatusActive {
		return false
	}
	if s.RoundEnded || len(s.BitoPile) > 0 || s.LastWasTake {
		return false
	}
	return true
}

// MaxAttacksThisRound — сколько всего пар можно положить на стол.
// Лимит = уже отбитые пары + карты в руке защитника:
// каждой карте в руке — не больше одной атаки (включая те, что ещё надо отбить).
// Пример: рука 5, на столе 2 неотбитых → всего не больше 5 пар → подкид ещё 3.
// В первом отбое партии — не больше 5 карт (включая первую атаку).
func (s *State) MaxAttacksThisRound() int {
	def := s.DefenderIndex()
	lim := s.MaxAttacks
	if lim <= 0 {
		lim = 6
	}
	if def >= 0 && def < len(s.Hands) {
		undefended := 0
		for _, p := range s.Table {
			if p.Defense == nil {
				undefended++
			}
		}
		beaten := len(s.Table) - undefended
		byHand := beaten + len(s.Hands[def])
		if byHand < 1 {
			byHand = 1
		}
		if byHand < lim {
			lim = byHand
		}
	}
	if s.isFirstRoundActive() && lim > firstRoundAttackCap {
		lim = firstRoundAttackCap
	}
	return lim
}

func (s *State) clearFirstRound() {
	s.FirstRound = false
	s.RoundEnded = true
}

// ---- Ошибки правил ----

var (
	ErrNotYourTurn    = errors.New("not your turn")
	ErrGameOver       = errors.New("game over")
	ErrCardNotInHand  = errors.New("card not in hand")
	ErrBadAttack      = errors.New("bad attack")
	ErrBadDefend      = errors.New("bad defend")
	ErrCannotTake     = errors.New("cannot take")
	ErrCannotBito     = errors.New("cannot bito")
	ErrCannotTransfer = errors.New("cannot transfer")
	ErrCannotDone     = errors.New("cannot confirm take")
	ErrCannotPass     = errors.New("cannot pass")
)

// PlayerIndex — индекс игрока по userID.
func (s *State) PlayerIndex(userID string) int {
	for i, id := range s.PlayerIDs {
		if id == userID {
			return i
		}
	}
	return -1
}

// ---- Действия ----

// Attack — положить карту атаки/подкидывания.
func (s *State) Attack(playerIdx int, card Card) error {
	return s.AttackMany(playerIdx, []Card{card})
}

// AttackMany — положить сразу несколько карт атаки/подкидывания.
// Пустой стол: только атакующий, все карты одного ранга.
// Непустой: подкид от CanThrowIn (при 4 игроках — соседи защитника).
func (s *State) AttackMany(playerIdx int, cards []Card) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if len(cards) == 0 {
		return ErrBadAttack
	}
	if !s.CanThrowIn(playerIdx) {
		return ErrNotYourTurn
	}
	// Подкид: защита, пачка throw_in, после отбоя, или вдогонку после «Беру».
	if s.Phase != PhaseAttack && s.Phase != PhaseAttackFollow &&
		s.Phase != PhaseDefend && s.Phase != PhaseThrowIn &&
		s.Phase != PhaseTakeFollow {
		return ErrNotYourTurn
	}
	if (s.Phase == PhaseDefend || s.Phase == PhaseThrowIn ||
		s.Phase == PhaseTakeFollow) && len(s.Table) == 0 {
		return ErrBadAttack
	}
	if len(s.Table)+len(cards) > s.MaxAttacksThisRound() {
		return ErrBadAttack
	}
	// Жёсткий потолок первого отбоя (по бите/take, не только по флагу).
	if s.isFirstRoundActive() && len(s.Table)+len(cards) > firstRoundAttackCap {
		return ErrBadAttack
	}
	// Все карты должны быть в руке (без повторов сверх наличия).
	handCopy := append([]Card(nil), s.Hands[playerIdx]...)
	for _, c := range cards {
		found := false
		for i, h := range handCopy {
			if h == c {
				handCopy = append(handCopy[:i], handCopy[i+1:]...)
				found = true
				break
			}
		}
		if !found {
			return ErrCardNotInHand
		}
	}
	if len(s.Table) == 0 {
		rank := cards[0].Rank
		for _, c := range cards[1:] {
			if c.Rank != rank {
				return ErrBadAttack
			}
		}
	} else {
		ranks := s.TableRanks()
		for _, c := range cards {
			if !ranks[c.Rank] {
				return ErrBadAttack
			}
		}
	}
	placedOnEmpty := len(s.Table) == 0
	for _, c := range cards {
		s.removeFromHand(playerIdx, c)
		s.Table = append(s.Table, Pair{Attack: c})
	}
	s.markFinishedIfEmpty(playerIdx)
	if s.Phase == PhaseTakeFollow {
		// Вдогонку: очередь на текущем; если карт больше нет — авто дальше.
		s.clearPassed()
		return s.skipThrowersWithoutCards()
	}
	// Первая атака / подкид пачкой: ход у атакующего до «Все».
	// Первый отбой — не больше 5 карт (MaxAttacksThisRound); без карт — сразу defend.
	s.Phase = PhaseThrowIn
	s.ThrowerIndex = playerIdx
	if placedOnEmpty {
		s.resetThrowerToAttacker()
		s.ThrowerIndex = playerIdx
	}
	if len(s.legalThrowInCards(playerIdx)) == 0 {
		return s.finishThrowIn()
	}
	return nil
}

// finishThrowIn — подкидывающий закончил пачку («Все» или авто) → бьёт защитник.
func (s *State) finishThrowIn() error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if len(s.Table) == 0 {
		s.Phase = PhaseAttack
		s.ThrowerIndex = s.AttackerIndex
		return nil
	}
	s.Phase = PhaseDefend
	return nil
}

// Defend — отбить неотбитую пару. pairIndex < 0 — первая, которую карта реально бьёт.
func (s *State) Defend(playerIdx int, card Card, pairIndex int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if s.Phase != PhaseDefend {
		return ErrNotYourTurn
	}
	if playerIdx != s.DefenderIndex() {
		return ErrNotYourTurn
	}
	if !s.handContains(playerIdx, card) {
		return ErrCardNotInHand
	}
	idx := pairIndex
	if idx >= 0 && idx < len(s.Table) && s.Table[idx].Defense == nil {
		if !card.Beats(s.Table[idx].Attack, s.Trump) {
			return ErrBadDefend
		}
	} else {
		idx = -1
		for i, p := range s.Table {
			if p.Defense == nil && card.Beats(p.Attack, s.Trump) {
				idx = i
				break
			}
		}
		if idx < 0 {
			return ErrBadDefend
		}
	}
	s.removeFromHand(playerIdx, card)
	s.Table[idx].Defense = &card
	// Рука пуста: отбитое — в биту, неотбитое — обратно атакующему.
	if len(s.Hands[playerIdx]) == 0 {
		s.resolveDefenderEmpty()
		return nil
	}
	if s.UndefendedIndex() < 0 {
		s.Phase = PhaseAttackFollow
		return s.beginThrowerQueue()
	}
	return nil
}

// transferAttackCap — жёсткий потолок пар после перевода (MaxAttacks / первый отбой).
func (s *State) transferAttackCap() int {
	cap := s.MaxAttacks
	if cap <= 0 {
		cap = 6
	}
	if s.isFirstRoundActive() && cap > firstRoundAttackCap {
		cap = firstRoundAttackCap
	}
	return cap
}

// canTransferToNext — у следующего защитника хватает карт отбить весь стол после перевода.
func (s *State) canTransferToNext(defIdx int) bool {
	if len(s.Table) == 0 {
		return false
	}
	for _, p := range s.Table {
		if p.Defense != nil {
			return false
		}
	}
	if len(s.Table)+1 > s.transferAttackCap() {
		return false
	}
	next := s.nextAliveAfter(defIdx)
	if next < 0 || next >= len(s.Hands) {
		return false
	}
	// После перевода на столе будет len(Table)+1 атак — у next не меньше карт.
	return len(s.Hands[next]) >= len(s.Table)+1
}

// Transfer — «переводной»: защитник кладёт свою карту того же ранга, что и
// последняя неотбитая атака, — атака переводится на следующего.
func (s *State) Transfer(playerIdx int, card Card) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if s.Mode != ModePerevodnoi {
		return ErrCannotTransfer
	}
	if s.Phase != PhaseDefend {
		return ErrNotYourTurn
	}
	def := s.DefenderIndex()
	if playerIdx != def {
		return ErrNotYourTurn
	}
	if !s.handContains(playerIdx, card) {
		return ErrCardNotInHand
	}
	if len(s.Table) == 0 {
		return ErrCannotTransfer
	}
	if card.Rank != s.Table[0].Attack.Rank {
		return ErrCannotTransfer
	}
	if !s.canTransferToNext(def) {
		return ErrCannotTransfer
	}
	s.removeFromHand(playerIdx, card)
	s.Table = append(s.Table, Pair{Attack: card})
	s.AttackerIndex = def
	s.resetThrowerToAttacker()
	// defender стал = next, phase = defend
	s.Phase = PhaseDefend
	return nil
}

// Pass — отказ подкидывать: ход следующему по часовой, иначе бито/взятие.
func (s *State) Pass(playerIdx int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if s.Phase == PhaseThrowIn {
		return s.Done(playerIdx)
	}
	if s.Phase == PhaseAttackFollow {
		return s.SayBito(playerIdx)
	}
	if s.Phase == PhaseTakeFollow {
		return s.Done(playerIdx)
	}
	return ErrCannotPass
}

// Take — защитник объявляет «Беру»: атакующий может подкинуть вдогонку,
// затем подтверждает (Done) — карты уходят защитнику.
func (s *State) Take(playerIdx int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if playerIdx != s.DefenderIndex() {
		return ErrNotYourTurn
	}
	if len(s.Table) == 0 {
		return ErrCannotTake
	}
	if s.Phase == PhaseTakeFollow || s.Phase == PhaseThrowIn {
		return ErrCannotTake
	}
	// Рука пуста: это не «взять», а закрытие раунда (бита + возврат неотбитых).
	if len(s.Hands[playerIdx]) == 0 {
		s.resolveDefenderEmpty()
		return nil
	}
	// В подкидном разрешаем «взять» на любой фазе защиты/атаки, пока стол не пуст.
	s.Phase = PhaseTakeFollow
	return s.beginThrowerQueue()
}

// Done — «Все» в пачке подкида → защитник; или конец вдогонки после «Беру».
func (s *State) Done(playerIdx int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if playerIdx != s.ThrowerIndex {
		return ErrNotYourTurn
	}
	if s.Phase == PhaseThrowIn {
		return s.finishThrowIn()
	}
	if s.Phase != PhaseTakeFollow {
		return ErrCannotDone
	}
	return s.advanceThrowerOrFinish()
}

// resolveTake — стол в руку защитнику, добор, ход следующему после защитника.
func (s *State) resolveTake() error {
	if len(s.Table) == 0 {
		return ErrCannotTake
	}
	di := s.DefenderIndex()
	for _, p := range s.Table {
		s.Hands[di] = append(s.Hands[di], p.Attack)
		if p.Defense != nil {
			s.Hands[di] = append(s.Hands[di], *p.Defense)
		}
	}
	SortHand(s.Hands[di], s.Trump)
	s.Table = nil
	s.clearPassed()
	s.refill()
	skipped := di
	s.AttackerIndex = s.nextAliveAfter(skipped)
	s.ThrowerIndex = s.AttackerIndex
	s.LastWasTake = true
	s.Phase = PhaseAttack
	s.clearFirstRound()
	s.checkOver()
	return nil
}

// SayBito — текущий подкидывающий: «Бито» → ход следующему по часовой, иначе бита.
func (s *State) SayBito(playerIdx int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if s.Phase != PhaseAttackFollow {
		return ErrCannotBito
	}
	if playerIdx != s.ThrowerIndex {
		return ErrNotYourTurn
	}
	for _, p := range s.Table {
		if p.Defense == nil {
			return ErrCannotBito
		}
	}
	return s.advanceThrowerOrFinish()
}

// resolveDefenderEmpty — у защитника кончились карты: отбитые пары в отбой,
// неотбитые атаки возвращаются атакующему; ход — бывшему защитнику (как после бито),
// а если он уже вышел «в ноль» — следующему живому.
func (s *State) resolveDefenderEmpty() {
	if s.Status != StatusActive || len(s.Table) == 0 {
		return
	}
	def := s.DefenderIndex()
	if def < 0 || def >= len(s.Hands) || len(s.Hands[def]) > 0 {
		return
	}
	atk := s.AttackerIndex
	if atk < 0 || atk >= len(s.Hands) {
		return
	}
	for _, p := range s.Table {
		if p.Defense != nil {
			s.BitoPile = append(s.BitoPile, p.Attack)
			s.BitoPile = append(s.BitoPile, *p.Defense)
		} else {
			s.Hands[atk] = append(s.Hands[atk], p.Attack)
		}
	}
	SortHand(s.Hands[atk], s.Trump)
	s.Table = nil
	s.clearPassed()
	s.refill()
	s.LastWasTake = false
	s.Phase = PhaseAttack
	s.clearFirstRound()
	// Сначала зафиксировать выходы «в ноль», потом выбрать атакующего среди живых
	// (иначе таймер остаётся на вышедшем защитнике).
	s.checkOver()
	if s.Status != StatusActive {
		return
	}
	if s.isAlive(def) {
		s.AttackerIndex = def
	} else {
		s.AttackerIndex = s.nextAliveAfter(def)
	}
	s.ThrowerIndex = s.AttackerIndex
}

// HealDefenderEmpty — дожать застрявшее состояние (пустая рука + стол).
func (s *State) HealDefenderEmpty() {
	s.resolveDefenderEmpty()
}

// HealGameOver — дожать конец партии (пустая колода, руки разобраны).
func (s *State) HealGameOver() {
	if s.Status != StatusActive {
		return
	}
	s.checkOver()
}

// resolveBito — стол в отбой, добор, ход бывшему защитнику
// (или следующему живому, если защитник вышел «в ноль»).
func (s *State) resolveBito() error {
	if len(s.Table) == 0 {
		return ErrCannotBito
	}
	for _, p := range s.Table {
		if p.Defense == nil {
			return ErrCannotBito
		}
	}
	atk := s.AttackerIndex
	def := s.DefenderIndex()
	for _, p := range s.Table {
		s.BitoPile = append(s.BitoPile, p.Attack)
		if p.Defense != nil {
			s.BitoPile = append(s.BitoPile, *p.Defense)
		}
	}
	s.Table = nil
	s.clearPassed()
	s.refill()
	s.LastWasTake = false
	s.Phase = PhaseAttack
	s.clearFirstRound()
	// Сначала выходы «в ноль», потом атакующий среди живых.
	s.checkOver()
	if s.Status != StatusActive {
		return nil
	}
	if def >= 0 && s.isAlive(def) {
		s.AttackerIndex = def
	} else if def >= 0 {
		s.AttackerIndex = s.nextAliveAfter(def)
	} else {
		s.AttackerIndex = s.nextAliveAfter(atk)
	}
	s.ThrowerIndex = s.AttackerIndex
	return nil
}

// Forfeit — сдача. При 2 живых — сразу конец (сдавшийся = дурак).
// При 3+ — выбывание (наблюдатель), партия продолжается между оставшимися
// (как eliminated_marks в крестиках).
func (s *State) Forfeit(playerIdx int) {
	_ = s.Eliminate(playerIdx)
}

// Eliminate — вывести игрока из партии. continues=true, если игра ещё идёт.
func (s *State) Eliminate(playerIdx int) (continues bool) {
	if s.Status != StatusActive {
		return false
	}
	if playerIdx < 0 || playerIdx >= len(s.Hands) || !s.isAlive(playerIdx) {
		return s.Status == StatusActive
	}
	s.EliminatedIndices = appendUniqueIndex(s.EliminatedIndices, playerIdx)
	s.Hands[playerIdx] = nil
	// Стол сбрасываем в отбой — раунд с выбывшим не продолжаем.
	if len(s.Table) > 0 {
		for _, p := range s.Table {
			s.BitoPile = append(s.BitoPile, p.Attack)
			if p.Defense != nil {
				s.BitoPile = append(s.BitoPile, *p.Defense)
			}
		}
		s.Table = nil
	}
	s.clearPassed()
	if s.aliveCount() <= 1 {
		s.Status = StatusOver
		if s.aliveCount() == 1 {
			// Последний сдавшийся при двух живых — «дурак»; оставшийся забирает банк.
			s.LoserIndex = playerIdx
		} else {
			s.LoserIndex = -1
		}
		return false
	}
	if !s.isAlive(s.AttackerIndex) {
		s.AttackerIndex = s.nextAliveAfter(playerIdx)
	}
	s.ThrowerIndex = s.AttackerIndex
	s.Phase = PhaseAttack
	s.LastWasTake = false
	// Стол ушёл в отбой / раунд сорван — первый отбой закончен.
	if len(s.BitoPile) > 0 {
		s.clearFirstRound()
	}
	s.checkOver()
	return s.Status == StatusActive
}

// ---- Вспомогательные ----

func (s *State) handContains(idx int, c Card) bool {
	for _, x := range s.Hands[idx] {
		if x == c {
			return true
		}
	}
	return false
}

func (s *State) removeFromHand(idx int, c Card) {
	for i, x := range s.Hands[idx] {
		if x == c {
			s.Hands[idx] = append(s.Hands[idx][:i], s.Hands[idx][i+1:]...)
			return
		}
	}
}

// refillOrder — атакующий, затем остальные по часовой (кроме защитника), защитник последний.
// Важно при 3 игроках: старый цикл i < n-1 пропускал «среднего» и дублировал защитника.
func (s *State) refillOrder() []int {
	n := len(s.PlayerIDs)
	if n == 0 {
		return nil
	}
	atk := s.AttackerIndex
	if atk < 0 || atk >= n {
		atk = 0
	}
	def := s.DefenderIndex()
	order := make([]int, 0, n)
	for i := 0; i < n; i++ {
		j := (atk + i) % n
		if j == def || !s.isAlive(j) {
			continue
		}
		order = append(order, j)
	}
	if def >= 0 && def < n && s.isAlive(def) {
		order = append(order, def)
	}
	return order
}

func (s *State) refill() {
	handSize := s.HandSize
	if handSize <= 0 {
		handSize = 6
	}
	for _, p := range s.refillOrder() {
		need := handSize - len(s.Hands[p])
		for need > 0 && len(s.Deck) > 0 {
			s.Hands[p] = append(s.Hands[p], s.Deck[0])
			s.Deck = s.Deck[1:]
			need--
		}
		SortHand(s.Hands[p], s.Trump)
	}
}

// markFinishedIfEmpty — зафиксировать выход «в ноль» по порядку (место в банке).
// Пока в колоде есть карты — добор, выход не считается.
func (s *State) markFinishedIfEmpty(idx int) {
	if idx < 0 || idx >= len(s.Hands) || len(s.Deck) > 0 {
		return
	}
	if len(s.Hands[idx]) > 0 || s.IsEliminated(idx) {
		return
	}
	for _, f := range s.FinishedIndices {
		if f == idx {
			return
		}
	}
	s.FinishedIndices = append(s.FinishedIndices, idx)
}

func (s *State) checkOver() {
	if len(s.Deck) > 0 {
		return
	}
	for i := range s.Hands {
		s.markFinishedIfEmpty(i)
	}
	var withCards []int
	for i, h := range s.Hands {
		if s.IsEliminated(i) {
			continue
		}
		// Уже вышедшие «в ноль» — не дурак.
		finished := false
		for _, f := range s.FinishedIndices {
			if f == i {
				finished = true
				break
			}
		}
		if finished {
			continue
		}
		if len(h) > 0 {
			withCards = append(withCards, i)
		} else {
			s.markFinishedIfEmpty(i)
		}
	}
	if len(withCards) <= 1 {
		s.Status = StatusOver
		if len(withCards) == 1 {
			s.LoserIndex = withCards[0]
		} else {
			s.LoserIndex = -1
		}
	}
}

// WinnerPlaceOrder — индексы победителей по местам (1-й вышедший, 2-й, …).
// Дурак и сдавшиеся не входят. Единственный оставшийся после сдач — 1-е место.
func (s *State) WinnerPlaceOrder() []int {
	seen := map[int]bool{}
	out := make([]int, 0, len(s.PlayerIDs))
	for _, i := range s.FinishedIndices {
		if i < 0 || i >= len(s.PlayerIDs) {
			continue
		}
		if i == s.LoserIndex || s.IsEliminated(i) || seen[i] {
			continue
		}
		seen[i] = true
		out = append(out, i)
	}
	for i := range s.PlayerIDs {
		if i == s.LoserIndex || s.IsEliminated(i) || seen[i] {
			continue
		}
		// Единственный выживший (ещё с картами) или вышедший без записи.
		out = append(out, i)
		seen[i] = true
	}
	return out
}

// PlaceShareNumerators — доли банка по местам (числители), знаменатель = N игроков.
// 3: 2/3 + 1/3; 4: 2/4 + 1/4 + 1/4; 2: весь банк победителю.
func PlaceShareNumerators(playerCount int) []int {
	switch playerCount {
	case 3:
		return []int{2, 1}
	case 4:
		return []int{2, 1, 1}
	default:
		if playerCount < 2 {
			return nil
		}
		return []int{playerCount}
	}
}

// CreditForPlace — начисление с банка за место (0 = первое). Проигравший — не сюда.
func CreditForPlace(stakeBronze, playerCount, placeIndex0 int) int {
	if stakeBronze <= 0 || playerCount < 2 || placeIndex0 < 0 {
		return 0
	}
	nums := PlaceShareNumerators(playerCount)
	if placeIndex0 >= len(nums) {
		return 0
	}
	pot := stakeBronze * playerCount
	return pot * nums[placeIndex0] / playerCount
}

// ---- Клиентские подсказки (легальные ходы) ----

// legalThrowInCards — карты для подкида по рангам стола (без проверки CanThrowIn).
func (s *State) legalThrowInCards(idx int) []Card {
	if idx < 0 || idx >= len(s.Hands) || len(s.Table) == 0 {
		return nil
	}
	if len(s.Table) >= s.MaxAttacksThisRound() {
		return nil
	}
	// Жёсткий потолок первого отбоя (UI не предлагает 6-ю).
	if s.isFirstRoundActive() && len(s.Table) >= firstRoundAttackCap {
		return nil
	}
	ranks := s.TableRanks()
	out := []Card{}
	for _, c := range s.Hands[idx] {
		if ranks[c.Rank] {
			out = append(out, c)
		}
	}
	return out
}

// LegalAttackCards — какие карты игрока [idx] можно положить атакой/подкидыванием.
func (s *State) LegalAttackCards(idx int) []Card {
	if s.Status != StatusActive || !s.CanThrowIn(idx) {
		return nil
	}
	if len(s.Table) >= s.MaxAttacksThisRound() {
		return nil
	}
	if len(s.Table) == 0 {
		if s.Phase == PhaseDefend || s.Phase == PhaseTakeFollow {
			return nil
		}
		out := append([]Card(nil), s.Hands[idx]...)
		return out
	}
	return s.legalThrowInCards(idx)
}

// LegalDefendCards — карты, которыми можно отбить хотя бы одну неотбитую атаку.
func (s *State) LegalDefendCards(idx int) []Card {
	if s.Status != StatusActive {
		return nil
	}
	if s.Phase != PhaseDefend {
		return nil
	}
	if idx != s.DefenderIndex() {
		return nil
	}
	out := []Card{}
	for _, c := range s.Hands[idx] {
		for _, p := range s.Table {
			if p.Defense == nil && c.Beats(p.Attack, s.Trump) {
				out = append(out, c)
				break
			}
		}
	}
	return out
}

// LegalTransferCards — карты, которыми можно перевести (переводной режим).
// Пусто, если у следующего защитника не хватит карт отбить весь стол.
func (s *State) LegalTransferCards(idx int) []Card {
	if s.Status != StatusActive || s.Mode != ModePerevodnoi {
		return nil
	}
	if s.Phase != PhaseDefend {
		return nil
	}
	if idx != s.DefenderIndex() {
		return nil
	}
	if !s.canTransferToNext(idx) {
		return nil
	}
	rank := s.Table[0].Attack.Rank
	out := []Card{}
	for _, c := range s.Hands[idx] {
		if c.Rank == rank {
			out = append(out, c)
		}
	}
	return out
}

// Encode / Decode для Redis (JSON).
func Encode(s *State) (string, error) {
	b, err := json.Marshal(s)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func Decode(raw string) (*State, error) {
	if raw == "" {
		return nil, fmt.Errorf("empty state")
	}
	var s State
	if err := json.Unmarshal([]byte(raw), &s); err != nil {
		return nil, err
	}
	if s.Passed == nil {
		s.Passed = map[int]bool{}
	}
	if s.HandSize <= 0 {
		s.HandSize = 6
	}
	// Старые сейвы без thrower_index → атакующий.
	if s.ThrowerIndex < 0 || s.ThrowerIndex >= len(s.PlayerIDs) {
		s.ThrowerIndex = s.AttackerIndex
	}
	// Старые сейвы: бита/take ⇒ раунд уже был; иначе при активной партии — первый отбой.
	if len(s.BitoPile) > 0 || s.LastWasTake {
		s.RoundEnded = true
		s.FirstRound = false
	} else if s.Status == StatusActive && !s.RoundEnded {
		s.FirstRound = true
	} else {
		s.FirstRound = s.isFirstRoundActive()
	}
	return &s, nil
}

// RefillIfNeeded — добрать до HandSize при пустом столе (лечит старый баг 3p).
// true, если хотя бы одна карта ушла из колоды.
func (s *State) RefillIfNeeded() bool {
	if s == nil || s.Status != StatusActive || len(s.Table) > 0 || len(s.Deck) == 0 {
		return false
	}
	before := len(s.Deck)
	s.refill()
	return len(s.Deck) < before
}

// UnixNow — стабильный источник времени (для сидов бота на сервере, если нужно).
func UnixNow() int64 { return time.Now().UTC().UnixNano() }
