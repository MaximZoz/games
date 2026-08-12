package poker

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"sort"
)

// Street — стадия раздачи.
const (
	StreetWaiting  = "waiting"
	StreetPreflop  = "preflop"
	StreetFlop     = "flop"
	StreetTurn     = "turn"
	StreetRiver    = "river"
	StreetShowdown = "showdown"
	StreetOver     = "over"
)

// Status — статус игры.
const (
	StatusActive = "active"
	StatusOver   = "over"
)

// ActionType — тип хода игрока.
type ActionType string

const (
	ActionFold  ActionType = "fold"
	ActionCheck ActionType = "check"
	ActionCall  ActionType = "call"
	ActionRaise ActionType = "raise"
	ActionAllIn ActionType = "all_in"
)

// Action — ход игрока.
//
// Для ActionRaise поле Amount задаёт «поднять ДО» (raise-to) — итоговый размер
// ставки игрока на текущей улице, а НЕ дополнительный доклад. Например, при
// CurrentBet=20 «рейз до 60» означает Amount=60 (игрок докладывает 60-свой_Bet).
// Для остальных типов Amount игнорируется.
type Action struct {
	Type   ActionType `json:"type"`
	Amount int        `json:"amount,omitempty"`
}

// Player — состояние игрока в раздаче.
type Player struct {
	UserID   string  `json:"userId"`
	Chips    int     `json:"chips"`
	Hole     [2]Card `json:"hole"`
	Bet      int     `json:"bet"`      // ставка на текущей улице
	TotalBet int     `json:"totalBet"` // суммарный вклад за всю раздачу
	Folded   bool    `json:"folded"`
	AllIn    bool    `json:"allIn"`
	Seat     int     `json:"seat"`
	HasActed bool    `json:"hasActed"` // ходил ли на текущей улице
	Shown    bool    `json:"shown"`    // добровольно показал карты после фолд-вины
}

// SidePot — банк (основной или побочный) и места, претендующие на него.
type SidePot struct {
	Amount   int   `json:"amount"`
	Eligible []int `json:"eligible"` // индексы мест, имеющих право на банк
}

// Game — полное состояние одной раздачи Texas Hold'em (это же State для Redis).
type Game struct {
	Players   []Player  `json:"players"`
	Community []Card    `json:"community"`
	Deck      *Deck     `json:"deck"`
	Pot       int       `json:"pot"`
	SidePots  []SidePot `json:"sidePots,omitempty"`

	Street string `json:"street"`
	Status string `json:"status"`

	DealerIndex int `json:"dealerIndex"`
	SBIndex     int `json:"sbIndex"`
	BBIndex     int `json:"bbIndex"`
	ActingIndex int `json:"actingIndex"`

	CurrentBet int `json:"currentBet"`
	MinRaise   int `json:"minRaise"`

	SmallBlind int `json:"smallBlind"`
	BigBlind   int `json:"bigBlind"`

	Winners       []int    `json:"winners"`
	WinnerUserIDs []string `json:"winnerUserIds"`

	// EliminatedOrder — UserID в порядке выбытия (первый выбывший — худшее место).
	EliminatedOrder []string `json:"eliminatedOrder,omitempty"`

	// Кэш-стол: партия = много раздач, пока фишки не соберутся у одного игрока.
	HandNumber     int  `json:"handNumber"`     // номер текущей раздачи, с 1
	BlindLevel     int  `json:"blindLevel"`     // уровень блайндов, с 0
	HandsPerLevel  int  `json:"handsPerLevel"`  // раздач на один уровень блайндов
	BaseSmallBlind int  `json:"baseSmallBlind"` // стартовый малый блайнд
	BaseBigBlind   int  `json:"baseBigBlind"`   // стартовый большой блайнд
	TableOver      bool `json:"tableOver"`      // весь стол окончен (фишки у одного)
	HandOver       bool `json:"handOver"`       // текущая раздача завершена, стол — нет
}

