import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/apple_native_sign_in.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/google_native_sign_in.dart';
import 'package:multigames_client/auth/system_auth_session.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/gamepad/gamepad_auth.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/widgets/oauth_redirect.dart';

/// Текст ошибки входа: не прячем причину за общей фразой.
String readableOauthError(Object error, String fallback) {
  if (error is AuthException) {
    final message = error.message.trim();
    return message.isEmpty ? fallback : message;
  }
  if (error is AppleSignInUnavailableException) {
    final message = error.message.trim();
    if (message.isEmpty || message == 'Sign in with Apple is not available') {
      return fallback;
    }
    return message;
  }
  if (error is SystemAuthSessionException) {
    final message = error.message.trim();
    return message.isEmpty ? fallback : message;
  }
  if (error is PlatformException) {
    final message = (error.message ?? '').trim();
    if (message.isNotEmpty) return message;
    final code = error.code.trim();
    if (code.isNotEmpty) return code;
  }
  final raw = error.toString().trim();
  if (raw.isEmpty || raw == 'null') return fallback;
  return raw;
}

/// Android: Google Sign-In аккаунта устройства. На iOS — системный лист,
/// потому что без iOS OAuth client плагин google_sign_in падает сразу.
bool get _useNativeGoogleSignIn =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get _useNativeAppleSignIn =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// iOS: Apple всегда первой (Guideline 4.8), даже если сервер её не отдал.
/// Android: Google всегда в списке. Иначе после вылета, таймаута или офлайна
/// /api/auth/oauth/providers кнопка пропадает и остаётся только пароль.
List<String> visibleOAuthProviders(
  List<String> fromServer, {
  required bool isIos,
  bool isAndroid = false,
}) {
  final seen = <String>{};
  final out = <String>[];
  if (isIos) {
    out.add('apple');
    seen.add('apple');
  } else if (isAndroid) {
    out.add('google');
    seen.add('google');
  }
  for (final provider in fromServer) {
    if (seen.add(provider)) out.add(provider);
  }
  return out;
}

final oauthProvidersProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final first = await repo.fetchOAuthProviders();
  if (first.isNotEmpty) return first;
  // Пустой список — и «OAuth выключен», и проглоченная ошибка сети.
  // Сразу после вылета первый запрос часто не успевает. Один повтор.
  return repo.fetchOAuthProviders();
});

const _cookiePendingSentinel = 'cookie';

class OAuthButtons extends ConsumerStatefulWidget {
  const OAuthButtons({
    super.key,
    this.redirect,
    this.refCode,
  });

  final String? redirect;
  final String? refCode;

  @override
  ConsumerState<OAuthButtons> createState() => _OAuthButtonsState();
}

