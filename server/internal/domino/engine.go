package domino

import (
	"encoding/json"
	"fmt"
	"strings"
)

const (
	TileCount    = 28
	SuitCopies   = 7
	GoatScore    = 101
	ClassicScore = 100
	SeaScore     = 125
	SeaRecordMin = 25
	SeaBlankHit  = 75
	SeaSixHit    = 100
	HandSize     = 7

	ModeKozel   = "kozel"
	ModeClassic = "classic"
	ModeSea     = "sea"

	StatusPlaying  = "playing"
	StatusRoundEnd = "round_end"
	StatusOver     = "over"

	ActionPlay      = "play"
	ActionDraw      = "draw"
	ActionPass      = "pass"
	ActionNextRound = "next_round"
	ActionForfeit   = "forfeit"

	RoundOut     = "out"
	RoundFish    = "fish"
	RoundForfeit = "forfeit"
	RoundFast    = "fast"
)

// Режимы на одной цепочке из двух концов.
// Козёл: штраф до 101, проигрывает набравший.
// Классика: вышедший записывает чужие очки, первый до 100 побеждает.
// Морской: как козёл по ходам, но пишет только самая тяжёлая рука (от 25),
// 0-0 сразу закрывает кон на 75, выход на 6-6 пишет 100 и сбрасывает счёт закрывшего.
// Партия до 125, набравший проигрывает.

// NormalizeMode приводит пустой и неизвестный режим к «Козлу».
func NormalizeMode(mode string) string {
	switch strings.ToLower(strings.TrimSpace(mode)) {
	case ModeClassic:
		return ModeClassic
	case ModeSea:
		return ModeSea
	default:
		return ModeKozel
	}
}

// TargetFor — порог партии для режима.
func TargetFor(mode string) int {
	switch NormalizeMode(mode) {
	case ModeClassic:
		return ClassicScore
	case ModeSea:
		return SeaScore
	default:
		return GoatScore
	}
}

type Action struct {
	Type  string `json:"type"`
	Tile  int    `json:"tile,omitempty"`
	End   string `json:"end,omitempty"`
	Actor string `json:"actor_user_id,omitempty"`
}

type Move struct {
	Tile int    `json:"tile"`
	End  string `json:"end"`
}

type Placed struct {
	ID      int    `json:"id"`
	Lo      int    `json:"lo"`
	Hi      int    `json:"hi"`
	Inward  int    `json:"inward"`
	Outward int    `json:"outward"`
	End     string `json:"end"`
	Double  bool   `json:"double"`
}

type Player struct {
	UserID     string `json:"user_id"`
	Hand       []int  `json:"hand"`
	Score      int    `json:"score"`
	Forfeited  bool   `json:"forfeited"`
	RoundPips  int    `json:"round_pips"`
	RoundDelta int    `json:"round_delta"`
}

type Game struct {
	Players       []Player `json:"players"`
	Boneyard      []int    `json:"boneyard"`
	Chain         []Placed `json:"chain"`
	LeftEnd       int      `json:"left_end"`
	RightEnd      int      `json:"right_end"`
	Turn          int      `json:"turn"`
	ForcedTile    int      `json:"forced_tile"`
	Round         int      `json:"round"`
	Status        string   `json:"status"`
	Starter       int      `json:"starter"`
	RoundKind     string   `json:"round_kind"`
	OutSeat       int      `json:"out_seat"`
	GoatSeat      int      `json:"goat_seat"`
	WinnerUserIDs []string `json:"winner_user_ids"`
	LastAction    string   `json:"last_action"`
	LastTile      int      `json:"last_tile"`
	LastEnd       string   `json:"last_end"`
	LastActor     int      `json:"last_actor"`
	EventSeq      int      `json:"event_seq"`
	Rng           uint64   `json:"rng"`
	Target        int      `json:"target"`
	Mode          string   `json:"mode"`
}

