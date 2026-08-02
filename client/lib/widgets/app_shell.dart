import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/offline_warmup.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/push_notification_nav_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/push_notification_nav_web.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/brand_accent_hairline.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';
import 'package:multigames_client/shop/pending_purchases.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/admin/admin_provider.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

bool _activeGameUsable(ActiveGameItem? active) {
  if (active == null) return false;
  if (active.type == 'game') {
    return active.gameId != null && active.gameId!.trim().isNotEmpty;
  }
  if (active.type == 'lobby') {
    return active.lobbyId != null && active.lobbyId!.trim().isNotEmpty;
  }
  return false;
}

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

List<_NavItem> _navItems(BuildContext context, {required bool offline}) {
  final l10n = context.l10n;
  final all = [
    _NavItem(branchIndex: 0, path: '/', icon: Icons.home, label: l10n.navHome),
    _NavItem(
      branchIndex: 1,
      path: '/profile',
      icon: Icons.person,
      label: l10n.navProfile,
    ),
    _NavItem(
      branchIndex: 2,
      path: '/friends',
      icon: Icons.people,
      label: l10n.navFriends,
    ),
    _NavItem(
      branchIndex: 3,
      path: '/chats',
      icon: Icons.chat_bubble_outline_rounded,
      label: l10n.navChats,
    ),
    _NavItem(
      branchIndex: 4,
      path: '/games',
      icon: Icons.sports_esports,
      label: l10n.navGames,
    ),
    _NavItem(
      branchIndex: 5,
      path: '/settings',
      icon: Icons.settings,
      label: l10n.navSettings,
    ),
  ];
  if (!offline) return all;
  return all
      .where((e) => e.path != '/friends' && e.path != '/chats')
      .toList(growable: false);
}