// NewGame создаёт новую раздачу: раздаёт карты, ставит блайнды и передаёт ход
// игроку слева от большого блайнда (UTG).
func NewGame(playerIDs []string, startingChips, smallBlind, bigBlind int, rng *rand.Rand) (*Game, error) {
	n := len(playerIDs)
	if n < 2 || n > 6 {
		return nil, fmt.Errorf("poker: need 2..6 players, got %d", n)
	}
	if startingChips <= 0 {
		return nil, fmt.Errorf("poker: startingChips must be > 0")
	}
	if smallBlind <= 0 || bigBlind <= 0 {
		return nil, fmt.Errorf("poker: blinds must be > 0")
	}
	if bigBlind < smallBlind {
		return nil, fmt.Errorf("poker: bigBlind must be >= smallBlind")
	}
	if rng == nil {
		return nil, fmt.Errorf("poker: rng is required")
	}

	g := &Game{
		Players:        make([]Player, n),
		Community:      []Card{},
		Deck:           NewShuffledDeck(rng),
		Street:         StreetPreflop,
		Status:         StatusActive,
		DealerIndex:    0,
		SmallBlind:     smallBlind,
		BigBlind:       bigBlind,
		MinRaise:       bigBlind,
		HandNumber:     1,
		BlindLevel:     0,
		HandsPerLevel:  3,
		BaseSmallBlind: smallBlind,
		BaseBigBlind:   bigBlind,
		HandOver:       false,
		TableOver:      false,
	}
	for i, id := range playerIDs {
		g.Players[i] = Player{UserID: id, Chips: startingChips, Seat: i}
	}

	// Позиции блайндов. Хедз-ап (2 игрока): дилер = малый блайнд.
	if n == 2 {
		g.SBIndex = g.DealerIndex
		g.BBIndex = g.other(g.DealerIndex)
	} else {
		g.SBIndex = (g.DealerIndex + 1) % n
		g.BBIndex = (g.DealerIndex + 2) % n
	}

	// Постим блайнды.
	g.postBet(g.SBIndex, smallBlind)
	g.postBet(g.BBIndex, bigBlind)
	g.CurrentBet = bigBlind

	// Раздаём по 2 карты каждому.
	for i := 0; i < n; i++ {
		c1, err := g.Deck.Deal()
		if err != nil {
			return nil, err
		}
		c2, err := g.Deck.Deal()
		if err != nil {
			return nil, err
		}
		g.Players[i].Hole = [2]Card{c1, c2}
	}

	// Первым ходит игрок слева от большого блайнда (UTG).
	g.ActingIndex = g.firstLiveFrom(g.BBIndex + 1)
	g.updatePot()
	return g, nil
}

func (g *Game) other(i int) int {
	return (i + 1) % len(g.Players)
}

// postBet списывает у игрока до amount фишек (или сколько есть — тогда all-in).
func (g *Game) postBet(i, amount int) int {
	p := &g.Players[i]
	actual := amount
	if actual > p.Chips {
		actual = p.Chips
	}
	p.Chips -= actual
	p.Bet += actual
	p.TotalBet += actual
	if p.Chips == 0 {
		p.AllIn = true
	}
	return actual
}

// updatePot пересчитывает общий банк как сумму вкладов всех игроков.
func (g *Game) updatePot() {
	total := 0
	for i := range g.Players {
		total += g.Players[i].TotalBet
	}
	g.Pot = total
}

// firstLiveFrom возвращает индекс первого «живого» игрока (не сбросил, не all-in,
// есть фишки), начиная со start по кругу. -1 если таких нет.
func (g *Game) firstLiveFrom(start int) int {
	n := len(g.Players)
	for k := 0; k < n; k++ {
		i := ((start % n) + n + k) % n
		p := g.Players[i]
		if !p.Folded && !p.AllIn && p.Chips > 0 {
			return i
		}
	}
	return -1
}

