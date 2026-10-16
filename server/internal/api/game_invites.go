package api

import (
	"context"
	"strings"
)

func userInvitesRedisKey(userID string) string {
	return "user:" + userID + ":invites"
}

func lobbyDeclinedRedisKey(lobbyID string) string {
	return "lobby:" + lobbyID + ":declined"
}

// pendingInviteVisible — карточка ещё ждёт ответа.
// Отказ прячет её, даже если приглашение ещё числится в :invited.
func pendingInviteVisible(invited bool, inviteTarget, userID string, declined bool) bool {
	if declined || strings.TrimSpace(userID) == "" {
		return false
	}
	return invited || strings.TrimSpace(inviteTarget) == userID
}

func lobbyIDFromInvitedKey(invitedKey string) string {
	lobbyID := strings.TrimSuffix(strings.TrimPrefix(invitedKey, "lobby:"), ":invited")
	if lobbyID == "" || lobbyID == invitedKey {
		return ""
	}
	return lobbyID
}

func mergePendingInviteLobbyIDs(indexed []string, scannedInvitedKeys []string) []string {
	seen := make(map[string]struct{}, len(indexed)+len(scannedInvitedKeys))
	out := make([]string, 0, len(indexed)+len(scannedInvitedKeys))
	add := func(id string) {
		id = strings.TrimSpace(id)
		if id == "" {
			return
		}
		if _, ok := seen[id]; ok {
			return
		}
		seen[id] = struct{}{}
		out = append(out, id)
	}
	for _, id := range indexed {
		add(id)
	}
	for _, key := range scannedInvitedKeys {
		add(lobbyIDFromInvitedKey(key))
	}
	return out
}

func (h *GamesHandler) trackUserInvite(ctx context.Context, userID, lobbyID string) {
	if h == nil || h.Rdb == nil || userID == "" || lobbyID == "" {
		return
	}
	key := userInvitesRedisKey(userID)
	h.Rdb.SAdd(ctx, key, lobbyID)
	h.Rdb.Expire(ctx, key, lobbyTTL)
}

func (h *GamesHandler) trackUserInvites(ctx context.Context, lobbyID string, userIDs []string) {
	for _, uid := range userIDs {
		h.trackUserInvite(ctx, uid, lobbyID)
	}
}

func (h *GamesHandler) untrackUserInvite(ctx context.Context, userID, lobbyID string) {
	if h == nil || h.Rdb == nil || userID == "" || lobbyID == "" {
		return
	}
	h.Rdb.SRem(ctx, userInvitesRedisKey(userID), lobbyID)
}
