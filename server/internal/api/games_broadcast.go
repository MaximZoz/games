package api

import (
	"context"
	"encoding/json"
	"log"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

const gamesBroadcastChannel = "games:broadcast"

// gamesBroadcastMsg is the message format for Redis Pub/Sub.
type gamesBroadcastMsg struct {
	UserIDs []string       `json:"user_ids"`
	All     bool           `json:"all,omitempty"`
	Payload map[string]any `json:"payload"`
}

// GamesBroadcaster publishes game events to Redis so all instances can deliver them.
type GamesBroadcaster struct {
	Rdb *redis.Client
	Hub *RealtimeHub
}

// Publish sends the payload to all userIDs via Redis Pub/Sub.
// Each server instance will receive and deliver to its connected users.
func (b *GamesBroadcaster) Publish(userIDs []uuid.UUID, payload any) {
	if b == nil || b.Rdb == nil || len(userIDs) == 0 {
		return
	}
	ids := make([]string, len(userIDs))
	for i, id := range userIDs {
		ids[i] = id.String()
	}
	payloadMap, ok := payload.(map[string]any)
	if !ok {
		return
	}
	raw, err := json.Marshal(gamesBroadcastMsg{UserIDs: ids, Payload: payloadMap})
	if err != nil {
		return
	}
	if err := b.Rdb.Publish(context.Background(), gamesBroadcastChannel, raw).Err(); err != nil {
		log.Printf("games broadcast publish: %v", err)
	}
}

// PublishAll — всем онлайн-клиентам на всех инстансах (список лобби и т.п.).
func (b *GamesBroadcaster) PublishAll(payload any) {
	if b == nil || b.Rdb == nil {
		return
	}
	payloadMap, ok := payload.(map[string]any)
	if !ok {
		return
	}
	raw, err := json.Marshal(gamesBroadcastMsg{All: true, Payload: payloadMap})
	if err != nil {
		return
	}
	if err := b.Rdb.Publish(context.Background(), gamesBroadcastChannel, raw).Err(); err != nil {
		log.Printf("games broadcast publish all: %v", err)
	}
}

// Start subscribes to games broadcast channel and forwards to local Hub.
// Call from main in a goroutine when Redis is available.
func (b *GamesBroadcaster) Start(ctx context.Context) {
	if b == nil || b.Rdb == nil || b.Hub == nil {
		return
	}
	pubsub := b.Rdb.Subscribe(ctx, gamesBroadcastChannel)
	defer pubsub.Close()

	ch := pubsub.Channel()
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-ch:
			if !ok {
				return
			}
			var m gamesBroadcastMsg
			if err := json.Unmarshal([]byte(msg.Payload), &m); err != nil {
				continue
			}
			if m.Payload == nil {
				continue
			}
			if m.All {
				b.Hub.PublishToAll(m.Payload)
				continue
			}
			userIDs := make([]uuid.UUID, 0, len(m.UserIDs))
			for _, s := range m.UserIDs {
				id, err := uuid.Parse(s)
				if err != nil {
					continue
				}
				userIDs = append(userIDs, id)
			}
			if len(userIDs) > 0 {
				b.Hub.PublishToUsers(userIDs, m.Payload)
			}
		}
	}
}
