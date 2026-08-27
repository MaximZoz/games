import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/google_native_sign_in.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/widgets/oauth_redirect.dart';

/// Android/iOS: Google Sign-In (аккаунт устройства / Play Store).
bool get _useNativeGoogleSignIn =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

final oauthProvidersProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(authRepositoryProvider).fetchOAuthProviders();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ignore: discarded_futures
      () async {
        await hydrateOAuthPendingState();
        if (mounted) await _resumePending();
      }();
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
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (providers) {
        if (providers.isEmpty) return const SizedBox.shrink();
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
              for (var i = 0; i < providers.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      maximumSize: const Size(double.infinity, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.accentSoft),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _busyProvider != null
                        ? null
                        : () {
                            final p = providers[i];
                            if (kIsWeb) {
                              _startWebNavigate(p, repo);
                            } else {
                              _startNative(context, p);
                            }
                          },
                    child: _busyProvider == providers[i]
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _label(l10n, providers[i]),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
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

  /// Web: сразу redirect на провайдера в той же вкладке, без промежуточной кнопки.
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
    if (provider == 'google' && _useNativeGoogleSignIn) {
      await _startNativeGoogle();
      return;
    }
    await _startNativeBrowserPoll(provider);
  }

  /// Google: системный аккаунт (тот же, что в Play Market) → id_token → API.
  Future<void> _startNativeGoogle() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final redirect = widget.redirect;
    setState(() => _busyProvider = 'google');
    try {
      final info =
          await ref.read(authRepositoryProvider).fetchOAuthProvidersInfo();
      final clientId = (info.googleClientId ?? '').trim();
      if (clientId.isEmpty) {
        if (!mounted) return;
        setState(() => _busyProvider = null);
        await _startNativeBrowserPoll('google');
        return;
      }

      final native = await signInWithGoogleNative(serverClientId: clientId);
      if (native == null) {
        // Пользователь закрыл picker.
        return;
      }
      if (!mounted) return;
      await ref.read(authStateProvider.notifier).loginWithGoogleIdToken(
            credential: native.idToken ?? '',
            serverAuthCode: native.serverAuthCode,
            redirect: redirect,
            ref: widget.refCode,
          );
      if (!mounted) return;
      final dest = safeAuthRedirect(redirect) ?? '/games';
      context.go(dest);
    } on GoogleIdTokenMissingException catch (e) {
      // Пикер прошёл, но id_token пуст — типичный SHA-1 / GCP misconfig.
      // Сразу браузерный OAuth, без «тихого» обрыва.
      debugPrint('Google native id_token missing, fallback to browser: $e');
      if (!mounted) return;
      setState(() => _busyProvider = null);
      await _startNativeBrowserPoll('google');
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('Google native sign-in failed: $e');
      if (!mounted) return;
      setState(() => _busyProvider = null);
      messenger.showSnackBar(SnackBar(content: Text(l10n.oauthError)));
      await _startNativeBrowserPoll('google');
    } finally {
      if (mounted && _busyProvider == 'google') {
        setState(() => _busyProvider = null);
      }
    }
  }

  /// Остальные провайдеры (и Google fallback): внешний браузер + poll.
  Future<void> _startNativeBrowserPoll(String provider) async {
    if (!mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
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
      await _finishPoll(context, started.state, providerLabel: provider);
    } on AuthException catch (e) {
      closeOAuthWindow(popup);
      clearOAuthPendingState();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      closeOAuthWindow(popup);
      clearOAuthPendingState();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.oauthError)));
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
    final messenger = ScaffoldMessenger.of(context);
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
        messenger.showSnackBar(SnackBar(content: Text(l10n.oauthError)));
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
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      clearOAuthPendingState();
      _pollingState = null;
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.oauthError)));
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }
}
