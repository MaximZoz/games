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
	PhaseAttackFollow TurnPhase = "attack_follow" // атакующий подкидывает или «Бито»
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
	// Кто уже вышел (руки пусты и колода пуста).
	FinishedIndices []int `json:"finished_indices,omitempty"`

	// Кто «пасует» подкидывать — сброс после успешной защиты / take.
	Passed map[int]bool `json:"passed,omitempty"`
	// Помечает: последнее действие — take (для UI и разгона следующих ходов).
	LastWasTake bool `json:"last_was_take,omitempty"`
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

func (s *State) isAlive(idx int) bool {
	for _, f := range s.FinishedIndices {
		if f == idx {
			return false
		}
	}
	return true
}

// New — создать новую партию.
func New(playerIDs []string, deckSize int, mode Mode, seed int64) (*State, error) {
	if len(playerIDs) < 2 || len(playerIDs) > 4 {
		return nil, fmt.Errorf("player count must be 2..4, got %d", len(playerIDs))
	}
	if deckSize != 24 && deckSize != 36 && deckSize != 52 {
		return nil, fmt.Errorf("deck size must be 24/36/52, got %d", deckSize)
	}
	if deckSize == 24 && len(playerIDs) > 2 {
		return nil, fmt.Errorf("deck 24 supports only 2 players")
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
		Phase:         PhaseAttack,
		Mode:          mode,
		DeckSize:      deckSize,
		HandSize:      handSize,
		MaxAttacks:    6,
		Status:        StatusActive,
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

// MaxAttacksThisRound — сколько всего пар можно положить на стол.
// Лимит = карты в руке защитника + уже лежащие атаки (классика подкидного):
// после 3 отбитых пар при 3 картах в руке можно подкинуть ещё до MaxAttacks.
func (s *State) MaxAttacksThisRound() int {
	def := s.DefenderIndex()
	if def < 0 || def >= len(s.Hands) {
		return s.MaxAttacks
	}
	lim := len(s.Hands[def]) + len(s.Table)
	if lim < 1 {
		lim = 1
	}
	if s.MaxAttacks > 0 && s.MaxAttacks < lim {
		return s.MaxAttacks
	}
	return lim
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
// Пустой стол: все карты одного ранга. Иначе каждая — ранг со стола.
func (s *State) AttackMany(playerIdx int, cards []Card) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if len(cards) == 0 {
		return ErrBadAttack
	}
	if playerIdx != s.AttackerIndex {
		return ErrNotYourTurn
	}
	// Подкид: во время защиты, после отбоя, или вдогонку после «Беру».
	if s.Phase != PhaseAttack && s.Phase != PhaseAttackFollow &&
		s.Phase != PhaseDefend && s.Phase != PhaseTakeFollow {
		return ErrNotYourTurn
	}
	if (s.Phase == PhaseDefend || s.Phase == PhaseTakeFollow) && len(s.Table) == 0 {
		return ErrBadAttack
	}
	if len(s.Table)+len(cards) > s.MaxAttacksThisRound() {
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
	for _, c := range cards {
		s.removeFromHand(playerIdx, c)
		s.Table = append(s.Table, Pair{Attack: c})
	}
	// Вдогонку после «Беру» — фаза не меняется; иначе снова ждём отбой.
	if s.Phase != PhaseTakeFollow {
		s.Phase = PhaseDefend
	}
	return nil
}

// Defend — отбить неотбитую пару. pairIndex < 0 — первая, которую карта реально бьёт.
func (s *State) Defend(playerIdx int, card Card, pairIndex int) error {
	if s.Status != StatusActive {
		return ErrGameOver
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
		// Атакующий без карт — подкинуть нечего, сразу бито.
		if len(s.Hands[s.AttackerIndex]) == 0 {
			return s.resolveBito()
		}
	}
	return nil
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
	def := s.DefenderIndex()
	if playerIdx != def {
		return ErrNotYourTurn
	}
	if !s.handContains(playerIdx, card) {
		return ErrCardNotInHand
	}
	// Только если ни одна пара ещё не бита.
	for _, p := range s.Table {
		if p.Defense != nil {
			return ErrCannotTransfer
		}
	}
	if len(s.Table) == 0 {
		return ErrCannotTransfer
	}
	if card.Rank != s.Table[0].Attack.Rank {
		return ErrCannotTransfer
	}
	// Следующий защитник — тот, кто идёт после текущего.
	next := s.nextAliveAfter(def)
	// Проверяем что у next в руке хватает под возросший стол.
	if len(s.Hands[next]) < len(s.Table)+1 {
		return ErrCannotTransfer
	}
	s.removeFromHand(playerIdx, card)
	s.Table = append(s.Table, Pair{Attack: card})
	s.AttackerIndex = def
	// defender стал = next, phase = defend
	s.Phase = PhaseDefend
	return nil
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
	if s.Phase == PhaseTakeFollow {
		return ErrCannotTake
	}
	// Рука пуста: это не «взять», а закрытие раунда (бита + возврат неотбитых).
	if len(s.Hands[playerIdx]) == 0 {
		s.resolveDefenderEmpty()
		return nil
	}
	// В подкидном разрешаем «взять» на любой фазе защиты/атаки, пока стол не пуст.
	s.Phase = PhaseTakeFollow
	// Нечего подкинуть — сразу забираем.
	if len(s.LegalAttackCards(s.AttackerIndex)) == 0 {
		return s.resolveTake()
	}
	return nil
}

// Done — атакующий закончил подкид вдогонку; защитник забирает стол.
func (s *State) Done(playerIdx int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if s.Phase != PhaseTakeFollow {
		return ErrCannotDone
	}
	if playerIdx != s.AttackerIndex {
		return ErrNotYourTurn
	}
	return s.resolveTake()
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
	s.refill()
	skipped := di
	s.AttackerIndex = s.nextAliveAfter(skipped)
	s.LastWasTake = true
	s.Phase = PhaseAttack
	s.checkOver()
	return nil
}

// SayBito — атакующий говорит «Бито».
func (s *State) SayBito(playerIdx int) error {
	if s.Status != StatusActive {
		return ErrGameOver
	}
	if s.Phase != PhaseAttackFollow {
		return ErrCannotBito
	}
	if playerIdx != s.AttackerIndex {
		return ErrNotYourTurn
	}
	return s.resolveBito()
}

// resolveDefenderEmpty — у защитника кончились карты: отбитые пары в отбой,
// неотбитые атаки возвращаются атакующему; ход — бывшему защитнику (как после бито).
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
	s.refill()
	s.AttackerIndex = s.nextAliveAfter(atk)
	s.LastWasTake = false
	s.Phase = PhaseAttack
	s.checkOver()
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

// resolveBito — стол в отбой, добор, ход бывшему защитнику.
func (s *State) resolveBito() error {
	if len(s.Table) == 0 {
		return ErrCannotBito
	}
	for _, p := range s.Table {
		if p.Defense == nil {
			return ErrCannotBito
		}
	}
	for _, p := range s.Table {
		s.BitoPile = append(s.BitoPile, p.Attack)
		if p.Defense != nil {
			s.BitoPile = append(s.BitoPile, *p.Defense)
		}
	}
	s.Table = nil
	s.refill()
	// Ход переходит к бывшему защитнику.
	s.AttackerIndex = s.nextAliveAfter(s.AttackerIndex)
	s.LastWasTake = false
	s.Phase = PhaseAttack
	s.checkOver()
	return nil
}

// Forfeit — сдача: игрок [playerIdx] становится «дураком» (loser), даже если
// колода не пуста. Простое правило для MVP; при 3+ игроках выходит и партия
// продолжается — но пока трактуем как конец партии в 2 игрока.
func (s *State) Forfeit(playerIdx int) {
	if s.Status != StatusActive {
		return
	}
	s.Status = StatusOver
	s.LoserIndex = playerIdx
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

func (s *State) refill() {
	n := len(s.PlayerIDs)
	order := []int{s.AttackerIndex}
	for i := 1; i < n-1; i++ {
		order = append(order, (s.AttackerIndex+i)%n)
	}
	def := s.DefenderIndex()
	if def != s.AttackerIndex {
		order = append(order, def)
	}
	for _, p := range order {
		need := s.HandSize - len(s.Hands[p])
		for need > 0 && len(s.Deck) > 0 {
			s.Hands[p] = append(s.Hands[p], s.Deck[0])
			s.Deck = s.Deck[1:]
			need--
		}
		SortHand(s.Hands[p], s.Trump)
	}
}

func (s *State) checkOver() {
	if len(s.Deck) > 0 {
		return
	}
	var withCards []int
	for i, h := range s.Hands {
		if !s.isAlive(i) {
			continue
		}
		if len(h) > 0 {
			withCards = append(withCards, i)
		} else {
			s.FinishedIndices = append(s.FinishedIndices, i)
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

// ---- Клиентские подсказки (легальные ходы) ----

// LegalAttackCards — какие карты игрока [idx] можно положить атакой/подкидыванием.
func (s *State) LegalAttackCards(idx int) []Card {
	if s.Status != StatusActive || idx != s.AttackerIndex {
		return nil
	}
	if s.Phase != PhaseAttack && s.Phase != PhaseAttackFollow &&
		s.Phase != PhaseDefend && s.Phase != PhaseTakeFollow {
		return nil
	}
	if len(s.Table) >= s.MaxAttacksThisRound() {
		return nil
	}
	out := []Card{}
	if len(s.Table) == 0 {
		if s.Phase == PhaseDefend || s.Phase == PhaseTakeFollow {
			return nil
		}
		out = append(out, s.Hands[idx]...)
		return out
	}
	ranks := s.TableRanks()
	for _, c := range s.Hands[idx] {
		if ranks[c.Rank] {
			out = append(out, c)
		}
	}
	return out
}

// LegalDefendCards — карты, которыми можно отбить хотя бы одну неотбитую атаку.
func (s *State) LegalDefendCards(idx int) []Card {
	if s.Status != StatusActive {
		return nil
	}
	if s.Phase == PhaseTakeFollow {
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
	return &s, nil
}

// UnixNow — стабильный источник времени (для сидов бота на сервере, если нужно).
func UnixNow() int64 { return time.Now().UTC().UnixNano() }
