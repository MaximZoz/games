package store

import "testing"

func TestEncodeGiftCollectionMessage(t *testing.T) {
	got := EncodeGiftCollectionMessage("c1", "Title", "🎁", "sparkles")
	want := "[gift_coll:c1|Title|🎁|sparkles]"
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
}

func TestEncodeGiftCollectionMessageSanitizes(t *testing.T) {
	got := EncodeGiftCollectionMessage("a|b", "Hi|there]", "x|y]", "name|z]")
	if got != "[gift_coll:a/b|Hi/there|x/y|name/z]" {
		t.Fatalf("got %q", got)
	}
}

func TestEncodeGiftCollectionMessageTrims(t *testing.T) {
	got := EncodeGiftCollectionMessage("  code  ", "  t  ", " e ", " n ")
	if got != "[gift_coll:code|t|e|n]" {
		t.Fatalf("got %q", got)
	}
}

func TestCalcCollectionWeeklyIncomeEmpty(t *testing.T) {
	items, bonus, owned, sets := calcCollectionWeeklyIncome(nil, nil)
	if items != 0 || bonus != 0 || owned != 0 || sets != 0 {
		t.Fatalf("%d %d %d %d", items, bonus, owned, sets)
	}
}

func TestCollectionSetBonusBronze(t *testing.T) {
	if CollectionSetBonusBronze("celebration") != 50 ||
		CollectionSetBonusBronze("nature") != 50 ||
		CollectionSetBonusBronze("cosmic") != 100 ||
		CollectionSetBonusBronze("adventure") != 200 ||
		CollectionSetBonusBronze("legends") != 500 ||
		CollectionSetBonusBronze("jewels") != 5000 ||
		CollectionSetBonusBronze("other") != 0 {
		t.Fatal("set bonuses")
	}
}

func TestCalcCollectionWeeklyIncomePartialAndCompleteSet(t *testing.T) {
	catalog := []collectionCatalogRow{
		{Code: "a1", Set: "legends", WeeklyBronze: 10},
		{Code: "a2", Set: "legends", WeeklyBronze: 20},
		{Code: "b1", Set: "nature", WeeklyBronze: 5},
	}
	owned := map[string]struct{}{"a1": {}, "b1": {}}
	items, bonus, ownedCount, sets := calcCollectionWeeklyIncome(catalog, owned)
	if items != 15 {
		t.Fatalf("items=%d want 15", items)
	}
	// nature из одного предмета — сет полный, бонус 50 бронзы/день.
	if sets != 1 || bonus != 50 {
		t.Fatalf("nature set complete: bonus=%d sets=%d", bonus, sets)
	}
	if ownedCount != 2 {
		t.Fatalf("owned=%d", ownedCount)
	}

	owned["a2"] = struct{}{}
	items, bonus, ownedCount, sets = calcCollectionWeeklyIncome(catalog, owned)
	if items != 35 {
		t.Fatalf("items=%d want 35", items)
	}
	if sets != 2 {
		t.Fatalf("sets=%d want 2", sets)
	}
	if bonus != 550 { // legends 500 + nature 50
		t.Fatalf("bonus=%d want 550", bonus)
	}
	if ownedCount != 3 {
		t.Fatalf("owned=%d", ownedCount)
	}
}

func TestCalcCollectionWeeklyIncomeAllSetsComplete(t *testing.T) {
	catalog := []collectionCatalogRow{
		{Code: "a1", Set: "celebration", WeeklyBronze: 1},
		{Code: "b1", Set: "cosmic", WeeklyBronze: 2},
	}
	owned := map[string]struct{}{"a1": {}, "b1": {}}
	items, bonus, _, sets := calcCollectionWeeklyIncome(catalog, owned)
	if items != 3 || bonus != 150 || sets != 2 {
		t.Fatalf("items=%d bonus=%d sets=%d", items, bonus, sets)
	}
}

func TestFrameRankEdges(t *testing.T) {
	if frameRank("") != 0 || frameRank("frame_neon") != 0 {
		t.Fatal("unknown should be 0")
	}
	if frameRank(FrameBronzeCode) != 1 || frameRank(FrameSilverCode) != 2 || frameRank(FrameGoldCode) != 3 {
		t.Fatal("rank order")
	}
}

func TestAchievementMet(t *testing.T) {
	wins := userWinStats{WinsBronze: 10, WinsSilver: 9, WinsGold: 10}
	def, _ := AchievementByCode(AchievementWinsBronze10)
	if !achievementMet(def, false, 0, 0, wins) {
		t.Fatal("bronze wins met")
	}
	defS, _ := AchievementByCode(AchievementWinsSilver10)
	if achievementMet(defS, false, 0, 0, wins) {
		t.Fatal("silver wins not met at 9")
	}
	defG, _ := AchievementByCode(AchievementWinsGold10)
	if !achievementMet(defG, false, 0, 0, wins) {
		t.Fatal("gold wins met")
	}
	defP, _ := AchievementByCode(AchievementProfileComplete)
	if !achievementMet(defP, true, 0, 0, wins) {
		t.Fatal("profile")
	}
	defGames, _ := AchievementByCode(AchievementGames10)
	if !achievementMet(defGames, false, 10, 0, wins) {
		t.Fatal("games 10")
	}
	defFriends, _ := AchievementByCode(AchievementFriends5)
	if achievementMet(defFriends, false, 0, 4, wins) {
		t.Fatal("friends not met")
	}
}
