package store

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	MaxProfilePhotos     = 3
	MaxProfilePhotoBytes = 256 * 1024
)

var (
	ErrPhotoSlotInvalid = errors.New("invalid photo slot")
	ErrPhotoLimit       = errors.New("profile photo limit reached")
	ErrPhotoTooLarge    = errors.New("photo too large")
	ErrPhotoEmpty       = errors.New("photo is empty")
	ErrPhotoNotFound    = errors.New("photo not found")
)

type ProfilePhotoMeta struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Slot      int
	ImageMime string
}

type ProfilePhoto struct {
	ProfilePhotoMeta
	ImageData []byte
}

func ValidProfilePhotoSlot(slot int) bool {
	return slot >= 0 && slot < MaxProfilePhotos
}

func ListProfilePhotos(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) ([]ProfilePhotoMeta, error) {
	rows, err := pool.Query(ctx, `
		SELECT id, user_id, slot, image_mime
		FROM user_profile_photos
		WHERE user_id = $1
		ORDER BY slot ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []ProfilePhotoMeta
	for rows.Next() {
		var p ProfilePhotoMeta
		if err := rows.Scan(&p.ID, &p.UserID, &p.Slot, &p.ImageMime); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

func GetProfilePhoto(ctx context.Context, pool *pgxpool.Pool, photoID uuid.UUID) (*ProfilePhoto, error) {
	var p ProfilePhoto
	err := pool.QueryRow(ctx, `
		SELECT id, user_id, slot, image_mime, image_data
		FROM user_profile_photos
		WHERE id = $1`, photoID).Scan(
		&p.ID, &p.UserID, &p.Slot, &p.ImageMime, &p.ImageData,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrPhotoNotFound
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func UpsertProfilePhoto(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, slot int, mime string, data []byte) (*ProfilePhotoMeta, error) {
	if !ValidProfilePhotoSlot(slot) {
		return nil, ErrPhotoSlotInvalid
	}
	if len(data) == 0 {
		return nil, ErrPhotoEmpty
	}
	if len(data) > MaxProfilePhotoBytes {
		return nil, ErrPhotoTooLarge
	}
	if mime == "" {
		mime = "image/jpeg"
	}
	var p ProfilePhotoMeta
	err := pool.QueryRow(ctx, `
		INSERT INTO user_profile_photos (user_id, slot, image_mime, image_data)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, slot) DO UPDATE
		SET image_mime = EXCLUDED.image_mime,
		    image_data = EXCLUDED.image_data
		RETURNING id, user_id, slot, image_mime`,
		userID, slot, mime, data,
	).Scan(&p.ID, &p.UserID, &p.Slot, &p.ImageMime)
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func NextFreeProfilePhotoSlot(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID) (int, error) {
	used := map[int]struct{}{}
	list, err := ListProfilePhotos(ctx, pool, userID)
	if err != nil {
		return -1, err
	}
	for _, p := range list {
		used[p.Slot] = struct{}{}
	}
	for slot := 0; slot < MaxProfilePhotos; slot++ {
		if _, ok := used[slot]; !ok {
			return slot, nil
		}
	}
	return -1, ErrPhotoLimit
}

func DeleteProfilePhoto(ctx context.Context, pool *pgxpool.Pool, userID, photoID uuid.UUID) error {
	tag, err := pool.Exec(ctx, `
		DELETE FROM user_profile_photos
		WHERE id = $1 AND user_id = $2`, photoID, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrPhotoNotFound
	}
	return nil
}
