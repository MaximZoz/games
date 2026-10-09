package store

import "time"

// Состояние коллекции считается от acquired_at (покупка или получение подарка).
//
//	первые 7 дней              новое         80%
//	до 2 календарных месяцев   потрепанное   60%
//	до 6 календарных месяцев   уставшее      40%
//	до 1 календарного года     ветхое        100%
//	дальше                     винтаж        300%
//
// «Месяц после покупки» попадает в потрепанное: оно длится от конца первой
// недели до двух месяцев.
const (
	CollectionCondNew     = "new"
	CollectionCondWorn    = "worn"
	CollectionCondTired   = "tired"
	CollectionCondShabby  = "shabby"
	CollectionCondVintage = "vintage"
)

// CollectionCanSell — продать можно только новое или винтаж.
func CollectionCanSell(condition string) bool {
	return condition == CollectionCondNew || condition == CollectionCondVintage
}

// CollectionSellPercent — доля цены каталога, которую вернёт продажа.
func CollectionSellPercent(condition string) int {
	switch condition {
	case CollectionCondWorn:
		return 60
	case CollectionCondTired:
		return 40
	case CollectionCondShabby:
		return 100
	case CollectionCondVintage:
		return 300
	default:
		return 80
	}
}

// CollectionConditionAt возвращает состояние на момент now.
// Нулевая или будущая дата покупки считается новым: неизвестный возраст
// не должен продаваться как винтаж.
func CollectionConditionAt(acquired, now time.Time) string {
	if acquired.IsZero() {
		return CollectionCondNew
	}
	acquired = acquired.UTC()
	now = now.UTC()
	if now.Before(acquired) {
		return CollectionCondNew
	}
	if now.Before(acquired.AddDate(0, 0, 7)) {
		return CollectionCondNew
	}
	if now.Before(acquired.AddDate(0, 2, 0)) {
		return CollectionCondWorn
	}
	if now.Before(acquired.AddDate(0, 6, 0)) {
		return CollectionCondTired
	}
	if now.Before(acquired.AddDate(1, 0, 0)) {
		return CollectionCondShabby
	}
	return CollectionCondVintage
}

// CollectionRefundBronze — выкуп по цене каталога и возрасту владения.
func CollectionRefundBronze(price int, acquired, now time.Time) int {
	return CollectionRefundAged(price, acquired, now, 0, nil)
}

// CollectionRefundAged учитывает сдвиг эликсира и ускорение до винтажа.
func CollectionRefundAged(price int, acquired, now time.Time, shift int, vintageAt *time.Time) int {
	if price <= 0 {
		return 0
	}
	cond := CollectionConditionEffective(acquired, now, shift, vintageAt)
	return price * CollectionSellPercent(cond) / 100
}

// CollectionIncomePercent — доля обычного дневного дохода предмета.
// Новое и ветхое — 100%, потрепанное — 60%, уставшее — 40%, винтаж — 200%.
func CollectionIncomePercent(condition string) int {
	switch condition {
	case CollectionCondWorn:
		return 60
	case CollectionCondTired:
		return 40
	case CollectionCondVintage:
		return 200
	default:
		return 100
	}
}

// CollectionDailyIncomeBronze — дневной доход предмета с учётом состояния.
func CollectionDailyIncomeBronze(base int, acquired, now time.Time, shift int, vintageAt *time.Time) int {
	if base <= 0 {
		return 0
	}
	cond := CollectionConditionEffective(acquired, now, shift, vintageAt)
	return base * CollectionIncomePercent(cond) / 100
}

// CollectionSetBonusAged — бонус полного набора. 300%, если винтажный каждый предмет.
func CollectionSetBonusAged(base int, allVintage bool) int {
	if base <= 0 {
		return 0
	}
	if allVintage {
		return base * 300 / 100
	}
	return base
}

func conditionIndex(condition string) int {
	switch condition {
	case CollectionCondWorn:
		return 1
	case CollectionCondTired:
		return 2
	case CollectionCondShabby:
		return 3
	case CollectionCondVintage:
		return 4
	default:
		return 0
	}
}

