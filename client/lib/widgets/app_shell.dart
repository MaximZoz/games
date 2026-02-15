import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';

/// Общий тулбар для всех экранов. На главной — только иконка «Войти»;
/// на /login и /register — иконка «домик» (на главную).
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Текущий путь из контекста, чтобы тулбар обновлялся при переходе на /login или /register
    final path = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authStateProvider);
    final isHome = path == '/' || path.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.go('/'),
          child: const Text('MultiGames'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isHome)
            authState.when(
              data: (user) {
                if (user != null) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          user.displayName ?? user.email,
                          style: const TextStyle(fontSize: 14),
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
      body: child,
    );
  }
}
