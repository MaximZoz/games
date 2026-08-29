package main

import (
	"context"
	"embed"
	"encoding/json"
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
	"multigames/server/internal/gameregistry"
	"multigames/server/internal/i18n"
	"multigames/server/internal/mailer"
	"multigames/server/internal/store"
	"multigames/server/internal/translate"
	"multigames/server/internal/whatsnew"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"
)

//go:embed web
var webFS embed.FS

//go:embed whats_new.md
var whatsNewFile string

const serverMessage = "go start"

// buildID — короткий git sha (или иной id), прошивается при деплое:
// go build -ldflags="-X main.buildID=abc1234"
// Либо переменная окружения BUILD_ID перекрывает значение.
var buildID = "dev"

func effectiveBuildID() string {
	if v := strings.TrimSpace(os.Getenv("BUILD_ID")); v != "" {
		return v
	}
	if strings.TrimSpace(buildID) == "" {
		return "dev"
	}
	return strings.TrimSpace(buildID)
}

// whatsNewTranslate — опциональный перевод WHAT_NEW, если нет секции ## lang.
var whatsNewTranslate *translate.Service

func whatsNewRaw() string {
	if v := strings.TrimSpace(os.Getenv("WHAT_NEW")); v != "" {
		return v
	}
	return whatsNewFile
}

// localizedWhatsNew — changelog под Accept-Language (секции ## ru/## en или перевод).
func localizedWhatsNew(ctx context.Context, lang string) string {
	raw := whatsNewRaw()
	lang = strings.ToLower(strings.TrimSpace(lang))
	if lang == "" {
		lang = i18n.LangRU
	}
	if whatsnew.HasLang(raw, lang) {
		return whatsnew.Format(raw, lang)
	}
	if lang == i18n.LangRU {
		return whatsnew.SourceRU(raw)
	}
	// Явного перевода нет — английская секция как общий fallback.
	if whatsnew.HasLang(raw, i18n.LangEN) {
		return whatsnew.Format(raw, i18n.LangEN)
	}
	ru := whatsnew.SourceRU(raw)
	if ru == "" || whatsNewTranslate == nil {
		return ru
	}
	tctx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	tr, err := whatsNewTranslate.Translate(tctx, ru, i18n.LangRU, lang)
	if err != nil || strings.TrimSpace(tr) == "" {
		return ru
	}
	return strings.TrimSpace(tr)
}

