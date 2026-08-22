package i18n

import "strings"

// Canonical maps raw engine / API error strings to a user-facing English key.
// That key is shown as-is for "en" and looked up in the translation catalogs
// for every other locale.
func Canonical(key string) string {
	key = strings.TrimSpace(key)
	if key == "" {
		return key
	}
	if en, ok := legacyRUToEN[key]; ok {
		key = en
	}
	if mapped, ok := rawErrorToKey[key]; ok {
		return mapped
	}
	for _, p := range rawErrorPrefixes {
		if strings.HasPrefix(key, p.prefix) {
			return p.key
		}
	}
	return key
}

type rawPrefix struct {
	prefix string
	key    string
}

var rawErrorToKey = map[string]string{
	// UNO
	"uno: only the same +2 or +4 can stack":                   ErrUnoStackSameOnly,
	"uno: discard pile is empty":                              ErrUnoCardMismatch,
	"uno: no active current player":                           ErrNotYourTurn,
	"uno: only the drawn card may be played":                  ErrUnoOnlyDrawnCard,
	"uno: current player has a legal card to play":            ErrUnoHaveLegalCard,
	"uno: keep is only allowed after drawing a playable card": ErrUnoCannotKeep,
	"uno: no player can call UNO":                             ErrUnoCallOnlyOneCard,
	"uno: challenger is not a player":                         ErrUnoCannotCatchUno,
	"uno: player cannot challenge themselves":                 ErrUnoCannotCatchSelf,
	"uno: no Wild Draw Four can be challenged":                ErrUnoNoPlus4Challenge,
	"uno: invalid Wild Draw Four player":                      ErrUnoNoPlus4Challenge,
	"uno: no color choice is pending":                         ErrUnoNoColorChoice,
	"uno: invalid color chooser":                              ErrUnoNoColorChoice,
	"uno: match is over":                                      ErrGameAlreadyEnded,
	"uno: wait for the next round":                            ErrWaitNextRound,
	"uno: next round is not pending":                          ErrNextRoundNotReady,
	"uno: no active player to forfeit":                        ErrCannotLeaveNow,
	"uno: nil game":                                           ErrSomethingWentWrong,
	"uno: empty state":                                        ErrSomethingWentWrong,
	"uno: deck exhausted during deal":                         ErrSomethingWentWrong,
	"uno: no colored opening card":                            ErrSomethingWentWrong,

	// Durak (engine sentinels) — keep existing catalog keys when they already exist.
	"game over":           "game is over",
	"card not in hand":    ErrCardNotInHand,
	"bad attack":          ErrDurakBadAttack,
	"bad defend":          ErrDurakBadDefend,
	"cannot take":         ErrDurakCannotTake,
	"cannot bito":         ErrDurakCannotBito,
	"cannot transfer":     ErrDurakCannotTransfer,
	"cannot confirm take": ErrDurakCannotConfirmTake,
	"cannot pass":         ErrDurakCannotPass,
	"bad card":            ErrBadCard,
	"empty cards":         ErrBadCard,
	"empty card":          ErrBadCard,

	// Battleship
	"invalid ships": ErrBattleshipInvalidShips,
	"invalid cell":  ErrBattleshipInvalidCell,

	// Shared
	"game is over": ErrGameAlreadyEnded,
}

