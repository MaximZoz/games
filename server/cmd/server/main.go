package main

import (
	"context"
	"embed"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"multigames/server/internal/api"
	"multigames/server/internal/applog"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"
)

//go:embed web
var webFS embed.FS

const serverMessage = "go start"

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}

func getEnvBool(key string, defaultVal bool) bool {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return defaultVal
	}
	parsed, err := strconv.ParseBool(raw)
	if err != nil {
		return defaultVal
	}
	return parsed
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

// spaHandler serves embedded Flutter web build; unknown paths return index.html (no redirects).
func spaHandler(webRoot fs.FS) http.Handler {
	sub, err := fs.Sub(webRoot, "web")
	if err != nil {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, "web assets not available", http.StatusInternalServerError)
		})
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if path == "" || path == "/" {
			path = "/index.html"
		}
		fsPath := path[1:]
		if fsPath == "" {
			fsPath = "index.html"
		}
		f, err := sub.Open(fsPath)
		if err != nil {
			// SPA fallback: любой неизвестный путь — index.html
			index, _ := sub.Open("index.html")
			if index != nil {
				defer index.Close()
				w.Header().Set("Content-Type", "text/html; charset=utf-8")
				w.Header().Set("Cache-Control", "no-cache")
				io.Copy(w, index)
				return
			}
			http.NotFound(w, r)
			return
		}
		defer f.Close()
		stat, err := f.Stat()
		if err != nil || stat.IsDir() {
			index, _ := sub.Open("index.html")
			if index != nil {
				defer index.Close()
				w.Header().Set("Content-Type", "text/html; charset=utf-8")
				io.Copy(w, index)
				return
			}
			http.NotFound(w, r)
			return
		}
		// Раздаём файл без редиректов
		contentType := "application/octet-stream"
		switch {
		case strings.HasSuffix(fsPath, ".html"):
			contentType = "text/html; charset=utf-8"
		case strings.HasSuffix(fsPath, ".js"):
			contentType = "application/javascript; charset=utf-8"
		case strings.HasSuffix(fsPath, ".css"):
			contentType = "text/css; charset=utf-8"
		case strings.HasSuffix(fsPath, ".json"):
			contentType = "application/json"
		case strings.HasSuffix(fsPath, ".png"):
			contentType = "image/png"
		case strings.HasSuffix(fsPath, ".ico"):
			contentType = "image/x-icon"
		case strings.HasSuffix(fsPath, ".woff2"):
			contentType = "font/woff2"
		}
		w.Header().Set("Content-Type", contentType)
		io.Copy(w, f)
	})
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

	redisURL := getEnv("REDIS_URL", "")
	var rdb *redis.Client
	if redisURL != "" {
		redisOpt, err := redis.ParseURL(redisURL)
		if err != nil {
			log.Printf("Redis parse URL: %v (Redis disabled)", err)
		} else {
			rdb = redis.NewClient(redisOpt)
			defer rdb.Close()
			if err := rdb.Ping(ctx).Err(); err != nil {
				log.Printf("Redis ping failed: %v (Redis disabled)", err)
				rdb = nil
			} else {
				log.Println("Redis: connected")
			}
		}
	}

	jwtSecret := getEnv("JWT_SECRET", "dev-secret-change-in-production")
	if jwtSecret == "dev-secret-change-in-production" {
		log.Println("JWT_SECRET: using default (dev only)")
	}

	appLogEnabled := getEnvBool("APP_LOG_ENABLED", false)
	var logWriter *applog.FileWriter
	var logImporter *applog.Importer
	if appLogEnabled {
		appLogFilePath := getEnv("APP_LOG_FILE", "logs/app_events.jsonl")
		appLogStatePath := getEnv("APP_LOG_STATE_FILE", "logs/app_events.offset")
		syncIntervalSeconds, err := strconv.Atoi(getEnv("APP_LOG_SYNC_INTERVAL_SECONDS", "5"))
		if err != nil || syncIntervalSeconds <= 0 {
			syncIntervalSeconds = 5
		}
		retentionDays, err := strconv.Atoi(getEnv("APP_LOG_RETENTION_DAYS", "30"))
		if err != nil || retentionDays < 0 {
			retentionDays = 30
		}
		cleanupIntervalSeconds, err := strconv.Atoi(getEnv("APP_LOG_CLEANUP_INTERVAL_SECONDS", "3600"))
		if err != nil || cleanupIntervalSeconds <= 0 {
			cleanupIntervalSeconds = 3600
		}
		retentionDuration := time.Duration(retentionDays) * 24 * time.Hour
		cleanupIntervalDuration := time.Duration(cleanupIntervalSeconds) * time.Second
		if retentionDuration > 0 {
			log.Printf(
				"App logs retention: delete older than %d days (every %s)",
				retentionDays,
				cleanupIntervalDuration,
			)
		} else {
			log.Printf("App logs retention: disabled")
		}

		logWriter, err = applog.NewFileWriter(appLogFilePath)
		if err != nil {
			log.Fatalf("App logs file: %v", err)
		}
		defer logWriter.Close()

		logImporter = applog.NewImporter(
			pool,
			appLogFilePath,
			appLogStatePath,
			time.Duration(syncIntervalSeconds)*time.Second,
			retentionDuration,
			cleanupIntervalDuration,
		)
		logImporter.Start(ctx)
		if err := logImporter.SyncNow(ctx); err != nil {
			log.Printf("App logs initial sync failed: %v", err)
		}
		_ = logWriter.Append(applog.Event{
			Source:     "backend",
			MethodName: "server.started",
			Level:      "info",
			Message:    "App logs enabled, presence events will be recorded",
		})
		log.Printf("App logs: enabled, file=%s", appLogFilePath)
	} else {
		log.Printf("App logs: disabled (APP_LOG_ENABLED=false or unset)")
	}

	authHandler := &api.AuthHandler{Pool: pool, JWTSecret: []byte(jwtSecret)}
	realtimeHub := api.NewRealtimeHub()
	wsHandler := &api.RealtimeWSHandler{
		Hub:           realtimeHub,
		Pool:          pool,
		JWTSecret:     []byte(jwtSecret),
		LogWriter:     logWriter,
		AppLogEnabled: appLogEnabled,
	}
	friendsHandler := &api.FriendsHandler{Pool: pool, Hub: realtimeHub}
	chatsHandler := &api.ChatsHandler{Pool: pool, Hub: realtimeHub}
	gamesBroadcaster := &api.GamesBroadcaster{Rdb: rdb, Hub: realtimeHub}
	gamesHandler := &api.GamesHandler{
		Pool:        pool,
		Rdb:         rdb,
		Hub:         realtimeHub,
		Broadcaster: gamesBroadcaster,
	}
	presenceHandler := &api.PresenceHandler{Pool: pool, Hub: realtimeHub}
	coinsHandler := &api.CoinsHandler{Pool: pool, Hub: realtimeHub}
	achievementsHandler := &api.AchievementsHandler{Pool: pool}
	shopHandler := &api.ShopHandler{Pool: pool, Hub: realtimeHub}
	if rdb != nil {
		go gamesBroadcaster.Start(ctx)
		go api.StartBotTimeoutTicker(ctx, gamesHandler)
	}
	adminInitSecret := getEnv("ADMIN_INIT_SECRET", "")
	adminHandler := &api.AdminHandler{
		Pool:        pool,
		JWTSecret:   []byte(jwtSecret),
		InitSecret:  adminInitSecret,
		LogImporter: logImporter,
	}
	frontendLogHandler := &api.FrontendLogHandler{
		Writer:    logWriter,
		JWTSecret: []byte(jwtSecret),
		Pool:      pool,
		DirectDB:  appLogEnabled,
	}

	adminAuth := func(next http.HandlerFunc) http.Handler {
		return api.RequireAuth([]byte(jwtSecret), api.RequireAdmin(pool, next))
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/start", handleStart)
	mux.HandleFunc("/api/auth/register", authHandler.Register)
	mux.HandleFunc("/api/auth/login", authHandler.Login)
	mux.HandleFunc("/api/auth/refresh", authHandler.Refresh)
	mux.HandleFunc("/api/logs/frontend", frontendLogHandler.Ingest)
	mux.Handle("/api/ws", http.HandlerFunc(wsHandler.ServeHTTP))
	mux.Handle("/api/me", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(authHandler.Me)))
	mux.Handle("/api/profile", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(authHandler.UpdateProfile)))
	mux.Handle("/api/friends", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.List)))
	mux.Handle("/api/friends/users-count", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.UsersCount)))
	mux.Handle("/api/friends/search", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.Search)))
	mux.Handle("/api/friends/request", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.SendRequest)))
	mux.Handle("/api/friends/accept", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.AcceptRequest)))
	mux.Handle("/api/friends/reject", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.RejectRequest)))
	mux.Handle("/api/friends/cancel", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.CancelRequest)))
	mux.Handle("/api/friends/remove", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(friendsHandler.RemoveFriend)))
	mux.Handle("/api/chats", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.List)))
	mux.Handle("/api/chats/start", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Start)))
	mux.Handle("/api/chats/messages", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Messages)))
	mux.Handle("/api/chats/read", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Read)))
	mux.Handle("/api/chats/delivered", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Delivered)))
	mux.Handle("/api/chats/clear", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Clear)))
	mux.Handle("/api/chats/block", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Block)))
	mux.Handle("/api/chats/unblock", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Unblock)))
	mux.Handle("/api/chats/blocked", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(chatsHandler.Blocked)))
	mux.Handle("/api/games/", api.RequireAuth([]byte(jwtSecret), gamesHandler))
	mux.Handle("/api/presence", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(presenceHandler.Get)))
	mux.Handle("/api/coins/daily-available", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(coinsHandler.DailyAvailable)))
	mux.Handle("/api/coins/claim-daily", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(coinsHandler.ClaimDaily)))
	mux.Handle("/api/achievements", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(achievementsHandler.List)))
	mux.Handle("/api/achievements/unclaimed-count", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(achievementsHandler.UnclaimedCount)))
	mux.Handle("/api/achievements/claim", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(achievementsHandler.Claim)))
	mux.Handle("/api/shop", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.List)))
	mux.Handle("/api/shop/buy", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.Buy)))
	mux.Handle("/api/inventory", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.Inventory)))
	mux.Handle("/api/inventory/capabilities", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.Capabilities)))
	mux.Handle("/api/inventory/consume", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.Consume)))
	mux.Handle("/api/inventory/sell", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.Sell)))
	mux.Handle("/api/inventory/gift", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.Gift)))
	mux.Handle("/api/inventory/collections", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.CollectionsShowcase)))
	mux.Handle("/api/inventory/collection-income", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.CollectionIncome)))
	mux.Handle("/api/inventory/claim-collection-income", api.RequireAuth([]byte(jwtSecret), http.HandlerFunc(shopHandler.ClaimCollectionIncome)))

	mux.HandleFunc("/api/admin/init", adminHandler.Init)
	mux.Handle("/api/admin/users", adminAuth(http.HandlerFunc(adminHandler.ListUsers)))
	mux.Handle("/api/admin/logs", adminAuth(http.HandlerFunc(adminHandler.ListLogs)))
	mux.Handle("/api/admin/logs/clear", adminAuth(http.HandlerFunc(adminHandler.ClearLogs)))
	mux.Handle("/api/admin/users/set-admin", adminAuth(http.HandlerFunc(adminHandler.SetAdmin)))
	mux.Handle("/api/admin/users/reset-password", adminAuth(http.HandlerFunc(adminHandler.ResetPassword)))
	mux.Handle("/api/admin/users/delete", adminAuth(http.HandlerFunc(adminHandler.DeleteUser)))

	directDB := appLogEnabled
	corsHandler := api.CORS(api.RequestLogger([]byte(jwtSecret), logWriter, pool, directDB, mux))
	var finalHandler http.Handler = corsHandler
	if _, err := webFS.Open("web/index.html"); err == nil {
		finalHandler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if len(r.URL.Path) >= 4 && r.URL.Path[:4] == "/api" {
				corsHandler.ServeHTTP(w, r)
				return
			}
			spaHandler(webFS).ServeHTTP(w, r)
		})
		log.Println("Serving API at /api/* and static SPA at /*")
	}

	port := getEnv("PORT", "8080")
	if port != "" && port[0] != ':' {
		port = ":" + port
	}
	log.Printf("MultiGames server listening on http://localhost%s", port)
	log.Printf("GET /api/start -> %q", serverMessage)
	log.Printf("POST /api/auth/register, POST /api/auth/login, POST /api/auth/refresh, GET /api/me (Bearer)")
	log.Printf("Realtime API: GET /api/ws?access_token=<token> (WebSocket)")
	log.Printf("Friends API: GET /api/friends, GET /api/friends/search, POST /api/friends/* (Bearer)")
	log.Printf("Chats API: GET /api/chats, /api/chats/blocked; POST /api/chats/start, /api/chats/messages, /api/chats/read, /api/chats/delivered, /api/chats/clear, /api/chats/block, /api/chats/unblock (Bearer)")
	log.Printf("Presence API: GET /api/presence?user_ids=... (Bearer)")
	log.Printf("Games API: POST /api/games/tictactoe/lobby, GET /api/games/tictactoe/lobbies, POST /api/games/tictactoe/lobby/:id/invite|join|leave, GET /api/games/tictactoe/game/:id, POST /api/games/tictactoe/game/:id/move (Bearer, Redis required)")
	if err := http.ListenAndServe(port, finalHandler); err != nil {
		log.Fatal(err)
	}
}
