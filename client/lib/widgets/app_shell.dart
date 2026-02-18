import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

/// Одна анимация 0→1: сначала исчезает старый контент, потом появляется новый.
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

class _RouteTransitionWrapperState extends State<_RouteTransitionWrapper>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 400);

  late AnimationController _controller;
  Widget _displayedChild = const SizedBox.shrink();
  Widget? _outgoingChild;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _duration, vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _displayedChild = widget.child;
          _outgoingChild = null;
        });
      }
    });
    _displayedChild = widget.child;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RouteTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_normalizePath(oldWidget.path) != _normalizePath(widget.path)) {
      setState(() => _outgoingChild = _displayedChild);
      _controller.forward(from: 0);
    } else if (_outgoingChild == null && !_controller.isAnimating) {
      _displayedChild = widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_outgoingChild == null) {
      return _displayedChild;
    }
    final t = _controller.value;
    final outOpacity = t <= 0.5 ? 1.0 - (t * 2) : 0.0;
    final inOpacity = t <= 0.5 ? 0.0 : (t - 0.5) * 2;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: outOpacity.clamp(0.0, 1.0),
            child: _outgoingChild,
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: inOpacity.clamp(0.0, 1.0),
            child: widget.child,
          ),
        ),
      ],
    );
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
    final isHome = path == '/' || path.isEmpty;
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
            Expanded(
              child: narrow
                  ? _RouteTransitionWrapper(child: child, path: path)
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
                          child: _RouteTransitionWrapper(child: child, path: path),
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
