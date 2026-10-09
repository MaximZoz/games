package gameregistry

import (
	"fmt"
	"sync"

	"multigames/server/internal/store"
)

// Registry — единственная точка «какие игры есть на сервере».
type Registry struct {
	mu   sync.RWMutex
	byID map[string]Module
	order []string
}

func New() *Registry {
	return &Registry{byID: make(map[string]Module)}
}

// Register добавляет модуль. Паника при дубликате id — ошибка конфигурации.
func (r *Registry) Register(m Module) {
	if m == nil {
		panic("gameregistry: nil module")
	}
	id := m.ID()
	if id == "" {
		panic("gameregistry: empty module id")
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.byID[id]; ok {
		panic(fmt.Sprintf("gameregistry: duplicate id %q", id))
	}
	r.byID[id] = m
	r.order = append(r.order, id)
}

func (r *Registry) Get(id string) (Module, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	m, ok := r.byID[id]
	return m, ok
}

func (r *Registry) MustGet(id string) Module {
	m, ok := r.Get(id)
	if !ok {
		panic(fmt.Sprintf("gameregistry: unknown game %q", id))
	}
	return m
}

func (r *Registry) Has(id string) bool {
	_, ok := r.Get(id)
	return ok
}

// IDs — в порядке регистрации.
func (r *Registry) IDs() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]string, len(r.order))
	copy(out, r.order)
	return out
}

// Normalize — неизвестный/пустой id → tictactoe (если зарегистрирован) либо первый.
func (r *Registry) Normalize(id string) string {
	if id != "" && r.Has(id) {
		return id
	}
	r.mu.RLock()
	defer r.mu.RUnlock()
	if _, ok := r.byID[store.GameTypeTicTacToe]; ok {
		return store.GameTypeTicTacToe
	}
	if len(r.order) > 0 {
		return r.order[0]
	}
	return store.GameTypeTicTacToe
}

// Default — реестр всех встроенных игр.
func Default() *Registry {
	r := New()
	r.Register(NewTicTacToe())
	r.Register(NewDurak())
	r.Register(NewBattleship())
	r.Register(NewPoker())
	r.Register(NewUno())
	r.Register(NewNardy())
	r.Register(NewCheckers())
	r.Register(NewChess())
	return r
}
