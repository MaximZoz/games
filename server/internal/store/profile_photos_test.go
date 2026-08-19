package store

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
)

func TestValidProfilePhotoSlot(t *testing.T) {
	if !ValidProfilePhotoSlot(0) || !ValidProfilePhotoSlot(2) {
		t.Fatal("0..2 must be valid")
	}
	if ValidProfilePhotoSlot(-1) || ValidProfilePhotoSlot(3) || ValidProfilePhotoSlot(99) {
		t.Fatal("out of range slots must be invalid")
	}
}

func TestProfilePhotoLimits(t *testing.T) {
	if MaxProfilePhotos != 3 {
		t.Fatalf("MaxProfilePhotos=%d want 3", MaxProfilePhotos)
	}
	if MaxProfilePhotoBytes <= 0 {
		t.Fatal("MaxProfilePhotoBytes must be positive")
	}
}

func TestUpsertProfilePhotoValidation(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()

	if _, err := UpsertProfilePhoto(ctx, nil, userID, -1, "image/jpeg", []byte("x")); !errors.Is(err, ErrPhotoSlotInvalid) {
		t.Fatalf("invalid slot: %v", err)
	}
	if _, err := UpsertProfilePhoto(ctx, nil, userID, 0, "image/jpeg", nil); !errors.Is(err, ErrPhotoEmpty) {
		t.Fatalf("empty: %v", err)
	}
	tooBig := make([]byte, MaxProfilePhotoBytes+1)
	if _, err := UpsertProfilePhoto(ctx, nil, userID, 0, "image/jpeg", tooBig); !errors.Is(err, ErrPhotoTooLarge) {
		t.Fatalf("too large: %v", err)
	}
}
