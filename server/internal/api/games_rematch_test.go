package api

import "testing"

func TestRematchInviteeIDsIncludesAllHumans(t *testing.T) {
	m := map[string]string{
		"x_user_id": "11111111-1111-1111-1111-111111111111",
		"o_user_id": "22222222-2222-2222-2222-222222222222",
		"t_user_id": "33333333-3333-3333-3333-333333333333",
		"s_user_id": "",
	}
	got := rematchInviteeIDs(m, "11111111-1111-1111-1111-111111111111")
	if len(got) != 2 {
		t.Fatalf("want 2 invitees, got %v", got)
	}
	seen := map[string]bool{}
	for _, id := range got {
		seen[id] = true
	}
	if !seen["22222222-2222-2222-2222-222222222222"] ||
		!seen["33333333-3333-3333-3333-333333333333"] {
		t.Fatalf("unexpected invitees: %v", got)
	}
}

func TestRematchInviteeIDsSkipsBotsAndRequester(t *testing.T) {
	m := map[string]string{
		"x_user_id": "11111111-1111-1111-1111-111111111111",
		"o_user_id": "bot:easy",
		"t_user_id": "33333333-3333-3333-3333-333333333333",
	}
	got := rematchInviteeIDs(m, "33333333-3333-3333-3333-333333333333")
	if len(got) != 1 || got[0] != "11111111-1111-1111-1111-111111111111" {
		t.Fatalf("want only human peer, got %v", got)
	}
}
