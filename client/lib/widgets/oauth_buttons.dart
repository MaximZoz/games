import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/widgets/oauth_redirect.dart';

final oauthProvidersProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(authRepositoryProvider).fetchOAuthProviders();
});

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

class _OAuthButtonsState extends ConsumerState<OAuthButtons> {
  String? _busyProvider;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(oauthProvidersProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (providers) {
        if (providers.isEmpty) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
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
              const SizedBox(height: 12),
              for (var i = 0; i < providers.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _busyProvider != null
                        ? null
                        : () => _start(context, providers[i]),
                    child: _busyProvider == providers[i]
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_label(l10n, providers[i])),
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

  Future<void> _start(BuildContext context, String provider) async {
    final l10n = context.l10n;
    setState(() => _busyProvider = provider);
    try {
      final url = ref.read(authRepositoryProvider).oauthStartUrl(
            provider: provider,
            redirect: widget.redirect,
            ref: widget.refCode,
          );
      final result = await openOAuthUrl(url);
      if (!mounted) return;
      // null = полный редирект (ушли со страницы) или пользователь закрыл popup.
      if (result == null) return;

      final err = (result['error'] ?? '').trim();
      if (err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      final access = (result['access_token'] ?? '').trim();
      final refresh = (result['refresh_token'] ?? '').trim();
      if (access.isEmpty || refresh.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.oauthError)),
        );
        return;
      }
      await ref.read(authStateProvider.notifier).loginWithTokens(
            accessToken: access,
            refreshToken: refresh,
          );
      if (!mounted) return;
      final dest = safeAuthRedirect(result['redirect']) ??
          safeAuthRedirect(widget.redirect) ??
          '/games';
      context.go(dest);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oauthError)),
      );
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }
}