// liveCount — сколько игроков ещё могут делать ставки.
func (g *Game) liveCount() int {
	c := 0
	for i := range g.Players {
		p := g.Players[i]
		if !p.Folded && !p.AllIn && p.Chips > 0 {
			c++
		}
	}
	return c
}

// notFolded возвращает индексы не сбросивших игроков.
func (g *Game) notFolded() []int {
	out := []int{}
	for i := range g.Players {
		if !g.Players[i].Folded {
			out = append(out, i)
		}
	}
	return out
}

// LegalActions возвращает список допустимых действий для игрока.
func (g *Game) LegalActions(playerIndex int) []string {
	if g.Status != StatusActive || playerIndex != g.ActingIndex {
		return []string{}
	}
	if playerIndex < 0 || playerIndex >= len(g.Players) {
		return []string{}
	}
	p := g.Players[playerIndex]
	if p.Folded || p.AllIn || p.Chips == 0 {
		return []string{}
	}
	acts := []string{string(ActionFold)}
	if p.Bet == g.CurrentBet {
		acts = append(acts, string(ActionCheck))
	} else {
		acts = append(acts, string(ActionCall))
	}
	// Рейз возможен, если игрок может доложить сверх колла.
	if p.Bet+p.Chips > g.CurrentBet {
		acts = append(acts, string(ActionRaise))
	}
	if p.Chips > 0 {
		acts = append(acts, string(ActionAllIn))
	}
	return acts
}

// Apply применяет ход игрока и продвигает состояние игры.
func (g *Game) Apply(playerIndex int, action Action) error {
	if g.Status != StatusActive {
		return fmt.Errorf("poker: game is over")
	}
	if playerIndex < 0 || playerIndex >= len(g.Players) {
		return fmt.Errorf("poker: bad player index %d", playerIndex)
	}
	if playerIndex != g.ActingIndex {
		return fmt.Errorf("poker: not your turn (acting=%d)", g.ActingIndex)
	}
	p := &g.Players[playerIndex]
	if p.Folded || p.AllIn {
		return fmt.Errorf("poker: player cannot act")
	}

	switch action.Type {
	case ActionFold:
		p.Folded = true
		p.HasActed = true

	case ActionCheck:
		if p.Bet != g.CurrentBet {
			return fmt.Errorf("poker: cannot check, must call %d", g.CurrentBet-p.Bet)
		}
		p.HasActed = true

	case ActionCall:
		need := g.CurrentBet - p.Bet
		if need <= 0 {
			return fmt.Errorf("poker: nothing to call, use check")
		}
		g.postBet(playerIndex, need)
		p.HasActed = true

	case ActionRaise:
		maxTo := p.Bet + p.Chips
		if action.Amount <= g.CurrentBet {
			return fmt.Errorf("poker: raise must exceed current bet %d", g.CurrentBet)
		}
		if action.Amount > maxTo {
			return fmt.Errorf("poker: not enough chips to raise to %d", action.Amount)
		}
		minTo := g.CurrentBet + g.MinRaise
		if action.Amount < minTo && action.Amount != maxTo {
			return fmt.Errorf("poker: raise to %d below min-raise %d", action.Amount, minTo)
		}
		g.applyRaiseTo(playerIndex, action.Amount)
		p.HasActed = true

	case ActionAllIn:
		if p.Chips <= 0 {
			return fmt.Errorf("poker: no chips to go all-in")
		}
		newBet := p.Bet + p.Chips
		if newBet > g.CurrentBet {
			g.applyRaiseTo(playerIndex, newBet)
		} else {
			// Короткий all-in call (меньше текущей ставки).
			g.postBet(playerIndex, p.Chips)
		}
		p.HasActed = true

	default:
		return fmt.Errorf("poker: unknown action %q", action.Type)
	}

	g.updatePot()
	g.advanceAfterAction()
	return nil
}

