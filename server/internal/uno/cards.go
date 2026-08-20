package uno

import (
	"fmt"
	"math/rand"
)

// Color is one of the four playable UNO colors. Wild cards have ColorWild.
type Color string

const (
	ColorRed    Color = "red"
	ColorYellow Color = "yellow"
	ColorGreen  Color = "green"
	ColorBlue   Color = "blue"
	ColorWild   Color = "wild"

	// Short aliases keep card construction concise for engine consumers.
	Red       = ColorRed
	Yellow    = ColorYellow
	Green     = ColorGreen
	Blue      = ColorBlue
	WildColor = ColorWild
)

// Kind describes the face of a card. Number cards use KindNumber and Number.
type Kind string

const (
	KindNumber       Kind = "number"
	KindSkip         Kind = "skip"
	KindReverse      Kind = "reverse"
	KindDrawTwo      Kind = "draw_two"
	KindWild         Kind = "wild"
	KindWildDrawFour Kind = "wild_draw_four"

	// Short aliases mirror the names printed on the cards.
	Number       = KindNumber
	Skip         = KindSkip
	Reverse      = KindReverse
	DrawTwo      = KindDrawTwo
	Wild         = KindWild
	WildDrawFour = KindWildDrawFour
)

// Card is a single, uniquely identifiable UNO card.
type Card struct {
	ID     string `json:"id"`
	Color  Color  `json:"color"`
	Kind   Kind   `json:"kind"`
	Number int    `json:"number"`
}

// NewDeck builds and deterministically shuffles a standard 108-card UNO deck.
func NewDeck(seed int64) []Card {
	colors := []Color{ColorRed, ColorYellow, ColorGreen, ColorBlue}
	deck := make([]Card, 0, 108)

	for _, color := range colors {
		deck = append(deck, Card{
			ID:     fmt.Sprintf("%s-0", color),
			Color:  color,
			Kind:   KindNumber,
			Number: 0,
		})
		for number := 1; number <= 9; number++ {
			for copyNumber := 1; copyNumber <= 2; copyNumber++ {
				deck = append(deck, Card{
					ID:     fmt.Sprintf("%s-%d-%d", color, number, copyNumber),
					Color:  color,
					Kind:   KindNumber,
					Number: number,
				})
			}
		}
		for _, kind := range []Kind{KindSkip, KindReverse, KindDrawTwo} {
			for copyNumber := 1; copyNumber <= 2; copyNumber++ {
				deck = append(deck, Card{
					ID:    fmt.Sprintf("%s-%s-%d", color, kind, copyNumber),
					Color: color,
					Kind:  kind,
				})
			}
		}
	}

	for copyNumber := 1; copyNumber <= 4; copyNumber++ {
		deck = append(deck,
			Card{
				ID:    fmt.Sprintf("wild-%d", copyNumber),
				Color: ColorWild,
				Kind:  KindWild,
			},
			Card{
				ID:    fmt.Sprintf("wild-draw-four-%d", copyNumber),
				Color: ColorWild,
				Kind:  KindWildDrawFour,
			},
		)
	}

	Shuffle(deck, seed)
	return deck
}

// Shuffle randomizes cards in place using seed.
func Shuffle(cards []Card, seed int64) {
	rng := rand.New(rand.NewSource(seed))
	rng.Shuffle(len(cards), func(i, j int) {
		cards[i], cards[j] = cards[j], cards[i]
	})
}

// Points returns the card's value when an opponent wins a round.
func (c Card) Points() int {
	switch c.Kind {
	case KindNumber:
		return c.Number
	case KindSkip, KindReverse, KindDrawTwo:
		return 20
	case KindWild, KindWildDrawFour:
		return 50
	default:
		return 0
	}
}

// Matches reports whether c can be played on top with the selected color.
// Wild Draw Four's color restriction is checked by the engine because it
// depends on the rest of the player's hand.
func (c Card) Matches(top Card, currentColor Color) bool {
	if c.Kind == KindWild || c.Kind == KindWildDrawFour {
		return true
	}
	if c.Color == currentColor {
		return true
	}
	if c.Kind == KindNumber && top.Kind == KindNumber {
		return c.Number == top.Number
	}
	return c.Kind == top.Kind &&
		c.Kind != KindWild &&
		c.Kind != KindWildDrawFour
}

func (c Color) validChoice() bool {
	switch c {
	case ColorRed, ColorYellow, ColorGreen, ColorBlue:
		return true
	default:
		return false
	}
}

func (c Card) isWild() bool {
	return c.Kind == KindWild || c.Kind == KindWildDrawFour
}
