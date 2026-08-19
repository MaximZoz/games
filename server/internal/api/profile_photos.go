package api

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"multigames/server/internal/store"

	"github.com/google/uuid"
)

type uploadProfilePhotoBody struct {
	Slot        *int   `json:"slot"`
	ImageBase64 string `json:"image_base64"`
	ImageMime   string `json:"image_mime"`
}

type deleteProfilePhotoBody struct {
	ID string `json:"id"`
}

func decodeProfileImageBase64(raw string) ([]byte, error) {
	s := strings.TrimSpace(raw)
	if s == "" {
		return nil, errors.New("empty")
	}
	if i := strings.Index(s, ","); i >= 0 && strings.Contains(strings.ToLower(s[:i]), "base64") {
		s = s[i+1:]
	}
	data, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		data, err = base64.RawStdEncoding.DecodeString(s)
		if err != nil {
			return nil, err
		}
	}
	return data, nil
}

func profilePhotoJSON(p store.ProfilePhotoMeta) map[string]any {
	return map[string]any{
		"id":         p.ID.String(),
		"user_id":    p.UserID.String(),
		"slot":       p.Slot,
		"image_mime": p.ImageMime,
	}
}

// GET /api/profile/photos?user_id=
func (h *AuthHandler) ListProfilePhotos(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if _, ok := GetUserID(r.Context()); !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	raw := strings.TrimSpace(r.URL.Query().Get("user_id"))
	var userID uuid.UUID
	if raw == "" {
		id, ok := GetUserID(r.Context())
		if !ok {
			WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
			return
		}
		userID = id
	} else {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			WriteErr(w, r, http.StatusBadRequest, "invalid user_id")
			return
		}
		userID = parsed
	}
	list, err := store.ListProfilePhotos(r.Context(), h.Pool, userID)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	items := make([]map[string]any, 0, len(list))
	for _, p := range list {
		items = append(items, profilePhotoJSON(p))
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	_ = json.NewEncoder(w).Encode(map[string]any{"photos": items})
}

// GET /api/profile/photos/file?id=
func (h *AuthHandler) GetProfilePhotoFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if _, ok := GetUserID(r.Context()); !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	id, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("id")))
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid id")
		return
	}
	photo, err := store.GetProfilePhoto(r.Context(), h.Pool, id)
	if err != nil {
		if errors.Is(err, store.ErrPhotoNotFound) {
			WriteErr(w, r, http.StatusNotFound, "not found")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	mime := strings.TrimSpace(photo.ImageMime)
	if mime == "" {
		mime = "image/jpeg"
	}
	w.Header().Set("Content-Type", mime)
	w.Header().Set("Cache-Control", "private, max-age=300")
	_, _ = w.Write(photo.ImageData)
}

// POST /api/profile/photos
func (h *AuthHandler) UploadProfilePhoto(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	var body uploadProfilePhotoBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid JSON")
		return
	}
	data, err := decodeProfileImageBase64(body.ImageBase64)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid image_base64")
		return
	}
	slot := -1
	if body.Slot != nil {
		slot = *body.Slot
	} else {
		slot, err = store.NextFreeProfilePhotoSlot(r.Context(), h.Pool, userID)
		if err != nil {
			if errors.Is(err, store.ErrPhotoLimit) {
				WriteErr(w, r, http.StatusConflict, "photo limit reached")
				return
			}
			WriteErr(w, r, http.StatusInternalServerError, "server error")
			return
		}
	}
	meta, err := store.UpsertProfilePhoto(r.Context(), h.Pool, userID, slot, body.ImageMime, data)
	if err != nil {
		switch {
		case errors.Is(err, store.ErrPhotoSlotInvalid):
			WriteErr(w, r, http.StatusBadRequest, "invalid slot")
		case errors.Is(err, store.ErrPhotoTooLarge):
			WriteErr(w, r, http.StatusRequestEntityTooLarge, "photo too large")
		case errors.Is(err, store.ErrPhotoEmpty):
			WriteErr(w, r, http.StatusBadRequest, "photo is empty")
		default:
			WriteErr(w, r, http.StatusInternalServerError, "server error")
		}
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"photo": profilePhotoJSON(*meta)})
}

// DELETE /api/profile/photos
func (h *AuthHandler) DeleteProfilePhoto(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete && r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := GetUserID(r.Context())
	if !ok {
		WriteErr(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}
	rawID := strings.TrimSpace(r.URL.Query().Get("id"))
	if rawID == "" && r.Method == http.MethodPost {
		var body deleteProfilePhotoBody
		if err := json.NewDecoder(r.Body).Decode(&body); err == nil {
			rawID = strings.TrimSpace(body.ID)
		}
	}
	id, err := uuid.Parse(rawID)
	if err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid id")
		return
	}
	if err := store.DeleteProfilePhoto(r.Context(), h.Pool, userID, id); err != nil {
		if errors.Is(err, store.ErrPhotoNotFound) {
			WriteErr(w, r, http.StatusNotFound, "not found")
			return
		}
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}