// applyRaiseTo поднимает ставку игрока до total и обновляет CurrentBet/MinRaise.
func (g *Game) applyRaiseTo(i, total int) {
	p := &g.Players[i]
	add := total - p.Bet
	g.postBet(i, add)
	increment := total - g.CurrentBet
	g.CurrentBet = total
	// Полноценный рейз обновляет минимальный размер поднятия.
	if increment >= g.MinRaise {
		g.MinRaise = increment
	}
}

// advanceAfterAction решает, что делать после хода: завершить раздачу,
// перейти на следующую улицу или передать ход дальше.
func (g *Game) advanceAfterAction() {
	nf := g.notFolded()
	if len(nf) == 1 {
		g.awardUncontested(nf[0])
		return
	}
	if g.bettingComplete() {
		g.advanceStreet()
		return
	}
	g.ActingIndex = g.firstLiveFrom(g.ActingIndex + 1)
}

// bettingComplete — раунд ставок завершён, если каждый «живой» игрок сходил и
// сравнял текущую ставку.
func (g *Game) bettingComplete() bool {
	for i := range g.Players {
		p := g.Players[i]
		if p.Folded || p.AllIn || p.Chips == 0 {
			continue
		}
		if !p.HasActed || p.Bet != g.CurrentBet {
			return false
		}
	}
	return true
}

// resetBets обнуляет ставки улицы и флаги хода перед новой улицей.
func (g *Game) resetBets() {
	for i := range g.Players {
		g.Players[i].Bet = 0
		g.Players[i].HasActed = false
	}
	g.CurrentBet = 0
	g.MinRaise = g.BigBlind
}

// advanceStreet сдаёт следующую улицу; если ставить больше некому (all-in) —
// докручивает борд до вскрытия.
func (g *Game) advanceStreet() {
	for {
		switch g.Street {
		case StreetPreflop:
			g.dealCommunity(3)
			g.Street = StreetFlop
		case StreetFlop:
			g.dealCommunity(1)
			g.Street = StreetTurn
		case StreetTurn:
			g.dealCommunity(1)
			g.Street = StreetRiver
		case StreetRiver:
			g.Street = StreetShowdown
			g.showdown()
			return
		default:
			return
		}
		g.resetBets()
		// Если способны действовать хотя бы двое — начинаем торговлю.
		if g.liveCount() >= 2 {
			g.ActingIndex = g.firstLiveFrom(g.DealerIndex + 1)
			return
		}
		// Иначе (all-in) — продолжаем сдавать карты.
	}
}

func (g *Game) dealCommunity(n int) {
	cards, err := g.Deck.DealN(n)
	if err != nil {
		return
	}
	g.Community = append(g.Community, cards...)
}

// awardUncontested отдаёт весь банк единственному не сбросившему игроку.
func (g *Game) awardUncontested(winner int) {
	g.updatePot()
	g.Players[winner].Chips += g.Pot
	g.SidePots = []SidePot{{Amount: g.Pot, Eligible: []int{winner}}}
	g.Winners = []int{winner}
	g.WinnerUserIDs = []string{g.Players[winner].UserID}
	g.Street = StreetOver
	g.markHandOver()
}

// markHandOver завершает текущую раздачу: выставляет статус «over» (для гварда в
// Apply) и HandOver. Если фишки остались максимум у одного игрока — весь стол
// закончен (TableOver).
func (g *Game) markHandOver() {
	g.Status = StatusOver
	g.HandOver = true
	withChips := 0
	for i := range g.Players {
		if g.Players[i].Chips > 0 {
			withChips++
		}
	}
	g.TableOver = withChips <= 1
	g.noteEliminations()
}

