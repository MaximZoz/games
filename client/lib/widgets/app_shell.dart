import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';

/// Синхронный переход на вкладку «Игры» по уже известному active (без сети).
void _goGamesTab(BuildContext context, String currentPath, ActiveGameItem? active) {
  if (active != null &&
      active.type == 'game' &&
      active.gameId != null &&
      active.gameId!.isNotEmpty) {
    final dest = '/games/tictactoe/game/${active.gameId}';
    if (currentPath == dest) return;
    context.go(dest);
    return;
  }
  if (active != null &&
      active.type == 'lobby' &&
      active.lobbyId != null &&
      active.lobbyId!.isNotEmpty) {
    final dest = '/games/tictactoe/lobby/${active.lobbyId}';
    if (currentPath == dest) return;
    context.go(dest);
    return;
  }
  if (currentPath != '/games') {
    context.go('/games');
  }
}

const List<_NavItem> _navItems = [
  _NavItem(path: '/', icon: Icons.home, label: 'Главная'),
  _NavItem(path: '/profile', icon: Icons.person, label: 'Профиль'),
  _NavItem(path: '/friends', icon: Icons.people, label: 'Друзья'),
  _NavItem(
      path: '/chats', icon: Icons.chat_bubble_outline_rounded, label: 'Чаты'),
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
    final gameNavigation = ref.read(gameNavigationCoordinatorProvider);
    final authState = ref.watch(authStateProvider);
    final isAuthorized = authState.valueOrNull != null;
    // Явно держим realtime WebSocket активным (меню, чаты, друзья, presence)
    if (isAuthorized) {
      ref.watch(realtimeEventsProvider);
      ref.watch(presenceMapProvider);
      ref.watch(chatDeliveryAckProvider);
      // Лениво подтягиваем конфиг игр из БД после входа/старта.
      ref.watch(userGameSettingsProvider);
      // Бейджи подарков: live WS + синхронизация из непрочитанных чатов.
      ref.watch(giftedCollectionsBadgeSyncProvider);
      ref.listen(realtimeEventsProvider, (_, next) {
        next.whenData((event) {
          final type = event['type'];
          if (type == 'game_started' || type == 'lobby_updated') {
            final router = GoRouter.of(context);
            final gameId = realtimeGameIdForNavigation(
              event,
              currentPath: router.routerDelegate.currentConfiguration.uri.path,
            );
            if (context.mounted) {
              navigateToGame(router, gameNavigation, gameId);
            }
          }
          if (type == 'daily_reward_available' ||
              type == 'daily_reward_claimed') {
            final available = event['available'] == true;
            ref.read(dailyRewardFromRealtimeProvider.notifier).state =
                available;
            ref.invalidate(dailyRewardStatusProvider);
            ref.invalidate(dailyRewardAvailableProvider);
          }
        });
      });
    }
    final unreadChats = ref.watch(chatsUnreadCountProvider);
    final incomingFriends = ref.watch(friendsIncomingCountProvider);
    final gamesMyTurn = ref.watch(gamesMyTurnCountProvider);
    final gameInvitesCount = ref.watch(gameInvitesCountProvider);
    final dailyRewardAsync = ref.watch(dailyRewardAvailableProvider);
    final dailyRewardCount = dailyRewardAsync.valueOrNull == true ? 1 : 0;
    final achievementsUnclaimed =
        ref.watch(achievementsUnclaimedCountProvider).valueOrNull ?? 0;
    final collectionIncomeAvailable =
        ref.watch(collectionIncomeAvailableProvider);
    final unreadGiftedCollections =
        ref.watch(unreadGiftedCollectionsCountProvider);
    // На «Главной» суммируем daily + достижения + доход + подарки коллекций.
    final homeBadgeCount = dailyRewardCount +
        achievementsUnclaimed +
        (collectionIncomeAvailable ? 1 : 0) +
        unreadGiftedCollections;
    final media = MediaQuery.of(context);
    final padding = media.padding;
    final narrow = isNarrow(context);
    final isLandscape = media.size.width > media.size.height;
    final narrowLandscape = narrow && isLandscape;
    final inChatRoom = path.startsWith('/chats/');
    final onChatsList = path == '/chats';
    final onFriends = path == '/friends';
    final onAuthScreen = path == '/login' || path == '/register';
    final toolbarLeading = ref.watch(mobileToolbarLeadingProvider);
    Future.microtask(() {
      if (!context.mounted) return;
      try {
        ref.read(currentRoutePathProvider.notifier).state = path;
        final shouldClearToolbar =
            !onFriends && !onChatsList && !(inChatRoom && narrowLandscape);
        if (shouldClearToolbar) {
          ref.read(mobileToolbarLeadingProvider.notifier).state = null;
        }
      } catch (_) {
        // Игнорируем: виджет мог быть disposed (defunct element)
      }
    });
    // Не убираем bottom nav из дерева при клавиатуре: на iOS Safari
    // dispose nav → сброс фокуса TextField. Вместо этого схлопываем
    // heightFactor=0 (поиск друзей и т.п.).
    final collapseBottomNav = ref.watch(collapseMobileBottomNavProvider);
    final selectedIndex = navigationShell.currentIndex;
    final showBottomNav =
        narrow && !narrowLandscape && !inChatRoom && !onAuthScreen;

    void navigateWithPrefetch(int i) {
      final target = _navItems[i].path;

      // «Главная» → карточки «Достижения» и «Монеты» (корень ветки).
      if (target == '/') {
        Router.neglect(context, () {
          navigationShell.goBranch(0, initialLocation: true);
          context.go('/');
        });
        return;
      }

      // Повторный тап по «Профиль» — выйти из редактирования.
      if (target == '/profile') {
        ref.read(profileExitEditTickProvider.notifier).state++;
      }

      // «Друзья» → корень вкладки + сброс поиска / таб «Друзья».
      if (target == '/friends') {
        ref.read(friendsNavTapTickProvider.notifier).state++;
      }

      // Сначала мгновенно меняем вкладку — без ожидания сети.
      // Не пишем в browser history (Safari back не прыгает по табам).
      if (target == '/games' && isAuthorized) {
        final currentPath = path;
        final cachedActive = ref.read(activeGameProvider).valueOrNull;
        Router.neglect(context, () {
          _goGamesTab(context, currentPath, cachedActive);
        });
        // Фон: обновить active/чаты для бейджей. Без повторного go —
        // иначе гонка с мгновенным leave из лобби.
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        unawaited(() async {
          try {
            ref.invalidate(activeGameProvider);
            await ref.read(activeGameProvider.future);
          } catch (_) {}
        }());
        return;
      }

      // Профиль: всегда /profile — иначе после логина ветка восстанавливает /login.
      Router.neglect(context, () {
        navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex ||
              target == '/profile',
        );
      });

      if (!isAuthorized) return;
      // Prefetch вкладок только после перехода, строго в фоне.
      if (target == '/chats') {
        unawaited(
          ref.read(chatsListProvider.future).then((_) {}, onError: (_, __) {}),
        );
        unawaited(
          ref
              .read(blockedUsersProvider.future)
              .then((_) {}, onError: (_, __) {}),
        );
      } else if (target == '/friends') {
        unawaited(
          ref
              .read(friendsSnapshotProvider.future)
              .then((_) {}, onError: (_, __) {}),
        );
      }
    }

    final shellBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: padding.top),
          child: SizedBox(
            height: kToolbarHeight,
            child: ClipRect(
              child: Row(
                children: [
                  if ((narrow && (onFriends || onChatsList) ||
                          (narrowLandscape && inChatRoom)) &&
                      toolbarLeading != null)
                    narrowLandscape && inChatRoom
                        ? Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: toolbarLeading,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: toolbarLeading,
                          )
                  else if (isAuthorized)
                    Flexible(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: authState.when(
                          data: (user) => user != null
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ToolbarBalanceChip(
                                      bronze: user.balanceBronze,
                                      coinSize: 16,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: authState.when(
                        data: (user) {
                          if (user != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.isAdmin)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.admin_panel_settings),
                                    onPressed: () => context.go('/admin'),
                                    tooltip: 'Админка',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                Flexible(
                                  child: Tooltip(
                                    message: user.displayName ?? user.email,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Text(
                                        user.displayName ?? user.email,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.none,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () async {
                                    await ref
                                        .read(authStateProvider.notifier)
                                        .logout();
                                  },
                                  tooltip: 'Выйти',
                                  visualDensity: VisualDensity.compact,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: narrow && !narrowLandscape
              ? SizedBox.expand(child: navigationShell)
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: navigateWithPrefetch,
                      backgroundColor: Colors.transparent,
                      selectedIconTheme:
                          const IconThemeData(color: AppColors.accentStart),
                      unselectedIconTheme:
                          const IconThemeData(color: AppColors.textSecondary),
                      labelType: narrowLandscape
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      destinations: _navItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return NavigationRailDestination(
                          icon: _navIcon(
                            item,
                            unreadChats,
                            incomingFriends,
                            gamesMyTurn,
                            gameInvitesCount,
                            homeBadgeCount,
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
      ],
    );

    // bottomNavigationBar — чтобы ScaffoldMessenger ставил SnackBar над меню
    // (раньше nav был в Column, тост рисовался у низа экрана и обрезался).
    //
    // iPhone (скруглённый экран + home indicator): фон панели должен идти
    // full-bleed до физического низа. Если красить только зону иконок, под
    // ней виден другой цвет — и из‑за скругления углов панель кажется
    // «закруглённой таблеткой». Иконки/подписи — над viewPadding, цвет — под ним.
    //
    // Scaffold обнуляет padding.bottom у bottomNavigationBar — поэтому inset
    // берём из viewPadding, а не из SafeArea(padding).
    final bottomInset = media.viewPadding.bottom;
    final bottomNav = showBottomNav
        ? ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: collapseBottomNav ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: collapseBottomNav,
                child: ColoredBox(
                  color: AppColors.surfaceUnified,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MediaQuery.withNoTextScaling(
                        child: _MobileBottomNav(
                          key: const ValueKey('mobile-bottom-nav'),
                          selectedIndex: selectedIndex,
                          onTap: navigateWithPrefetch,
                          unreadChats: unreadChats,
                          incomingFriends: incomingFriends,
                          gamesMyTurn: gamesMyTurn,
                          gameInvitesCount: gameInvitesCount,
                          homeBadgeCount: homeBadgeCount,
                        ),
                      ),
                      // Заливка под home indicator — до скруглённых углов.
                      SizedBox(height: bottomInset),
                    ],
                  ),
                ),
              ),
            ),
          )
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: GradientBackground(
            cloudIntensity: 0.7,
            child: SizedBox.expand(),
          ),
        ),
        // Свой Messenger: SnackBar привязан к этому Scaffold с bottom nav,
        // а не к корневому на весь экран.
        ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: shellBody,
            bottomNavigationBar: bottomNav,
          ),
        ),
      ],
    );
  }
}

