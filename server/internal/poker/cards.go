// Package poker реализует движок Texas Hold'em No-Limit для 2–6 игроков.
// Одна раздача = одна «игра» (MVP): блайнды, улицы, ставки, сайд-поты, вскрытие.
package poker

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"strings"
)

// Suit — масть карты. Кодируется в JSON буквой "H"/"D"/"C"/"S".
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

// MarshalJSON — масть как буква (клиент ждёт "H"/"D"/"C"/"S", не 0..3).
func (s Suit) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.String())
}

// UnmarshalJSON принимает букву или legacy-число 0..3.
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

// Rank — достоинство карты в диапазоне [2..14] (11=J,12=Q,13=K,14=A).
type Rank int

const (
	Two   Rank = 2
	Three Rank = 3
	Four  Rank = 4
	Five  Rank = 5
	Six   Rank = 6
	Seven Rank = 7
	Eight Rank = 8
	Nine  Rank = 9
	Ten   Rank = 10
	Jack  Rank = 11
	Queen Rank = 12
	King  Rank = 13
	Ace   Rank = 14
)

// String — короткое имя ранга (T/J/Q/K/A для 10..14).
func (r Rank) String() string {
	switch r {
	case Ten:
		return "T"
	case Jack:
		return "J"
	case Queen:
		return "Q"
	case King:
		return "K"
	case Ace:
		return "A"
	}
	if r >= 2 && r <= 9 {
		return fmt.Sprintf("%d", int(r))
	}
	return "?"
}

// Card — карта. Rank в диапазоне [2..14].
type Card struct {
	Rank Rank `json:"rank"`
	Suit Suit `json:"suit"`
}

func (c Card) String() string {
	return c.Rank.String() + c.Suit.String()
}

// ParseCard принимает JSON-объект {rank,suit} или строку вида "10H"/"AH".
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
		return Card{Rank: Rank(c.Rank), Suit: s}, nil
	}
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return Card{}, err
	}
	return ParseCardString(s)
}

// ParseCardString разбирает строку вида "10H", "AH", "KS".
func ParseCardString(s string) (Card, error) {
	s = strings.TrimSpace(s)
	if len(s) < 2 {
		return Card{}, fmt.Errorf("bad card %q", s)
	}
	suit, err := ParseSuit(s[len(s)-1:])
	if err != nil {
		return Card{}, err
	}
	rankPart := strings.ToUpper(s[:len(s)-1])
	var rank int
	switch rankPart {
	case "T", "10":
		rank = 10
	case "J":
		rank = 11
	case "Q":
		rank = 12
	case "K":
		rank = 13
	case "A":
		rank = 14
	default:
		if _, err := fmt.Sscanf(rankPart, "%d", &rank); err != nil {
			return Card{}, fmt.Errorf("bad rank %q", rankPart)
		}
	}
	if rank < 2 || rank > 14 {
		return Card{}, fmt.Errorf("bad rank %d", rank)
	}
	return Card{Rank: Rank(rank), Suit: suit}, nil
}

// Deck — колода из 52 карт с указателем на следующую сдаваемую карту.
type Deck struct {
	Cards []Card `json:"cards"`
	Pos   int    `json:"pos"`
}

// NewDeck возвращает НЕперемешанную полную колоду 52 карт.
func NewDeck() *Deck {
	cards := make([]Card, 0, 52)
	for _, s := range []Suit{Hearts, Diamonds, Clubs, Spades} {
		for v := 2; v <= 14; v++ {
			cards = append(cards, Card{Rank: Rank(v), Suit: s})
		}
	}
	return &Deck{Cards: cards, Pos: 0}
}

// NewShuffledDeck возвращает перемешанную колоду 52 карт.
func NewShuffledDeck(r *rand.Rand) *Deck {
	d := NewDeck()
	d.Shuffle(r)
	return d
}

// Shuffle перемешивает оставшиеся (не сданные) карты колоды.
func (d *Deck) Shuffle(r *rand.Rand) {
	rem := d.Cards[d.Pos:]
	r.Shuffle(len(rem), func(i, j int) { rem[i], rem[j] = rem[j], rem[i] })
}

// Remaining — сколько карт ещё можно сдать.
func (d *Deck) Remaining() int {
	return len(d.Cards) - d.Pos
}

// Deal сдаёт одну карту из колоды.
func (d *Deck) Deal() (Card, error) {
	if d.Pos >= len(d.Cards) {
		return Card{}, fmt.Errorf("deck exhausted")
	}
	c := d.Cards[d.Pos]
	d.Pos++
	return c, nil
}

// DealN сдаёт n карт из колоды.
func (d *Deck) DealN(n int) ([]Card, error) {
	if d.Remaining() < n {
		return nil, fmt.Errorf("deck exhausted: need %d, have %d", n, d.Remaining())
	}
	out := make([]Card, n)
	for i := 0; i < n; i++ {
		c, err := d.Deal()
		if err != nil {
			return nil, err
		}
		out[i] = c
	}
	return out, nil
}