func handleVersion(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, i18n.T(i18n.LangFromRequest(r), "Method not allowed"), http.StatusMethodNotAllowed)
		return
	}
	lang := i18n.LangFromRequest(r)
	id := effectiveBuildID()
	payload := map[string]string{
		"build_id":     id,
		"latest_build": id,
		"whats_new":    localizedWhatsNew(r.Context(), lang),
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_ = json.NewEncoder(w).Encode(payload)
}

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
		http.Error(w, i18n.T(i18n.LangFromRequest(r), "Method not allowed"), http.StatusMethodNotAllowed)
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
			http.Error(w, i18n.T(i18n.LangFromRequest(r), "web assets not available"), http.StatusInternalServerError)
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
		case strings.HasSuffix(fsPath, ".webmanifest"):
			contentType = "application/manifest+json"
		case strings.HasSuffix(fsPath, ".png"):
			contentType = "image/png"
		case strings.HasSuffix(fsPath, ".ico"):
			contentType = "image/x-icon"
		case strings.HasSuffix(fsPath, ".woff2"):
			contentType = "font/woff2"
		}
		w.Header().Set("Content-Type", contentType)
		// Entry / SW: без долгого кэша — иначе вкладка месяцами держит старый main.dart.js
		// и не видит ни новый UI, ни диалог «есть обновление».
		switch fsPath {
		case "index.html",
			"flutter.js",
			"flutter_bootstrap.js",
			"main.dart.js",
			"flutter_service_worker.js",
			"push-sw.js",
			"manifest.json",
			"version.json":
			w.Header().Set("Cache-Control", "no-cache")
		}
		if fsPath == "push-sw.js" {
			w.Header().Set("Service-Worker-Allowed", "/")
		}
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

	// Гарантировать наличие системного аккаунта поддержки (идемпотентно).
	if err := store.EnsureSupportUser(ctx, pool); err != nil {
		log.Printf("Support user: %v", err)
	} else {
		log.Println("Support user: ok")
	}

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

	pushSender := &api.WebPushSender{
		Pool:                  pool,
		PublicKey:             getEnv("VAPID_PUBLIC_KEY", ""),
		PrivateKey:            getEnv("VAPID_PRIVATE_KEY", ""),
		Subject:               getEnv("VAPID_SUBJECT", "admin@zozu.games"),
		TTLSeconds:            86400,
		FCMServiceAccountJSON: getEnv("FCM_SERVICE_ACCOUNT_JSON", ""),
	}
	if pushSender.Enabled() {
		log.Printf("Web Push: enabled")
	} else {
		log.Printf("Web Push: disabled (set VAPID_PUBLIC_KEY / VAPID_PRIVATE_KEY)")
	}
	if pushSender.FCMEnabled() {
		log.Printf("FCM: enabled")
	} else {
		log.Printf("FCM: disabled (set FCM_SERVICE_ACCOUNT_JSON)")
	}

	publicBase := getEnv("PUBLIC_BASE_URL", "http://localhost:8080")
	frontendURL := getEnv("FRONTEND_URL", publicBase)

	mailFrom := getEnv("MAIL_FROM", "")
	if mailFrom == "" {
		mailFrom = getEnv("SMTP_FROM", "")
	}
	mail := mailer.New(mailer.Config{
		ResendAPIKey: getEnv("RESEND_API_KEY", ""),
		From:         mailFrom,
		AppOrigin:    frontendURL,
		Host:         getEnv("SMTP_HOST", ""),
		Port:         getEnv("SMTP_PORT", "587"),
		Username:     getEnv("SMTP_USER", ""),
		Password:     getEnv("SMTP_PASSWORD", ""),
	})
	switch mail.Provider() {
	case "resend":
		log.Printf("Mailer: Resend enabled (from=%s)", mailFrom)
		if strings.Contains(strings.ToLower(mailFrom), "onboarding@resend.dev") {
			log.Printf("Mailer: Resend sandbox From — delivery only to your Resend account email until domain is verified")
		}
	case "smtp":
		log.Printf("Mailer: SMTP enabled (%s)", getEnv("SMTP_HOST", ""))
	default:
		log.Printf("Mailer: not configured — set RESEND_API_KEY (or SMTP_*); codes logged only")
	}
	oauthCfg := &api.OAuthConfig{
		PublicBaseURL:      publicBase,
		FrontendURL:        frontendURL,
		GoogleClientID:     getEnv("GOOGLE_CLIENT_ID", ""),
		GoogleClientSecret: getEnv("GOOGLE_CLIENT_SECRET", ""),
		AppleClientID:      getEnv("APPLE_CLIENT_ID", ""),
		AppleTeamID:        getEnv("APPLE_TEAM_ID", ""),
		AppleKeyID:         getEnv("APPLE_KEY_ID", ""),
		ApplePrivateKey:    getEnv("APPLE_PRIVATE_KEY", ""),
		YandexClientID:     getEnv("YANDEX_CLIENT_ID", ""),
		YandexClientSecret: getEnv("YANDEX_CLIENT_SECRET", ""),
		VKClientID:         getEnv("VK_CLIENT_ID", ""),
		VKClientSecret:     getEnv("VK_CLIENT_SECRET", ""),
	}
	if providers := oauthCfg.EnabledProviders(); len(providers) > 0 {
		log.Printf("OAuth providers: %s", strings.Join(providers, ", "))
	} else {
		log.Printf("OAuth: no providers configured")
	}

	realtimeHub := api.NewRealtimeHub()
	authHandler := &api.AuthHandler{
		Pool:      pool,
		JWTSecret: []byte(jwtSecret),
		Push:      pushSender,
		Mailer:    mail,
		OAuth:     oauthCfg,
		Hub:       realtimeHub,
	}
	wsHandler := &api.RealtimeWSHandler{
		Hub:           realtimeHub,
		Pool:          pool,
		JWTSecret:     []byte(jwtSecret),
		LogWriter:     logWriter,
		AppLogEnabled: appLogEnabled,
		Push:          pushSender,
	}
	webPushHandler := &api.WebPushHandler{Pool: pool, Sender: pushSender}
	settingsHandler := &api.SettingsHandler{Pool: pool}
	languageSettingsHandler := &api.LanguageSettingsHandler{Pool: pool}
	translateService := translate.NewService()
	whatsNewTranslate = translateService
	chatTranslateHandler := &api.ChatTranslateHandler{Pool: pool, Translate: translateService}
	friendsHandler := &api.FriendsHandler{Pool: pool, Hub: realtimeHub, Push: pushSender}
	chatsHandler := &api.ChatsHandler{Pool: pool, Rdb: rdb, Hub: realtimeHub, Push: pushSender}
	gamesBroadcaster := &api.GamesBroadcaster{Rdb: rdb, Hub: realtimeHub}
	gamesHandler := &api.GamesHandler{
		Pool:        pool,
		Rdb:         rdb,
		Hub:         realtimeHub,
		Broadcaster: gamesBroadcaster,
		Push:        pushSender,
		Registry:    gameregistry.Default(),
	}
	presenceHandler := &api.PresenceHandler{Pool: pool, Hub: realtimeHub}
	coinsHandler := &api.CoinsHandler{Pool: pool, Hub: realtimeHub}
	achievementsHandler := &api.AchievementsHandler{Pool: pool}
	shopHandler := &api.ShopHandler{Pool: pool, Hub: realtimeHub, Push: pushSender}
	if rdb != nil {
		go gamesBroadcaster.Start(ctx)
	}
	adminInitSecret := getEnv("ADMIN_INIT_SECRET", "")
	adminHandler := &api.AdminHandler{
		Pool:        pool,
		JWTSecret:   []byte(jwtSecret),
		InitSecret:  adminInitSecret,
		LogImporter: logImporter,
		Hub:         realtimeHub,
		Push:        pushSender,
	}
	frontendLogHandler := &api.FrontendLogHandler{
		Writer:    logWriter,
		JWTSecret: []byte(jwtSecret),
		Pool:      pool,
		DirectDB:  appLogEnabled,
	}

	adminAuth := func(next http.HandlerFunc) http.Handler {
		return api.RequireAuth([]byte(jwtSecret), pool, api.RequireAdmin(pool, next))
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/start", handleStart)
	mux.HandleFunc("/api/version", handleVersion)
	mux.HandleFunc("/api/auth/register", authHandler.Register)
	mux.HandleFunc("/api/auth/login", authHandler.Login)
	mux.HandleFunc("/api/auth/refresh", authHandler.Refresh)
	mux.HandleFunc("/api/auth/verify-email", authHandler.VerifyEmail)
	mux.HandleFunc("/api/auth/resend-verification", authHandler.ResendVerification)
	mux.HandleFunc("/api/auth/forgot-password", authHandler.ForgotPassword)
	mux.HandleFunc("/api/auth/reset-password", authHandler.ResetPassword)
	mux.HandleFunc("/api/auth/oauth/providers", authHandler.OAuthProviders)
	mux.HandleFunc("/api/auth/oauth/poll", authHandler.OAuthPoll)
	mux.HandleFunc("/api/auth/oauth/google/id-token", authHandler.GoogleIDTokenLogin)
	mux.HandleFunc("/api/auth/oauth/", func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if strings.HasSuffix(path, "/start") {
			authHandler.OAuthStart(w, r)
			return
		}
		if strings.HasSuffix(path, "/callback") {
			authHandler.OAuthCallback(w, r)
			return
		}
		if strings.HasSuffix(path, "/id-token") {
			authHandler.GoogleIDTokenLogin(w, r)
			return
		}
		http.NotFound(w, r)
	})
	mux.HandleFunc("/api/logs/frontend", frontendLogHandler.Ingest)
	mux.Handle("/api/ws", http.HandlerFunc(wsHandler.ServeHTTP))
	mux.Handle("/api/support-user", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(adminHandler.SupportUserInfo)))
	mux.Handle("/api/me", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(authHandler.Me)))
	mux.Handle("/api/profile", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(authHandler.UpdateProfile)))
	mux.Handle("/api/profile/photos", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			authHandler.ListProfilePhotos(w, r)
		case http.MethodPost:
			authHandler.UploadProfilePhoto(w, r)
		case http.MethodDelete:
			authHandler.DeleteProfilePhoto(w, r)
		default:
			api.WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		}
	})))
	mux.Handle("/api/profile/photos/file", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(authHandler.GetProfilePhotoFile)))
	mux.Handle("/api/profile/photos/delete", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(authHandler.DeleteProfilePhoto)))
	mux.Handle("/api/friends", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.List)))
	mux.Handle("/api/friends/users-count", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.UsersCount)))
	mux.Handle("/api/friends/search", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.Search)))
	mux.Handle("/api/friends/request", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.SendRequest)))
	mux.Handle("/api/friends/accept", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.AcceptRequest)))
	mux.Handle("/api/friends/reject", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.RejectRequest)))
	mux.Handle("/api/friends/cancel", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.CancelRequest)))
	mux.Handle("/api/friends/remove", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(friendsHandler.RemoveFriend)))
	mux.Handle("/api/chats", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.List)))
	mux.Handle("/api/chats/start", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Start)))
	mux.Handle("/api/chats/capabilities", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Capabilities)))
	mux.Handle("/api/chats/messages", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Messages)))
	mux.Handle("/api/chats/messages/edit", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.EditMessage)))
	mux.Handle("/api/chats/messages/delete", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.DeleteMessage)))
	mux.Handle("/api/chats/messages/image", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.MessageImage)))
	mux.Handle("/api/chats/read", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Read)))
	mux.Handle("/api/chats/delivered", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Delivered)))
	mux.Handle("/api/chats/clear", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Clear)))
	mux.Handle("/api/chats/block", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Block)))
	mux.Handle("/api/chats/unblock", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Unblock)))
	mux.Handle("/api/chats/blocked", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(chatsHandler.Blocked)))
	mux.Handle("/api/chats/translate", api.RequireAuth([]byte(jwtSecret), pool, chatTranslateHandler))
	mux.Handle("/api/settings", api.RequireAuth([]byte(jwtSecret), pool, settingsHandler))
	mux.Handle("/api/settings/language", api.RequireAuth([]byte(jwtSecret), pool, languageSettingsHandler))
	mux.Handle("/api/games/", api.RequireAuth([]byte(jwtSecret), pool, gamesHandler))
	mux.Handle("/api/presence", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(presenceHandler.Get)))
	mux.Handle("/api/coins/daily-available", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(coinsHandler.DailyAvailable)))
	mux.Handle("/api/coins/claim-daily", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(coinsHandler.ClaimDaily)))
	mux.Handle("/api/coins/claim-admin-grant", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(coinsHandler.ClaimAdminGrant)))
	mux.Handle("/api/achievements", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(achievementsHandler.List)))
	mux.Handle("/api/achievements/unclaimed-count", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(achievementsHandler.UnclaimedCount)))
	mux.Handle("/api/achievements/claim", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(achievementsHandler.Claim)))
	mux.Handle("/api/shop", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.List)))
	mux.Handle("/api/shop/buy", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.Buy)))
	mux.Handle("/api/inventory", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.Inventory)))
	mux.Handle("/api/inventory/capabilities", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.Capabilities)))
	mux.Handle("/api/inventory/consume", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.Consume)))
	mux.Handle("/api/inventory/sell", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.Sell)))
	mux.Handle("/api/inventory/gift", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.Gift)))
	mux.Handle("/api/inventory/collections", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.CollectionsShowcase)))
	mux.Handle("/api/inventory/collection-income", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.CollectionIncome)))
	mux.Handle("/api/inventory/claim-collection-income", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(shopHandler.ClaimCollectionIncome)))

	mux.Handle("/api/push/vapid-key", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(webPushHandler.VapidPublicKey)))
	mux.Handle("/api/push/subscribe", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(webPushHandler.Subscribe)))
	mux.Handle("/api/push/unsubscribe", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(webPushHandler.Unsubscribe)))
	mux.Handle("/api/push/preferences", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(webPushHandler.Preferences)))
	mux.Handle("/api/push/device", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(webPushHandler.RegisterDevice)))
	mux.Handle("/api/push/device/unregister", api.RequireAuth([]byte(jwtSecret), pool, http.HandlerFunc(webPushHandler.UnregisterDevice)))

	mux.HandleFunc("/api/admin/init", adminHandler.Init)
	mux.Handle("/api/admin/users", adminAuth(http.HandlerFunc(adminHandler.ListUsers)))
	mux.Handle("/api/admin/logs", adminAuth(http.HandlerFunc(adminHandler.ListLogs)))
	mux.Handle("/api/admin/logs/clear", adminAuth(http.HandlerFunc(adminHandler.ClearLogs)))
	mux.Handle("/api/admin/users/set-admin", adminAuth(http.HandlerFunc(adminHandler.SetAdmin)))
	mux.Handle("/api/admin/users/reset-password", adminAuth(http.HandlerFunc(adminHandler.ResetPassword)))
	mux.Handle("/api/admin/users/freeze", adminAuth(http.HandlerFunc(adminHandler.FreezeUser)))
	mux.Handle("/api/admin/users/grant-coins", adminAuth(http.HandlerFunc(adminHandler.GrantCoins)))
	mux.Handle("/api/admin/support/chats", adminAuth(http.HandlerFunc(adminHandler.SupportChats)))
	mux.Handle("/api/admin/support/chats/", adminAuth(http.HandlerFunc(adminHandler.SupportMessages)))

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
	log.Printf("build_id=%s", effectiveBuildID())
	log.Printf("GET /api/start -> %q", serverMessage)
	log.Printf("GET /api/version -> build_id")
	log.Printf("POST /api/auth/register, POST /api/auth/login, POST /api/auth/refresh, POST /api/auth/verify-email, POST /api/auth/resend-verification, POST /api/auth/forgot-password, POST /api/auth/reset-password, GET /api/me (Bearer)")
	log.Printf("OAuth: GET /api/auth/oauth/providers, GET /api/auth/oauth/{google|apple|yandex|vk}/start, /callback")
	log.Printf("Realtime API: GET /api/ws?access_token=<token> (WebSocket)")
	log.Printf("Friends API: GET /api/friends, GET /api/friends/search, POST /api/friends/* (Bearer)")
	log.Printf("Chats API: GET /api/chats, /api/chats/blocked; POST /api/chats/start, /api/chats/messages, /api/chats/read, /api/chats/delivered, /api/chats/clear, /api/chats/block, /api/chats/unblock (Bearer)")
	log.Printf("Presence API: GET /api/presence?user_ids=... (Bearer)")
	log.Printf("Games API: POST /api/games/tictactoe/lobby, GET /api/games/tictactoe/lobbies, POST /api/games/tictactoe/lobby/:id/invite|join|leave, GET /api/games/tictactoe/game/:id, POST /api/games/tictactoe/game/:id/move (Bearer, Redis required)")
	log.Printf("Battleship API: POST /api/games/battleship/lobby, GET /api/games/battleship/lobbies, POST /api/games/battleship/game/:id/place_ships|shoot|forfeit (Bearer, Redis required)")

	// После деплоя уведомляем онлайн-клиентов (с небольшой задержкой на подъём WS).
	// whats_new не кладём в broadcast: у каждого своя локаль — клиент тянет /api/version.
	go func() {
		time.Sleep(3 * time.Second)
		id := effectiveBuildID()
		payload := map[string]any{
			"type":         "client_update_available",
			"build_id":     id,
			"latest_build": id,
		}
		gamesBroadcaster.PublishAll(payload)
	}()

	if err := http.ListenAndServe(port, finalHandler); err != nil {
		log.Fatal(err)
	}
}
