package uno

import (
	"encoding/json"
	"fmt"
)

const (
	// DefaultTargetScore is the 1v1 match limit.
	DefaultTargetScore = 100
	// MultiplayerTargetScore is the match limit for 3+ players.
	MultiplayerTargetScore = 300
	minPlayers             = 2
	maxPlayers             = 10
	cardsPerHand           = 7
)

// TargetScoreForPlayerCount returns 100 for heads-up and 300 for 3+ players.
func TargetScoreForPlayerCount(playerCount int) int {
	if playerCount >= 3 {
		return MultiplayerTargetScore
	}
	return DefaultTargetScore
}

// Status identifies the action currently expected by the engine.
type Status string

const (
	StatusActive               Status = "active"
	StatusAwaitingColor        Status = "awaiting_color"
	StatusAwaitingWD4Challenge Status = "awaiting_wd4_challenge"
	StatusAwaitingDrawnPlay    Status = "awaiting_drawn_play"
	StatusBetweenRounds        Status = "between_rounds"
	StatusOver                 Status = "over"
)

// Action types accepted by Apply.
const (
	ActionPlay         = "play"
	ActionDraw         = "draw"
	ActionKeep         = "keep"
	ActionCallUno      = "call_uno"
	ActionChallengeUno = "challenge_uno"
	ActionChallengeWD4 = "challenge_wd4"
	ActionChooseColor  = "choose_color"
	ActionForfeit      = "forfeit"
	ActionNextRound    = "next_round"
)

// Action is a state transition requested by a player.
// ActorUserID is required for forfeit and challenge_uno; turn actions use CurrentIndex.
// CallUno applies to the vulnerable last player, while TargetUserID identifies
// that player for ChallengeUno.
type Action struct {
	Type         string `json:"type"`
	CardID       string `json:"cardId,omitempty"`
	Color        string `json:"color,omitempty"`
	TargetUserID string `json:"targetUserId,omitempty"`
	ActorUserID  string `json:"actorUserId,omitempty"`
}

// Player is one seat in an UNO match.
type Player struct {
	UserID    string `json:"userId"`
	Hand      []Card `json:"hand"`
	Score     int    `json:"score"`
	SaidUno   bool   `json:"saidUno"`
	Seat      int    `json:"seat"`
	Forfeited bool   `json:"forfeited,omitempty"`
}

// Game contains the complete, persistence-safe state of an UNO match.
type Game struct {
	Players               []Player `json:"players"`
	DrawPile              []Card   `json:"drawPile"`
	DiscardPile           []Card   `json:"discardPile"`
	CurrentColor          Color    `json:"currentColor"`
	Direction             int      `json:"direction"`
	CurrentIndex          int      `json:"currentIndex"`
	Status                Status   `json:"status"`
	PendingDraw           int      `json:"pendingDraw"`
	DrawnCardID           string   `json:"drawnCardId,omitempty"`
	LastPlayedBy          string   `json:"lastPlayedBy,omitempty"`
	Wild4PlayerIndex      int      `json:"wild4PlayerIndex"`
	RoundNumber           int      `json:"roundNumber"`
	TargetScore           int      `json:"targetScore"`
	WinnerUserIDs         []string `json:"winnerUserIds"`
	EliminatedOrder       []string `json:"eliminatedOrder,omitempty"`
	LastRoundWinnerUserID string   `json:"lastRoundWinnerUserId,omitempty"`
	LastRoundPoints       int      `json:"lastRoundPoints,omitempty"`
	LastRoundNumber       int      `json:"lastRoundNumber,omitempty"`

	DealerIndex             int   `json:"dealerIndex"`
	ColorChooserIndex       int   `json:"colorChooserIndex"`
	UnoVulnerableIndex      int   `json:"unoVulnerableIndex"`
	PendingRoundWinnerIndex int   `json:"pendingRoundWinnerIndex"`
	Wild4WasLegal           bool  `json:"wild4WasLegal"`
	Seed                    int64 `json:"seed"`
	ShuffleCount            int   `json:"shuffleCount"`

	EventSeq       int    `json:"eventSeq"`
	LastEventType  string `json:"lastEventType,omitempty"`
	LastEventActor string `json:"lastEventActor,omitempty"`
	LastDrawUserID string `json:"lastDrawUserId,omitempty"`
	LastDrawCount  int    `json:"lastDrawCount,omitempty"`
	LastEventCard  *Card  `json:"lastEventCard,omitempty"`
	Wild4ProofCard *Card  `json:"wild4ProofCard,omitempty"`
}

