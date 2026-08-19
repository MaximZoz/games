package api

import (
	"encoding/base64"
	"testing"

	"github.com/google/uuid"
	"multigames/server/internal/store"
)

func TestDecodeProfileImageBase64(t *testing.T) {
	raw := []byte("hello-photo")
	encoded := base64.StdEncoding.EncodeToString(raw)

	got, err := decodeProfileImageBase64(encoded)
	if err != nil {
		t.Fatalf("plain base64: %v", err)
	}
	if string(got) != string(raw) {
		t.Fatalf("got %q want %q", got, raw)
	}

	dataURL := "data:image/jpeg;base64," + encoded
	got, err = decodeProfileImageBase64(dataURL)
	if err != nil {
		t.Fatalf("data url: %v", err)
	}
	if string(got) != string(raw) {
		t.Fatalf("data url got %q want %q", got, raw)
	}

	if _, err := decodeProfileImageBase64("   "); err == nil {
		t.Fatal("empty must fail")
	}
}

func TestProfilePhotoJSON(t *testing.T) {
	id := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	userID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	m := profilePhotoJSON(store.ProfilePhotoMeta{
		ID:        id,
		UserID:    userID,
		Slot:      1,
		ImageMime: "image/jpeg",
	})
	if m["id"] != id.String() || m["user_id"] != userID.String() {
		t.Fatalf("ids: %#v", m)
	}
	if m["slot"] != 1 {
		t.Fatalf("slot=%v", m["slot"])
	}
	if m["image_mime"] != "image/jpeg" {
		t.Fatalf("mime=%v", m["image_mime"])
	}
}