type ViewPlayer struct {
	UserID      string `json:"user_id"`
	Seat        int    `json:"seat"`
	Hand        []int  `json:"hand"`
	HandCount   int    `json:"hand_count"`
	Score       int    `json:"score"`
	Forfeited   bool   `json:"forfeited"`
	RoundPips   int    `json:"round_pips"`
	RoundDelta  int    `json:"round_delta"`
	DisplayName string `json:"display_name,omitempty"`
	AvatarKind  string `json:"avatar_kind,omitempty"`
	AvatarValue string `json:"avatar_value,omitempty"`
	FrameCode   string `json:"frame_code,omitempty"`
	FrameColor  string `json:"frame_color,omitempty"`
}

type View struct {
	Players       []ViewPlayer `json:"players"`
	Chain         []Placed     `json:"chain"`
	LeftEnd       int          `json:"left_end"`
	RightEnd      int          `json:"right_end"`
	BoneyardCount int          `json:"boneyard_count"`
	Turn          int          `json:"turn"`
	ForcedTile    int          `json:"forced_tile"`
	Round         int          `json:"round"`
	Status        string       `json:"status"`
	Starter       int          `json:"starter"`
	RoundKind     string       `json:"round_kind"`
	OutSeat       int          `json:"out_seat"`
	GoatSeat      int          `json:"goat_seat"`
	WinnerUserIDs []string     `json:"winner_user_ids"`
	Legal         []Move       `json:"legal"`
	TargetScore   int          `json:"target_score"`
	LastAction    string       `json:"last_action"`
	LastTile      int          `json:"last_tile"`
	LastEnd       string       `json:"last_end"`
	LastActor     int          `json:"last_actor"`
	EventSeq      int          `json:"event_seq"`
	Mode          string       `json:"mode"`
}

func Pips(id int) (lo, hi int) {
	if id < 0 || id >= TileCount {
		return 0, 0
	}
	hi = 0
	for {
		count := hi + 1
		base := hi * (hi + 1) / 2
		if id < base+count {
			return id - base, hi
		}
		hi++
	}
}

func TileID(lo, hi int) int {
	if lo > hi {
		lo, hi = hi, lo
	}
	return hi*(hi+1)/2 + lo
}

func PipSum(ids []int) int {
	sum := 0
	for _, id := range ids {
		lo, hi := Pips(id)
		sum += lo + hi
	}
	return sum
}

func IsDouble(id int) bool {
	lo, hi := Pips(id)
	return lo == hi
}

func NewGame(playerIDs []string, seed int64) (*Game, error) {
	return NewMatch(playerIDs, seed, ModeKozel)
}

func NewMatch(playerIDs []string, seed int64, mode string) (*Game, error) {
	if len(playerIDs) < 2 || len(playerIDs) > 4 {
		return nil, fmt.Errorf("domino: need 2..4 players")
	}
	if seed == 0 {
		seed = 1
	}
	mode = NormalizeMode(mode)
	g := &Game{
		Players:    make([]Player, len(playerIDs)),
		LeftEnd:    -1,
		RightEnd:   -1,
		ForcedTile: -1,
		OutSeat:    -1,
		GoatSeat:   -1,
		Status:     StatusPlaying,
		Round:      1,
		Target:     TargetFor(mode),
		Mode:       mode,
		Rng:        uint64(seed),
		LastTile:   -1,
		LastActor:  -1,
	}
	for i, id := range playerIDs {
		g.Players[i] = Player{UserID: id, Hand: []int{}}
	}
	if err := g.deal(true); err != nil {
		return nil, err
	}
	return g, nil
}

func Encode(g *Game) (string, error) {
	if g == nil {
		return "", fmt.Errorf("domino: nil game")
	}
	raw, err := json.Marshal(g)
	if err != nil {
		return "", err
	}
	return string(raw), nil
}

func Decode(raw string) (*Game, error) {
	if raw == "" {
		return nil, fmt.Errorf("domino: empty state")
	}
	var g Game
	if err := json.Unmarshal([]byte(raw), &g); err != nil {
		return nil, err
	}
	g.Mode = NormalizeMode(g.Mode)
	if g.Target == 0 {
		g.Target = TargetFor(g.Mode)
	}
	return &g, nil
}

