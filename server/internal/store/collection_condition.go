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
	if price <= 0 {
		return 0
	}
	return price * CollectionSellPercent(CollectionConditionAt(acquired, now)) / 100
}