func conditionByIndex(idx int) string {
	switch idx {
	case 1:
		return CollectionCondWorn
	case 2:
		return CollectionCondTired
	case 3:
		return CollectionCondShabby
	case 4:
		return CollectionCondVintage
	default:
		return CollectionCondNew
	}
}

// CollectionConditionEffective — состояние с учётом эликсиров.
// Положительный shift не создаёт винтаж: винтаж только по календарю
// или когда срок ускорения (vintageAt) уже наступил у ветхой коллекции.
func CollectionConditionEffective(acquired, now time.Time, shift int, vintageAt *time.Time) string {
	now = now.UTC()
	base := conditionIndex(CollectionConditionAt(acquired, now))
	idx := base + shift
	if idx < 0 {
		idx = 0
	}
	if idx > 4 {
		idx = 4
	}
	if idx >= 4 && base < 4 {
		idx = 3
	}
	if vintageAt != nil && !now.Before(vintageAt.UTC()) && idx >= 3 && base < 4 {
		return CollectionCondVintage
	}
	return conditionByIndex(idx)
}

// CollectionConditionBoundaries — моменты смены календарного состояния.
func CollectionConditionBoundaries(acquired time.Time) []time.Time {
	acquired = acquired.UTC()
	return []time.Time{
		acquired.AddDate(0, 0, 7),
		acquired.AddDate(0, 2, 0),
		acquired.AddDate(0, 6, 0),
		acquired.AddDate(1, 0, 0),
	}
}

// NextCollectionCondition — следующее состояние и момент, когда оно наступит.
// У винтажа следующего состояния нет.
func NextCollectionCondition(acquired, now time.Time, shift int, vintageAt *time.Time) (condition string, at time.Time, ok bool) {
	now = now.UTC()
	cur := CollectionConditionEffective(acquired, now, shift, vintageAt)
	if cur == CollectionCondVintage {
		return "", time.Time{}, false
	}
	candidates := CollectionConditionBoundaries(acquired)
	if vintageAt != nil {
		candidates = append(candidates, vintageAt.UTC())
	}
	var best time.Time
	var bestCond string
	for _, t := range candidates {
		if !t.After(now) {
			continue
		}
		next := CollectionConditionEffective(acquired, t, shift, vintageAt)
		if next == cur {
			continue
		}
		if best.IsZero() || t.Before(best) {
			best = t
			bestCond = next
		}
	}
	if best.IsZero() {
		return "", time.Time{}, false
	}
	return bestCond, best, true
}

const (
	ElixirRejuvenate = "rejuvenate"
	ElixirAge        = "age"
	ElixirAccelerate = "accelerate"
)

// PlanElixirApply считает новый сдвиг и срок винтажа, не трогая базу.
// Омоложение сбрасывает ускорение. Ускорение ставит винтаж через 3 месяца,
// если это раньше календарного года и коллекция сейчас ветхая.
func PlanElixirApply(effect string, acquired, now time.Time, shift int, vintageAt *time.Time) (int, *time.Time, error) {
	now = now.UTC()
	cur := CollectionConditionEffective(acquired, now, shift, vintageAt)
	switch effect {
	case ElixirRejuvenate:
		if cur == CollectionCondNew {
			return 0, nil, ErrElixirNotApplicable
		}
		// Ускоренный винтаж — один шаг назад, к ветхому: срок снимается, сдвиг остаётся.
		base := conditionIndex(CollectionConditionAt(acquired, now))
		if cur == CollectionCondVintage && vintageAt != nil && base < 4 {
			return shift, nil, nil
		}
		return shift - 1, nil, nil
	case ElixirAge:
		if cur == CollectionCondShabby || cur == CollectionCondVintage {
			return 0, nil, ErrElixirNotApplicable
		}
		return shift + 1, vintageAt, nil
	case ElixirAccelerate:
		if cur != CollectionCondShabby || vintageAt != nil {
			return 0, nil, ErrElixirNotApplicable
		}
		until := now.AddDate(0, 3, 0)
		natural := acquired.UTC().AddDate(1, 0, 0)
		if !until.Before(natural) {
			return 0, nil, ErrElixirNotApplicable
		}
		return shift, &until, nil
	default:
		return 0, nil, ErrElixirNotApplicable
	}
}
