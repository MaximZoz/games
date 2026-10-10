package store

import (
	"os"
	"regexp"
	"strconv"
	"testing"
)

func TestElixirPricesAreTenthOfPrevious(t *testing.T) {
	up := elixirPrices(t, "../../migrations/059_elixir_prices.up.sql")
	down := elixirPrices(t, "../../migrations/059_elixir_prices.down.sql")
	want := map[string]int{
		"elixir_celebration_rejuvenate": 75,
		"elixir_celebration_age":         175,
		"elixir_celebration_accelerate":  100,
		"elixir_legends_rejuvenate":      90,
		"elixir_legends_age":             210,
		"elixir_legends_accelerate":      120,
		"elixir_nature_rejuvenate":       105,
		"elixir_nature_age":              245,
		"elixir_nature_accelerate":       140,
		"elixir_cosmic_rejuvenate":       150,
		"elixir_cosmic_age":              350,
		"elixir_cosmic_accelerate":       200,
		"elixir_adventure_rejuvenate":    1200,
		"elixir_adventure_age":           2800,
		"elixir_adventure_accelerate":    1600,
		"elixir_jewels_rejuvenate":       15000,
		"elixir_jewels_age":              35000,
		"elixir_jewels_accelerate":       20000,
	}
	if len(up) != len(want) {
		t.Fatalf("в миграции %d цен, ожидалось %d", len(up), len(want))
	}
	for code, price := range want {
		if up[code] != price {
			t.Errorf("%s: цена %d, ожидалось %d", code, up[code], price)
		}
		if down[code] != price*10 {
			t.Errorf("%s: откат %d, ожидалось %d", code, down[code], price*10)
		}
	}
}

var elixirPriceRE = regexp.MustCompile(`price_bronze = (\d+) WHERE code = '([^']+)'`)

func elixirPrices(t *testing.T, path string) map[string]int {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("прочитать %s: %v", path, err)
	}
	out := map[string]int{}
	for _, m := range elixirPriceRE.FindAllStringSubmatch(string(raw), -1) {
		price, err := strconv.Atoi(m[1])
		if err != nil {
			t.Fatalf("цена %s: %v", m[2], err)
		}
		out[m[2]] = price
	}
	return out
}