// PlayerView hides opponents' cards while retaining their hand sizes.
type PlayerView struct {
	UserID    string `json:"userId"`
	Hand      []Card `json:"hand,omitempty"`
	HandCount int    `json:"handCount"`
	Score     int    `json:"score"`
	SaidUno   bool   `json:"saidUno"`
	Seat      int    `json:"seat"`
	Forfeited bool   `json:"forfeited,omitempty"`
}

// GameView is the information safe to return to one player.
type GameView struct {
	Players               []PlayerView `json:"players"`
	TopDiscard            *Card        `json:"topDiscard,omitempty"`
	DrawCount             int          `json:"drawCount"`
	CurrentColor          Color        `json:"currentColor"`
	Direction             int          `json:"direction"`
	CurrentIndex          int          `json:"currentIndex"`
	CurrentUserID         string       `json:"currentUserId,omitempty"`
	Status                Status       `json:"status"`
	PendingDraw           int          `json:"pendingDraw"`
	DrawnCardID           string       `json:"drawnCardId,omitempty"`
	LastPlayedBy          string       `json:"lastPlayedBy,omitempty"`
	RoundNumber           int          `json:"roundNumber"`
	TargetScore           int          `json:"targetScore"`
	WinnerUserIDs         []string     `json:"winnerUserIds"`
	EliminatedOrder       []string     `json:"eliminatedOrder,omitempty"`
	LastRoundWinnerUserID string       `json:"lastRoundWinnerUserId,omitempty"`
	LastRoundPoints       int          `json:"lastRoundPoints,omitempty"`
	LastRoundNumber       int          `json:"lastRoundNumber,omitempty"`

	CanChallengeUno    bool `json:"canChallengeUno"`
	CanChallengeWD4    bool `json:"canChallengeWd4"`
	MustChooseColor    bool `json:"mustChooseColor"`
	CanKeepOrPlayDrawn bool `json:"canKeepOrPlayDrawn"`
	MyIndex            int  `json:"myIndex"`

	EventSeq       int    `json:"eventSeq"`
	LastEventType  string `json:"lastEventType,omitempty"`
	LastEventActor string `json:"lastEventActor,omitempty"`
	LastDrawUserID string `json:"lastDrawUserId,omitempty"`
	LastDrawCount  int    `json:"lastDrawCount,omitempty"`
	LastEventCard  *Card  `json:"lastEventCard,omitempty"`
}

// NewGame creates a deterministic match and deals its first round.
func NewGame(playerIDs []string, seed int64) (*Game, error) {
	if len(playerIDs) < minPlayers || len(playerIDs) > maxPlayers {
		return nil, fmt.Errorf("uno: need %d..%d players, got %d", minPlayers, maxPlayers, len(playerIDs))
	}

	seen := make(map[string]struct{}, len(playerIDs))
	players := make([]Player, len(playerIDs))
	for i, id := range playerIDs {
		if id == "" {
			return nil, fmt.Errorf("uno: player ID at seat %d is empty", i)
		}
		if _, exists := seen[id]; exists {
			return nil, fmt.Errorf("uno: duplicate player ID %q", id)
		}
		seen[id] = struct{}{}
		players[i] = Player{UserID: id, Hand: []Card{}, Seat: i}
	}

	g := &Game{
		Players:                 players,
		Direction:               1,
		Status:                  StatusActive,
		Wild4PlayerIndex:        -1,
		RoundNumber:             1,
		TargetScore:             TargetScoreForPlayerCount(len(playerIDs)),
		WinnerUserIDs:           []string{},
		EliminatedOrder:         []string{},
		DealerIndex:             0,
		ColorChooserIndex:       -1,
		UnoVulnerableIndex:      -1,
		PendingRoundWinnerIndex: -1,
		Seed:                    seed,
	}
	if err := g.startRound(); err != nil {
		return nil, err
	}
	return g, nil
}