/// Нижняя панель: только иконки + одна подпись по центру с двумя линиями.
class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.unreadChats,
    required this.incomingFriends,
    required this.gamesMyTurn,
    required this.gameInvitesCount,
    required this.homeBadgeCount,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int unreadChats;
  final int incomingFriends;
  final int gamesMyTurn;
  final int gameInvitesCount;
  final int homeBadgeCount;

  @override
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex.clamp(0, _navItems.length - 1);
    final label = _navItems[safeIndex].label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < _navItems.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: _navIcon(
                          _navItems[i],
                          unreadChats,
                          incomingFriends,
                          gamesMyTurn,
                          gameInvitesCount,
                          homeBadgeCount,
                          selected: i == safeIndex,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Симметричная подпись: линия — текст — линия (фиолет. как иконка).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Row(
              key: ValueKey(label),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Чуть выше центра строки — visually на уровне середины букв.
                Transform.translate(
                  offset: const Offset(0, -1),
                  child: _captionHairline(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: AppColors.accentStart,
                      height: 1.0,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -1),
                  child: _captionHairline(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _captionHairline() {
    return Container(
      width: 33, // ×1.5 от прежних 22
      height: 1.5,
      decoration: BoxDecoration(
        color: AppColors.accentStart.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

Widget _navIcon(
  _NavItem item,
  int unreadChats,
  int incomingFriends,
  int gamesMyTurn,
  int gameInvitesCount,
  int homeBadgeCount, {
  bool selected = false,
}) {
  final iconColor = selected ? AppColors.accentStart : AppColors.textSecondary;
  final iconSize = selected ? 24.0 : 22.0;
  // Без рамки/заливки у активного — только цвет иконки.
  final baseIcon = Icon(item.icon, color: iconColor, size: iconSize);

  var badgeValue = 0;
  if (item.path == '/chats') {
    badgeValue = unreadChats;
  } else if (item.path == '/friends') {
    badgeValue = incomingFriends;
  } else if (item.path == '/games') {
    badgeValue = gamesMyTurn + gameInvitesCount;
  } else if (item.path == '/') {
    badgeValue = homeBadgeCount;
  }

  if (badgeValue <= 0) {
    return baseIcon;
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      baseIcon,
      Positioned(
        right: -6,
        top: -4,
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