// noteEliminations добавляет в EliminatedOrder игроков с нулём фишек (по местам).
func (g *Game) noteEliminations() {
	known := make(map[string]bool, len(g.EliminatedOrder))
	for _, id := range g.EliminatedOrder {
		known[id] = true
	}
	for i := range g.Players {
		p := &g.Players[i]
		if p.Chips > 0 || p.UserID == "" || known[p.UserID] {
			continue
		}
		g.EliminatedOrder = append(g.EliminatedOrder, p.UserID)
		known[p.UserID] = true
	}
}

// PlaceOf — итоговое место игрока (1 = победитель). 0 — ещё не определено.
func (g *Game) PlaceOf(userID string) int {
	if userID == "" || len(g.Players) < 2 {
		return 0
	}
	n := len(g.Players)
	if g.TableOver {
		for _, wid := range g.WinnerUserIDs {
			if wid == userID {
				return 1
			}
		}
	}
	for i, id := range g.EliminatedOrder {
		if id == userID {
			// Первый выбывший → место n; последний выбывший → место 2.
			return n - i
		}
	}
	return 0
}

// FinishPlaces — карта userID→место после окончания стола (иначе только выбывшие).
func (g *Game) FinishPlaces() map[string]int {
	out := make(map[string]int, len(g.Players))
	n := len(g.Players)
	if g.TableOver {
		for _, wid := range g.WinnerUserIDs {
			if wid != "" {
				out[wid] = 1
			}
		}
	}
	for i, id := range g.EliminatedOrder {
		if id == "" {
			continue
		}
		if _, ok := out[id]; ok {
			continue
		}
		out[id] = n - i
	}
	return out
}

// IsEliminated — игрок без фишек (выбыл, стол может ещё идти).
func (g *Game) IsEliminated(idx int) bool {
	if idx < 0 || idx >= len(g.Players) {
		return false
	}
	return g.Players[idx].Chips <= 0
}

// showdown строит банки, определяет победителей и распределяет фишки.
func (g *Game) showdown() {
	pots := g.buildSidePots()
	g.SidePots = pots

	winnerSet := map[int]bool{}
	for _, pot := range pots {
		if len(pot.Eligible) == 0 || pot.Amount == 0 {
			continue
		}
		best := g.bestAmong(pot.Eligible)
		g.distribute(pot.Amount, best)
		for _, w := range best {
			winnerSet[w] = true
		}
	}

	winners := make([]int, 0, len(winnerSet))
	for w := range winnerSet {
		winners = append(winners, w)
	}
	sort.Ints(winners)
	g.Winners = winners
	g.WinnerUserIDs = make([]string, len(winners))
	for i, w := range winners {
		g.WinnerUserIDs[i] = g.Players[w].UserID
	}
	g.markHandOver()
}

// buildSidePots строит основной и побочные банки из вкладов игроков.
// Деньги сброшенных игроков остаются в банке, но выиграть их они не могут.
func (g *Game) buildSidePots() []SidePot {
	// Уникальные уровни вкладов по возрастанию.
	levelsSet := map[int]bool{}
	for i := range g.Players {
		if g.Players[i].TotalBet > 0 {
			levelsSet[g.Players[i].TotalBet] = true
		}
	}
	levels := make([]int, 0, len(levelsSet))
	for l := range levelsSet {
		levels = append(levels, l)
	}
	sort.Ints(levels)

	pots := []SidePot{}
	prev := 0
	for _, lvl := range levels {
		amount := 0
		eligible := []int{}
		for i := range g.Players {
			if g.Players[i].TotalBet >= lvl {
				amount += lvl - prev
				if !g.Players[i].Folded {
					eligible = append(eligible, i)
				}
			}
		}
		if amount > 0 {
			pots = append(pots, SidePot{Amount: amount, Eligible: eligible})
		}
		prev = lvl
	}
	return mergePots(pots)
}

// mergePots объединяет соседние банки с одинаковым набором претендентов.
func mergePots(pots []SidePot) []SidePot {
	if len(pots) == 0 {
		return pots
	}
	out := []SidePot{}
	for _, p := range pots {
		if len(out) > 0 && sameInts(out[len(out)-1].Eligible, p.Eligible) {
			out[len(out)-1].Amount += p.Amount
		} else {
			out = append(out, p)
		}
	}
	return out
}

