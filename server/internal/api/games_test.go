package api

import (
	"context"
	"errors"
	"testing"

	"multigames/server/internal/store"

	"github.com/google/uuid"
)

func TestAddGamePlayerMetadata(t *testing.T) {
	xID := uuid.New()
	oID := uuid.New()
	xName, xAvatar := "Alice", "alice.png"
	oName, oAvatar := "Bob", "7"
	users := map[uuid.UUID]*store.User{
		xID: {
			ID: xID, DisplayName: &xName,
			AvatarKind: "network", AvatarValue: &xAvatar,
		},
		oID: {
			ID: oID, DisplayName: &oName,
			AvatarKind: "preset", AvatarValue: &oAvatar,
		},
	}
	lookup := func(_ context.Context, id uuid.UUID) (*store.User, error) {
		user, ok := users[id]
		if !ok {
			return nil, errors.New("user not found")
		}
		return user, nil
	}

	t.Run("move preserves player metadata", func(t *testing.T) {
		payload := map[string]any{
			"x_user_id": xID.String(),
			"o_user_id": oID.String(),
		}

		addGamePlayerMetadata(context.Background(), payload, xID.String(), oID.String(), lookup)

		assertGamePlayerMetadata(t, payload, "x", xName, "network", xAvatar)
		assertGamePlayerMetadata(t, payload, "o", oName, "preset", oAvatar)
	})

	t.Run("swap follows reassigned sides", func(t *testing.T) {
		payload := map[string]any{
			"x_user_id": oID.String(),
			"o_user_id": xID.String(),
		}

		addGamePlayerMetadata(context.Background(), payload, oID.String(), xID.String(), lookup)

		assertGamePlayerMetadata(t, payload, "x", oName, "preset", oAvatar)
		assertGamePlayerMetadata(t, payload, "o", xName, "network", xAvatar)
	})
}

func TestAddGamePlayerMetadataToleratesUnavailableProfiles(t *testing.T) {
	payload := map[string]any{"status": gameStatusActive}
	lookup := func(_ context.Context, _ uuid.UUID) (*store.User, error) {
		return nil, errors.New("database unavailable")
	}

	addGamePlayerMetadata(context.Background(), payload, uuid.NewString(), "bot:easy", lookup)

	if payload["status"] != gameStatusActive {
		t.Fatal("existing mutation response fields were changed")
	}
	if payload["o_display_name"] != "Бот" {
		t.Fatalf("o_display_name = %v, want Бот", payload["o_display_name"])
	}
	if _, exists := payload["x_display_name"]; exists {
		t.Fatal("x_display_name must be omitted when profile lookup fails")
	}
}

func assertGamePlayerMetadata(t *testing.T, payload map[string]any, side, name, avatarKind, avatarValue string) {
	t.Helper()
	want := map[string]string{
		side + "_display_name": name,
		side + "_avatar_kind":  avatarKind,
		side + "_avatar_value": avatarValue,
	}
	for key, expected := range want {
		if actual := payload[key]; actual != expected {
			t.Errorf("%s = %v, want %q", key, actual, expected)
		}
	}
}
