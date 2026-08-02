package store

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/google/uuid"
)

// Токен чата: [coins_credit:<grantId>|<amountBronze>|<reason>]
// или после получения: [coins_credit:<grantId>|<amountBronze>|<reason>|claimed]
var coinsCreditTokenRe = regexp.MustCompile(
	`^\[coins_credit:([0-9a-fA-F-]{36})\|(-?\d+)\|([^|\]]*)(?:\|(claimed))?\]$`,
)

// CoinsCreditPayload — разобранная карточка начисления в чате.
type CoinsCreditPayload struct {
	GrantID       uuid.UUID
	AmountBronze  int
	Reason        string
	Claimed       bool
}

func sanitizeCoinsCreditField(s string) string {
	s = strings.ReplaceAll(s, "|", "/")
	s = strings.ReplaceAll(s, "]", "")
	s = strings.ReplaceAll(s, "\n", " ")
	s = strings.ReplaceAll(s, "\r", " ")
	return strings.TrimSpace(s)
}

// EncodeCoinsCreditMessage собирает body-токен для карточки начисления.
func EncodeCoinsCreditMessage(grantID uuid.UUID, amountBronze int, reason string) string {
	return fmt.Sprintf("[coins_credit:%s|%d|%s]",
		grantID.String(), amountBronze, sanitizeCoinsCreditField(reason))
}

// EncodeCoinsCreditMessageClaimed — тот же токен после «Забрать».
func EncodeCoinsCreditMessageClaimed(grantID uuid.UUID, amountBronze int, reason string) string {
	return fmt.Sprintf("[coins_credit:%s|%d|%s|claimed]",
		grantID.String(), amountBronze, sanitizeCoinsCreditField(reason))
}

// ParseCoinsCreditMessage разбирает body карточки начисления.
func ParseCoinsCreditMessage(body string) (CoinsCreditPayload, bool) {
	m := coinsCreditTokenRe.FindStringSubmatch(strings.TrimSpace(body))
	if m == nil {
		return CoinsCreditPayload{}, false
	}
	grantID, err := uuid.Parse(m[1])
	if err != nil {
		return CoinsCreditPayload{}, false
	}
	amount, err := strconv.Atoi(m[2])
	if err != nil {
		return CoinsCreditPayload{}, false
	}
	return CoinsCreditPayload{
		GrantID:      grantID,
		AmountBronze: amount,
		Reason:       strings.TrimSpace(m[3]),
		Claimed:      m[4] == "claimed",
	}, true
}

// IsCoinsCreditMessage — тело целиком карточка начисления.
func IsCoinsCreditMessage(body string) bool {
	_, ok := ParseCoinsCreditMessage(body)
	return ok
}