func (g *Game) IsOver() bool {
	return g != nil && g.Status == StatusOver
}

func (g *Game) PlayerIndex(userID string) int {
	if g == nil {
		return -1
	}
	for i := range g.Players {
		if g.Players[i].UserID == userID {
			return i
		}
	}
	return -1
}

func (g *Game) clone() *Game {
	if g == nil {
		return nil
	}
	n := *g
	n.Players = append([]Player(nil), g.Players...)
	for i := range n.Players {
		n.Players[i].Hand = append([]int(nil), g.Players[i].Hand...)
	}
	n.Boneyard = append([]int(nil), g.Boneyard...)
	n.Chain = append([]Placed(nil), g.Chain...)
	n.WinnerUserIDs = append([]string(nil), g.WinnerUserIDs...)
	return &n
}

func (g *Game) nextRand() uint64 {
	g.Rng += 0x9E3779B97F4A7C15
	z := g.Rng
	z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
	z = (z ^ (z >> 27)) * 0x94D049BB133111EB
	return z ^ (z >> 31)
}

func (g *Game) shuffle(ids []int) {
	for i := len(ids) - 1; i > 0; i-- {
		j := int(g.nextRand() % uint64(i+1))
		ids[i], ids[j] = ids[j], ids[i]
	}
}

func (g *Game) aliveCount() int {
	n := 0
	for i := range g.Players {
		if !g.Players[i].Forfeited {
			n++
		}
	}
	return n
}

func (g *Game) deal(opening bool) error {
	useOpening := opening || (g.Round <= 1 && g.EventSeq == 0)
	nextStarter := 0
	if !useOpening {
		nextStarter = g.pickNextStarter()
	}
	ids := make([]int, TileCount)
	for i := 0; i < TileCount; i++ {
		ids[i] = i
	}
	g.shuffle(ids)
	for i := range g.Players {
		g.Players[i].Hand = []int{}
		g.Players[i].RoundPips = 0
		g.Players[i].RoundDelta = 0
	}
	cursor := 0
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		handSize := g.handSize()
		if cursor+handSize > len(ids) {
			return fmt.Errorf("domino: not enough tiles")
		}
		g.Players[i].Hand = append([]int(nil), ids[cursor:cursor+handSize]...)
		cursor += handSize
	}
	g.Boneyard = append([]int(nil), ids[cursor:]...)
	g.Chain = nil
	g.LeftEnd = -1
	g.RightEnd = -1
	g.ForcedTile = -1
	g.OutSeat = -1
	g.RoundKind = ""
	g.LastTile = -1
	g.LastEnd = ""
	g.LastAction = ""
	if useOpening {
		seat, tile, ok := g.pickOpening()
		if !ok {
			return fmt.Errorf("domino: no opening tile")
		}
		g.Starter = seat
		g.Turn = seat
		g.ForcedTile = tile
		return nil
	}
	g.Starter = nextStarter
	g.Turn = nextStarter
	g.ForcedTile = -1
	return nil
}

func (g *Game) handSize() int {
	if g.normalizedMode() == ModeClassic && len(g.Players) >= 4 {
		return 5
	}
	return HandSize
}

func (g *Game) normalizedMode() string {
	if g == nil {
		return ModeKozel
	}
	return NormalizeMode(g.Mode)
}

func (g *Game) openingDoubles() []int {
	if g.normalizedMode() == ModeClassic {
		return []int{6, 0, 5, 4, 3, 2, 1}
	}
	return []int{1, 2, 3, 4, 5, 6, 0}
}

// pickOpening — козёл и морской: дубли 1-1 … 6-6, затем 0-0.
// Классика: 6-6, затем 0-0 и дальше дубли по убыванию.
// Если дублей нет, самая старшая кость (старший пайк, затем младший).
func (g *Game) pickOpening() (seat, tile int, ok bool) {
	for _, pip := range g.openingDoubles() {
		id := TileID(pip, pip)
		for i := range g.Players {
			if g.Players[i].Forfeited {
				continue
			}
			if contains(g.Players[i].Hand, id) {
				return i, id, true
			}
		}
	}
	bestSeat := -1
	bestTile := -1
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		for _, id := range g.Players[i].Hand {
			if bestTile < 0 || tileBeats(id, bestTile) {
				bestTile = id
				bestSeat = i
			}
		}
	}
	if bestSeat < 0 {
		return 0, 0, false
	}
	return bestSeat, bestTile, true
}

