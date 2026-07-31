import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/widgets/google_gis.dart';
import 'package:multigames_client/widgets/oauth_redirect.dart';

final oauthProvidersProvider =
    FutureProvider<({List<String> providers, String? googleClientId})>((ref) async {
  return ref.watch(authRepositoryProvider).fetchOAuthProvidersInfo();
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
  bool _showStuckHelp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumePending());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumePending();
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
      data: (info) {
        final providers = info.providers;
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
                            if (kIsWeb && p == 'google') {
                              // iOS PWA: GIS открывает ASWebAuthenticationSession →
                              // белый accounts.google.com. Нужен top-level redirect.
                              if (isIosStandalonePwa) {
                                _startIosPwaGoogle(repo);
                              } else {
                                _startGoogleGis(context, info.googleClientId);
                              }
                            } else if (kIsWeb) {
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
              if (_showStuckHelp ||
                  (readOAuthPendingState() ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Если зависли на accounts.google.com / CheckCookie — '
                  'закройте ту вкладку (PWA не может закрыть страницы Google). '
                  'Инкогнито часто ломает вход Google.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resuming
                      ? null
                      : () async {
                          setState(() => _busyProvider ??= 'google');
                          await _resumePending();
                          if (!mounted) return;
                          final user = ref.read(authStateProvider).valueOrNull;
                          if (user != null) {
                            GoRouter.of(context).go('/games');
                          }
                        },
                  child: const Text('Продолжить вход в приложении'),
                ),
                TextButton(
                  onPressed: () {
                    clearOAuthPendingState();
                    setState(() {
                      _showStuckHelp = false;
                      _busyProvider = null;
                    });
                    GoRouter.of(context).go('/games');
                  },
                  child: const Text('Открыть игры'),
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

  /// Desktop/Android web: GIS без ухода из вкладки.
  Future<void> _startGoogleGis(BuildContext context, String? clientId) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final redirect = widget.redirect;
    if (clientId == null || clientId.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.oauthError)));
      return;
    }
    setState(() => _busyProvider = 'google');
    try {
      final cred = await requestGoogleIdToken(clientId);
      if (cred == null || cred.isEmpty) {
        throw AuthException(400, l10n.oauthError);
      }
      final result =
          await ref.read(authRepositoryProvider).loginWithGoogleIdToken(
                credential: cred,
                redirect: redirect,
                ref: widget.refCode,
              );
      if (!mounted) return;
      // Не loginWithTokens: лишний /api/me может «сбросить» сессию при сбое сети.
      ref.read(authStateProvider.notifier).acceptSession(result);
      if (!mounted) return;
      router.go(safeAuthRedirect(redirect) ?? '/games');
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancelled') || msg.contains('cancel')) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.oauthError)));
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  /// iOS PWA: sync state + location.assign (не GIS / не target=_blank).
  void _startIosPwaGoogle(AuthRepository repo) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyProvider = 'google');
    final startUrl = repo.oauthStartUrl(
      provider: 'google',
      redirect: widget.redirect,
      ref: widget.refCode,
      poll: true,
    );
    final started = fetchOAuthPollStartSync(startUrl);
    setState(() => _showStuckHelp = true);
    if (started != null) {
      saveOAuthPendingState(started.state);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Завершите Google и вернитесь в приложение. '
            'Не используйте инкогнито — там зависает CheckCookie.',
          ),
          duration: Duration(seconds: 10),
        ),
      );
      openOAuthExternal(started.authorizeUrl);
      return;
    }
    // Fallback: same-origin navigate=1 → cookie + 302 на Google.
    saveOAuthPendingState(_cookiePendingSentinel);
    openOAuthExternal(
      repo.oauthStartUrl(
        provider: 'google',
        redirect: widget.redirect,
        ref: widget.refCode,
        poll: true,
        navigate: true,
      ),
    );
  }

  /// Web: redirect-flow только для не-Google провайдеров.
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
      await _finishPoll(this.context, started.state, providerLabel: provider);
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
