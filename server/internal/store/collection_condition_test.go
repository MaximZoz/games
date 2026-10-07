package store

import (
	"testing"
	"time"
)

func TestCollectionConditionAt(t *testing.T) {
	acquired := time.Date(2024, 1, 15, 12, 0, 0, 0, time.UTC)
	cases := []struct {
		name string
		at   time.Time
		want string
	}{
		{"сразу", acquired, CollectionCondNew},
		{"6 дней", acquired.AddDate(0, 0, 6), CollectionCondNew},
		{"ровно неделя", acquired.AddDate(0, 0, 7), CollectionCondWorn},
		{"месяц", acquired.AddDate(0, 1, 0), CollectionCondWorn},
		{"без одного дня до 2 месяцев", acquired.AddDate(0, 2, 0).Add(-time.Second), CollectionCondWorn},
		{"2 месяца", acquired.AddDate(0, 2, 0), CollectionCondTired},
		{"5 месяцев", acquired.AddDate(0, 5, 0), CollectionCondTired},
		{"6 месяцев", acquired.AddDate(0, 6, 0), CollectionCondShabby},
		{"11 месяцев", acquired.AddDate(0, 11, 0), CollectionCondShabby},
		{"год", acquired.AddDate(1, 0, 0), CollectionCondVintage},
		{"два года", acquired.AddDate(2, 0, 0), CollectionCondVintage},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := CollectionConditionAt(acquired, tc.at); got != tc.want {
				t.Fatalf("got %s want %s", got, tc.want)
			}
		})
	}
	if got := CollectionConditionAt(time.Time{}, acquired); got != CollectionCondNew {
		t.Fatalf("zero acquired: got %s", got)
	}
}

func TestCollectionRefundBronze(t *testing.T) {
	acquired := time.Date(2024, 3, 1, 0, 0, 0, 0, time.UTC)
	if got := CollectionRefundBronze(1000, acquired, acquired.AddDate(0, 0, 1)); got != 800 {
		t.Fatalf("new: got %d", got)
	}
	if got := CollectionRefundBronze(1000, acquired, acquired.AddDate(0, 0, 20)); got != 600 {
		t.Fatalf("worn: got %d", got)
	}
	if got := CollectionRefundBronze(1000, acquired, acquired.AddDate(0, 3, 0)); got != 400 {
		t.Fatalf("tired: got %d", got)
	}
	if got := CollectionRefundBronze(1000, acquired, acquired.AddDate(0, 8, 0)); got != 1000 {
		t.Fatalf("shabby: got %d", got)
	}
	if got := CollectionRefundBronze(1000, acquired, acquired.AddDate(1, 1, 0)); got != 3000 {
		t.Fatalf("vintage: got %d", got)
	}
	if got := CollectionRefundBronze(0, acquired, acquired); got != 0 {
		t.Fatalf("zero price: got %d", got)
	}
}

func TestCollectionConditionEffective(t *testing.T) {
	acquired := time.Date(2024, 1, 15, 12, 0, 0, 0, time.UTC)
	now := acquired.AddDate(0, 0, 1) // новое
	if got := CollectionConditionEffective(acquired, now, 1, nil); got != CollectionCondWorn {
		t.Fatalf("старение нового: got %s", got)
	}
	if got := CollectionConditionEffective(acquired, now, -1, nil); got != CollectionCondNew {
		t.Fatalf("омоложение не моложе нового: got %s", got)
	}
	tired := acquired.AddDate(0, 3, 0)
	if got := CollectionConditionEffective(acquired, tired, 1, nil); got != CollectionCondShabby {
		t.Fatalf("старение уставшего: got %s", got)
	}
	shabby := acquired.AddDate(0, 8, 0)
	if got := CollectionConditionEffective(acquired, shabby, 1, nil); got != CollectionCondShabby {
		t.Fatalf("старение не даёт винтаж: got %s", got)
	}
	vintage := acquired.AddDate(1, 1, 0)
	if got := CollectionConditionEffective(acquired, vintage, -1, nil); got != CollectionCondShabby {
		t.Fatalf("омоложение винтажа: got %s", got)
	}
	boost := shabby.AddDate(0, 3, 0)
	if got := CollectionConditionEffective(acquired, shabby, 0, &boost); got != CollectionCondShabby {
		t.Fatalf("ускорение ещё не наступило: got %s", got)
	}
	if got := CollectionConditionEffective(acquired, boost, 0, &boost); got != CollectionCondVintage {
		t.Fatalf("ускорение наступило: got %s", got)
	}
	agedPrice := CollectionRefundAged(1000, acquired, tired, 1, nil)
	if agedPrice != 1000 {
		t.Fatalf("продажа уставшего после старения: got %d", agedPrice)
	}
}

