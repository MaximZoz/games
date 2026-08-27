package api

import (
	"context"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"multigames/server/internal/store"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// OAuthConfig — клиентские ID/секреты провайдеров. Пустые = провайдер выключен.
type OAuthConfig struct {
	PublicBaseURL string // публичный URL API, напр. https://zozu.games
	FrontendURL   string // куда редиректить после OAuth (обычно тот же origin)

	GoogleClientID     string
	GoogleClientSecret string

	AppleClientID    string // Services ID
	AppleTeamID      string
	AppleKeyID       string
	ApplePrivateKey  string // PEM PKCS8

	YandexClientID     string
	YandexClientSecret string

	VKClientID     string
	VKClientSecret string

	mu      sync.Mutex
	states  map[string]oauthState  // state → data; cleanup по TTL
	results map[string]oauthResult // state → токены для poll (PWA)
}

type oauthState struct {
	Provider string
	Redirect string
	Ref      string
	Expires  time.Time
}

type oauthResult struct {
	AccessToken  string
	RefreshToken string
	Redirect     string
	Error        string
	Expires      time.Time
}

func (c *OAuthConfig) ensureStates() {
	if c.states == nil {
		c.states = make(map[string]oauthState)
	}
	if c.results == nil {
		c.results = make(map[string]oauthResult)
	}
}

func (c *OAuthConfig) putResult(state string, res oauthResult) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.ensureStates()
	res.Expires = time.Now().Add(5 * time.Minute)
	c.results[state] = res
	now := time.Now()
	for k, v := range c.results {
		if now.After(v.Expires) {
			delete(c.results, k)
		}
	}
}

func (c *OAuthConfig) takeResult(state string) (oauthResult, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.ensureStates()
	res, ok := c.results[state]
	if !ok || time.Now().After(res.Expires) {
		delete(c.results, state)
		return oauthResult{}, false
	}
	delete(c.results, state)
	return res, true
}

func (c *OAuthConfig) putState(provider, redirect, ref string) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.ensureStates()
	b := make([]byte, 24)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	state := base64.RawURLEncoding.EncodeToString(b)
	c.states[state] = oauthState{
		Provider: provider,
		Redirect: redirect,
		Ref:      ref,
		Expires:  time.Now().Add(10 * time.Minute),
	}
	// Простая уборка
	now := time.Now()
	for k, v := range c.states {
		if now.After(v.Expires) {
			delete(c.states, k)
		}
	}
	return state, nil
}

func (c *OAuthConfig) takeState(state string) (oauthState, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.ensureStates()
	s, ok := c.states[state]
	if !ok || time.Now().After(s.Expires) {
		delete(c.states, state)
		return oauthState{}, false
	}
	delete(c.states, state)
	return s, true
}

func (c *OAuthConfig) EnabledProviders() []string {
	out := make([]string, 0, 4)
	if c == nil {
		return out
	}
	if c.GoogleClientID != "" && c.GoogleClientSecret != "" {
		out = append(out, "google")
	}
	if c.AppleClientID != "" && c.AppleTeamID != "" && c.AppleKeyID != "" && c.ApplePrivateKey != "" {
		out = append(out, "apple")
	}
	if c.YandexClientID != "" && c.YandexClientSecret != "" {
		out = append(out, "yandex")
	}
	if c.VKClientID != "" && c.VKClientSecret != "" {
		out = append(out, "vk")
	}
	return out
}

func (c *OAuthConfig) callbackURL(provider string) string {
	base := strings.TrimRight(c.PublicBaseURL, "/")
	return base + "/api/auth/oauth/" + provider + "/callback"
}

