import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/widgets/oauth_redirect.dart';

class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
  }

  Future<void> _finish() async {
    final q = GoRouterState.of(context).uri.queryParameters;
    final params = <String, String>{
      for (final e in q.entries) e.key: e.value,
    };
    // Popup PWA: отдать токены opener и закрыться (без навигации в Safari-оболочке).
    if (completeOAuthPopup(params)) {
      return;
    }
    final err = q['error'];
    if (err != null && err.isNotEmpty) {
      setState(() => _error = err);
      return;
    }
    final access = q['access_token'] ?? '';
    final refresh = q['refresh_token'] ?? '';
    final redirect = safeAuthRedirect(q['redirect']) ?? '/games';
    if (access.isEmpty || refresh.isEmpty) {
      setState(() => _error = context.l10n.oauthError);
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).loginWithTokens(
            accessToken: access,
            refreshToken: refresh,
          );
      if (mounted) context.go(redirect);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.oauthError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GradientCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      l10n.oauthCallbackTitle,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ] else ...[
                    MessageBanner(message: _error!, type: BannerType.error),
                    const SizedBox(height: 16),
                    AppButton(
                      onPressed: () => context.go('/login'),
                      label: l10n.loginSubmit,
                      expanded: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