func sameInts(a, b []int) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// bestAmong возвращает индексы игроков с сильнейшей рукой среди eligible.
func (g *Game) bestAmong(eligible []int) []int {
	var bestVal HandValue
	best := []int{}
	for _, i := range eligible {
		cards := append([]Card{g.Players[i].Hole[0], g.Players[i].Hole[1]}, g.Community...)
		v, err := EvaluateBest(cards)
		if err != nil {
			continue
		}
		if len(best) == 0 {
			bestVal = v
			best = []int{i}
			continue
		}
		cmp := v.Compare(bestVal)
		if cmp > 0 {
			bestVal = v
			best = []int{i}
		} else if cmp == 0 {
			best = append(best, i)
		}
	}
	return best
}

// distribute делит банк между победителями; лишние фишки уходят игрокам ближе
// всего слева от дилера.
func (g *Game) distribute(amount int, winners []int) {
	if len(winners) == 0 {
		return
	}
	base := amount / len(winners)
	rem := amount % len(winners)
	for _, w := range winners {
		g.Players[w].Chips += base
	}
	if rem > 0 {
		order := g.orderFromDealer(winners)
		for k := 0; k < rem; k++ {
			g.Players[order[k]].Chips++
		}
	}
}

// orderFromDealer сортирует места по кругу, начиная слева от дилера.
func (g *Game) orderFromDealer(seats []int) []int {
	n := len(g.Players)
	out := make([]int, len(seats))
	copy(out, seats)
	sort.SliceStable(out, func(i, j int) bool {
		oi := ((out[i] - g.DealerIndex - 1) + n) % n
		oj := ((out[j] - g.DealerIndex - 1) + n) % n
		return oi < oj
	})
	return out
}

// nextSeatWithChips возвращает индекс первого места с фишками (>0), начиная с
// start по кругу. -1 если таких мест нет.
func (g *Game) nextSeatWithChips(start int) int {
	n := len(g.Players)
	for k := 0; k < n; k++ {
		i := ((start % n) + n + k) % n
		if g.Players[i].Chips > 0 {
			return i
		}
	}
	return -1
}