class _NavItem {
  const _NavItem({
    required this.branchIndex,
    required this.path,
    required this.icon,
    required this.label,
  });
  final int branchIndex;
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
    final isOffline = ref.watch(isOfflineProvider);
    // Очередь покупок: при выходе в онлайн — flush + тосты результата.
    ref.watch(pendingPurchasesProvider);
    ref.listen<PendingPurchaseFlushNotice?>(
      pendingPurchaseFlushNoticeProvider,
      (prev, next) {
        if (next == null || next.isEmpty) return;
        final l10n = context.l10n;
        final lines = <String>[
          for (final a in next.applied) l10n.shopPurchaseApplied(a.title),
          for (final f in next.failed)
            l10n.shopPurchaseRejected(
              f.title,
              (f.reason ?? '').trim().isEmpty
                  ? l10n.commonGenericError
                  : f.reason!.trim(),
            ),
        ];
        final kind = next.failed.isEmpty
            ? AppSnackKind.success
            : (next.applied.isEmpty ? AppSnackKind.error : AppSnackKind.info);
        showAppSnackBar(
          context,
          message: lines.join('\n'),
          kind: kind,
          duration: Duration(seconds: (4 + lines.length).clamp(4, 10)),
        );
        // Сбрасываем, чтобы то же событие не показалось повторно.
        ref.read(pendingPurchaseFlushNoticeProvider.notifier).state = null;
      },
    );
    // Данные и ассеты для офлайна: держим в памяти + прогрев при онлайне.
    if (isAuthorized) {
      ref.watch(offlineWarmupProvider);
      ref.watch(shopCatalogProvider);
      ref.watch(inventoryListProvider);
      ref.watch(inventoryCapabilitiesProvider);
      ref.watch(userGameSettingsProvider);
      ref.watch(achievementsListProvider);
      ref.watch(collectionIncomeProvider);
      ref.watch(dailyRewardStatusProvider);
    }
    // Явно держим realtime WebSocket активным (меню, чаты, друзья, presence)
    if (isAuthorized && !isOffline) {
      ref.watch(realtimeEventsProvider);
      ref.watch(presenceMapProvider);
      ref.watch(chatDeliveryAckProvider);
      // Бейджи подарков: live WS + синхронизация из непрочитанных чатов.
      ref.watch(giftedCollectionsBadgeSyncProvider);
      // iOS PWA: после рестарта/смены SW заново привязываем Web Push.
      ref.listen(authStateProvider, (prev, next) {
        if (next.valueOrNull != null && prev?.valueOrNull == null) {
          unawaited(
            ref.read(webPushEnabledProvider.notifier).ensureActiveSubscription(),
          );
        }
      });
      ref.listen<bool>(webPushEnabledProvider, (prev, next) {
        if (next == true && prev != true) {
          unawaited(
            ref.read(webPushEnabledProvider.notifier).ensureActiveSubscription(),
          );
        }
      });
      // Уже залогинен при первом кадре shell — тоже rebind.
      if (authState.valueOrNull != null) {
        unawaited(
          ref.read(webPushEnabledProvider.notifier).ensureActiveSubscription(),
        );
      }
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
          if (type == 'support_message') {
            ref.invalidate(supportChatsProvider);
          }
          if (type == 'coins_granted') {
            final amount = (event['amount'] as num?)?.toInt() ?? 0;
            final balance = (event['balance'] as num?)?.toInt();
            final reason = (event['reason'] as String?)?.trim() ?? '';
            final l10n = context.l10n;
            final title = amount >= 0
                ? l10n.coinsGrantedTitle(amount)
                : l10n.coinsDeductedTitle(amount.abs());
            final message =
                reason.isEmpty ? title : '$title\n$reason';
            if (context.mounted) {
              showAppSnackBar(
                context,
                message: message,
                kind: amount >= 0 ? AppSnackKind.success : AppSnackKind.info,
                duration: Duration(seconds: reason.isEmpty ? 4 : 6),
                icon: Icons.monetization_on_rounded,
              );
            }
            if (balance != null && context.mounted) {
              if (amount > 0) {
                unawaited(playBalanceGain(
                  ref: ref,
                  context: context,
                  newBalanceBronze: balance,
                  rewardBronze: amount,
                ));
              } else {
                unawaited(
                  ref.read(authStateProvider.notifier).applyBalance(balance),
                );
              }
            }
          }
        });
      });
      // Держим подписку на обновления inbox поддержки для админ-бейджа.
      if (authState.valueOrNull?.isAdmin == true) {
        ref.watch(supportInboxRealtimeProvider);
      }
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
    // Как и для нижней панели: Scaffold может обнулять padding — для
    // челки/status bar берём viewPadding, чтобы цвет шёл full-bleed.
    final topInset = media.viewPadding.top;
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
        // SW глушит пуш про уже открытый чат/матч (особенно iOS PWA).
        reportPushSwActiveRoute(path);
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
    final showBottomNav =
        narrow && !narrowLandscape && !inChatRoom && !onAuthScreen;

    final navItems = _navItems(context, offline: isOffline);
    final selectedIndex = () {
      final i = navItems.indexWhere(
        (e) => e.branchIndex == navigationShell.currentIndex,
      );
      return i < 0 ? 0 : i;
    }();

    void navigateWithPrefetch(int i) {
      final item = navItems[i];
      final target = item.path;
      final branch = item.branchIndex;

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

      // «Друзья»: при входящих заявках с другой вкладки — сразу «Входящие».
      if (target == '/friends') {
        final incoming = ref.read(friendsIncomingCountProvider);
        final alreadyOnFriends = branch == navigationShell.currentIndex;
        if (!alreadyOnFriends && incoming > 0) {
          Router.neglect(context, () {
            context.go('/friends?tab=incoming');
          });
          unawaited(
            ref
                .read(friendsSnapshotProvider.future)
                .then((_) {}, onError: (_, __) {}),
          );
          return;
        }
        ref.read(friendsNavTapTickProvider.notifier).state++;
      }

      // Сначала мгновенно меняем вкладку — без ожидания сети.
      // Не пишем в browser history (Safari back не прыгает по табам).
      if (target == '/games' && isAuthorized) {
        final currentPath = path;
        if (isOffline) {
          Router.neglect(context, () {
            if (currentPath != '/games' &&
                !currentPath.startsWith('/games/tictactoe/offline')) {
              context.go('/games');
            } else {
              navigationShell.goBranch(branch, initialLocation: true);
            }
          });
          return;
        }
        final activeNotifier = ref.read(activeGameProvider.notifier);
        final epochAtTap = activeNotifier.epoch;
        final cachedActive = ref.read(activeGameProvider).valueOrNull;
        final cacheUsable = _activeGameUsable(cachedActive);
        Router.neglect(context, () {
          _goGamesTab(context, currentPath, cachedActive);
        });
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        // Если кэш был пуст (создали лобби и ушли в чаты) — после refresh
        // увести в «Своя игра». Epoch отсекает гонку с leaveLobby.
        unawaited(() async {
          try {
            ref.invalidate(activeGameProvider);
            final fresh = await ref.read(activeGameProvider.future);
            if (!context.mounted) return;
            if (ref.read(activeGameProvider.notifier).epoch != epochAtTap) {
              return;
            }
            if (cacheUsable || fresh == null || !_activeGameUsable(fresh)) {
              return;
            }
            final nowPath =
                GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
            if (nowPath != '/games') return;
            Router.neglect(context, () {
              _goGamesTab(context, nowPath, fresh);
            });
          } catch (_) {}
        }());
        return;
      }

      // Профиль: всегда /profile — иначе после логина ветка восстанавливает /login.
      // Чаты: всегда список (не восстанавливать лобби/комнату поверх списка).
      Router.neglect(context, () {
        navigationShell.goBranch(
          branch,
          initialLocation: branch == navigationShell.currentIndex ||
              target == '/profile' ||
              target == '/chats',
        );
      });

      if (!isAuthorized || isOffline) return;
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
        // Одна заливка: status bar (чёлка) + тулбар — тот же цвет, что низ.
        ColoredBox(
          color: AppColors.surfaceUnified,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topInset),
              SizedBox(
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
                          data: (user) {
                            if (user == null) return const SizedBox.shrink();
                            final gain = ref.watch(balanceGainProvider);
                            final bronze =
                                gain.displayBronze ?? user.balanceBronze;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ToolbarBalanceChip(
                                  bronze: bronze,
                                  coinSize: 16,
                                  forceShow: gain.forceShow,
                                  coinKeys: ref.watch(toolbarCoinKeysProvider),
                                ),
                              ),
                            );
                          },
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
                                  _AdminIconWithBadge(
                                    onTap: () => context.go('/admin'),
                                    tooltip: context.l10n.adminTitle,
                                    unreadCount: ref
                                            .watch(supportUnreadTotalProvider)
                                            .valueOrNull ??
                                        0,
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
                                if (isOffline)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cloud_off_rounded,
                                      size: 20,
                                    ),
                                    tooltip: context.l10n.offlineBadgeTooltip,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(
                                            ctx.l10n.offlineModePopupTitle,
                                          ),
                                          content: Text(
                                            ctx.l10n.offlineModePopupBody,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: Text(
                                                ctx.l10n.commonClose,
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                                context.go('/settings');
                                              },
                                              child: Text(
                                                ctx.l10n
                                                    .offlineModePopupSettings,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () async {
                                    await ref
                                        .read(authStateProvider.notifier)
                                        .logout();
                                  },
                                  tooltip: context.l10n.logoutTooltip,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            );
                          }
                          return IconButton(
                            icon: const Icon(Icons.login),
                            onPressed: () => context.go('/login'),
                            tooltip: context.l10n.loginTooltip,
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
                          tooltip: context.l10n.loginTooltip,
                        ),
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ],
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
                      destinations: navItems.asMap().entries.map((entry) {
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
                          offline: isOffline,
                          unreadChats: unreadChats,
                          incomingFriends: incomingFriends,
                          gamesMyTurn: gamesMyTurn,
                          gameInvitesCount: gameInvitesCount,
                          homeBadgeCount: homeBadgeCount,
                          hairlinesOpacity: ref.watch(
                            bootToolbarHairlinesOpacityProvider,
                          ),
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
            // Тот же цвет, что чёлка и низ — без «шва» после splash.
            backgroundColor: AppColors.surfaceUnified,
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
    required this.offline,
    required this.unreadChats,
    required this.incomingFriends,
    required this.gamesMyTurn,
    required this.gameInvitesCount,
    required this.homeBadgeCount,
    this.hairlinesOpacity = 1,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool offline;
  final int unreadChats;
  final int incomingFriends;
  final int gamesMyTurn;
  final int gameInvitesCount;
  final int homeBadgeCount;
  final double hairlinesOpacity;

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems(context, offline: offline);
    final safeIndex = selectedIndex.clamp(0, navItems.length - 1);
    final label = navItems[safeIndex].label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < navItems.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: _navIcon(
                          navItems[i],
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
          // Симметричная подпись: линия — текст — линия (тот же стиль, что splash).
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
                  offset: const Offset(0, -3),
                  child: Opacity(
                    opacity: hairlinesOpacity.clamp(0.0, 1.0),
                    child: const BrandAccentHairline(
                      width: 33,
                      height: 2.5,
                      side: BrandAccentHairlineSide.fadeOutsideLeft,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Padding(
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
                ),
                Transform.translate(
                  offset: const Offset(0, -3),
                  child: Opacity(
                    opacity: hairlinesOpacity.clamp(0.0, 1.0),
                    child: const BrandAccentHairline(
                      width: 33,
                      height: 2.5,
                      side: BrandAccentHairlineSide.fadeOutsideRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    // На табе «Игры» бейдж «мой ход» не нужен — ход уже виден в партии.
    // Приглашения в новую игру оставляем.
    badgeValue = (selected ? 0 : gamesMyTurn) + gameInvitesCount;
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

/// Иконка админки с badge непрочитанных обращений в поддержку.
class _AdminIconWithBadge extends StatelessWidget {
  const _AdminIconWithBadge({
    required this.onTap,
    required this.tooltip,
    required this.unreadCount,
  });

  final VoidCallback onTap;
  final String tooltip;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final icon = IconButton(
      icon: const Icon(Icons.admin_panel_settings),
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
    if (unreadCount <= 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.surfaceCard, width: 1.2),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
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
}
