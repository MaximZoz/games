package api

import "testing"

func TestIsWaitingLobbyStatus(t *testing.T) {
	if !isWaitingLobbyStatus(lobbyStatusWaitingInvite) {
		t.Fatal("waiting_invite")
	}
	if !isWaitingLobbyStatus(lobbyStatusWaitingMatchmake) {
		t.Fatal("waiting_matchmake")
	}
	if isWaitingLobbyStatus(lobbyStatusInGame) {
		t.Fatal("in_game is not waiting")
	}
	if isWaitingLobbyStatus("") {
		t.Fatal("empty")
	}
}

func TestClassifyGetActiveLobby(t *testing.T) {
	kind, clear := classifyGetActiveLobby(lobbyStatusWaitingInvite, "", "")
	if kind != getActiveLobbyAsLobby || clear {
		t.Fatalf("waiting invite: kind=%q clear=%v", kind, clear)
	}
	kind, clear = classifyGetActiveLobby(lobbyStatusWaitingMatchmake, "g1", gameStatusDraw)
	if kind != getActiveLobbyAsLobby || clear {
		t.Fatalf("waiting matchmake: kind=%q clear=%v", kind, clear)
	}
	kind, clear = classifyGetActiveLobby(lobbyStatusInGame, "g1", gameStatusActive)
	if kind != getActiveLobbyAsGame || clear {
		t.Fatalf("live in_game: kind=%q clear=%v", kind, clear)
	}
	kind, clear = classifyGetActiveLobby(lobbyStatusInGame, "g1", gameStatusDraw)
	if kind != getActiveLobbyNone || !clear {
		t.Fatalf("finished in_game: kind=%q clear=%v", kind, clear)
	}
	kind, clear = classifyGetActiveLobby(lobbyStatusInGame, "", gameStatusActive)
	if kind != getActiveLobbyNone || !clear {
		t.Fatalf("in_game without game: kind=%q clear=%v", kind, clear)
	}
}

func TestClassifyOtherLobbyForJoin(t *testing.T) {
	if got := classifyOtherLobbyForJoin("", "target", lobbyStatusWaitingInvite, ""); got != otherLobbyNone {
		t.Fatalf("empty other: %v", got)
	}
	if got := classifyOtherLobbyForJoin("target", "target", lobbyStatusWaitingInvite, ""); got != otherLobbyNone {
		t.Fatalf("same lobby: %v", got)
	}
	if got := classifyOtherLobbyForJoin("mine", "theirs", lobbyStatusWaitingInvite, ""); got != otherLobbyRelease {
		t.Fatalf("own rematch lobby: %v", got)
	}
	if got := classifyOtherLobbyForJoin("mine", "theirs", lobbyStatusWaitingMatchmake, ""); got != otherLobbyRelease {
		t.Fatalf("own matchmake lobby: %v", got)
	}
	if got := classifyOtherLobbyForJoin("mine", "theirs", lobbyStatusInGame, gameStatusActive); got != otherLobbyBlock {
		t.Fatalf("live leftover: %v", got)
	}
	if got := classifyOtherLobbyForJoin("mine", "theirs", lobbyStatusInGame, gameStatusDraw); got != otherLobbyClear {
		t.Fatalf("finished leftover: %v", got)
	}
	if got := classifyOtherLobbyForJoin("mine", "theirs", "", ""); got != otherLobbyClear {
		t.Fatalf("missing lobby: %v", got)
	}
}

func TestGroupChatSessionLive(t *testing.T) {
	if groupChatSessionLive(false, lobbyStatusInGame, "g1", gameStatusActive) {
		t.Fatal("missing lobby is dead")
	}
	if !groupChatSessionLive(true, lobbyStatusWaitingInvite, "", "") {
		t.Fatal("waiting lobby is live")
	}
	if !groupChatSessionLive(true, lobbyStatusInGame, "g1", gameStatusActive) {
		t.Fatal("active game is live")
	}
	if groupChatSessionLive(true, lobbyStatusInGame, "g1", gameStatusDraw) {
		t.Fatal("finished in_game lobby is orphan")
	}
	if groupChatSessionLive(true, lobbyStatusInGame, "", "") {
		t.Fatal("in_game without game is orphan")
	}
}