func tileBeats(a, b int) bool {
	alo, ahi := Pips(a)
	blo, bhi := Pips(b)
	if ahi != bhi {
		return ahi > bhi
	}
	return alo > blo
}

func (g *Game) pickNextStarter() int {
	if (g.RoundKind == RoundOut || g.RoundKind == RoundFast) && g.OutSeat >= 0 && g.OutSeat < len(g.Players) && !g.Players[g.OutSeat].Forfeited {
		return g.OutSeat
	}
	minPips := int(^uint(0) >> 1)
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		if g.Players[i].RoundPips < minPips {
			minPips = g.Players[i].RoundPips
		}
	}
	n := len(g.Players)
	start := g.Starter
	if g.RoundKind == RoundFish {
		start = (g.Starter + 1) % n
	}
	for step := 0; step < n; step++ {
		seat := (start + step) % n
		if g.Players[seat].Forfeited {
			continue
		}
		if g.Players[seat].RoundPips == minPips {
			return seat
		}
	}
	for i := range g.Players {
		if !g.Players[i].Forfeited {
			return i
		}
	}
	return 0
}

func (g *Game) Apply(action Action) error {
	if g == nil {
		return fmt.Errorf("domino: nil game")
	}
	if g.Status == StatusOver {
		return fmt.Errorf("game is over")
	}
	switch action.Type {
	case ActionForfeit:
		return g.forfeit(action)
	case ActionNextRound:
		if g.Status != StatusRoundEnd {
			return fmt.Errorf("next round is not pending")
		}
		g.Round++
		if err := g.deal(false); err != nil {
			return err
		}
		g.Status = StatusPlaying
		g.EventSeq++
		g.LastAction = ActionNextRound
		g.LastActor = g.Turn
		return nil
	}
	if g.Status != StatusPlaying {
		return fmt.Errorf("not your turn")
	}
	seat := g.Turn
	if seat < 0 || seat >= len(g.Players) || g.Players[seat].Forfeited {
		return fmt.Errorf("not your turn")
	}
	switch action.Type {
	case ActionDraw:
		if len(g.legal(seat)) > 0 {
			return fmt.Errorf("illegal move")
		}
		if len(g.Boneyard) == 0 {
			return fmt.Errorf("illegal move")
		}
		tile := g.Boneyard[len(g.Boneyard)-1]
		g.Boneyard = g.Boneyard[:len(g.Boneyard)-1]
		g.Players[seat].Hand = append(g.Players[seat].Hand, tile)
		g.EventSeq++
		g.LastAction = ActionDraw
		g.LastTile = tile
		g.LastEnd = ""
		g.LastActor = seat
		return nil
	case ActionPass:
		if len(g.legal(seat)) > 0 || len(g.Boneyard) > 0 {
			return fmt.Errorf("illegal move")
		}
		g.EventSeq++
		g.LastAction = ActionPass
		g.LastTile = -1
		g.LastEnd = ""
		g.LastActor = seat
		g.advance()
		g.maybeFish()
		return nil
	case ActionPlay:
		mv, ok := g.matchLegal(seat, action.Tile, action.End)
		if !ok {
			return fmt.Errorf("illegal move")
		}
		g.play(seat, mv)
		return nil
	default:
		return fmt.Errorf("unknown move")
	}
}