func (h *AuthHandler) OAuthProviders(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	providers := []string{}
	out := map[string]any{"providers": providers}
	if h.OAuth != nil {
		providers = h.OAuth.EnabledProviders()
		out["providers"] = providers
		// Публичный client_id для Google Identity Services (кнопка без ухода в Safari).
		if h.OAuth.GoogleClientID != "" {
			out["google_client_id"] = h.OAuth.GoogleClientID
		}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(out)
}

// GoogleIDTokenLogin — вход по GIS credential (JWT) или Android server_auth_code.
// Нужен для iOS PWA / Android native Google Sign-In без redirect/popup.
func (h *AuthHandler) GoogleIDTokenLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.OAuth == nil || h.OAuth.GoogleClientID == "" {
		WriteErr(w, r, http.StatusServiceUnavailable, "oauth not configured")
		return
	}
	var body struct {
		Credential     string `json:"credential"`
		ServerAuthCode string `json:"server_auth_code"`
		Redirect       string `json:"redirect"`
		Ref            string `json:"ref"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteErr(w, r, http.StatusBadRequest, "invalid json")
		return
	}
	cred := strings.TrimSpace(body.Credential)
	authCode := strings.TrimSpace(body.ServerAuthCode)

	var identity *oauthIdentity
	var err error
	switch {
	case cred != "":
		identity, err = h.verifyGoogleIDToken(r.Context(), cred)
	case authCode != "":
		identity, err = h.exchangeGoogleServerAuthCode(r.Context(), authCode)
	default:
		WriteErr(w, r, http.StatusBadRequest, "credential required")
		return
	}
	if err != nil {
		log.Printf("[oauth] google native login verify/exchange failed: %v", err)
		WriteErr(w, r, http.StatusUnauthorized, "invalid google credential")
		return
	}

	var referredBy *uuid.UUID
	if refRaw := strings.TrimSpace(body.Ref); refRaw != "" {
		if id, parseErr := uuid.Parse(refRaw); parseErr == nil {
			referredBy = &id
		}
	}
	u, _, err := store.FindOrCreateOAuthUser(
		r.Context(),
		h.Pool,
		"google",
		identity.Subject,
		identity.Email,
		identity.Name,
		referredBy,
	)
	if err != nil {
		log.Printf("[oauth] find/create user failed: %v", err)
		WriteErr(w, r, http.StatusInternalServerError, "oauth user create failed")
		return
	}
	accessToken, refreshToken, expiresIn, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "oauth session failed")
		return
	}
	redirect := strings.TrimSpace(body.Redirect)
	if redirect == "" {
		redirect = "/games"
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"expires_in":    expiresIn,
		"redirect":      redirect,
		"user":          userToResponse(u),
	})
}

func (h *AuthHandler) verifyGoogleIDToken(ctx context.Context, idToken string) (*oauthIdentity, error) {
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		"https://oauth2.googleapis.com/tokeninfo?id_token="+url.QueryEscape(idToken),
		nil,
	)
	if err != nil {
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("tokeninfo: %s", string(raw))
	}
	var info struct {
		Aud           string `json:"aud"`
		Sub           string `json:"sub"`
		Email         string `json:"email"`
		EmailVerified string `json:"email_verified"`
		Name          string `json:"name"`
	}
	if err := json.Unmarshal(raw, &info); err != nil {
		return nil, err
	}
	if info.Sub == "" {
		return nil, fmt.Errorf("empty sub")
	}
	if info.Aud != h.OAuth.GoogleClientID {
		return nil, fmt.Errorf("aud mismatch")
	}
	if info.EmailVerified != "true" && info.EmailVerified != "1" {
		// tokeninfo иногда отдаёт bool как строку; пустой email тоже допустим редко
		if info.Email != "" && info.EmailVerified == "false" {
			return nil, fmt.Errorf("email not verified")
		}
	}
	return &oauthIdentity{
		Subject: info.Sub,
		Email:   info.Email,
		Name:    info.Name,
	}, nil
}

func (h *AuthHandler) OAuthStart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.OAuth == nil {
		WriteErr(w, r, http.StatusServiceUnavailable, "oauth not configured")
		return
	}
	provider := oauthProviderFromPath(r.URL.Path)
	if provider == "" || !containsStr(h.OAuth.EnabledProviders(), provider) {
		WriteErr(w, r, http.StatusNotFound, "oauth provider not available")
		return
	}

	redirect := strings.TrimSpace(r.URL.Query().Get("redirect"))
	if redirect == "" {
		redirect = "/games"
	}
	ref := strings.TrimSpace(r.URL.Query().Get("ref"))
	state, err := h.OAuth.putState(provider, redirect, ref)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}

	authURL, err := h.oauthAuthorizeURL(provider, state)
	if err != nil {
		WriteErr(w, r, http.StatusInternalServerError, "server error")
		return
	}
	modePoll := strings.EqualFold(strings.TrimSpace(r.URL.Query().Get("mode")), "poll")
	navigate := strings.TrimSpace(r.URL.Query().Get("navigate")) == "1"
	// mode=poll&navigate=1 — браузерный редирект (cookie для poll без state в query).
	if modePoll && navigate {
		http.SetCookie(w, &http.Cookie{
			Name:     "oauth_pending_state",
			Value:    state,
			Path:     "/",
			MaxAge:   600,
			HttpOnly: true,
			Secure:   strings.HasPrefix(strings.ToLower(h.OAuth.PublicBaseURL), "https://"),
			SameSite: http.SameSiteLaxMode,
		})
		http.Redirect(w, r, authURL, http.StatusFound)
		return
	}
	// mode=poll — JSON: клиент открывает authorize_url и ждёт /oauth/poll.
	if modePoll {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"authorize_url": authURL,
			"state":         state,
		})
		return
	}
	http.Redirect(w, r, authURL, http.StatusFound)
}

func (h *AuthHandler) OAuthPoll(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.OAuth == nil {
		WriteErr(w, r, http.StatusServiceUnavailable, "oauth not configured")
		return
	}
	state := strings.TrimSpace(r.URL.Query().Get("state"))
	if state == "" {
		if c, err := r.Cookie("oauth_pending_state"); err == nil {
			state = strings.TrimSpace(c.Value)
		}
	}
	if state == "" {
		WriteErr(w, r, http.StatusBadRequest, "state required")
		return
	}
	res, ok := h.OAuth.takeResult(state)
	if !ok {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusAccepted)
		_ = json.NewEncoder(w).Encode(map[string]any{"status": "pending"})
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name:     "oauth_pending_state",
		Value:    "",
		Path:     "/",
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   h.OAuth != nil && strings.HasPrefix(strings.ToLower(h.OAuth.PublicBaseURL), "https://"),
		SameSite: http.SameSiteLaxMode,
	})
	w.Header().Set("Content-Type", "application/json")
	if res.Error != "" {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"status": "error",
			"error":  res.Error,
		})
		return
	}
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":        "ok",
		"access_token":  res.AccessToken,
		"refresh_token": res.RefreshToken,
		"redirect":      res.Redirect,
	})
}

func (h *AuthHandler) OAuthCallback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodPost {
		WriteErr(w, r, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if h.OAuth == nil {
		WriteErr(w, r, http.StatusServiceUnavailable, "oauth not configured")
		return
	}
	provider := oauthProviderFromPath(r.URL.Path)
	if provider == "" {
		WriteErr(w, r, http.StatusNotFound, "not found")
		return
	}

	state := r.URL.Query().Get("state")
	if state == "" && r.Method == http.MethodPost {
		_ = r.ParseForm()
		state = r.FormValue("state")
	}

	if errMsg := r.URL.Query().Get("error"); errMsg != "" {
		if state != "" {
			h.OAuth.putResult(state, oauthResult{Error: "oauth denied: " + errMsg})
		}
		h.oauthDonePage(w, r, state, "oauth denied: "+errMsg)
		return
	}

	st, ok := h.OAuth.takeState(state)
	if !ok || st.Provider != provider {
		WriteErr(w, r, http.StatusBadRequest, "invalid oauth state")
		return
	}

	code := r.URL.Query().Get("code")
	if code == "" && r.Method == http.MethodPost {
		code = r.FormValue("code")
	}
	if code == "" {
		h.OAuth.putResult(state, oauthResult{Error: "oauth code required", Redirect: st.Redirect})
		h.oauthDonePage(w, r, state, "oauth code required")
		return
	}

	identity, err := h.oauthExchange(r.Context(), provider, code)
	if err != nil {
		log.Printf("[oauth] %s exchange failed: %v", provider, err)
		h.OAuth.putResult(state, oauthResult{Error: "oauth exchange failed", Redirect: st.Redirect})
		h.oauthDonePage(w, r, state, "oauth exchange failed")
		return
	}

	var referredBy *uuid.UUID
	if refRaw := strings.TrimSpace(st.Ref); refRaw != "" {
		if id, parseErr := uuid.Parse(refRaw); parseErr == nil {
			referredBy = &id
		}
	}

	u, created, err := store.FindOrCreateOAuthUser(
		r.Context(),
		h.Pool,
		provider,
		identity.Subject,
		identity.Email,
		identity.Name,
		referredBy,
	)
	if err != nil {
		log.Printf("[oauth] find/create user failed: %v", err)
		h.OAuth.putResult(state, oauthResult{Error: "oauth user create failed", Redirect: st.Redirect})
		h.oauthDonePage(w, r, state, "oauth user create failed")
		return
	}
	_ = created

	accessToken, refreshToken, _, err := h.issueSessionTokens(r.Context(), u)
	if err != nil {
		h.OAuth.putResult(state, oauthResult{Error: "oauth session failed", Redirect: st.Redirect})
		h.oauthDonePage(w, r, state, "oauth session failed")
		return
	}

	h.OAuth.putResult(state, oauthResult{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		Redirect:     st.Redirect,
	})
	// PWA: oauth_done → /login?oauth=1&state=… → poll забирает токены.
	h.oauthDonePage(w, r, state, "")
}

func (h *AuthHandler) oauthDonePage(w http.ResponseWriter, r *http.Request, state, errMsg string) {
	front := ""
	if h.OAuth != nil {
		front = strings.TrimRight(h.OAuth.FrontendURL, "/")
		if front == "" {
			front = strings.TrimRight(h.OAuth.PublicBaseURL, "/")
		}
	}
	if front == "" {
		if errMsg != "" {
			WriteErr(w, r, http.StatusBadRequest, errMsg)
			return
		}
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		_, _ = w.Write([]byte("OK — вернитесь в приложение"))
		return
	}
	q := url.Values{}
	if errMsg != "" {
		q.Set("error", errMsg)
	}
	if s := strings.TrimSpace(state); s != "" {
		q.Set("state", s)
	}
	dest := front + "/oauth_done.html"
	if enc := q.Encode(); enc != "" {
		dest += "?" + enc
	}
	http.Redirect(w, r, dest, http.StatusFound)
}

type oauthIdentity struct {
	Subject string
	Email   string
	Name    string
}

func (h *AuthHandler) oauthAuthorizeURL(provider, state string) (string, error) {
	cb := h.OAuth.callbackURL(provider)
	switch provider {
	case "google":
		q := url.Values{}
		q.Set("client_id", h.OAuth.GoogleClientID)
		q.Set("redirect_uri", cb)
		q.Set("response_type", "code")
		q.Set("scope", "openid email profile")
		q.Set("state", state)
		q.Set("access_type", "online")
		q.Set("prompt", "select_account")
		return "https://accounts.google.com/o/oauth2/v2/auth?" + q.Encode(), nil
	case "apple":
		q := url.Values{}
		q.Set("client_id", h.OAuth.AppleClientID)
		q.Set("redirect_uri", cb)
		q.Set("response_type", "code")
		q.Set("response_mode", "form_post")
		q.Set("scope", "name email")
		q.Set("state", state)
		return "https://appleid.apple.com/auth/authorize?" + q.Encode(), nil
	case "yandex":
		q := url.Values{}
		q.Set("client_id", h.OAuth.YandexClientID)
		q.Set("redirect_uri", cb)
		q.Set("response_type", "code")
		q.Set("state", state)
		return "https://oauth.yandex.ru/authorize?" + q.Encode(), nil
	case "vk":
		q := url.Values{}
		q.Set("client_id", h.OAuth.VKClientID)
		q.Set("redirect_uri", cb)
		q.Set("response_type", "code")
		q.Set("scope", "email")
		q.Set("state", state)
		q.Set("v", "5.199")
		return "https://oauth.vk.com/authorize?" + q.Encode(), nil
	default:
		return "", fmt.Errorf("unknown provider")
	}
}

func (h *AuthHandler) oauthExchange(ctx context.Context, provider, code string) (*oauthIdentity, error) {
	switch provider {
	case "google":
		return h.exchangeGoogle(ctx, code)
	case "apple":
		return h.exchangeApple(ctx, code)
	case "yandex":
		return h.exchangeYandex(ctx, code)
	case "vk":
		return h.exchangeVK(ctx, code)
	default:
		return nil, fmt.Errorf("unknown provider")
	}
}

func (h *AuthHandler) exchangeGoogle(ctx context.Context, code string) (*oauthIdentity, error) {
	form := url.Values{}
	form.Set("code", code)
	form.Set("client_id", h.OAuth.GoogleClientID)
	form.Set("client_secret", h.OAuth.GoogleClientSecret)
	form.Set("redirect_uri", h.OAuth.callbackURL("google"))
	form.Set("grant_type", "authorization_code")
	return h.exchangeGoogleForm(ctx, form)
}

// exchangeGoogleServerAuthCode — код из Android GoogleSignIn.requestServerAuthCode.
// Для mobile server auth code redirect_uri должен быть пустой строкой.
func (h *AuthHandler) exchangeGoogleServerAuthCode(ctx context.Context, code string) (*oauthIdentity, error) {
	if strings.TrimSpace(h.OAuth.GoogleClientSecret) == "" {
		return nil, fmt.Errorf("google client secret not configured")
	}
	form := url.Values{}
	form.Set("code", code)
	form.Set("client_id", h.OAuth.GoogleClientID)
	form.Set("client_secret", h.OAuth.GoogleClientSecret)
	form.Set("redirect_uri", "")
	form.Set("grant_type", "authorization_code")
	return h.exchangeGoogleForm(ctx, form)
}

func (h *AuthHandler) exchangeGoogleForm(ctx context.Context, form url.Values) (*oauthIdentity, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://oauth2.googleapis.com/token", strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("google token: %s", string(body))
	}
	var tok struct {
		AccessToken string `json:"access_token"`
		IDToken     string `json:"id_token"`
	}
	if err := json.Unmarshal(body, &tok); err != nil {
		return nil, err
	}
	if tok.IDToken != "" {
		if id, err := h.verifyGoogleIDToken(ctx, tok.IDToken); err == nil {
			return id, nil
		}
	}
	if tok.AccessToken == "" {
		return nil, fmt.Errorf("google token: empty access_token")
	}

	ureq, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://openidconnect.googleapis.com/v1/userinfo", nil)
	if err != nil {
		return nil, err
	}
	ureq.Header.Set("Authorization", "Bearer "+tok.AccessToken)
	uresp, err := http.DefaultClient.Do(ureq)
	if err != nil {
		return nil, err
	}
	defer uresp.Body.Close()
	ubody, _ := io.ReadAll(uresp.Body)
	if uresp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("google userinfo: %s", string(ubody))
	}
	var info struct {
		Sub   string `json:"sub"`
		Email string `json:"email"`
		Name  string `json:"name"`
	}
	if err := json.Unmarshal(ubody, &info); err != nil {
		return nil, err
	}
	if info.Sub == "" {
		return nil, fmt.Errorf("google: empty sub")
	}
	return &oauthIdentity{Subject: info.Sub, Email: info.Email, Name: info.Name}, nil
}

func (h *AuthHandler) exchangeApple(ctx context.Context, code string) (*oauthIdentity, error) {
	clientSecret, err := h.appleClientSecret()
	if err != nil {
		return nil, err
	}
	form := url.Values{}
	form.Set("code", code)
	form.Set("client_id", h.OAuth.AppleClientID)
	form.Set("client_secret", clientSecret)
	form.Set("redirect_uri", h.OAuth.callbackURL("apple"))
	form.Set("grant_type", "authorization_code")

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://appleid.apple.com/auth/token", strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("apple token: %s", string(body))
	}
	var tok struct {
		IDToken string `json:"id_token"`
	}
	if err := json.Unmarshal(body, &tok); err != nil {
		return nil, err
	}
	claims, err := parseUnverifiedJWTClaims(tok.IDToken)
	if err != nil {
		return nil, err
	}
	sub, _ := claims["sub"].(string)
	email, _ := claims["email"].(string)
	if sub == "" {
		return nil, fmt.Errorf("apple: empty sub")
	}
	return &oauthIdentity{Subject: sub, Email: email}, nil
}

func (h *AuthHandler) appleClientSecret() (string, error) {
	block, _ := pem.Decode([]byte(h.OAuth.ApplePrivateKey))
	if block == nil {
		// Попробуем как одну строку с \n
		key := strings.ReplaceAll(h.OAuth.ApplePrivateKey, `\n`, "\n")
		block, _ = pem.Decode([]byte(key))
	}
	if block == nil {
		return "", fmt.Errorf("apple private key: invalid PEM")
	}
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return "", err
	}
	ecdsaKey, ok := key.(*ecdsa.PrivateKey)
	if !ok {
		return "", fmt.Errorf("apple private key: not ECDSA")
	}
	now := time.Now()
	token := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
		"iss": h.OAuth.AppleTeamID,
		"iat": now.Unix(),
		"exp": now.Add(5 * time.Minute).Unix(),
		"aud": "https://appleid.apple.com",
		"sub": h.OAuth.AppleClientID,
	})
	token.Header["kid"] = h.OAuth.AppleKeyID
	return token.SignedString(ecdsaKey)
}

func (h *AuthHandler) exchangeYandex(ctx context.Context, code string) (*oauthIdentity, error) {
	form := url.Values{}
	form.Set("grant_type", "authorization_code")
	form.Set("code", code)
	form.Set("client_id", h.OAuth.YandexClientID)
	form.Set("client_secret", h.OAuth.YandexClientSecret)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://oauth.yandex.ru/token", strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("yandex token: %s", string(body))
	}
	var tok struct {
		AccessToken string `json:"access_token"`
	}
	if err := json.Unmarshal(body, &tok); err != nil {
		return nil, err
	}

	ureq, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://login.yandex.ru/info?format=json", nil)
	if err != nil {
		return nil, err
	}
	ureq.Header.Set("Authorization", "OAuth "+tok.AccessToken)
	uresp, err := http.DefaultClient.Do(ureq)
	if err != nil {
		return nil, err
	}
	defer uresp.Body.Close()
	ubody, _ := io.ReadAll(uresp.Body)
	if uresp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("yandex info: %s", string(ubody))
	}
	var info struct {
		ID           string `json:"id"`
		DefaultEmail string `json:"default_email"`
		Login        string `json:"login"`
		DisplayName  string `json:"display_name"`
		RealName     string `json:"real_name"`
	}
	if err := json.Unmarshal(ubody, &info); err != nil {
		return nil, err
	}
	if info.ID == "" {
		return nil, fmt.Errorf("yandex: empty id")
	}
	name := info.DisplayName
	if name == "" {
		name = info.RealName
	}
	if name == "" {
		name = info.Login
	}
	return &oauthIdentity{Subject: info.ID, Email: info.DefaultEmail, Name: name}, nil
}

func (h *AuthHandler) exchangeVK(ctx context.Context, code string) (*oauthIdentity, error) {
	q := url.Values{}
	q.Set("client_id", h.OAuth.VKClientID)
	q.Set("client_secret", h.OAuth.VKClientSecret)
	q.Set("redirect_uri", h.OAuth.callbackURL("vk"))
	q.Set("code", code)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://oauth.vk.com/access_token?"+q.Encode(), nil)
	if err != nil {
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("vk token: %s", string(body))
	}
	var tok struct {
		AccessToken string `json:"access_token"`
		UserID      int64  `json:"user_id"`
		Email       string `json:"email"`
		Error       string `json:"error"`
	}
	if err := json.Unmarshal(body, &tok); err != nil {
		return nil, err
	}
	if tok.Error != "" || tok.UserID == 0 {
		return nil, fmt.Errorf("vk token: %s", string(body))
	}
	sub := fmt.Sprintf("%d", tok.UserID)

	name := ""
	uq := url.Values{}
	uq.Set("access_token", tok.AccessToken)
	uq.Set("v", "5.199")
	uq.Set("fields", "first_name,last_name")
	uq.Set("user_ids", sub)
	ureq, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.vk.com/method/users.get?"+uq.Encode(), nil)
	if err == nil {
		uresp, err := http.DefaultClient.Do(ureq)
		if err == nil {
			defer uresp.Body.Close()
			ubody, _ := io.ReadAll(uresp.Body)
			var info struct {
				Response []struct {
					FirstName string `json:"first_name"`
					LastName  string `json:"last_name"`
				} `json:"response"`
			}
			if json.Unmarshal(ubody, &info) == nil && len(info.Response) > 0 {
				name = strings.TrimSpace(info.Response[0].FirstName + " " + info.Response[0].LastName)
			}
		}
	}

	return &oauthIdentity{Subject: sub, Email: tok.Email, Name: name}, nil
}

func oauthProviderFromPath(path string) string {
	// /api/auth/oauth/{provider}/start|callback
	parts := strings.Split(strings.Trim(path, "/"), "/")
	for i, p := range parts {
		if p == "oauth" && i+1 < len(parts) {
			return strings.ToLower(parts[i+1])
		}
	}
	return ""
}

func containsStr(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

func parseUnverifiedJWTClaims(token string) (map[string]any, error) {
	parts := strings.Split(token, ".")
	if len(parts) < 2 {
		return nil, fmt.Errorf("invalid jwt")
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		// padded
		payload, err = base64.URLEncoding.DecodeString(parts[1])
		if err != nil {
			return nil, err
		}
	}
	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		return nil, err
	}
	return claims, nil
}
