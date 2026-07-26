package store

import (
	"testing"
)

func TestAchievementCatalog(t *testing.T) {
	cat := AchievementCatalog()
	if len(cat) != 3 {
		t.Fatalf("want 3 achievements, got %d", len(cat))
	}
	for _, d := range cat {
		if d.RewardBronze != AchievementRewardBronze {
			t.Fatalf("%s reward=%d want %d", d.Code, d.RewardBronze, AchievementRewardBronze)
		}
		if d.Target <= 0 {
			t.Fatalf("%s target must be > 0", d.Code)
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
	defGames, _ := AchievementByCode(AchievementGames10)
	if got := progressFor(defGames, false, 7, 0); got != 7 {
		t.Fatalf("games progress=%d want 7", got)
	}
	if got := progressFor(defGames, false, 99, 0); got != 10 {
		t.Fatalf("games capped progress=%d want 10", got)
	}
	defFriends, _ := AchievementByCode(AchievementFriends5)
	if got := progressFor(defFriends, false, 0, 5); got != 5 {
		t.Fatalf("friends progress=%d want 5", got)
	}
	defProfile, _ := AchievementByCode(AchievementProfileComplete)
	if got := progressFor(defProfile, true, 0, 0); got != 1 {
		t.Fatalf("profile progress=%d want 1", got)
	}
}

func TestAchievementByCodeUnknown(t *testing.T) {
	if _, ok := AchievementByCode("nope"); ok {
		t.Fatal("expected unknown")
	}
}
