import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

const List<_NavItem> _navItems = [
  _NavItem(path: '/', icon: Icons.home, label: 'Главная'),
  _NavItem(path: '/profile', icon: Icons.person, label: 'Профиль'),
  _NavItem(path: '/friends', icon: Icons.people, label: 'Друзья'),
  _NavItem(path: '/chats', icon: Icons.chat_bubble_outline_rounded, label: 'Чаты'),
  _NavItem(path: '/games', icon: Icons.sports_esports, label: 'Игры'),
  _NavItem(path: '/settings', icon: Icons.settings, label: 'Настройки'),
];

int _selectedIndexForPath(String path) {
  final n = _normalizePath(path);
  if (n.startsWith('/chats')) {
    return _navItems.indexWhere((e) => e.path == '/chats');
  }
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
    final unreadChats = ref.watch(chatsUnreadCountProvider).valueOrNull ?? 0;
    final incomingFriends = ref.watch(friendsIncomingCountProvider).valueOrNull ?? 0;
    final media = MediaQuery.of(context);
    final padding = media.padding;
    final narrow = isNarrow(context);
    final keyboardLikelyVisible =
        narrow && (media.viewInsets.bottom > 0 || media.size.height < 500);
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
                                  onPressed: () => context.go('/admin'),
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
                          onPressed: () => context.go('/login'),
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
                        onPressed: () => context.go('/login'),
                        tooltip: 'Войти',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: narrow
                  ? SizedBox.expand(child: child)
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
                                    icon: _navIcon(e, unreadChats, incomingFriends),
                                    label: Text(e.label),
                                  ))
                              .toList(),
                        ),
                        Expanded(
                          child: SizedBox.expand(child: child),
                        ),
                      ],
                    ),
            ),
            if (narrow && !keyboardLikelyVisible)
              SafeArea(
                top: false,
                child: Material(
                  type: MaterialType.transparency,
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (i) => context.go(_navItems[i].path),
                    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                    height: 64,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    destinations: _navItems
                        .map((e) => NavigationDestination(
                              icon: _navIcon(e, unreadChats, incomingFriends),
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

Widget _navIcon(_NavItem item, int unreadChats, int incomingFriends) {
  var badgeValue = 0;
  if (item.path == '/chats') {
    badgeValue = unreadChats;
  } else if (item.path == '/friends') {
    badgeValue = incomingFriends;
  }

  if (badgeValue <= 0) {
    return Icon(item.icon);
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(item.icon),
      Positioned(
        right: -10,
        top: -8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badgeValue > 99 ? '99+' : '$badgeValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}
