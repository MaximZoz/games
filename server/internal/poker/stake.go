package poker

// PlaceCredit — кредит с банка stake×N за итоговое место (1 = победитель).
//
//	2 игрока: 1-й — весь банк, 2-й — 0
//	3: 1-й 2/3, 2-й возврат ставки («ничего»), 3-й — 0
//	4: 1-й 3/4, 2-й возврат, 3–4 — 0
//	5: 1-й 3/5, 2–3 возврат, 4–5 — 0
//	6: 1-й 4/6, 2–3 возврат, 4–6 — 0
func PlaceCredit(stake, playerCount, place int) int {
	if stake <= 0 || playerCount < 2 || place < 1 || place > playerCount {
		return 0
	}
	pot := stake * playerCount
	switch playerCount {
	case 2:
		if place == 1 {
			return pot
		}
		return 0
	case 3:
		switch place {
		case 1:
			return pot * 2 / 3
		case 2:
			return stake
		default:
			return 0
		}
	case 4:
		switch place {
		case 1:
			return pot * 3 / 4
		case 2:
			return stake
		default:
			return 0
		}
	case 5:
		switch place {
		case 1:
			return pot * 3 / 5
		case 2, 3:
			return stake
		default:
			return 0
		}
	case 6:
		switch place {
		case 1:
			return pot * 4 / 6
		case 2, 3:
			return stake
		default:
			return 0
		}
	default:
		if place == 1 {
			return pot
		}
		return 0
	}
}

// PlaceNetProfit — чистый плюс относительно доматчевого баланса (credit − stake).
func PlaceNetProfit(stake, playerCount, place int) int {
	credit := PlaceCredit(stake, playerCount, place)
	if credit <= stake {
		return 0
	}
	return credit - stake
}