// StartNextHand начинает следующую раздачу за тем же столом: сохраняет фишки,
// вращает дилера, при необходимости поднимает блайнды, тасует колоду и раздаёт
// карты. Выбывшие (0 фишек) остаются на местах, но пропускают раздачу.
func (g *Game) StartNextHand(rng *rand.Rand) error {
	if !g.HandOver || g.TableOver {
		return fmt.Errorf("poker: cannot start next hand (handOver=%v tableOver=%v)", g.HandOver, g.TableOver)
	}
	if rng == nil {
		return fmt.Errorf("poker: rng is required")
	}

	// Вращаем дилера на следующее место с фишками.
	nextDealer := g.nextSeatWithChips(g.DealerIndex + 1)
	if nextDealer < 0 {
		return fmt.Errorf("poker: no players with chips")
	}
	g.DealerIndex = nextDealer

	g.HandNumber++
	// Каждые HandsPerLevel раздач поднимаем уровень блайндов.
	if g.HandsPerLevel > 0 && g.HandNumber > 1 && (g.HandNumber-1)%g.HandsPerLevel == 0 {
		g.BlindLevel++
	}
	// Блайнды удваиваются на каждом уровне: BB = BaseBigBlind << level, SB = BB/2.
	bb := g.BaseBigBlind << uint(g.BlindLevel)
	sb := bb / 2
	if sb < 1 {
		sb = 1
	}
	g.BigBlind = bb
	g.SmallBlind = sb
	g.MinRaise = bb

	// Свежая колода и чистый борд.
	g.Deck = NewShuffledDeck(rng)
	g.Community = []Card{}
	g.SidePots = nil
	g.Winners = nil
	g.WinnerUserIDs = nil
	g.Pot = 0
	g.CurrentBet = 0

	// Сброс состояния игроков; выбывших помечаем folded, чтобы они пропускали ход.
	liveSeats := make([]int, 0, len(g.Players))
	for i := range g.Players {
		g.Players[i].Bet = 0
		g.Players[i].TotalBet = 0
		g.Players[i].AllIn = false
		g.Players[i].HasActed = false
		g.Players[i].Shown = false
		g.Players[i].Hole = [2]Card{}
		if g.Players[i].Chips > 0 {
			g.Players[i].Folded = false
			liveSeats = append(liveSeats, i)
		} else {
			g.Players[i].Folded = true
		}
	}
	if len(liveSeats) < 2 {
		// Не должно происходить (иначе TableOver), но подстрахуемся.
		return fmt.Errorf("poker: need at least 2 players with chips")
	}

	// Позиции блайндов. Хедз-ап (2 живых): дилер = малый блайнд.
	if len(liveSeats) == 2 {
		g.SBIndex = g.DealerIndex
		g.BBIndex = g.nextSeatWithChips(g.DealerIndex + 1)
	} else {
		g.SBIndex = g.nextSeatWithChips(g.DealerIndex + 1)
		g.BBIndex = g.nextSeatWithChips(g.SBIndex + 1)
	}
	g.postBet(g.SBIndex, g.SmallBlind)
	g.postBet(g.BBIndex, g.BigBlind)
	g.CurrentBet = g.BigBlind

	// Раздаём по 2 карты живым игрокам.
	for i := range g.Players {
		if g.Players[i].Folded {
			continue
		}
		c1, err := g.Deck.Deal()
		if err != nil {
			return err
		}
		c2, err := g.Deck.Deal()
		if err != nil {
			return err
		}
		g.Players[i].Hole = [2]Card{c1, c2}
	}

	g.Street = StreetPreflop
	g.Status = StatusActive
	g.HandOver = false

	// Первым ходит игрок слева от большого блайнда (UTG).
	g.ActingIndex = g.firstLiveFrom(g.BBIndex + 1)
	g.updatePot()
	// Если ходить некому (все живые уже all-in из-за блайндов) — докрутить борд.
	if g.ActingIndex < 0 {
		g.advanceStreet()
	}
	return nil
}

// ShowCards добровольно показывает карманные карты победителя после фолд-вины
// (раздача окончена без вскрытия). На contested showdown карты уже открыты.
func (g *Game) ShowCards(playerIndex int) error {
	if playerIndex < 0 || playerIndex >= len(g.Players) {
		return fmt.Errorf("poker: bad player index %d", playerIndex)
	}
	if !g.HandOver || g.TableOver {
		return fmt.Errorf("poker: cannot show cards now")
	}
	if g.Street != StreetOver {
		return fmt.Errorf("poker: cards already shown at showdown")
	}
	p := &g.Players[playerIndex]
	if p.Folded {
		return fmt.Errorf("poker: folded player cannot show")
	}
	isWinner := false
	for _, w := range g.Winners {
		if w == playerIndex {
			isWinner = true
			break
		}
	}
	if !isWinner {
		return fmt.Errorf("poker: only winner can show")
	}
	p.Shown = true
	return nil
}

// CanShowCards — можно ли игроку нажать «Показать карты» в паузе перед следующей раздачей.
func (g *Game) CanShowCards(playerIndex int) bool {
	if playerIndex < 0 || playerIndex >= len(g.Players) {
		return false
	}
	if !g.HandOver || g.TableOver || g.Street != StreetOver {
		return false
	}
	p := g.Players[playerIndex]
	if p.Folded || p.Shown {
		return false
	}
	for _, w := range g.Winners {
		if w == playerIndex {
			return true
		}
	}
	return false
}