var rawErrorPrefixes = []rawPrefix{
	{prefix: "uno: only the same +2 or +4", key: ErrUnoStackSameOnly},
	{prefix: "uno: card ", key: ErrUnoCardMismatch},
	{prefix: "uno: cannot play while status", key: ErrUnoCannotPlayNow},
	{prefix: "uno: cannot draw while status", key: ErrUnoCannotDrawNow},
	{prefix: "uno: invalid chosen color", key: ErrUnoInvalidColor},
	{prefix: "uno: player ", key: ErrUnoCannotCatchUno},
	{prefix: "uno: unknown action", key: ErrActionUnavailable},
	{prefix: "uno: unsupported card kind", key: ErrUnoCannotPlayNow},
	{prefix: "uno: need ", key: ErrSomethingWentWrong},
	{prefix: "uno: player ID", key: ErrSomethingWentWrong},
	{prefix: "uno: duplicate player", key: ErrSomethingWentWrong},
	{prefix: "poker: game is over", key: "game is over"},
	{prefix: "poker: not your turn", key: "not your turn"},
	{prefix: "poker: player cannot act", key: ErrCannotActNow},
	{prefix: "poker: cannot check", key: ErrPokerCannotCheck},
	{prefix: "poker: nothing to call", key: ErrPokerNothingToCall},
	{prefix: "poker: raise must exceed", key: ErrPokerRaiseTooSmall},
	{prefix: "poker: not enough chips", key: ErrPokerNotEnoughChips},
	{prefix: "poker: raise to ", key: ErrPokerRaiseBelowMin},
	{prefix: "poker: no chips to go all-in", key: ErrPokerNoAllIn},
	{prefix: "poker: unknown action", key: ErrActionUnavailable},
	{prefix: "poker: cannot show cards now", key: ErrPokerCannotShow},
	{prefix: "poker: cards already shown", key: ErrPokerAlreadyShown},
	{prefix: "poker: folded player cannot show", key: ErrPokerFoldedCannotShow},
	{prefix: "poker: only winner can show", key: ErrPokerOnlyWinnerShow},
	{prefix: "poker: bad player index", key: "not your turn"},
	{prefix: "poker: cannot start next hand", key: ErrWaitNextRound},
	{prefix: "poker: need at least 2", key: ErrSomethingWentWrong},
	{prefix: "invalid ships", key: ErrBattleshipInvalidShips},
	{prefix: "invalid cell", key: ErrBattleshipInvalidCell},
}

// User-facing English keys. For "en", T returns these strings unchanged.
const (
	ErrUnoStackSameOnly       = "You can only play +2 on +2, or +4 on +4. A +2 cannot be stacked on +4."
	ErrUnoCardMismatch        = "This card does not match the discard pile or the current color."
	ErrUnoCannotPlayNow       = "You cannot play a card right now."
	ErrUnoOnlyDrawnCard       = "You can only play the card you just drew."
	ErrUnoHaveLegalCard       = "You still have a card you can play. Take from the deck only if you have no legal card."
	ErrUnoCannotKeep          = "You can keep a card only after drawing a playable one."
	ErrUnoCallOnlyOneCard     = "You can say Uno only when you have one card left."
	ErrUnoCannotCatchUno      = "This player cannot be caught for forgetting Uno."
	ErrUnoCannotCatchSelf     = "You cannot catch yourself for forgetting Uno."
	ErrUnoCatchTooEarly       = "Wait a second — they can still say Uno."
	ErrUnoNoPlus4Challenge    = "There is no +4 to challenge right now."
	ErrUnoNoColorChoice       = "There is no color to choose right now."
	ErrUnoCannotDrawNow       = "You cannot take a card right now."
	ErrUnoInvalidColor        = "Choose a color: red, yellow, green or blue."
	ErrNotYourTurn            = "It is not your turn."
	ErrCardNotInHand          = "This card is not in your hand."
	ErrGameAlreadyEnded       = "This game has already ended."
	ErrWaitNextRound          = "Wait for the next round to start."
	ErrNextRoundNotReady      = "The next round is not ready yet."
	ErrActionUnavailable      = "This action is not available now."
	ErrCannotLeaveNow         = "You cannot leave this game now."
	ErrCannotActNow           = "You cannot act right now."
	ErrSomethingWentWrong     = "Something went wrong. Try again."
	ErrBadCard                = "This card cannot be used now."
	ErrDurakBadAttack         = "You cannot attack with this card."
	ErrDurakBadDefend         = "You cannot defend with this card."
	ErrDurakCannotTake        = "You cannot take the cards now."
	ErrDurakCannotBito        = "You cannot say “bito” now."
	ErrDurakCannotTransfer    = "You cannot transfer this attack."
	ErrDurakCannotConfirmTake = "You cannot finish the take yet."
	ErrDurakCannotPass        = "You cannot pass now."
	ErrPokerCannotCheck       = "You cannot check — you need to call first."
	ErrPokerNothingToCall     = "Nothing to call. Check instead."
	ErrPokerRaiseTooSmall     = "The raise must be higher than the current bet."
	ErrPokerNotEnoughChips    = "Not enough chips to raise."
	ErrPokerRaiseBelowMin     = "This raise is below the minimum."
	ErrPokerNoAllIn           = "You have no chips left for all-in."
	ErrPokerCannotShow        = "You cannot show cards now."
	ErrPokerAlreadyShown      = "The cards are already shown."
	ErrPokerFoldedCannotShow  = "A folded player cannot show cards."
	ErrPokerOnlyWinnerShow    = "Only the winner can show cards."
	ErrBattleshipInvalidShips = "This ship placement is not allowed."
	ErrBattleshipInvalidCell  = "You cannot shoot this cell."
)