func (g *Game) forfeit(action Action) error {
	seat := g.Turn
	if action.Actor != "" {
		seat = g.PlayerIndex(action.Actor)
	}
	if seat < 0 || seat >= len(g.Players) {
		return fmt.Errorf("not a player")
	}
	if g.Players[seat].Forfeited {
		return fmt.Errorf("player forfeited")
	}
	g.Players[seat].Forfeited = true
	g.Players[seat].Hand = []int{}
	g.EventSeq++
	g.LastAction = ActionForfeit
	g.LastTile = -1
	g.LastActor = seat
	if g.aliveCount() <= 1 {
		g.Status = StatusOver
		g.RoundKind = RoundForfeit
		g.GoatSeat = seat
		g.settleSurvival()
		return nil
	}
	if g.Status == StatusRoundEnd {
		return nil
	}
	if g.Turn == seat {
		g.advance()
	}
	g.maybeFish()
	return nil
}

func (g *Game) settleSurvival() {
	g.WinnerUserIDs = nil
	for i := range g.Players {
		if !g.Players[i].Forfeited {
			g.WinnerUserIDs = append(g.WinnerUserIDs, g.Players[i].UserID)
		}
	}
}

func (g *Game) matchLegal(seat, tile int, end string) (Move, bool) {
	moves := g.legal(seat)
	if g.LeftEnd < 0 {
		for _, mv := range moves {
			if mv.Tile == tile {
				return mv, true
			}
		}
		return Move{}, false
	}
	for _, mv := range moves {
		if mv.Tile == tile && mv.End == end {
			return mv, true
		}
	}
	if end == "" {
		var found *Move
		for i := range moves {
			if moves[i].Tile != tile {
				continue
			}
			if found != nil {
				return Move{}, false
			}
			cp := moves[i]
			found = &cp
		}
		if found != nil {
			return *found, true
		}
	}
	return Move{}, false
}

func (g *Game) play(seat int, mv Move) {
	g.removeHand(seat, mv.Tile)
	lo, hi := Pips(mv.Tile)
	placed := Placed{ID: mv.Tile, Lo: lo, Hi: hi, Double: lo == hi}
	if g.LeftEnd < 0 {
		placed.Inward = lo
		placed.Outward = hi
		placed.End = "start"
		g.LeftEnd = lo
		g.RightEnd = hi
		g.Chain = []Placed{placed}
	} else if mv.End == "left" {
		in, out := orient(mv.Tile, g.LeftEnd)
		placed.Inward = in
		placed.Outward = out
		placed.End = "left"
		g.LeftEnd = out
		g.Chain = append([]Placed{placed}, g.Chain...)
	} else {
		in, out := orient(mv.Tile, g.RightEnd)
		placed.Inward = in
		placed.Outward = out
		placed.End = "right"
		g.RightEnd = out
		g.Chain = append(g.Chain, placed)
	}
	g.ForcedTile = -1
	g.EventSeq++
	g.LastAction = ActionPlay
	g.LastTile = mv.Tile
	g.LastEnd = placed.End
	g.LastActor = seat
	if g.normalizedMode() == ModeSea && mv.Tile == TileID(0, 0) {
		g.finishRound(RoundFast, seat)
		return
	}
	if len(g.Players[seat].Hand) == 0 {
		g.finishRound(RoundOut, seat)
		return
	}
	g.advance()
	g.maybeFish()
}

func orient(id, end int) (inward, outward int) {
	lo, hi := Pips(id)
	if lo == end {
		return lo, hi
	}
	return hi, lo
}

func (g *Game) removeHand(seat, tile int) {
	hand := g.Players[seat].Hand
	for i, id := range hand {
		if id == tile {
			g.Players[seat].Hand = append(hand[:i], hand[i+1:]...)
			return
		}
	}
}

func (g *Game) advance() {
	if g.Status != StatusPlaying {
		return
	}
	n := len(g.Players)
	for i := 0; i < n; i++ {
		g.Turn = (g.Turn + 1) % n
		if !g.Players[g.Turn].Forfeited {
			return
		}
	}
}

func (g *Game) maybeFish() {
	if g.Status != StatusPlaying || len(g.Boneyard) > 0 {
		return
	}
	if g.anyCanPlay() {
		return
	}
	g.finishRound(RoundFish, -1)
}