// BestHandFor возвращает лучшую 5-карточную комбинацию игрока по его карманным
// картам и борду, если карт достаточно (минимум 5).
func (g *Game) BestHandFor(playerIndex int) (HandValue, error) {
	if playerIndex < 0 || playerIndex >= len(g.Players) {
		return HandValue{}, fmt.Errorf("poker: bad player index %d", playerIndex)
	}
	p := g.Players[playerIndex]
	cards := make([]Card, 0, 7)
	if p.Hole[0] != (Card{}) {
		cards = append(cards, p.Hole[0])
	}
	if p.Hole[1] != (Card{}) {
		cards = append(cards, p.Hole[1])
	}
	cards = append(cards, g.Community...)
	if len(cards) < 5 {
		return HandValue{}, fmt.Errorf("poker: not enough cards to evaluate (%d)", len(cards))
	}
	return EvaluateBest(cards)
}

// ForfeitPlayer убирает игрока со стола (сдача/выход): обнуляет фишки и сбрасывает
// карты. Если это завершает текущую раздачу или весь стол — состояние обновится.
func (g *Game) ForfeitPlayer(idx int) {
	if idx < 0 || idx >= len(g.Players) {
		return
	}

	if g.Status == StatusActive {
		// Обнуляем фишки ДО фолда, чтобы корректно посчитать TableOver, если
		// сброс завершит раздачу.
		g.Players[idx].Chips = 0
		g.Players[idx].Folded = true
		g.Players[idx].HasActed = true

		nf := g.notFolded()
		if len(nf) == 1 {
			g.awardUncontested(nf[0])
			return
		}
		g.noteEliminations()
		if g.ActingIndex == idx {
			g.ActingIndex = g.firstLiveFrom(idx + 1)
			if g.ActingIndex < 0 || g.bettingComplete() {
				g.advanceStreet()
			}
		}
		return
	}

	// Раздача не активна (пауза между раздачами) — просто убираем со стола.
	g.Players[idx].Chips = 0
	g.Players[idx].Folded = true
	g.noteEliminations()
	withChips := make([]int, 0, len(g.Players))
	for i := range g.Players {
		if g.Players[i].Chips > 0 {
			withChips = append(withChips, i)
		}
	}
	if len(withChips) <= 1 {
		g.TableOver = true
		g.HandOver = true
		g.Status = StatusOver
		if len(withChips) == 1 {
			g.Winners = []int{withChips[0]}
			g.WinnerUserIDs = []string{g.Players[withChips[0]].UserID}
		}
	}
}

// IsOver — завершена ли игра.
func (g *Game) IsOver() bool {
	return g.Status == StatusOver
}

// WinnerIDs возвращает UserID победителей (пусто, пока игра не завершена).
func (g *Game) WinnerIDs() []string {
	return g.WinnerUserIDs
}

// Encode сериализует состояние игры в JSON-строку (для Redis).
func Encode(g *Game) (string, error) {
	b, err := json.Marshal(g)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// Decode восстанавливает состояние игры из JSON-строки.
func Decode(raw string) (*Game, error) {
	if raw == "" {
		return nil, fmt.Errorf("poker: empty state")
	}
	var g Game
	if err := json.Unmarshal([]byte(raw), &g); err != nil {
		return nil, err
	}
	if g.Community == nil {
		g.Community = []Card{}
	}
	if g.Deck == nil {
		g.Deck = &Deck{Cards: []Card{}}
	}
	// Обратная совместимость со «старыми» состояниями (одна раздача = игра).
	if g.HandNumber == 0 {
		g.HandNumber = 1
	}
	if g.HandsPerLevel == 0 {
		g.HandsPerLevel = 3
	}
	if g.BaseBigBlind == 0 {
		g.BaseBigBlind = g.BigBlind
	}
	if g.BaseSmallBlind == 0 {
		g.BaseSmallBlind = g.SmallBlind
	}
	return &g, nil
}
