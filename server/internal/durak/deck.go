// Package durak реализует правила игры «Дурак» (подкидной / переводной)
// для 2–4 игроков и колод 24/36/52 карт.
package durak

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"sort"
	"strings"
)

// Suit — масть карты.
type Suit int

const (
	Hearts Suit = iota
	Diamonds
	Clubs
	Spades
)

func (s Suit) String() string {
	switch s {
	case Hearts:
		return "H"
	case Diamonds:
		return "D"
	case Clubs:
		return "C"
	case Spades:
		return "S"
	}
	return "?"
}

// MarshalJSON — масть как "H"/"D"/"C"/"S" (клиент ждёт буквы, не 0..3).
func (s Suit) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.String())
}

// UnmarshalJSON принимает букву или legacy-число 0..3 (старые state в Redis).
func (s *Suit) UnmarshalJSON(b []byte) error {
	var str string
	if err := json.Unmarshal(b, &str); err == nil {
		parsed, err := ParseSuit(str)
		if err != nil {
			return err
		}
		*s = parsed
		return nil
	}
	var n int
	if err := json.Unmarshal(b, &n); err != nil {
		return fmt.Errorf("bad suit json %s", string(b))
	}
	if n < 0 || n > 3 {
		return fmt.Errorf("bad suit %d", n)
	}
	*s = Suit(n)
	return nil
}

// ParseSuit разбирает символ масти.
func ParseSuit(s string) (Suit, error) {
	switch strings.ToUpper(strings.TrimSpace(s)) {
	case "H", "0":
		return Hearts, nil
	case "D", "1":
		return Diamonds, nil
	case "C", "2":
		return Clubs, nil
	case "S", "3":
		return Spades, nil
	}
	return 0, fmt.Errorf("bad suit %q", s)
}

// Card — карта. Rank в диапазоне [2..14] (11=J,12=Q,13=K,14=A).
type Card struct {
	Rank int  `json:"rank"`
	Suit Suit `json:"suit"`
}

func (c Card) String() string {
	return fmt.Sprintf("%d%s", c.Rank, c.Suit)
}

// ParseCard принимает JSON-объект или строку вида "10H".
func ParseCard(raw json.RawMessage) (Card, error) {
	if len(raw) == 0 || string(raw) == "null" {
		return Card{}, fmt.Errorf("empty card")
	}
	if raw[0] == '{' {
		var c struct {
			Rank int    `json:"rank"`
			Suit string `json:"suit"`
		}
		if err := json.Unmarshal(raw, &c); err != nil {
			return Card{}, err
		}
		s, err := ParseSuit(c.Suit)
		if err != nil {
			return Card{}, err
		}
		if c.Rank < 2 || c.Rank > 14 {
			return Card{}, fmt.Errorf("bad rank %d", c.Rank)
		}
		return Card{Rank: c.Rank, Suit: s}, nil
	}
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return Card{}, err
	}
	if len(s) < 2 {
		return Card{}, fmt.Errorf("bad card %q", s)
	}
	suit, err := ParseSuit(s[len(s)-1:])
	if err != nil {
		return Card{}, err
	}
	var rank int
	if _, err := fmt.Sscanf(s[:len(s)-1], "%d", &rank); err != nil {
		return Card{}, err
	}
	if rank < 2 || rank > 14 {
		return Card{}, fmt.Errorf("bad rank %d", rank)
	}
	return Card{Rank: rank, Suit: suit}, nil
}

// Beats — бьёт ли [c] карту [target] при козыре [trump].
func (c Card) Beats(target Card, trump Suit) bool {
	cTrump := c.Suit == trump
	tTrump := target.Suit == trump
	if cTrump && !tTrump {
		return true
	}
	if !cTrump && tTrump {
		return false
	}
	if c.Suit != target.Suit {
		return false
	}
	return c.Rank > target.Rank
}

// NewDeck возвращает перемешанную колоду [size] карт (24/36/52).
func NewDeck(size int, r *rand.Rand) []Card {
	minValue := 6
	switch size {
	case 24:
		minValue = 9
	case 36:
		minValue = 6
	case 52:
		minValue = 2
	default:
		minValue = 6
	}
	deck := make([]Card, 0, size)
	for _, s := range []Suit{Hearts, Diamonds, Clubs, Spades} {
		for v := minValue; v <= 14; v++ {
			deck = append(deck, Card{Rank: v, Suit: s})
		}
	}
	r.Shuffle(len(deck), func(i, j int) { deck[i], deck[j] = deck[j], deck[i] })
	return deck
}

// SortHand — сортировка руки: сначала не-козыри по масти/рангу, затем козыри.
func SortHand(hand []Card, trump Suit) {
	sort.SliceStable(hand, func(i, j int) bool {
		a, b := hand[i], hand[j]
		at := 0
		if a.Suit == trump {
			at = 1
		}
		bt := 0
		if b.Suit == trump {
			bt = 1
		}
		if at != bt {
			return at < bt
		}
		if a.Suit != b.Suit {
			return a.Suit < b.Suit
		}
		return a.Rank < b.Rank
	})
}