// Apply validates and applies one action. Turn actions are attributed to
// CurrentIndex; color choice and UNO calls are attributed by pending state.
func (g *Game) Apply(action Action) error {
	if g == nil {
		return fmt.Errorf("uno: nil game")
	}
	if g.Status == StatusOver {
		return fmt.Errorf("uno: match is over")
	}
	if action.Type == ActionNextRound {
		return g.applyNextRound()
	}
	if action.Type == ActionForfeit {
		return g.applyForfeit(action.ActorUserID)
	}
	if g.Status == StatusBetweenRounds {
		return fmt.Errorf("uno: wait for the next round")
	}
	g.LastDrawUserID = ""
	g.LastDrawCount = 0
	g.LastEventCard = nil

	switch action.Type {
	case ActionPlay:
		return g.applyPlay(action)
	case ActionDraw:
		return g.applyDraw()
	case ActionKeep:
		return g.applyKeep()
	case ActionCallUno:
		return g.applyCallUno()
	case ActionChallengeUno:
		return g.applyChallengeUno(action.ActorUserID, action.TargetUserID)
	case ActionChallengeWD4:
		return g.applyChallengeWD4()
	case ActionChooseColor:
		return g.applyChooseColor(Color(action.Color))
	default:
		return fmt.Errorf("uno: unknown action type %q", action.Type)
	}
}

// View returns a copy of public state with only forUserID's hand revealed.
func (g *Game) View(forUserID string) GameView {
	view := GameView{
		Players:               make([]PlayerView, len(g.Players)),
		DrawCount:             len(g.DrawPile),
		CurrentColor:          g.CurrentColor,
		Direction:             g.Direction,
		CurrentIndex:          g.CurrentIndex,
		Status:                g.Status,
		PendingDraw:           g.PendingDraw,
		LastPlayedBy:          g.LastPlayedBy,
		RoundNumber:           g.RoundNumber,
		TargetScore:           g.TargetScore,
		WinnerUserIDs:         append([]string(nil), g.WinnerUserIDs...),
		EliminatedOrder:       append([]string(nil), g.EliminatedOrder...),
		LastRoundWinnerUserID: g.LastRoundWinnerUserID,
		LastRoundPoints:       g.LastRoundPoints,
		LastRoundNumber:       g.LastRoundNumber,
		EventSeq:              g.EventSeq,
		LastEventType:         g.LastEventType,
		LastEventActor:        g.LastEventActor,
		LastDrawUserID:        g.LastDrawUserID,
		LastDrawCount:         g.LastDrawCount,
	}
	if len(g.DiscardPile) > 0 {
		top := g.DiscardPile[len(g.DiscardPile)-1]
		view.TopDiscard = &top
	}
	if g.CurrentIndex >= 0 && g.CurrentIndex < len(g.Players) {
		view.CurrentUserID = g.Players[g.CurrentIndex].UserID
	}
	for i, player := range g.Players {
		pv := PlayerView{
			UserID:    player.UserID,
			HandCount: len(player.Hand),
			Score:     player.Score,
			SaidUno:   player.SaidUno,
			Seat:      player.Seat,
			Forfeited: player.Forfeited,
		}
		if player.UserID == forUserID {
			pv.Hand = append([]Card(nil), player.Hand...)
		}
		view.Players[i] = pv
	}

	if g.LastEventCard != nil {
		card := *g.LastEventCard
		view.LastEventCard = &card
	}
	viewerIndex := g.playerIndex(forUserID)
	view.MyIndex = viewerIndex
	view.CanChallengeUno = viewerIndex == g.CurrentIndex &&
		g.UnoVulnerableIndex >= 0 &&
		g.UnoVulnerableIndex != viewerIndex
	view.CanChallengeWD4 = viewerIndex == g.CurrentIndex &&
		g.Status == StatusAwaitingWD4Challenge
	view.MustChooseColor = viewerIndex == g.ColorChooserIndex &&
		g.Status == StatusAwaitingColor
	view.CanKeepOrPlayDrawn = viewerIndex == g.CurrentIndex &&
		g.Status == StatusAwaitingDrawnPlay
	if view.CanKeepOrPlayDrawn {
		view.DrawnCardID = g.DrawnCardID
	}
	return view
}

