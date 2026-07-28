package store

import (
	"testing"
)

func TestAchievementCatalog(t *testing.T) {
	cat := AchievementCatalog()
	if len(cat) != 6 {
		t.Fatalf("want 6 achievements, got %d", len(cat))
	}
	foundFrame := 0
	for _, d := range cat {
		if d.Target <= 0 {
			t.Fatalf("%s target must be > 0", d.Code)
		}
		if d.RewardItemCode != "" {
			foundFrame++
			if d.RewardBronze != 0 {
				t.Fatalf("%s frame reward should be 0 bronze, got %d", d.Code, d.RewardBronze)
			}
		} else if d.RewardBronze != AchievementRewardBronze {
			t.Fatalf("%s reward=%d want %d", d.Code, d.RewardBronze, AchievementRewardBronze)
		}
	}
	if foundFrame != 3 {
		t.Fatalf("want 3 frame achievements, got %d", foundFrame)
	}
}

func TestStakeLeague(t *testing.T) {
	cases := []struct {
		stake int
		want  string
	}{
		{0, ""},
		{1, "bronze"},
		{50, "bronze"},
		{99, "bronze"},
		{100, "silver"},
		{5000, "silver"},
		{9999, "silver"},
		{10000, "gold"},
		{50000, "gold"},
	}
	for _, c := range cases {
		if got := StakeLeague(c.stake); got != c.want {
			t.Fatalf("stake %d: got %q want %q", c.stake, got, c.want)
		}
	}
}

func TestIsProfileComplete(t *testing.T) {
	name := "player1"
	about := "hello"
	gender := "Мужской"
	age := 20
	avatar := "base64,abc"
	u := &User{
		DisplayName: &name,
		Age:         &age,
		Gender:      &gender,
		About:       &about,
		AvatarKind:  "file",
		AvatarValue: &avatar,
	}
	if !isProfileComplete(u) {
		t.Fatal("expected complete")
	}
	u.AvatarKind = "preset"
	if isProfileComplete(u) {
		t.Fatal("preset avatar should not complete")
	}
	u.AvatarKind = "file"
	empty := ""
	u.About = &empty
	if isProfileComplete(u) {
		t.Fatal("empty about should not complete")
	}
}

func TestProgressFor(t *testing.T) {
	wins := userWinStats{WinsBronze: 3, WinsSilver: 7, WinsGold: 12}
	defGames, _ := AchievementByCode(AchievementGames10)
	if got := progressFor(defGames, false, 7, 0, wins); got != 7 {
		t.Fatalf("games progress=%d want 7", got)
	}
	if got := progressFor(defGames, false, 99, 0, wins); got != 10 {
		t.Fatalf("games capped progress=%d want 10", got)
	}
	defFriends, _ := AchievementByCode(AchievementFriends5)
	if got := progressFor(defFriends, false, 0, 5, wins); got != 5 {
		t.Fatalf("friends progress=%d want 5", got)
	}
	defProfile, _ := AchievementByCode(AchievementProfileComplete)
	if got := progressFor(defProfile, true, 0, 0, wins); got != 1 {
		t.Fatalf("profile progress=%d want 1", got)
	}
	defBronze, _ := AchievementByCode(AchievementWinsBronze10)
	if got := progressFor(defBronze, false, 0, 0, wins); got != 3 {
		t.Fatalf("bronze wins progress=%d want 3", got)
	}
	defGold, _ := AchievementByCode(AchievementWinsGold10)
	if got := progressFor(defGold, false, 0, 0, wins); got != 10 {
		t.Fatalf("gold wins capped progress=%d want 10", got)
	}
}

func TestAchievementByCodeUnknown(t *testing.T) {
	if _, ok := AchievementByCode("nope"); ok {
		t.Fatal("expected unknown")
	}
}

func TestFrameRank(t *testing.T) {
	if frameRank(FrameGoldCode) <= frameRank(FrameSilverCode) {
		t.Fatal("gold should rank above silver")
	}
	if frameRank(FrameSilverCode) <= frameRank(FrameBronzeCode) {
		t.Fatal("silver should rank above bronze")
	}
}
