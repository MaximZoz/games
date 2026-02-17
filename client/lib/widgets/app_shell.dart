import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

/// Общий тулбар для всех экранов. Один фон на весь экран (тулбар + контент).
/// Тулбар — своя полоса без Material, чтобы градиент был везде одинаковый.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authStateProvider);
    final isHome = path == '/' || path.isEmpty;
    final padding = MediaQuery.of(context).padding;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: GradientBackground(
            cloudIntensity: 0.7,
            child: SizedBox.expand(),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: padding.top),
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'MultiGames',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isHome)
                      authState.when(
                        data: (user) {
                          if (user != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.admin_panel_settings),
                                    onPressed: () => context.push('/admin'),
                                    tooltip: 'Админка',
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    user.displayName ?? user.email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () async {
                                    await ref.read(authStateProvider.notifier).logout();
                                  },
                                  tooltip: 'Выйти',
                                ),
                              ],
                            );
                          }
                          return IconButton(
                            icon: const Icon(Icons.login),
                            onPressed: () => context.push('/login'),
                            tooltip: 'Войти',
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => IconButton(
                          icon: const Icon(Icons.login),
                          onPressed: () => context.push('/login'),
                          tooltip: 'Войти',
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.home),
                        onPressed: () => context.go('/'),
                        tooltip: 'На главную',
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }
}