func (g *Game) startRound() error {
	g.DrawPile = NewDeck(g.roundSeed())
	g.DiscardPile = []Card{}
	g.Direction = 1
	g.Status = StatusActive
	g.PendingDraw = 0
	g.DrawnCardID = ""
	g.LastPlayedBy = ""
	g.Wild4PlayerIndex = -1
	g.ColorChooserIndex = -1
	g.UnoVulnerableIndex = -1
	g.PendingRoundWinnerIndex = -1
	g.Wild4WasLegal = false
	g.ShuffleCount = 0
	g.WinnerUserIDs = []string{}
	g.Wild4ProofCard = nil
	g.noteEvent("deal", "", 0, nil)

	for i := range g.Players {
		g.Players[i].Hand = []Card{}
		g.Players[i].SaidUno = false
	}
	for dealt := 0; dealt < cardsPerHand; dealt++ {
		for i := range g.Players {
			if g.Players[i].Forfeited {
				continue
			}
			card, ok := g.drawOne()
			if !ok {
				return fmt.Errorf("uno: deck exhausted during deal")
			}
			g.Players[i].Hand = append(g.Players[i].Hand, card)
		}
	}

	topIndex := -1
	for i := len(g.DrawPile) - 1; i >= 0; i-- {
		if !g.DrawPile[i].isWild() {
			topIndex = i
			break
		}
	}
	if topIndex < 0 {
		return fmt.Errorf("uno: no colored opening card")
	}
	top := g.DrawPile[topIndex]
	g.DrawPile = append(g.DrawPile[:topIndex], g.DrawPile[topIndex+1:]...)
	g.DiscardPile = append(g.DiscardPile, top)
	g.CurrentColor = top.Color

	first := g.nextActive(g.DealerIndex)
	g.CurrentIndex = first
	switch top.Kind {
	case KindSkip:
		g.CurrentIndex = g.nextActive(first)
	case KindReverse:
		if g.activePlayerCount() == 2 {
			g.CurrentIndex = g.nextActive(first)
		} else {
			g.Direction = -1
			g.CurrentIndex = g.nextActive(g.DealerIndex)
		}
	case KindDrawTwo:
		g.drawCards(first, 2)
		g.CurrentIndex = g.nextActive(first)
	}
	return nil
}