func (g *Game) canPlace(seat int) bool {
	if seat < 0 || seat >= len(g.Players) || g.Players[seat].Forfeited {
		return false
	}
	hand := g.Players[seat].Hand
	if g.LeftEnd < 0 {
		return len(hand) > 0
	}
	for _, id := range hand {
		if tileMatches(id, g.LeftEnd) || tileMatches(id, g.RightEnd) {
			return true
		}
	}
	return false
}

func (g *Game) anyCanPlay() bool {
	for i := range g.Players {
		if g.canPlace(i) {
			return true
		}
	}
	return false
}

func (g *Game) legal(seat int) []Move {
	if g == nil || g.Status != StatusPlaying || seat < 0 || seat >= len(g.Players) {
		return nil
	}
	if g.Players[seat].Forfeited || g.Turn != seat {
		return nil
	}
	hand := g.Players[seat].Hand
	if g.LeftEnd < 0 {
		if g.ForcedTile >= 0 {
			if contains(hand, g.ForcedTile) {
				return []Move{{Tile: g.ForcedTile, End: "left"}}
			}
			return nil
		}
		out := make([]Move, 0, len(hand))
		for _, id := range hand {
			out = append(out, Move{Tile: id, End: "left"})
		}
		return out
	}
	out := make([]Move, 0, 4)
	for _, id := range hand {
		if tileMatches(id, g.LeftEnd) {
			out = append(out, Move{Tile: id, End: "left"})
		}
		if tileMatches(id, g.RightEnd) {
			out = append(out, Move{Tile: id, End: "right"})
		}
	}
	return out
}

func tileMatches(id, end int) bool {
	if end < 0 {
		return false
	}
	lo, hi := Pips(id)
	return lo == end || hi == end
}

func (g *Game) finishRound(kind string, outSeat int) {
	switch g.normalizedMode() {
	case ModeClassic:
		g.finishClassic(kind, outSeat)
	case ModeSea:
		g.finishSea(kind, outSeat)
	default:
		g.finishGoat(kind, outSeat)
	}
}

func (g *Game) finishGoat(kind string, outSeat int) {
	g.RoundKind = kind
	g.OutSeat = outSeat
	active := 0
	minPips := int(^uint(0) >> 1)
	pips := make([]int, len(g.Players))
	for i := range g.Players {
		if g.Players[i].Forfeited {
			g.Players[i].RoundPips = 0
			g.Players[i].RoundDelta = 0
			continue
		}
		sum := PipSum(g.Players[i].Hand)
		pips[i] = sum
		g.Players[i].RoundPips = sum
		active++
		if sum < minPips {
			minPips = sum
		}
	}
	minCount := 0
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		if pips[i] == minPips {
			minCount++
		}
	}
	crossed := false
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		delta := pips[i]
		if kind == RoundFish && minCount < active && pips[i] == minPips {
			delta = 0
		}
		g.Players[i].RoundDelta = delta
		g.Players[i].Score += delta
		if g.Players[i].Score >= g.Target {
			crossed = true
		}
	}
	g.closeRound(crossed)
}

func (g *Game) finishClassic(kind string, outSeat int) {
	g.RoundKind = kind
	g.OutSeat = outSeat
	pips, _, minPips, minCount := g.snapshotPips()
	for i := range g.Players {
		if !g.Players[i].Forfeited {
			g.Players[i].RoundDelta = 0
		}
	}
	if kind == RoundOut && outSeat >= 0 && outSeat < len(g.Players) && !g.Players[outSeat].Forfeited {
		gain := 0
		for i := range g.Players {
			if g.Players[i].Forfeited || i == outSeat {
				continue
			}
			gain += pips[i]
		}
		g.Players[outSeat].RoundDelta = gain
		g.Players[outSeat].Score += gain
	} else if kind == RoundFish && minCount == 1 {
		winner := -1
		others := 0
		oppN := 0
		for i := range g.Players {
			if g.Players[i].Forfeited {
				continue
			}
			if pips[i] == minPips {
				winner = i
				continue
			}
			others += pips[i]
			oppN++
		}
		if winner >= 0 {
			gain := others - minPips*oppN
			if gain < 0 {
				gain = 0
			}
			g.Players[winner].RoundDelta = gain
			g.Players[winner].Score += gain
		}
	}
	g.closeRound(g.someoneReached())
}

