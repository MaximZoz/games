package poker

import (
	"fmt"
	"sort"
)

// HandRank — категория покерной комбинации (от старшей карты до роял-флеша).
type HandRank int

const (
	HighCard HandRank = iota
	OnePair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
	RoyalFlush
)

func (h HandRank) String() string {
	switch h {
	case HighCard:
		return "HighCard"
	case OnePair:
		return "OnePair"
	case TwoPair:
		return "TwoPair"
	case ThreeOfAKind:
		return "ThreeOfAKind"
	case Straight:
		return "Straight"
	case Flush:
		return "Flush"
	case FullHouse:
		return "FullHouse"
	case FourOfAKind:
		return "FourOfAKind"
	case StraightFlush:
		return "StraightFlush"
	case RoyalFlush:
		return "RoyalFlush"
	}
	return "Unknown"
}

// HandValue — результат оценки руки: категория + «тай-брейкеры» (ключевые ранги
// по убыванию значимости) + сами 5 карт лучшей комбинации.
type HandValue struct {
	Rank  HandRank `json:"rank"`
	Tie   []int    `json:"tie"`   // ранги для сравнения, от старшего к младшему
	Cards []Card   `json:"cards"` // лучшие 5 карт
}

// Compare сравнивает две руки: >0 если a сильнее, <0 если b сильнее, 0 — равны.
func (a HandValue) Compare(b HandValue) int {
	if a.Rank != b.Rank {
		if a.Rank > b.Rank {
			return 1
		}
		return -1
	}
	for i := 0; i < len(a.Tie) && i < len(b.Tie); i++ {
		if a.Tie[i] != b.Tie[i] {
			if a.Tie[i] > b.Tie[i] {
				return 1
			}
			return -1
		}
	}
	return 0
}

// EvaluateBest оценивает лучшую 5-карточную комбинацию из 5..7 карт.
func EvaluateBest(cards []Card) (HandValue, error) {
	if len(cards) < 5 || len(cards) > 7 {
		return HandValue{}, fmt.Errorf("need 5..7 cards, got %d", len(cards))
	}
	var best HandValue
	found := false
	// Перебираем все сочетания по 5 карт.
	n := len(cards)
	idx := []int{0, 1, 2, 3, 4}
	combo := make([]Card, 5)
	for {
		for i, ci := range idx {
			combo[i] = cards[ci]
		}
		v := eval5(combo)
		if !found || v.Compare(best) > 0 {
			best = v
			found = true
		}
		// следующее сочетание (лексикографический перебор)
		i := 4
		for i >= 0 && idx[i] == n-5+i {
			i--
		}
		if i < 0 {
			break
		}
		idx[i]++
		for j := i + 1; j < 5; j++ {
			idx[j] = idx[j-1] + 1
		}
	}
	return best, nil
}

// eval5 оценивает ровно 5 карт.
func eval5(cards []Card) HandValue {
	c := make([]Card, 5)
	copy(c, cards)
	// сортировка по убыванию ранга
	sort.Slice(c, func(i, j int) bool { return c[i].Rank > c[j].Rank })

	flush := isFlush(c)
	straightHigh, isStr := straightHighCard(c)

	// подсчёт по рангам
	counts := map[Rank]int{}
	for _, card := range c {
		counts[card.Rank]++
	}
	// группы: [count, rank] отсортированы по count desc, потом rank desc
	type group struct {
		count int
		rank  int
	}
	groups := make([]group, 0, len(counts))
	for r, cnt := range counts {
		groups = append(groups, group{count: cnt, rank: int(r)})
	}
	sort.Slice(groups, func(i, j int) bool {
		if groups[i].count != groups[j].count {
			return groups[i].count > groups[j].count
		}
		return groups[i].rank > groups[j].rank
	})

	mk := func(rank HandRank, tie []int) HandValue {
		return HandValue{Rank: rank, Tie: tie, Cards: c}
	}

	switch {
	case isStr && flush:
		if straightHigh == int(Ace) {
			return mk(RoyalFlush, []int{straightHigh})
		}
		return mk(StraightFlush, []int{straightHigh})
	case groups[0].count == 4:
		return mk(FourOfAKind, []int{groups[0].rank, groups[1].rank})
	case groups[0].count == 3 && len(groups) > 1 && groups[1].count == 2:
		return mk(FullHouse, []int{groups[0].rank, groups[1].rank})
	case flush:
		return mk(Flush, ranksDesc(c))
	case isStr:
		return mk(Straight, []int{straightHigh})
	case groups[0].count == 3:
		return mk(ThreeOfAKind, []int{groups[0].rank, groups[1].rank, groups[2].rank})
	case groups[0].count == 2 && len(groups) > 1 && groups[1].count == 2:
		return mk(TwoPair, []int{groups[0].rank, groups[1].rank, groups[2].rank})
	case groups[0].count == 2:
		return mk(OnePair, []int{groups[0].rank, groups[1].rank, groups[2].rank, groups[3].rank})
	default:
		return mk(HighCard, ranksDesc(c))
	}
}

func ranksDesc(c []Card) []int {
	out := make([]int, len(c))
	for i, card := range c {
		out[i] = int(card.Rank)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(out)))
	return out
}

func isFlush(c []Card) bool {
	for i := 1; i < len(c); i++ {
		if c[i].Suit != c[0].Suit {
			return false
		}
	}
	return true
}

// straightHighCard возвращает старшую карту стрита и признак наличия стрита.
// Учитывает «колесо» A-2-3-4-5 (старшая карта — 5).
func straightHighCard(c []Card) (int, bool) {
	uniq := map[int]bool{}
	for _, card := range c {
		uniq[int(card.Rank)] = true
	}
	if len(uniq) != 5 {
		return 0, false
	}
	ranks := make([]int, 0, 5)
	for r := range uniq {
		ranks = append(ranks, r)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(ranks)))
	// обычный стрит: 5 подряд
	if ranks[0]-ranks[4] == 4 {
		return ranks[0], true
	}
	// колесо: A,5,4,3,2
	if ranks[0] == int(Ace) && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2 {
		return 5, true
	}
	return 0, false
}