func (g *Game) applyPlay(action Action) error {
	if g.Status != StatusActive && g.Status != StatusAwaitingDrawnPlay {
		return fmt.Errorf("uno: cannot play while status is %q", g.Status)
	}
	playerIndex := g.CurrentIndex
	if playerIndex < 0 || playerIndex >= len(g.Players) || g.Players[playerIndex].Forfeited {
		return fmt.Errorf("uno: no active current player")
	}

	cardIndex := -1
	for i, card := range g.Players[playerIndex].Hand {
		if card.ID == action.CardID {
			cardIndex = i
			break
		}
	}
	if cardIndex < 0 {
		return fmt.Errorf("uno: card %q is not in current hand", action.CardID)
	}
	card := g.Players[playerIndex].Hand[cardIndex]
	if g.Status == StatusAwaitingDrawnPlay && card.ID != g.DrawnCardID {
		return fmt.Errorf("uno: only the drawn card may be played")
	}
	if len(g.DiscardPile) == 0 {
		return fmt.Errorf("uno: discard pile is empty")
	}
	top := g.DiscardPile[len(g.DiscardPile)-1]
	if !card.Matches(top, g.CurrentColor) {
		return fmt.Errorf("uno: card %q does not match", card.ID)
	}
	chosenColor := Color(action.Color)
	if card.isWild() && action.Color != "" && !chosenColor.validChoice() {
		return fmt.Errorf("uno: invalid chosen color %q", action.Color)
	}

	wild4Legal := true
	g.Wild4ProofCard = nil
	if card.Kind == KindWildDrawFour {
		for i, other := range g.Players[playerIndex].Hand {
			if i != cardIndex && !other.isWild() && other.Color == g.CurrentColor {
				wild4Legal = false
				proof := other
				g.Wild4ProofCard = &proof
				break
			}
		}
	}

	g.expireUnoWindow()
	player := &g.Players[playerIndex]
	player.Hand = append(player.Hand[:cardIndex], player.Hand[cardIndex+1:]...)
	player.SaidUno = false
	g.DiscardPile = append(g.DiscardPile, card)
	g.DrawnCardID = ""
	g.LastPlayedBy = player.UserID
	played := card
	g.noteEvent("play", player.UserID, 1, &played)
	g.PendingRoundWinnerIndex = -1
	if len(player.Hand) == 1 {
		g.UnoVulnerableIndex = playerIndex
	}
	if len(player.Hand) == 0 {
		g.UnoVulnerableIndex = -1
		g.PendingRoundWinnerIndex = playerIndex
	}

	switch card.Kind {
	case KindNumber:
		g.CurrentColor = card.Color
		g.CurrentIndex = g.nextActive(playerIndex)
		g.Status = StatusActive
	case KindSkip:
		g.CurrentColor = card.Color
		skipped := g.nextActive(playerIndex)
		g.CurrentIndex = g.nextActive(skipped)
		g.Status = StatusActive
	case KindReverse:
		g.CurrentColor = card.Color
		if g.activePlayerCount() == 2 {
			skipped := g.nextActive(playerIndex)
			g.CurrentIndex = g.nextActive(skipped)
		} else {
			g.Direction *= -1
			g.CurrentIndex = g.nextActive(playerIndex)
		}
		g.Status = StatusActive
	case KindDrawTwo:
		g.CurrentColor = card.Color
		target := g.nextActive(playerIndex)
		g.PendingDraw = 2
		g.drawCards(target, g.PendingDraw)
		g.PendingDraw = 0
		g.CurrentIndex = g.nextActive(target)
		g.Status = StatusActive
	case KindWild:
		if action.Color == "" {
			g.ColorChooserIndex = playerIndex
			g.Status = StatusAwaitingColor
			g.CurrentIndex = playerIndex
			return nil
		}
		g.CurrentColor = chosenColor
		g.CurrentIndex = g.nextActive(playerIndex)
		g.Status = StatusActive
	case KindWildDrawFour:
		g.Wild4PlayerIndex = playerIndex
		g.Wild4WasLegal = wild4Legal
		g.PendingDraw = 4
		if action.Color == "" {
			g.ColorChooserIndex = playerIndex
			g.Status = StatusAwaitingColor
			g.CurrentIndex = playerIndex
			return nil
		}
		g.CurrentColor = chosenColor
		g.CurrentIndex = g.nextActive(playerIndex)
		g.Status = StatusAwaitingWD4Challenge
	default:
		return fmt.Errorf("uno: unsupported card kind %q", card.Kind)
	}

	return g.finishPendingRound()
}