func (g *Game) finishSea(kind string, outSeat int) {
	g.RoundKind = kind
	g.OutSeat = outSeat
	pips, _, _, _ := g.snapshotPips()
	for i := range g.Players {
		if !g.Players[i].Forfeited {
			g.Players[i].RoundDelta = 0
		}
	}
	if kind == RoundOut && g.LastTile == TileID(6, 6) && outSeat >= 0 && outSeat < len(g.Players) {
		g.Players[outSeat].Score = 0
	}
	candidates := make([]int, 0, len(g.Players))
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		if (kind == RoundOut || kind == RoundFast) && i == outSeat {
			continue
		}
		candidates = append(candidates, i)
	}
	switch {
	case kind == RoundFast:
		g.chargeUnique(candidates, pips, SeaBlankHit)
	case kind == RoundOut && g.LastTile == TileID(6, 6):
		g.chargeUnique(candidates, pips, SeaSixHit)
	default:
		g.chargeHeaviest(candidates, pips)
	}
	g.closeRound(g.someoneReached())
}

func (g *Game) snapshotPips() (pips []int, active, minPips, minCount int) {
	pips = make([]int, len(g.Players))
	minPips = int(^uint(0) >> 1)
	for i := range g.Players {
		if g.Players[i].Forfeited {
			g.Players[i].RoundPips = 0
			g.Players[i].RoundDelta = 0
			continue
		}
		sum := PipSum(g.Players[i].Hand)
		pips[i] = sum
		g.Players[i].RoundPips = sum
		active++
		if sum < minPips {
			minPips = sum
		}
	}
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		if pips[i] == minPips {
			minCount++
		}
	}
	return pips, active, minPips, minCount
}

func (g *Game) someoneReached() bool {
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		if g.Players[i].Score >= g.Target {
			return true
		}
	}
	return false
}

func (g *Game) chargeUnique(candidates, pips []int, amount int) {
	best, ties, bestPips := -1, 0, -1
	for _, seat := range candidates {
		if pips[seat] > bestPips {
			bestPips = pips[seat]
			best = seat
			ties = 1
			continue
		}
		if pips[seat] == bestPips {
			ties++
		}
	}
	if ties != 1 || best < 0 {
		return
	}
	g.Players[best].RoundDelta = amount
	g.Players[best].Score += amount
}

func (g *Game) chargeHeaviest(candidates, pips []int) {
	heavy := 0
	best, ties, bestPips := -1, 0, -1
	for _, seat := range candidates {
		if pips[seat] >= SeaRecordMin {
			heavy++
		}
		if pips[seat] > bestPips {
			bestPips = pips[seat]
			best = seat
			ties = 1
			continue
		}
		if pips[seat] == bestPips {
			ties++
		}
	}
	if heavy >= 2 || ties != 1 || best < 0 || bestPips < SeaRecordMin {
		return
	}
	g.Players[best].RoundDelta = bestPips
	g.Players[best].Score += bestPips
}

func (g *Game) closeRound(crossed bool) {
	if crossed || g.aliveCount() <= 1 {
		g.Status = StatusOver
		if g.normalizedMode() == ModeClassic {
			g.settlePositive()
			return
		}
		g.settleScores()
		return
	}
	g.Status = StatusRoundEnd
}

func (g *Game) settlePositive() {
	g.GoatSeat = -1
	g.WinnerUserIDs = nil
	bestScore := -1
	alive := 0
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		alive++
		if g.Players[i].Score > bestScore {
			bestScore = g.Players[i].Score
		}
	}
	if bestScore < 0 || alive == 0 {
		return
	}
	same := 0
	for i := range g.Players {
		if g.Players[i].Forfeited {
			continue
		}
		if g.Players[i].Score == bestScore {
			same++
		}
	}
	if same == alive {
		return
	}
	for i := range g.Players {
		if g.Players[i].Forfeited || g.Players[i].Score != bestScore {
			continue
		}
		g.WinnerUserIDs = append(g.WinnerUserIDs, g.Players[i].UserID)
	}
}

