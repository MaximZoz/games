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