func (g *Game) applyDraw() error {
	if g.Status == StatusAwaitingWD4Challenge {
		g.expireUnoWindow()
		challenger := g.CurrentIndex
		actor := ""
		if challenger >= 0 && challenger < len(g.Players) {
			actor = g.Players[challenger].UserID
		}
		g.noteEvent("draw", actor, g.PendingDraw, nil)
		g.drawCards(challenger, g.PendingDraw)
		g.PendingDraw = 0
		g.Wild4PlayerIndex = -1
		g.Wild4WasLegal = false
		g.Wild4ProofCard = nil
		g.CurrentIndex = g.nextActive(challenger)
		g.Status = StatusActive
		return g.finishPendingRound()
	}
	if g.Status != StatusActive {
		return fmt.Errorf("uno: cannot draw while status is %q", g.Status)
	}
	if g.hasLegalPlay(g.CurrentIndex) {
		return fmt.Errorf("uno: current player has a legal card to play")
	}

	g.expireUnoWindow()
	actor := g.Players[g.CurrentIndex].UserID
	g.noteEvent("draw", actor, 1, nil)
	card, ok := g.drawOne()
	if !ok {
		g.CurrentIndex = g.nextActive(g.CurrentIndex)
		return nil
	}
	player := &g.Players[g.CurrentIndex]
	player.Hand = append(player.Hand, card)
	player.SaidUno = false
	g.LastDrawUserID = actor
	g.LastDrawCount = 1

	top := g.DiscardPile[len(g.DiscardPile)-1]
	if card.Matches(top, g.CurrentColor) {
		g.DrawnCardID = card.ID
		g.Status = StatusAwaitingDrawnPlay
		return nil
	}
	g.CurrentIndex = g.nextActive(g.CurrentIndex)
	return nil
}

func (g *Game) applyKeep() error {
	if g.Status != StatusAwaitingDrawnPlay {
		return fmt.Errorf("uno: keep is only allowed after drawing a playable card")
	}
	g.expireUnoWindow()
	g.DrawnCardID = ""
	g.Status = StatusActive
	g.CurrentIndex = g.nextActive(g.CurrentIndex)
	return nil
}

func (g *Game) applyCallUno() error {
	index := g.UnoVulnerableIndex
	if index < 0 || index >= len(g.Players) || len(g.Players[index].Hand) != 1 {
		return fmt.Errorf("uno: no player can call UNO")
	}
	g.Players[index].SaidUno = true
	g.UnoVulnerableIndex = -1
	return nil
}

func (g *Game) applyChallengeUno(actorUserID, targetUserID string) error {
	actor := g.playerIndex(actorUserID)
	if actor < 0 || g.Players[actor].Forfeited {
		return fmt.Errorf("uno: challenger is not a player")
	}
	target := g.playerIndex(targetUserID)
	if target < 0 || target != g.UnoVulnerableIndex {
		return fmt.Errorf("uno: player %q cannot be challenged for UNO", targetUserID)
	}
	if target == actor {
		return fmt.Errorf("uno: player cannot challenge themselves")
	}
	if g.Players[target].SaidUno || len(g.Players[target].Hand) != 1 {
		return fmt.Errorf("uno: player %q is not vulnerable to an UNO challenge", targetUserID)
	}
	g.drawCards(target, 2)
	g.UnoVulnerableIndex = -1
	return nil
}

func (g *Game) applyChallengeWD4() error {
	if g.Status != StatusAwaitingWD4Challenge {
		return fmt.Errorf("uno: no Wild Draw Four can be challenged")
	}
	g.expireUnoWindow()
	challenger := g.CurrentIndex
	offender := g.Wild4PlayerIndex
	if offender < 0 || offender >= len(g.Players) {
		return fmt.Errorf("uno: invalid Wild Draw Four player")
	}

	if g.Wild4WasLegal {
		g.noteEvent("draw", g.Players[challenger].UserID, 6, nil)
		g.drawCards(challenger, 6)
		g.CurrentIndex = g.nextActive(challenger)
	} else {
		g.noteEvent("wd4_reveal", g.Players[offender].UserID, 0, g.Wild4ProofCard)
		g.drawCards(offender, 4)
		g.CurrentIndex = challenger
		g.PendingRoundWinnerIndex = -1
	}
	g.PendingDraw = 0
	g.Wild4PlayerIndex = -1
	g.Wild4WasLegal = false
	g.Wild4ProofCard = nil
	g.Status = StatusActive
	return g.finishPendingRound()
}