func (g *Game) settleScores() {
	n := len(g.Players)
	best := -1
	bestScore := -1
	for step := 0; step < n; step++ {
		seat := (g.Starter + step) % n
		if g.Players[seat].Forfeited {
			continue
		}
		if best < 0 || g.Players[seat].Score > bestScore {
			best = seat
			bestScore = g.Players[seat].Score
		}
	}
	g.GoatSeat = best
	g.WinnerUserIDs = nil
	if best < 0 {
		return
	}
	minScore := int(^uint(0) >> 1)
	for i := range g.Players {
		if g.Players[i].Forfeited || i == best {
			continue
		}
		if g.Players[i].Score < minScore {
			minScore = g.Players[i].Score
		}
	}
	if minScore == int(^uint(0)>>1) || minScore == bestScore {
		return
	}
	for i := range g.Players {
		if g.Players[i].Forfeited || i == best {
			continue
		}
		if g.Players[i].Score == minScore {
			g.WinnerUserIDs = append(g.WinnerUserIDs, g.Players[i].UserID)
		}
	}
}

func (g *Game) LegalMoves(seat int) []Move {
	return g.legal(seat)
}

func (g *Game) PublicHandCount(seat int) int {
	if seat < 0 || seat >= len(g.Players) {
		return 0
	}
	return len(g.Players[seat].Hand)
}

func (g *Game) View(viewer string) View {
	reveal := g.Status == StatusRoundEnd || g.Status == StatusOver
	viewerSeat := g.PlayerIndex(viewer)
	players := make([]ViewPlayer, len(g.Players))
	for i := range g.Players {
		p := g.Players[i]
		vp := ViewPlayer{
			UserID:     p.UserID,
			Seat:       i,
			HandCount:  len(p.Hand),
			Score:      p.Score,
			Forfeited:  p.Forfeited,
			RoundPips:  p.RoundPips,
			RoundDelta: p.RoundDelta,
			Hand:       []int{},
		}
		if reveal || i == viewerSeat {
			vp.Hand = append([]int(nil), p.Hand...)
		}
		players[i] = vp
	}
	legal := []Move{}
	if viewerSeat == g.Turn && g.Status == StatusPlaying && viewerSeat >= 0 && !g.Players[viewerSeat].Forfeited {
		legal = append(legal, g.legal(viewerSeat)...)
	}
	if legal == nil {
		legal = []Move{}
	}
	lastTile := g.LastTile
	if g.LastAction == ActionDraw && viewerSeat != g.LastActor && !reveal {
		lastTile = -1
	}
	winners := append([]string(nil), g.WinnerUserIDs...)
	if winners == nil {
		winners = []string{}
	}
	chain := append([]Placed(nil), g.Chain...)
	if chain == nil {
		chain = []Placed{}
	}
	return View{
		Players:       players,
		Chain:         chain,
		LeftEnd:       g.LeftEnd,
		RightEnd:      g.RightEnd,
		BoneyardCount: len(g.Boneyard),
		Turn:          g.Turn,
		ForcedTile:    g.ForcedTile,
		Round:         g.Round,
		Status:        g.Status,
		Starter:       g.Starter,
		RoundKind:     g.RoundKind,
		OutSeat:       g.OutSeat,
		GoatSeat:      g.GoatSeat,
		WinnerUserIDs: winners,
		Legal:         legal,
		TargetScore:   g.Target,
		LastAction:    g.LastAction,
		LastTile:      lastTile,
		LastEnd:       g.LastEnd,
		LastActor:     g.LastActor,
		EventSeq:      g.EventSeq,
		Mode:          g.normalizedMode(),
	}
}

func contains(ids []int, id int) bool {
	for _, v := range ids {
		if v == id {
			return true
		}
	}
	return false
}
