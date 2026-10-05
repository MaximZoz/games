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
	UserIDs []string       `json:"user_ids,omitempty"`
	All     bool           `json:"all,omitempty"`
	Payload map[string]any `json:"payload"`
}

// GamesBroadcaster publishes game events to Redis so all instances can deliver them.
type GamesBroadcaster struct {
	Rdb *redis.Client
	Hub *RealtimeHub
}

// PublishRemote кладёт событие в Redis. Подписчик на каждой реплике пишет его в локальные сокеты.
func (b *GamesBroadcaster) PublishRemote(userIDs []uuid.UUID, all bool, payload any) error {
	if b == nil || b.Rdb == nil {
		return redis.ErrClosed
	}
	payloadMap, ok := payload.(map[string]any)
	if !ok || payloadMap == nil {
		return redis.ErrClosed
	}
	msg := gamesBroadcastMsg{All: all, Payload: payloadMap}
	if !all {
		if len(userIDs) == 0 {
			return nil
		}
		ids := make([]string, len(userIDs))
		for i, id := range userIDs {
			ids[i] = id.String()
		}
		msg.UserIDs = ids
	}
	raw, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	return b.Rdb.Publish(context.Background(), gamesBroadcastChannel, raw).Err()
}

// Publish sends the payload to all userIDs via Redis Pub/Sub.
// Each server instance will receive and deliver to its connected users.
func (b *GamesBroadcaster) Publish(userIDs []uuid.UUID, payload any) {
	if b == nil || b.Rdb == nil || len(userIDs) == 0 {
		return
	}
	if err := b.PublishRemote(userIDs, false, payload); err != nil {
		log.Printf("games broadcast publish: %v", err)
		if b.Hub != nil {
			b.Hub.DeliverLocal(userIDs, payload)
		}
	}
}

// PublishAll рассылает payload всем онлайн-клиентам на всех инстансах.
// Без Redis — только локальный Hub.
func (b *GamesBroadcaster) PublishAll(payload any) {
	if b == nil {
		return
	}
	if b.Rdb == nil {
		if b.Hub != nil {
			b.Hub.DeliverLocalAll(payload)
		}
		return
	}
	if err := b.PublishRemote(nil, true, payload); err != nil {
		log.Printf("games broadcast publish all: %v", err)
		if b.Hub != nil {
			b.Hub.DeliverLocalAll(payload)
		}
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
				b.Hub.DeliverLocalAll(m.Payload)
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
				b.Hub.DeliverLocal(userIDs, m.Payload)
			}
		}
	}
}