class _OAuthButtonsState extends ConsumerState<OAuthButtons>
    with WidgetsBindingObserver {
  String? _busyProvider;
  String? _pollingState;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await hydrateOAuthPendingState();
      if (mounted) await _resumePending();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showAuthMessage(
    String message, {
    AppSnackKind kind = AppSnackKind.error,
    Duration duration = const Duration(seconds: 6),
  }) {
    if (!mounted) return;
    final text = message.trim();
    if (text.isEmpty) return;
    showAppSnackBar(context, message: text, kind: kind, duration: duration);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retryOAuthProvidersIfEmpty();
      // ignore: discarded_futures
      () async {
        await hydrateOAuthPendingState();
        if (mounted) await _resumePending();
      }();
    }
  }

  /// Сеть после вылета часто оживает только на следующем открытии.
  void _retryOAuthProvidersIfEmpty() {
    final async = ref.read(oauthProvidersProvider);
    if (async.isLoading) return;
    final providers = async.asData?.value;
    if (async.hasError || providers == null || providers.isEmpty) {
      ref.invalidate(oauthProvidersProvider);
    }
  }

  Future<void> _resumePending() async {
    if (_busyProvider != null || _resuming) return;
    final q = GoRouterState.of(context).uri.queryParameters;
    final fromQuery = (q['state'] ?? '').trim();
    final oauthQuery = q.containsKey('oauth');
    final pending = readOAuthPendingState();
    if (!oauthQuery &&
        fromQuery.isEmpty &&
        (pending == null || pending.isEmpty)) {
      return;
    }

    String state = fromQuery;
    if (state.isEmpty &&
        pending != null &&
        pending.isNotEmpty &&
        pending != _cookiePendingSentinel) {
      state = pending;
    }

    _resuming = true;
    try {
      await _finishPoll(context, state, providerLabel: 'google');
    } finally {
      _resuming = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(oauthProvidersProvider);
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final fromServer = async.asData?.value ?? const <String>[];
    // Сайт ждёт ответ сервера: чужие кнопки не показываем.
    // Телефон показывает Apple/Google сразу, даже если список ещё грузится
    // или запрос упал в пустой кэш.
    if (!isIos && !isAndroid && !async.hasValue) {
      return const SizedBox.shrink();
    }
    final shown = visibleOAuthProviders(
      fromServer,
      isIos: isIos,
      isAndroid: isAndroid,
    );
    if (shown.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final repo = ref.read(authRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.oauthOrContinue,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            GamepadActionBlock(
              outlined: true,
              radius: AppRadius.button,
              onActivate: _busyProvider != null
                  ? () {}
                  : () => _startProvider(context, shown[i], repo),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  style: AppButtonStyles.of(
                    minimumSize: const Size(double.infinity, 48),
                    maximumSize: const Size(double.infinity, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _busyProvider != null
                      ? null
                      : () => _startProvider(context, shown[i], repo),
                  child: _busyProvider == shown[i]
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _label(l10n, shown[i]),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startProvider(
    BuildContext context,
    String provider,
    AuthRepository repo,
  ) {
    if (kIsWeb) {
      if (isStandalonePwa) {
        _startStandalonePwaOAuth(provider, repo);
      } else {
        _startWebNavigate(provider, repo);
      }
    } else {
      _startNative(context, provider);
    }
  }

  String _label(AppLocalizations l10n, String provider) {
    switch (provider) {
      case 'google':
        return l10n.oauthGoogle;
      case 'apple':
        return l10n.oauthApple;
      case 'yandex':
        return l10n.oauthYandex;
      case 'vk':
        return l10n.oauthVK;
      default:
        return provider;
    }
  }

  /// Установленная PWA: state в storage до ухода в Safari, oauth_done не грузит Flutter.
  void _startStandalonePwaOAuth(String provider, AuthRepository repo) {
    setState(() => _busyProvider = provider);
    final startUrl = repo.oauthStartUrl(
      provider: provider,
      redirect: widget.redirect,
      ref: widget.refCode,
      poll: true,
      pwa: true,
    );
    final started = fetchOAuthPollStartSync(startUrl);
    if (started != null) {
      saveOAuthPendingState(started.state);
      _showAuthMessage(
        'Завершите вход и вернитесь в Zozu Games с экрана «Домой»',
        kind: AppSnackKind.info,
        duration: const Duration(seconds: 8),
      );
      openOAuthExternal(started.authorizeUrl);
      return;
    }
    saveOAuthPendingState(_cookiePendingSentinel);
    openOAuthExternal(
      repo.oauthStartUrl(
        provider: provider,
        redirect: widget.redirect,
        ref: widget.refCode,
        poll: true,
        navigate: true,
        pwa: true,
      ),
    );
  }

  /// Web (не PWA): сразу redirect на провайдера в той же вкладке.
  void _startWebNavigate(String provider, AuthRepository repo) {
    saveOAuthPendingState(_cookiePendingSentinel);
    setState(() => _busyProvider = provider);
    final href = repo.oauthStartUrl(
      provider: provider,
      redirect: widget.redirect,
      ref: widget.refCode,
      poll: true,
      navigate: true,
    );
    openOAuthExternal(href);
  }

  Future<void> _startNative(BuildContext context, String provider) async {
    if (provider == 'apple' && _useNativeAppleSignIn) {
      await _startNativeApple();
      return;
    }
    if (provider == 'google' && defaultTargetPlatform == TargetPlatform.iOS) {
      await _startIosGoogleSheet();
      return;
    }
    if (provider == 'google' && _useNativeGoogleSignIn) {
      await _startNativeGoogle();
      return;
    }
    await _startNativeBrowserPoll(provider);
  }

  /// iOS: лист Google (аккаунт Safari), без ухода на сайт.
  Future<void> _startIosGoogleSheet() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final redirect = widget.redirect;
    setState(() => _busyProvider = 'google');
    try {
      final scheme = oauthAppReturnScheme;
      final started = await ref.read(authRepositoryProvider).startOAuthPoll(
            provider: 'google',
            redirect: redirect,
            ref: widget.refCode,
            returnScheme: scheme,
          );
      if (!mounted) return;
      saveOAuthPendingState(started.state);
      _pollingState = started.state;
      var userCanceled = false;
      Object? sessionError;
      unawaited(startSystemAuthSession(
        url: started.authorizeUrl,
        callbackScheme: scheme,
      ).then((ok) {
        userCanceled = !ok;
      }, onError: (Object error, StackTrace _) {
        sessionError = error;
        userCanceled = true;
      }));
      final Map<String, String> result;
      try {
        result = await ref.read(authRepositoryProvider).pollOAuthResult(
              state: started.state,
              isCanceled: () => userCanceled,
            );
      } on OauthCanceledException {
        clearOAuthPendingState();
        _pollingState = null;
        final err = sessionError;
        if (err != null && mounted) {
          _showAuthMessage(readableOauthError(err, l10n.oauthError));
        }
        return;
      }
      await cancelSystemAuthSession();
      clearOAuthPendingState();
      _pollingState = null;
      if (!mounted) return;
      final access = (result['access_token'] ?? '').trim();
      final refresh = (result['refresh_token'] ?? '').trim();
      if (access.isEmpty || refresh.isEmpty) {
        _showAuthMessage(l10n.oauthError);
        return;
      }
      await ref.read(authStateProvider.notifier).loginWithTokens(
            accessToken: access,
            refreshToken: refresh,
          );
      if (!mounted) return;
      final dest = safeAuthRedirect(result['redirect']) ??
          safeAuthRedirect(redirect) ??
          '/games';
      context.go(dest);
    } on AuthException catch (e) {
      await cancelSystemAuthSession();
      clearOAuthPendingState();
      _pollingState = null;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } on SystemAuthSessionException catch (e) {
      await cancelSystemAuthSession();
      clearOAuthPendingState();
      _pollingState = null;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } catch (e) {
      debugPrint('iOS Google sheet failed: $e');
      await cancelSystemAuthSession();
      clearOAuthPendingState();
      _pollingState = null;
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } finally {
      if (mounted && _busyProvider == 'google') {
        setState(() => _busyProvider = null);
      }
    }
  }

  /// iOS: системный лист Apple ID (Настройки → Apple ID), без Safari.
  Future<void> _startNativeApple() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final redirect = widget.redirect;
    setState(() => _busyProvider = 'apple');
    try {
      final native = await signInWithAppleNative();
      if (native == null) return;
      if (!mounted) return;
      await ref
          .read(authStateProvider.notifier)
          .loginWithAppleIdToken(
            identityToken: native.identityToken,
            email: native.email,
            givenName: native.givenName,
            familyName: native.familyName,
            redirect: redirect,
            ref: widget.refCode,
          )
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      final dest = safeAuthRedirect(redirect) ?? '/games';
      context.go(dest);
    } on TimeoutException {
      if (!mounted) return;
      _showAuthMessage(l10n.oauthError);
    } on AppleSignInUnavailableException catch (e) {
      debugPrint('Sign in with Apple unavailable: $e');
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } on AuthException catch (e) {
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } catch (e) {
      debugPrint('Sign in with Apple failed: $e');
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } finally {
      if (mounted && _busyProvider == 'apple') {
        setState(() => _busyProvider = null);
      }
    }
  }

  /// Google на Android: только нативный Sign-In (без браузера).
  /// На iOS Google идёт через системный лист, не через этот плагин.
  Future<void> _startNativeGoogle() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final redirect = widget.redirect;
    setState(() => _busyProvider = 'google');
    try {
      final info =
          await ref.read(authRepositoryProvider).fetchOAuthProvidersInfo();
      final clientId = (info.googleClientId ?? '').trim();
      if (clientId.isEmpty) {
        if (!mounted) return;
        _showAuthMessage(l10n.oauthError);
        return;
      }

      final native = await signInWithGoogleNative(serverClientId: clientId);
      if (native == null) {
        // Пользователь закрыл picker.
        return;
      }
      if (!mounted) return;
      await ref
          .read(authStateProvider.notifier)
          .loginWithGoogleIdToken(
            credential: native.idToken ?? '',
            serverAuthCode: native.serverAuthCode,
            redirect: redirect,
            ref: widget.refCode,
          )
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      final dest = safeAuthRedirect(redirect) ?? '/games';
      context.go(dest);
    } on TimeoutException {
      if (!mounted) return;
      _showAuthMessage(l10n.oauthError);
    } on GoogleSignInDeveloperErrorException catch (e) {
      // Код 10: нужен Android OAuth client + SHA-1 App signing в Google Cloud.
      debugPrint('Google DEVELOPER_ERROR: $e');
      if (!mounted) return;
      _showAuthMessage(e.message, duration: const Duration(seconds: 12));
    } on GoogleIdTokenMissingException catch (e) {
      debugPrint('Google native credential missing: $e');
      if (!mounted) return;
      _showAuthMessage(
        defaultTargetPlatform == TargetPlatform.iOS
            ? e.message
            : 'Google Sign-In: нет id_token. Добавь SHA-1 App signing '
                'в Google Cloud → Android OAuth client '
                '(com.zozugames.app / .dev).',
        duration: const Duration(seconds: 12),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } catch (e) {
      debugPrint('Google native sign-in failed: $e');
      if (!mounted) return;
      if (isGoogleDeveloperError(e)) {
        _showAuthMessage(
          GoogleSignInDeveloperErrorException().message,
          duration: const Duration(seconds: 12),
        );
        return;
      }
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } finally {
      if (mounted && _busyProvider == 'google') {
        setState(() => _busyProvider = null);
      }
    }
  }

  /// Остальные провайдеры: внешний браузер + poll.
  Future<void> _startNativeBrowserPoll(
    String provider, {
    bool blockUntilDone = true,
  }) async {
    if (!mounted) return;
    final l10n = context.l10n;
    final popup = openOAuthWindowBlank();
    setState(() => _busyProvider = provider);
    try {
      final started = await ref.read(authRepositoryProvider).startOAuthPoll(
            provider: provider,
            redirect: widget.redirect,
            ref: widget.refCode,
          );
      saveOAuthPendingState(started.state);
      _pollingState = started.state;
      navigateOAuthWindow(popup, started.authorizeUrl);
      if (!mounted) return;
      if (!blockUntilDone) {
        // Лоадер снимем в finally; poll добьёт _resumePending при resume.
        return;
      }
      await _finishPoll(context, started.state, providerLabel: provider);
    } on AuthException catch (e) {
      closeOAuthWindow(popup);
      clearOAuthPendingState();
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } catch (e) {
      closeOAuthWindow(popup);
      clearOAuthPendingState();
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  Future<void> _finishPoll(
    BuildContext context,
    String state, {
    required String providerLabel,
  }) async {
    if (_pollingState == state &&
        state.isNotEmpty &&
        _busyProvider != null &&
        _busyProvider != providerLabel) {
      return;
    }
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final redirect = widget.redirect;
    setState(() => _busyProvider ??= providerLabel);
    try {
      final result = await ref.read(authRepositoryProvider).pollOAuthResult(
            state: state,
          );
      clearOAuthPendingState();
      _pollingState = null;
      if (!mounted) return;
      final access = (result['access_token'] ?? '').trim();
      final refresh = (result['refresh_token'] ?? '').trim();
      if (access.isEmpty || refresh.isEmpty) {
        _showAuthMessage(l10n.oauthError);
        return;
      }
      await ref.read(authStateProvider.notifier).loginWithTokens(
            accessToken: access,
            refreshToken: refresh,
          );
      if (!mounted) return;
      final dest = safeAuthRedirect(result['redirect']) ??
          safeAuthRedirect(redirect) ??
          '/games';
      router.go(dest);
    } on AuthException catch (e) {
      clearOAuthPendingState();
      _pollingState = null;
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } catch (e) {
      clearOAuthPendingState();
      _pollingState = null;
      if (!mounted) return;
      _showAuthMessage(readableOauthError(e, l10n.oauthError));
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }
}
