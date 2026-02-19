import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

/// Старый экран убирается сразу, новый появляется через 100 ms.
class _RouteTransitionWrapper extends StatefulWidget {
  const _RouteTransitionWrapper({
    required this.child,
    required this.path,
  });

  final Widget child;
  final String path;

  @override
  State<_RouteTransitionWrapper> createState() => _RouteTransitionWrapperState();
}

class _RouteTransitionWrapperState extends State<_RouteTransitionWrapper> {
  static const _delay = Duration(milliseconds: 100);

  Widget _displayedChild = const SizedBox.shrink();
  bool _isTransitioning = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _displayedChild = widget.child;
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RouteTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_normalizePath(oldWidget.path) != _normalizePath(widget.path)) {
      _delayTimer?.cancel();
      setState(() => _isTransitioning = true);
      _delayTimer = Timer(_delay, () {
        _delayTimer = null;
        if (mounted) {
          setState(() {
            _displayedChild = widget.child;
            _isTransitioning = false;
          });
        }
      });
    } else if (!_isTransitioning) {
      _displayedChild = widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTransitioning) return _displayedChild;
    return const SizedBox.shrink();
  }
}

const List<_NavItem> _navItems = [
  _NavItem(path: '/', icon: Icons.home, label: 'Главная'),
  _NavItem(path: '/profile', icon: Icons.person, label: 'Профиль'),
  _NavItem(path: '/friends', icon: Icons.people, label: 'Друзья'),
  _NavItem(path: '/games', icon: Icons.sports_esports, label: 'Игры'),
  _NavItem(path: '/settings', icon: Icons.settings, label: 'Настройки'),
];

int _selectedIndexForPath(String path) {
  final n = _normalizePath(path);
  final i = _navItems.indexWhere((e) => e.path == n);
  if (i >= 0) return i;
  if (n == '/achievements' || n == '/coins') return 1;
  return 0;
}

String _normalizePath(String path) {
  return path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
}

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.label});
  final String path;
  final IconData icon;
  final String label;
}

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
    final padding = MediaQuery.of(context).padding;
    final narrow = isNarrow(context);
    final selectedIndex = _selectedIndexForPath(path);

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
                        key: Key('toolbar_title'),
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
                                padding: const EdgeInsets.only(right: 4),
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
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: narrow
                  ? SizedBox.expand(
                      child: _RouteTransitionWrapper(path: path, child: child),
                    )
                  : Row(
                      children: [
                        NavigationRail(
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (i) => context.go(_navItems[i].path),
                          backgroundColor: Colors.transparent,
                          selectedIconTheme: const IconThemeData(color: AppColors.accentStart),
                          unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
                          labelType: NavigationRailLabelType.all,
                          destinations: _navItems
                              .map((e) => NavigationRailDestination(
                                    icon: Icon(e.icon),
                                    label: Text(e.label),
                                  ))
                              .toList(),
                        ),
                        Expanded(
                          child: SizedBox.expand(
                            child: _RouteTransitionWrapper(path: path, child: child),
                          ),
                        ),
                      ],
                    ),
            ),
            if (narrow)
              SafeArea(
                top: false,
                child: Material(
                  type: MaterialType.transparency,
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (i) => context.go(_navItems[i].path),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    destinations: _navItems
                        .map((e) => NavigationDestination(
                              icon: Icon(e.icon),
                              label: e.label,
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