func TestPlanElixirApply(t *testing.T) {
	acquired := time.Date(2024, 1, 15, 12, 0, 0, 0, time.UTC)
	now := acquired.AddDate(0, 0, 2)
	if _, _, err := PlanElixirApply(ElixirRejuvenate, acquired, now, 0, nil); err != ErrElixirNotApplicable {
		t.Fatalf("омоложение нового: %v", err)
	}
	shift, vintage, err := PlanElixirApply(ElixirAge, acquired, now, 0, nil)
	if err != nil || shift != 1 || vintage != nil {
		t.Fatalf("старение нового: shift %d vintage %v err %v", shift, vintage, err)
	}
	shabby := acquired.AddDate(0, 8, 0)
	if _, _, err := PlanElixirApply(ElixirAge, acquired, shabby, 0, nil); err != ErrElixirNotApplicable {
		t.Fatalf("старение ветхого: %v", err)
	}
	shift, vintage, err = PlanElixirApply(ElixirAccelerate, acquired, shabby, 0, nil)
	if err != nil || shift != 0 || vintage == nil {
		t.Fatalf("ускорение: shift %d vintage %v err %v", shift, vintage, err)
	}
	if !vintage.Equal(shabby.AddDate(0, 3, 0)) {
		t.Fatalf("срок ускорения: %s", vintage)
	}
	if _, _, err := PlanElixirApply(ElixirAccelerate, acquired, shabby, 0, vintage); err != ErrElixirNotApplicable {
		t.Fatalf("повтор ускорения: %v", err)
	}
	late := acquired.AddDate(0, 11, 0)
	if _, _, err := PlanElixirApply(ElixirAccelerate, acquired, late, 0, nil); err != ErrElixirNotApplicable {
		t.Fatalf("ускорение не короче года: %v", err)
	}
	boost := shabby.AddDate(0, 3, 0)
	shift, vintage, err = PlanElixirApply(ElixirRejuvenate, acquired, boost, 0, &boost)
	if err != nil || shift != 0 || vintage != nil {
		t.Fatalf("омоложение ускоренного винтажа: shift %d vintage %v err %v", shift, vintage, err)
	}
	if got := CollectionConditionEffective(acquired, boost, shift, vintage); got != CollectionCondShabby {
		t.Fatalf("после омоложения ускоренного винтажа: %s", got)
	}
}

func TestNextCollectionCondition(t *testing.T) {
	acquired := time.Date(2024, 1, 15, 12, 0, 0, 0, time.UTC)
	now := acquired.AddDate(0, 0, 1)
	cond, at, ok := NextCollectionCondition(acquired, now, 0, nil)
	if !ok || cond != CollectionCondWorn || !at.Equal(acquired.AddDate(0, 0, 7)) {
		t.Fatalf("новое: %s %s %v", cond, at, ok)
	}
	cond, at, ok = NextCollectionCondition(acquired, now, 1, nil)
	if !ok || cond != CollectionCondTired || !at.Equal(acquired.AddDate(0, 0, 7)) {
		t.Fatalf("состаренное новое: %s %s %v", cond, at, ok)
	}
	shabby := acquired.AddDate(0, 8, 0)
	cond, _, ok = NextCollectionCondition(acquired, shabby, 0, nil)
	if !ok || cond != CollectionCondVintage {
		t.Fatalf("ветхое: %s %v", cond, ok)
	}
	boost := shabby.AddDate(0, 3, 0)
	cond, at, ok = NextCollectionCondition(acquired, shabby, 0, &boost)
	if !ok || cond != CollectionCondVintage || !at.Equal(boost) {
		t.Fatalf("ускоренное ветхое: %s %s %v", cond, at, ok)
	}
	if _, _, ok = NextCollectionCondition(acquired, acquired.AddDate(2, 0, 0), 0, nil); ok {
		t.Fatalf("у винтажа не должно быть таймера")
	}
}
