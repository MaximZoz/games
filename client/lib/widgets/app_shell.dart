import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
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

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.label});
  final String path;
  final IconData icon;
  final String label;
}

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authStateProvider);
    final isAuthorized = authState.valueOrNull != null;
    // Явно держим realtime WebSocket активным для бейджей (чаты, друзья)
    if (isAuthorized) {
      ref.watch(realtimeEventsProvider);
    }
    final unreadChats = ref.watch(chatsUnreadCountProvider);
    final incomingFriends = ref.watch(friendsIncomingCountProvider);
    final media = MediaQuery.of(context);
    final padding = media.padding;
    final narrow = isNarrow(context);
    final inChatRoom = path.startsWith('/chats/');
    final keyboardLikelyVisible =
        narrow && (media.viewInsets.bottom > 0 || media.size.height < 500);
    final selectedIndex = navigationShell.currentIndex;

    void navigateWithPrefetch(int i) {
      final target = _navItems[i].path;
      context.go(target);

      if (!isAuthorized) return;
      if (target == '/chats') {
        unawaited(
          ref.read(chatsListProvider.future).then((_) {}, onError: (_, __) {}),
        );
        unawaited(
          ref.read(blockedUsersProvider.future).then((_) {}, onError: (_, __) {}),
        );
      } else if (target == '/friends') {
        unawaited(
          ref.read(friendsSnapshotProvider.future).then((_) {}, onError: (_, __) {}),
        );
      }
    }

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
                  ? SizedBox.expand(child: navigationShell)
                  : Row(
                      children: [
                        NavigationRail(
                          selectedIndex: selectedIndex,
                          onDestinationSelected: navigateWithPrefetch,
                          backgroundColor: Colors.transparent,
                          selectedIconTheme: const IconThemeData(color: AppColors.accentStart),
                          unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
                          labelType: NavigationRailLabelType.all,
                          destinations: _navItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return NavigationRailDestination(
                              icon: _navIcon(
                                item,
                                unreadChats,
                                incomingFriends,
                                selected: index == selectedIndex,
                              ),
                              label: Text(item.label),
                            );
                          }).toList(),
                        ),
                        Expanded(
                          child: SizedBox.expand(child: navigationShell),
                        ),
                      ],
                    ),
            ),
            if (narrow && !keyboardLikelyVisible && !inChatRoom)
              SafeArea(
                top: false,
                child: Material(
                  type: MaterialType.transparency,
                  child: MediaQuery.withNoTextScaling(
                    child: BottomNavigationBar(
                      currentIndex: selectedIndex,
                      onTap: navigateWithPrefetch,
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      selectedItemColor: AppColors.textPrimary,
                      unselectedItemColor: AppColors.textSecondary,
                      selectedFontSize: 10,
                      unselectedFontSize: 10,
                      showUnselectedLabels: true,
                      items: _navItems.asMap().entries.map((entry) {
                        final item = entry.value;
                        return BottomNavigationBarItem(
                          icon: _navIcon(item, unreadChats, incomingFriends),
                          activeIcon: _navIcon(
                            item,
                            unreadChats,
                            incomingFriends,
                            selected: true,
                          ),
                          label: item.label,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _navIcon(
  _NavItem item,
  int unreadChats,
  int incomingFriends, {
  bool selected = false,
}) {
  final iconColor = selected ? AppColors.accentStart : AppColors.textSecondary;
  final iconSize = selected ? 25.0 : 22.0;
  final baseIcon = Container(
    padding: const EdgeInsets.all(5),
    decoration: selected
        ? BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accentStart.withValues(alpha: 0.35)),
          )
        : null,
    child: Icon(item.icon, color: iconColor, size: iconSize),
  );

  var badgeValue = 0;
  if (item.path == '/chats') {
    badgeValue = unreadChats;
  } else if (item.path == '/friends') {
    badgeValue = incomingFriends;
  }

  if (badgeValue <= 0) {
    return baseIcon;
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      baseIcon,
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