func (g *Game) applyChooseColor(color Color) error {
	if g.Status != StatusAwaitingColor {
		return fmt.Errorf("uno: no color choice is pending")
	}
	if !color.validChoice() {
		return fmt.Errorf("uno: invalid chosen color %q", color)
	}
	chooser := g.ColorChooserIndex
	if chooser < 0 || chooser >= len(g.Players) {
		return fmt.Errorf("uno: invalid color chooser")
	}
	g.CurrentColor = color
	g.ColorChooserIndex = -1
	if g.Wild4PlayerIndex == chooser && g.PendingDraw == 4 {
		g.CurrentIndex = g.nextActive(chooser)
		g.Status = StatusAwaitingWD4Challenge
		return nil
	}
	g.CurrentIndex = g.nextActive(chooser)
	g.Status = StatusActive
	return g.finishPendingRound()
}

func (g *Game) applyForfeit(actorUserID string) error {
	index := g.playerIndex(actorUserID)
	if index < 0 {
		index = g.CurrentIndex
	}
	if index < 0 || index >= len(g.Players) || g.Players[index].Forfeited {
		return fmt.Errorf("uno: no active player to forfeit")
	}
	g.expireUnoWindow()
	g.noteEvent("forfeit", g.Players[index].UserID, 0, nil)
	g.Players[index].Forfeited = true
	g.Players[index].SaidUno = false
	g.Players[index].Hand = []Card{}
	g.EliminatedOrder = append(g.EliminatedOrder, g.Players[index].UserID)
	g.DrawnCardID = ""
	g.PendingDraw = 0
	g.Wild4PlayerIndex = -1
	g.Wild4WasLegal = false
	g.ColorChooserIndex = -1
	g.PendingRoundWinnerIndex = -1

	if g.activePlayerCount() == 1 {
		for i := range g.Players {
			if !g.Players[i].Forfeited {
				g.CurrentIndex = i
				g.WinnerUserIDs = []string{g.Players[i].UserID}
				break
			}
		}
		g.Status = StatusOver
		return nil
	}
	if g.CurrentIndex == index || g.Players[g.CurrentIndex].Forfeited {
		g.CurrentIndex = g.nextActive(index)
	}
	g.Status = StatusActive
	return nil
}

func (g *Game) finishPendingRound() error {
	if g.PendingRoundWinnerIndex < 0 {
		return nil
	}
	winner := g.PendingRoundWinnerIndex
	g.PendingRoundWinnerIndex = -1

	points := 0
	for i, player := range g.Players {
		if i == winner {
			continue
		}
		for _, card := range player.Hand {
			points += card.Points()
		}
	}
	g.Players[winner].Score += points
	g.UnoVulnerableIndex = -1
	g.PendingDraw = 0
	g.DrawnCardID = ""
	g.Wild4PlayerIndex = -1
	g.ColorChooserIndex = -1
	g.LastRoundWinnerUserID = g.Players[winner].UserID
	g.LastRoundPoints = points
	g.LastRoundNumber = g.RoundNumber
	g.noteEvent("round_scored", g.Players[winner].UserID, points, nil)

	if g.Players[winner].Score >= g.TargetScore {
		g.Status = StatusOver
		g.CurrentIndex = winner
		g.WinnerUserIDs = []string{g.Players[winner].UserID}
		return nil
	}

	g.Status = StatusBetweenRounds
	g.CurrentIndex = winner
	return nil
}

func (g *Game) applyNextRound() error {
	if g.Status != StatusBetweenRounds {
		return fmt.Errorf("uno: next round is not pending")
	}
	g.RoundNumber++
	g.DealerIndex = g.nextActiveClockwise(g.DealerIndex)
	return g.startRound()
}

func (g *Game) noteEvent(eventType, actor string, count int, card *Card) {
	g.EventSeq++
	g.LastEventType = eventType
	g.LastEventActor = actor
	if card != nil {
		copyCard := *card
		g.LastEventCard = &copyCard
	}
}

