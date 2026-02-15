package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"multigames/server/internal/api"

	"github.com/golang-migrate/migrate/v4"
	"github.com/joho/godotenv"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

const serverMessage = "go start"

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}

func runMigrations(dbURL string) error {
	m, err := migrate.New("file://migrations", dbURL)
	if err != nil {
		return err
	}
	defer m.Close()
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return err
	}
	return nil
}

func handleStart(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, serverMessage)
}

func main() {
	_ = godotenv.Load(".env")
	_ = godotenv.Load("../.env")

	ctx := context.Background()

	dbURL := getEnv("DATABASE_URL", "postgres://multigames:multigames@localhost:5432/multigames?sslmode=disable")
	if err := runMigrations(dbURL); err != nil {
		log.Fatalf("Migrations: %v", err)
	}
	log.Println("Migrations: ok")

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Postgres: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("Postgres ping: %v", err)
	}
	log.Println("Postgres: connected")

	redisURL := getEnv("REDIS_URL", "redis://localhost:6379/0")
	redisOpt, err := redis.ParseURL(redisURL)
	if err != nil {
		log.Fatalf("Redis parse URL: %v", err)
	}
	rdb := redis.NewClient(redisOpt)
	defer rdb.Close()
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("Redis ping: %v", err)
	}
	log.Println("Redis: connected")

	jwtSecret := getEnv("JWT_SECRET", "dev-secret-change-in-production")
	if jwtSecret == "dev-secret-change-in-production" {
		log.Println("JWT_SECRET: using default (dev only)")
	}

	authHandler := &api.AuthHandler{Pool: pool, JWTSecret: []byte(jwtSecret)}
	adminInitSecret := getEnv("ADMIN_INIT_SECRET", "")
	adminHandler := &api.AdminHandler{Pool: pool, JWTSecret: []byte(jwtSecret), InitSecret: adminInitSecret}

	adminAuth := func(next http.HandlerFunc) http.Handler {
		return api.RequireAuth([]byte(jwtSecret), api.RequireAdmin(pool, next))
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/start", handleStart)
	mux.HandleFunc("/api/auth/register", authHandler.Register)
	mux.HandleFunc("/api/auth/login", authHandler.Login)
	mux.Handle("/api/me", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(authHandler.Me)))

	mux.HandleFunc("/api/admin/init", adminHandler.Init)
	mux.Handle("/api/admin/users", adminAuth(http.HandlerFunc(adminHandler.ListUsers)))
	mux.Handle("/api/admin/users/set-admin", adminAuth(http.HandlerFunc(adminHandler.SetAdmin)))
	mux.Handle("/api/admin/users/reset-password", adminAuth(http.HandlerFunc(adminHandler.ResetPassword)))
	mux.Handle("/api/admin/users/delete", adminAuth(http.HandlerFunc(adminHandler.DeleteUser)))

	handler := api.CORS(mux)

	port := ":8080"
	log.Printf("MultiGames server listening on http://localhost%s", port)
	log.Printf("GET /api/start -> %q", serverMessage)
	log.Printf("POST /api/auth/register, POST /api/auth/login, GET /api/me (Bearer)")
	_ = rdb
	if err := http.ListenAndServe(port, handler); err != nil {
		log.Fatal(err)
	}
}