func (g *Game) drawCards(playerIndex, count int) {
	if playerIndex < 0 || playerIndex >= len(g.Players) {
		return
	}
	drawn := 0
	for i := 0; i < count; i++ {
		card, ok := g.drawOne()
		if !ok {
			break
		}
		g.Players[playerIndex].Hand = append(g.Players[playerIndex].Hand, card)
		drawn++
	}
	if drawn > 0 {
		g.LastDrawUserID = g.Players[playerIndex].UserID
		g.LastDrawCount = drawn
	}
	if len(g.Players[playerIndex].Hand) != 1 {
		g.Players[playerIndex].SaidUno = false
	}
}

func (g *Game) drawOne() (Card, bool) {
	if len(g.DrawPile) == 0 {
		if len(g.DiscardPile) <= 1 {
			return Card{}, false
		}
		top := g.DiscardPile[len(g.DiscardPile)-1]
		g.DrawPile = append([]Card(nil), g.DiscardPile[:len(g.DiscardPile)-1]...)
		g.DiscardPile = []Card{top}
		g.ShuffleCount++
		Shuffle(g.DrawPile, g.roundSeed()+int64(g.ShuffleCount)*7919)
	}
	last := len(g.DrawPile) - 1
	card := g.DrawPile[last]
	g.DrawPile = g.DrawPile[:last]
	return card, true
}

func (g *Game) nextActive(index int) int {
	return g.nextActiveInDirection(index, g.Direction)
}

func (g *Game) nextActiveClockwise(index int) int {
	return g.nextActiveInDirection(index, 1)
}

func (g *Game) nextActiveInDirection(index, direction int) int {
	n := len(g.Players)
	for step := 1; step <= n; step++ {
		next := (index + direction*step) % n
		if next < 0 {
			next += n
		}
		if !g.Players[next].Forfeited {
			return next
		}
	}
	return index
}

func (g *Game) activePlayerCount() int {
	count := 0
	for _, player := range g.Players {
		if !player.Forfeited {
			count++
		}
	}
	return count
}

func (g *Game) playerIndex(userID string) int {
	for i, player := range g.Players {
		if player.UserID == userID {
			return i
		}
	}
	return -1
}

func (g *Game) hasLegalPlay(playerIndex int) bool {
	if playerIndex < 0 || playerIndex >= len(g.Players) || len(g.DiscardPile) == 0 {
		return false
	}
	top := g.DiscardPile[len(g.DiscardPile)-1]
	hasCurrentColor := false
	for _, card := range g.Players[playerIndex].Hand {
		if !card.isWild() && card.Color == g.CurrentColor {
			hasCurrentColor = true
			break
		}
	}
	for _, card := range g.Players[playerIndex].Hand {
		if !card.Matches(top, g.CurrentColor) {
			continue
		}
		if card.Kind != KindWildDrawFour || !hasCurrentColor {
			return true
		}
	}
	return false
}

func (g *Game) expireUnoWindow() {
	if g.UnoVulnerableIndex >= 0 {
		g.UnoVulnerableIndex = -1
	}
}

func (g *Game) roundSeed() int64 {
	return g.Seed + int64(g.RoundNumber-1)*104729
}

// IsOver — матч завершён.
func (g *Game) IsOver() bool {
	return g.Status == StatusOver
}

// Encode сериализует состояние для Redis.
func Encode(g *Game) (string, error) {
	b, err := json.Marshal(g)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// Decode восстанавливает состояние из JSON.
func Decode(raw string) (*Game, error) {
	if raw == "" {
		return nil, fmt.Errorf("uno: empty state")
	}
	var g Game
	if err := json.Unmarshal([]byte(raw), &g); err != nil {
		return nil, err
	}
	if g.DrawPile == nil {
		g.DrawPile = []Card{}
	}
	if g.DiscardPile == nil {
		g.DiscardPile = []Card{}
	}
	if g.WinnerUserIDs == nil {
		g.WinnerUserIDs = []string{}
	}
	if g.EliminatedOrder == nil {
		g.EliminatedOrder = []string{}
	}
	if g.TargetScore <= 0 {
		g.TargetScore = DefaultTargetScore
	}
	if g.Direction == 0 {
		g.Direction = 1
	}
	return &g, nil
}
