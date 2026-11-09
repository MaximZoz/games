import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/app_update_provider.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_chrome.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_nav.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/offline_warmup.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/core/push_notification_nav_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/push_notification_nav_web.dart'
    if (dart.library.io) 'package:multigames_client/core/push_notification_nav_io.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/live_my_turn.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';
import 'package:multigames_client/screens/profile_edit_back.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_update_dialog.dart';
import 'package:multigames_client/ui/widgets/brand_accent_hairline.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';
import 'package:multigames_client/ui/widgets/keyboard_inset_hud.dart';
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

/// Одноразовый bootstrap в shell (listen без fireImmediately в этой версии Riverpod).
bool _shellDidBootstrapSession = false;

/// Прошлый путь shell — чтобы поймать уход со стола в сообщения во время хода.
String? _lastAwaySfxPath;

String? _gameIdFromPath(String path) => gameIdFromGamePath(path);

/// Для unit-тестов навигации таба «Игры».
bool activeGameUsableForTest(ActiveGameItem? active) => _activeGameUsable(active);

/// Для unit-тестов навигации таба «Игры».
String? gameIdFromPathForTest(String path) => _gameIdFromPath(path);

/// Синхронный переход на вкладку «Игры» по уже известному active (без сети).
/// Active game/lobby — всегда туда. Observation только карточкой в списке.
/// Офлайн-партию возвращаем по [lastSessionPath], чтобы таб не сбрасывал стол.
void _goGamesTab(
  BuildContext context,
  String currentPath,
  ActiveGameItem? active, {
  String? pinnedLiveGameId,
  String? pinnedLiveGameType,
  String? observingGameId,
  String? lastSessionPath,
}) {
  final dest = resolveGamesTabPath(
    currentPath: currentPath,
    active: active,
    pinnedLiveGameId: pinnedLiveGameId,
    pinnedLiveGameType: pinnedLiveGameType,
    observingGameId: observingGameId,
    lastSessionPath: lastSessionPath,
  );
  if (dest == null || dest == currentPath) return;
  context.go(dest);
}

/// Тап по «Игры»: живую/офлайн партию сначала просто показываем веткой
/// (IndexedStack), чтобы не пересоздать стол. На каталог — [context.go].
void _openGamesBranch(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  int branch,
  String currentPath,
  String? dest,
) {
  if (dest == null || dest == currentPath) {
    navigationShell.goBranch(branch);
    return;
  }
  if (gameRegistry.isActiveGamePath(dest)) {
    navigationShell.goBranch(branch);
    final now =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    if (now != dest && !gameRegistry.isActiveGamePath(now)) {
      context.go(dest);
    }
    return;
  }
  context.go(dest);
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

/// После WS хода подставляем is_my_turn из кадра и звучим, если не за столом.
Future<void> _announceAwayGameTurn(
  WidgetRef ref,
  BuildContext context,
  Map<String, dynamic> event,
) async {
  final hinted = applyActiveGameTurnFromEvent(
    ref.read(activeGameProvider).valueOrNull,
    event,
  );
  if (hinted != null) {
    ref.read(activeGameProvider.notifier).setLocal(hinted);
  }
  await Future<void>.delayed(const Duration(milliseconds: 150));
  if (!context.mounted) return;
  final active = ref.read(activeGameProvider).valueOrNull;
  final path =
      GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  final eventTurn = event['is_my_turn'] == true;
  GameAwaySfx.playIfNeeded(
    path: path,
    gameId: event['game_id']?.toString() ?? active?.gameId,
    isMyTurn: event.containsKey('is_my_turn')
        ? eventTurn
        : active?.type == 'game' && (active?.isMyTurn ?? false),
  );
}

/// Уход со стола на другую вкладку: звук только если сейчас наш ход.
void _announceLeftBoard(
  WidgetRef ref,
  String path, {
  required bool isMyTurn,
}) {
  final prev = _lastAwaySfxPath;
  if (prev == path) return;
  _lastAwaySfxPath = path;
  final active = ref.read(activeGameProvider).valueOrNull;
  if (!GameAwaySfx.leftBoard(
    previousPath: prev,
    nextPath: path,
    gameId: active?.gameId,
  )) {
    return;
  }
  GameAwaySfx.playIfNeeded(
    path: path,
    gameId: active?.gameId,
    isMyTurn: isMyTurn,
    leftBoardWhileMyTurn: isMyTurn,
  );
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
    GameFlyOverlay.syncVisiblePath(path);
    final gameNavigation = ref.read(gameNavigationCoordinatorProvider);
    final authState = ref.watch(authStateProvider);
    final isAuthorized = authState.valueOrNull != null;
    final isOffline = ref.watch(isOfflineProvider);
    // Бейджи заданий/достижений — сразу после выполнения, без захода в раздел.
    ref.watch(rewardBadgesRealtimeSyncProvider);
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
    ref.listen<OfflineModeState>(offlineModeProvider, (prev, next) {
      if (next.isOffline) return;
      if (!next.shouldOfferOffline) return;
      if (prev != null && prev.shouldOfferOffline) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final ok = await ref
            .read(offlineModeProvider.notifier)
            .consumeOfflineOffer();
        if (!ok || !context.mounted) return;
        final l10n = context.l10n;
        showAppSnackBar(
          context,
          message: l10n.offlineModeOfferBody,
          actionLabel: l10n.offlineModeOfferAction,
          onAction: () {
            ref
                .read(offlineModeProvider.notifier)
                .setPreference(OfflinePreference.offline);
          },
          duration: const Duration(seconds: 8),
          icon: Icons.wifi_off_rounded,
        );
      });
    });
    // Данные и ассеты для офлайна: держим в памяти + прогрев при онлайне.
    if (isAuthorized) {
      ref.watch(offlineWarmupProvider);
      ref.watch(shopCatalogProvider);
      ref.watch(inventoryListProvider);
      ref.watch(inventoryCapabilitiesProvider);
      ref.watch(userGameSettingsProvider('tictactoe'));
      ref.watch(userGameSettingsProvider('durak'));
      ref.watch(userGameSettingsProvider('poker'));
      ref.watch(achievementsListProvider);
      ref.watch(collectionIncomeProvider);
      ref.watch(dailyRewardStatusProvider);
    }
    // Версия приложения: сверка с /api/version и WS client_update_available.
    ref.watch(appUpdateProvider);
    ref.listen(activeGameProvider, (_, __) {
      ref.read(appUpdateProvider.notifier).onActiveGameChanged();
    });
    ref.listen<AppUpdateState>(appUpdateProvider, (prev, next) {
      if (!next.updateAvailable) return;
      if (next.deferredUntilGameEnd) return;
      if (next.dialogShown) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final cur = ref.read(appUpdateProvider);
        if (!cur.updateAvailable ||
            cur.deferredUntilGameEnd ||
            cur.dialogShown) {
          return;
        }
        ref.read(appUpdateProvider.notifier).markDialogShown();
        unawaited(_showAppUpdateDialog(context, ref));
      });
    });
    // Первая проверка при появлении shell (и для гостя на /login).
    // Всегда пробуем — даже в «офлайне» после возврата сети поймает poll.
    unawaited(ref.read(appUpdateProvider.notifier).ensureInitialCheck());

    // Явно держим realtime WebSocket активным (меню, чаты, друзья, presence)
    if (isAuthorized && !isOffline) {
      ref.watch(realtimeEventsProvider);
      ref.watch(presenceMapProvider);
      ref.watch(chatDeliveryAckProvider);
      // Бейджи подарков: live WS + синхронизация из непрочитанных чатов.
      ref.watch(giftedCollectionsBadgeSyncProvider);
      // iOS PWA: после рестарта/смены SW заново привязываем Web Push.
      // Язык → сервер только при логине / смене локали (не из каждого build).
      ref.listen(authStateProvider, (prev, next) {
        if (next.valueOrNull != null && prev?.valueOrNull == null) {
          unawaited(
            ref.read(webPushEnabledProvider.notifier).ensurePushForSession(),
          );
          unawaited(syncPreferredLanguageToServer(ref));
        }
        if (next.valueOrNull == null) {
          _shellDidBootstrapSession = false;
        }
      });
      ref.listen<Locale?>(appLocaleProvider, (prev, next) {
        if (ref.read(authStateProvider).valueOrNull == null) return;
        if (prev == next) return;
        unawaited(syncPreferredLanguageToServer(ref));
      });
      ref.listen<bool>(webPushEnabledProvider, (prev, next) {
        if (next == true && prev != true) {
          unawaited(
            ref.read(webPushEnabledProvider.notifier).ensurePushForSession(),
          );
        }
      });
      // Уже залогинен при первом заходе в shell — один раз, не на каждый rebuild.
      if (!_shellDidBootstrapSession && authState.valueOrNull != null) {
        _shellDidBootstrapSession = true;
        unawaited(syncPreferredLanguageToServer(ref));
          unawaited(
            ref.read(webPushEnabledProvider.notifier).ensurePushForSession(),
          );
      }
      ref.listen(realtimeEventsProvider, (_, next) {
        next.whenData((event) {
          final type = event['type'];
          if (type == 'session_replaced' || type == 'account_frozen') {
            // Заморозка или старый сервер, который гасил остальные устройства.
            unawaited(ref.read(authStateProvider.notifier).logout());
            return;
          }
          if (type == 'realtime_connected') {
            unawaited(ref.read(appUpdateProvider.notifier).check());
          }
          if (type == 'client_update_available') {
            final latest =
                (event['latest_build'] ?? event['build_id'])?.toString();
            // Текст «Что нового» не берём из WS — он без локали.
            // Клиент тянет /api/version с Accept-Language.
            unawaited(
              ref.read(appUpdateProvider.notifier).check(
                    latestBuild: latest,
                  ),
            );
          }
          if (type == 'game_started' || type == 'lobby_updated') {
            final router = GoRouter.of(context);
            final nav = realtimeGameNavForEvent(
              event,
              currentPath: router.routerDelegate.currentConfiguration.uri.path,
            );
            if (context.mounted && nav != null) {
              navigateToGame(
                router,
                gameNavigation,
                nav.gameId,
                gameType: nav.gameType,
              );
            }
          }
          if (type == 'game_state' || type == 'game_started') {
            unawaited(_announceAwayGameTurn(ref, context, event));
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
            // Анимация «Забрать» идёт из карточки в чате; здесь только
            // синхронизация баланса на других вкладках / после списания.
            final balance = (event['balance'] as num?)?.toInt();
            if (balance != null) {
              unawaited(
                ref.read(authStateProvider.notifier).applyBalance(balance),
              );
            }
          }
        });
      });
      // Держим подписку на обновления inbox поддержки для админ-бейджа.
      if (authState.valueOrNull?.isAdmin == true) {
        ref.watch(supportInboxRealtimeProvider);
      }
    }
    ref.listen<int>(chatsUnreadCountProvider, (prev, next) {
      if (AlertSfx.shouldPlayChatUnread(
        previous: prev,
        next: next,
        path: path,
      )) {
        AlertSfx.playNotify();
      }
    });
    ref.listen<int>(friendsIncomingCountProvider, (prev, next) {
      if (AlertSfx.shouldPlayCountBump(prev, next)) AlertSfx.playNotify();
    });
    ref.listen<int>(gameInvitesCountProvider, (prev, next) {
      if (AlertSfx.shouldPlayCountBump(prev, next)) AlertSfx.playNotify();
    });
    ref.listen<int>(gamesMyTurnCountProvider, (prev, next) {
      final active = ref.read(activeGameProvider).valueOrNull;
      GameAwaySfx.playIfNeeded(
        path: path,
        gameId: active?.gameId,
        isMyTurn: next > 0,
      );
    });
    final unreadChats = ref.watch(chatsUnreadCountProvider);
    final incomingFriends = ref.watch(friendsIncomingCountProvider);
    final activeForTurn = ref.watch(activeGameProvider).valueOrNull;
    final liveTurn = watchLiveIsMyTurn(
      ref,
      activeForTurn,
      meId: authState.valueOrNull?.id,
    );
    final isMyTurnNow = liveTurn ??
        (activeForTurn?.type == 'game' && activeForTurn!.isMyTurn);
    scheduleActiveTurnSync(ref, activeForTurn, liveTurn);
    _announceLeftBoard(ref, path, isMyTurn: isMyTurnNow);
    // На другой вкладке бейдж есть только при живом «моём ходе», не со старта.
    final gamesMyTurn = isMyTurnNow ? 1 : 0;
    final gameInvitesCount = ref.watch(gameInvitesCountProvider);
    final dailyRewardAsync = ref.watch(dailyRewardAvailableProvider);
    final dailyRewardCount = dailyRewardAsync.valueOrNull == true ? 1 : 0;
    final achievementsUnclaimed =
        ref.watch(achievementsUnclaimedCountProvider).valueOrNull ?? 0;
    final tasksUnclaimed =
        ref.watch(tasksUnclaimedCountProvider).valueOrNull ?? 0;
    final collectionIncomeAvailable =
        ref.watch(collectionIncomeAvailableProvider);
    final unreadGiftedCollections =
        ref.watch(unreadGiftedCollectionsCountProvider);
    // На «Главной» суммируем daily + достижения + доход + подарки коллекций.
    final homeBadgeCount = dailyRewardCount +
        achievementsUnclaimed +
        tasksUnclaimed +
        (collectionIncomeAvailable ? 1 : 0) +
        unreadGiftedCollections;
    final media = MediaQuery.of(context);
    // Как и для нижней панели: Scaffold может обнулять padding — для
    // челки/status bar берём viewPadding, чтобы цвет шёл full-bleed.
    final topInset = media.viewPadding.top;
    final toolbarHeight = shellToolbarHeight(context);
    final narrow = isNarrow(context);
    final isLandscape = media.size.width > media.size.height;
    final narrowLandscape = narrow && isLandscape;
    // Android landscape: клавиатура забирает 70%+ высоты. Тулбар+рейл
    // оставляют полю ввода ~60px — текст не видно. Схлопываем хром.
    final landscapeKeyboard = narrowLandscape && media.viewInsets.bottom >= 80;
    // Профиль: клавиатура в портрете тоже съедает низ — прячем тулбар и nav,
    // чтобы полоска ввода оставалась на экране.
    final profileKeyboard =
        path == '/profile' && media.viewInsets.bottom >= 80 && narrow;
    final profileFieldOpen = ref.watch(profileEditFieldOpenProvider);
    final hideLandscapeProfileChrome =
        narrowLandscape && path == '/profile' && profileFieldOpen;
    final inChatRoom = path.startsWith('/chats/');
    final onChatsList = path == '/chats';
    final onFriends = path == '/friends';
    // Друзья и чаты: клавиатуру вычитает только оболочка — ровно один раз
    // и не больше 60% высоты (iOS PWA умеет отдать inset больше экрана).
    // Вложенные Scaffold'ы этих экранов идут с resizeToAvoidBottomInset:
    // false, поэтому второго вычитания нет.
    final shellOwnsKeyboardInset = narrow && (onFriends || onChatsList || inChatRoom);
    final keyboardOpen = keyboardIsOpen(media.viewInsets.bottom);
    final shellKeyboardInset = sanitizeKeyboardInset(
      inset: media.viewInsets.bottom,
      viewportHeight: media.size.height,
    );
    // Друзья и чаты: компактный хром только с открытой клавиатурой.
    final hideInputChrome = (onFriends || onChatsList || inChatRoom) &&
        inputHideChrome(
          phoneLandscape: narrowLandscape,
          keyboardInset: media.viewInsets.bottom,
        );
    // Партия на телефоне в альбоме: столу остаётся ~300px по высоте, а тулбар
    // оболочки дублирует шапку самой игры. Прячем его — навигация в рейле.
    final hideGameChromeLandscape =
        narrowLandscape && gameRegistry.isActiveGamePath(path);
    final hideToolbarForKeyboard = landscapeKeyboard ||
        profileKeyboard ||
        hideLandscapeProfileChrome ||
        hideInputChrome ||
        hideGameChromeLandscape;
    final onAuthScreen = path == '/login' || path == '/register';
    final toolbarLeading = ref.watch(mobileToolbarLeadingProvider);
    Future.microtask(() {
      if (!context.mounted) return;
      try {
        ref.read(currentRoutePathProvider.notifier).state = path;
        rememberGamesSessionPath(ref, path);
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
    final collapseNavForKeyboard = shellOwnsKeyboardInset && keyboardOpen;
    // Схлопнутая панель не занимает низ: контенту снова нужен home indicator.
    final navCollapsed = collapseBottomNav ||
        profileKeyboard ||
        collapseNavForKeyboard;
    final navReservesBottom = showBottomNav && !navCollapsed;

    final navItems = _navItems(context, offline: isOffline);
    final selectedIndex = () {
      final i = navItems.indexWhere(
        (e) => e.branchIndex == navigationShell.currentIndex,
      );
      return i < 0 ? 0 : i;
    }();

    void navigateWithPrefetch(int i) {
      GameFlyOverlay.dismissAll();
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
        final lastSession = ref.read(lastGamesSessionPathProvider);
        if (isOffline) {
          final dest = resolveGamesTabPath(
            currentPath: currentPath,
            lastSessionPath: lastSession,
          );
          Router.neglect(context, () {
            _openGamesBranch(
              context,
              navigationShell,
              branch,
              currentPath,
              dest,
            );
          });
          return;
        }
        final activeNotifier = ref.read(activeGameProvider.notifier);
        final epochAtTap = activeNotifier.epoch;
        final cachedActive = ref.read(activeGameProvider).valueOrNull;
        final cacheUsable = _activeGameUsable(cachedActive);
        final pinnedLive = ref.read(blockingGamePinProvider);
        final pinnedLiveId = pinnedLive?.gameId.trim() ?? '';
        final observingId =
            ref.read(observationGameProvider)?.gameId.trim() ?? '';
        // На экране живой партии — закрепить active, чтобы refresh не «съел» матч.
        final pathGameId = _gameIdFromPath(currentPath);
        final pathGameType = gameTypeFromGamePath(currentPath);
        final pathIsObserving =
            pathGameId != null && observingId.isNotEmpty && pathGameId == observingId;
        final pathIsLive = pathGameId != null &&
            !pathIsObserving &&
            (pinnedLiveId == pathGameId || cachedActive?.gameId == pathGameId);
        final livePathForPin = pathGameId;
        if (pathIsLive &&
            livePathForPin != null &&
            (cachedActive == null ||
                cachedActive.type != 'game' ||
                cachedActive.gameId != livePathForPin)) {
          activeNotifier.setLocal(
            ActiveGameItem(
              type: 'game',
              gameId: livePathForPin,
              lobbyId: cachedActive?.lobbyId,
              isMyTurn: cachedActive?.isMyTurn ?? false,
              gameType: pathGameType ??
                  normalizeGameType(cachedActive?.gameType),
            ),
          );
        }
        final activeForNav = ref.read(activeGameProvider).valueOrNull;
        Router.neglect(context, () {
          final dest = resolveGamesTabPath(
            currentPath: currentPath,
            active: activeForNav ?? cachedActive,
            pinnedLiveGameId: pinnedLiveId.isNotEmpty
                ? pinnedLiveId
                : (pathIsLive ? pathGameId : null),
            pinnedLiveGameType: pinnedLive?.gameType ??
                pathGameType ??
                activeForNav?.gameType ??
                cachedActive?.gameType,
            observingGameId: observingId.isNotEmpty ? observingId : null,
            lastSessionPath: lastSession,
          );
          _openGamesBranch(
            context,
            navigationShell,
            branch,
            currentPath,
            dest,
          );
        });
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        // Если кэш был пуст (создали лобби и ушли в чаты) — после refresh
        // увести в активную партию / «Своя игра». Epoch отсекает leaveLobby.
        unawaited(() async {
          try {
            ref.invalidate(activeGameProvider);
            final fresh = await ref.read(activeGameProvider.future);
            if (!context.mounted) return;
            if (ref.read(activeGameProvider.notifier).epoch != epochAtTap) {
              return;
            }
            final pinNowItem = ref.read(blockingGamePinProvider);
            final pinNow = pinNowItem?.gameId.trim() ?? pinnedLiveId;
            final pinNowType = pinNowItem?.gameType ??
                pinnedLive?.gameType ??
                pathGameType;
            final obsNow =
                ref.read(observationGameProvider)?.gameId.trim() ?? observingId;
            // Живая партия на экране / в пине важнее лобби-инвайта с GetActive.
            final livePathId = pathGameId;
            if (pathIsLive &&
                livePathId != null &&
                (fresh == null || fresh.type == 'lobby')) {
              ref.read(activeGameProvider.notifier).setLocal(
                    ActiveGameItem(
                      type: 'game',
                      gameId: livePathId,
                      lobbyId: cachedActive?.lobbyId,
                      isMyTurn: cachedActive?.isMyTurn ?? false,
                      gameType: pathGameType ??
                          normalizeGameType(cachedActive?.gameType),
                    ),
                  );
              return;
            }
            // Партия с экрана важнее «пустого» ответа — не теряем её.
            if ((fresh == null || !_activeGameUsable(fresh)) &&
                pathIsLive &&
                livePathId != null) {
              ref.read(activeGameProvider.notifier).setLocal(
                    ActiveGameItem(
                      type: 'game',
                      gameId: livePathId,
                      lobbyId: cachedActive?.lobbyId,
                      isMyTurn: cachedActive?.isMyTurn ?? false,
                      gameType: pathGameType ??
                          normalizeGameType(cachedActive?.gameType),
                    ),
                  );
              return;
            }
            if (fresh == null || !_activeGameUsable(fresh)) {
              // Только observation — остаёмся/идём на список.
              if (obsNow.isNotEmpty) {
                final nowPath = GoRouter.of(context)
                    .routerDelegate
                    .currentConfiguration
                    .uri
                    .path;
                Router.neglect(context, () {
                  _goGamesTab(
                    context,
                    nowPath,
                    null,
                    observingGameId: obsNow,
                    lastSessionPath: lastSession,
                  );
                });
              }
              return;
            }
            // Даже если кэш был — сервер мог вернуть актуальную партию.
            if (cacheUsable &&
                fresh.type == cachedActive?.type &&
                fresh.gameId == cachedActive?.gameId &&
                fresh.lobbyId == cachedActive?.lobbyId &&
                fresh.gameType == cachedActive?.gameType) {
              return;
            }
            final nowPath =
                GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
            Router.neglect(context, () {
              _goGamesTab(
                context,
                nowPath,
                fresh,
                pinnedLiveGameId: pinNow.isNotEmpty ? pinNow : null,
                pinnedLiveGameType: pinNowType,
                observingGameId: obsNow.isNotEmpty ? obsNow : null,
                lastSessionPath: lastSession,
              );
            });
          } catch (_) {
            if (pathIsLive && livePathForPin != null && context.mounted) {
              ref.read(activeGameProvider.notifier).setLocal(
                    ActiveGameItem(
                      type: 'game',
                      gameId: livePathForPin,
                      lobbyId: cachedActive?.lobbyId,
                      isMyTurn: cachedActive?.isMyTurn ?? false,
                      gameType: pathGameType ??
                          normalizeGameType(cachedActive?.gameType),
                    ),
                  );
            }
          }
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

    GamepadNav.switchTab = (delta) {
      final n = navItems.length;
      if (n <= 0) return;
      var next = (selectedIndex + delta) % n;
      if (next < 0) next += n;
      navigateWithPrefetch(next);
    };

    // IndexedStack веток shell: непрозрачный слой, чтобы Impeller не
    // показывал предыдущую вкладку, пока новая не растрировалась.
    // Status bar резервирует SizedBox(shellStatusBarExtent) выше — и в
    // альбоме партии тоже. Иначе каждый экран со своим SafeArea добавляет
    // ту же высоту ещё раз, а рейл уезжает под часы Android.
    //
    // В альбоме нижнего меню нет, и вырез сбоку с home indicator снизу
    // никто не отступает — стол игры уезжает под них. Отступаем здесь и
    // убираем padding из MediaQuery, чтобы SafeArea экранов не сдвинули
    // содержимое второй раз.
    //
    // removePadding читает MediaQuery контекста оболочки — он над Scaffold
    // и всё ещё содержит home indicator. В портрете меню уже сидит на этом
    // вырезе. Если вернуть bottom в ветки, SafeArea каждого экрана оставляет
    // ~34px пустоты над иконками (на «Настройках» карточка её перекрывает
    // из‑за clipBehavior: none, на «Играх» видна серая полоса).
    final railVisible =
        !(landscapeKeyboard || hideLandscapeProfileChrome || hideInputChrome);
    final landscapeSafe = landscapeContentSafeArea(
      viewPadding: media.viewPadding,
      phoneLandscape: narrowLandscape,
      railVisible: railVisible,
    );
    // Экраны партий считают раскладку от ширины экрана (веер, анимации). В
    // альбоме у них остаётся заметно меньше: рейл слева и вырезы по краям —
    // отдаём им размер их собственной коробки, иначе стол уезжает вбок.
    final branchHost = AppOpaqueSurface(
      child: RepaintBoundary(
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeLeft: narrowLandscape,
          removeRight: narrowLandscape,
          removeBottom: narrowLandscape || navReservesBottom,
          // Padding и LayoutBuilder всегда в дереве: при повороте экрана
          // условная обёртка пересоздала бы ветки и сбросила их состояние.
          child: Padding(
            padding: landscapeSafe,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final data = MediaQuery.of(context);
                return MediaQuery(
                  data: hideGameChromeLandscape
                      ? data.copyWith(size: constraints.biggest)
                      : data,
                  child: navigationShell,
                );
              },
            ),
          ),
        ),
      ),
    );

    final toolbarEndInset = phoneLandscapeCornerInset(
      phoneLandscape: narrowLandscape,
      platform: Theme.of(context).platform,
    );
    final toolbarLeadingLeft = 8.0 +
        phoneLandscapeToolbarLeadingNudge(
          phoneLandscape: narrowLandscape,
          platform: Theme.of(context).platform,
        );
    final shellBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Одна заливка: status bar (чёлка) + тулбар — тот же цвет, что низ.
        ColoredBox(
          color: AppColors.surfaceUnified,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: shellStatusBarExtent(
                  viewPaddingTop: topInset,
                  // Партия в альбоме прячет тулбар, но status bar остаётся.
                  collapseForInput:
                      hideLandscapeProfileChrome || hideInputChrome,
                ),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: hideToolbarForKeyboard ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: hideToolbarForKeyboard,
                    child: SizedBox(
                height: toolbarHeight,
                child: ClipRect(
                  child: Padding(
                    key: const ValueKey('shell-toolbar-ends'),
                    padding:
                        EdgeInsets.symmetric(horizontal: toolbarEndInset),
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
                            padding: EdgeInsets.only(left: toolbarLeadingLeft),
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
                                ListenableBuilder(
                                  listenable: GamepadService.instance.devices,
                                  builder: (context, _) {
                                    final button = SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: GamepadFocusBlock(
                                        chrome: GamepadChromeSlot.logout,
                                        shape: GamepadHighlightShape.circle,
                                        radius: 20,
                                        borderWidth: 2,
                                        onActivate: () {
                                          unawaited(
                                            ref
                                                .read(authStateProvider.notifier)
                                                .logout(),
                                          );
                                        },
                                        child: IconButton(
                                          icon: const Icon(Icons.logout),
                                          onPressed: () async {
                                            await ref
                                                .read(authStateProvider.notifier)
                                                .logout();
                                          },
                                          tooltip: context.l10n.logoutTooltip,
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    );
                                    if (!gamepadConnected()) return button;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        button,
                                        const SizedBox(width: 4),
                                        const GamepadGlyph(
                                          action: GamepadAction.triggerR,
                                          size: 16,
                                        ),
                                      ],
                                    );
                                  },
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: narrow && !narrowLandscape
              ? SizedBox.expand(child: branchHost)
              : Row(
                  children: [
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            (landscapeKeyboard ||
                                    hideLandscapeProfileChrome ||
                                    hideInputChrome)
                                ? 0.0
                                : 1.0,
                        child: IgnorePointer(
                          ignoring: landscapeKeyboard ||
                              hideLandscapeProfileChrome ||
                              hideInputChrome,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: landscapeRailLeadingInset(
                                viewPadding: media.viewPadding,
                                phoneLandscape: narrowLandscape,
                                railVisible: railVisible,
                                platform: Theme.of(context).platform,
                              ),
                            ),
                            child: _GamepadTabShoulders(
                              axis: Axis.vertical,
                              child: ExcludeFocus(
                                child: narrowLandscape
                                    ? _PhoneLandscapeNav(
                                        key: const ValueKey(
                                          'phone-landscape-nav',
                                        ),
                                        selectedIndex: selectedIndex,
                                        onTap: navigateWithPrefetch,
                                        offline: isOffline,
                                        unreadChats: unreadChats,
                                        incomingFriends: incomingFriends,
                                        gamesMyTurn: gamesMyTurn,
                                        gameInvitesCount: gameInvitesCount,
                                        homeBadgeCount: homeBadgeCount,
                                      )
                                    : MediaQuery.removePadding(
                                        context: context,
                                        removeLeft: narrowLandscape,
                                        removeBottom: narrowLandscape,
                                        child: NavigationRail(
                                          selectedIndex: selectedIndex,
                                          onDestinationSelected:
                                              navigateWithPrefetch,
                                          backgroundColor: Colors.transparent,
                                          selectedIconTheme:
                                              const IconThemeData(
                                            color: AppColors.accentStart,
                                          ),
                                          unselectedIconTheme:
                                              const IconThemeData(
                                            color: AppColors.textSecondary,
                                          ),
                                          labelType:
                                              NavigationRailLabelType.all,
                                          destinations: navItems
                                              .asMap()
                                              .entries
                                              .map((entry) {
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
                                                selected:
                                                    index == selectedIndex,
                                              ),
                                              label: Text(item.label),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                              ),
                            ),
                        ),
                      ),
                    ),
                    ),
                    Expanded(
                      child: SizedBox.expand(child: branchHost),
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
    // Полный home-indicator inset (~34) оставлял пустоту под иконками.
    // 12 хватает, чтобы подпись не села на полоску Home, фон всё равно до низа.
    final navBottomGap =
        bottomInset <= 0 ? 0.0 : (bottomInset > 16 ? 12.0 : bottomInset);
    // Оболочка сама сдвигает контент на клавиатуру, поэтому панель под ней
    // не должна занимать высоту — иначе между вводом и клавиатурой щель.
    Widget? bottomNav;
    if (showBottomNav) {
      bottomNav = Align(
        alignment: Alignment.topCenter,
        heightFactor: navCollapsed ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: navCollapsed,
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
                SizedBox(height: navBottomGap),
              ],
            ),
          ),
        ),
      );
      // ClipRect нужен, только когда панель схлопнута (heightFactor 0):
      // Align сам детей не обрезает. На открытой панели тот же ClipRect
      // срезал бейдж, который на 4px выше иконки.
      if (navCollapsed) {
        bottomNav = ClipRect(child: bottomNav);
      }
    }

    final updateState = ref.watch(appUpdateProvider);
    final showUpdateBanner = updateState.updateAvailable &&
        updateState.deferredUntilGameEnd &&
        !updateState.bannerDismissed;

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
            resizeToAvoidBottomInset: shellOwnsKeyboardInset
                ? false
                : profileEditShellResizeToAvoidInset(
                    onProfile: path == '/profile',
                  ),
            // Padding всегда в дереве. Ветка «Friends/Chats ↔ остальные»
            // раньше подменяла Column на Padding и обратно: боковой рейл
            // пересоздавался под пальцем, жест умирал и дальше одной вкладки
            // не шёл. Нижнее меню в портрете живёт в bottomNavigationBar и
            // этого скачка не видит.
            body: KeyboardInsetScope(
              handled: shellOwnsKeyboardInset,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: shellOwnsKeyboardInset ? shellKeyboardInset : 0,
                ),
                child: shellBody,
              ),
            ),
            bottomNavigationBar: bottomNav,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Overlay(
              key: ref.watch(appFlyOverlayKeyProvider),
            ),
          ),
        ),
        if (showUpdateBanner)
          Positioned(
            left: 12,
            right: 12,
            top: topInset + toolbarHeight + 6,
            child: _AppUpdateBanner(
              onUpdate: () => ref.read(appUpdateProvider.notifier).applyUpdate(),
              onDismiss: () =>
                  ref.read(appUpdateProvider.notifier).dismissBanner(),
            ),
          ),
        if (keyboardInsetHudEnabled())
          Positioned(
            left: 0,
            right: 0,
            top: topInset,
            child: const KeyboardInsetHud(),
          ),
      ],
    );
  }
}

Future<void> _showAppUpdateDialog(BuildContext context, WidgetRef ref) async {
  final whatsNew = ref.read(appUpdateProvider).whatsNew;
  final go = await showAppUpdatePromptDialog(
    context,
    whatsNew: whatsNew,
    allowClose: false,
  );
  if (!go || !context.mounted) return;
  await ref.read(appUpdateProvider.notifier).applyUpdate();
}

class _AppUpdateBanner extends StatelessWidget {
  const _AppUpdateBanner({
    required this.onUpdate,
    required this.onDismiss,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Icon(Icons.system_update_alt_rounded,
                  size: 20, color: AppColors.accentStart),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.appUpdateLaterBanner,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onUpdate,
                child: Text(l10n.appUpdateOk),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Нижняя панель: только иконки + одна подпись по центру с двумя линиями.
/// LB/RB (или L1/R1, L/R) по краям панели вкладок — только если пад подключён.
class _GamepadTabShoulders extends StatelessWidget {
  const _GamepadTabShoulders({
    required this.child,
    required this.axis,
  });

  final Widget child;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamepadService.instance.devices,
      builder: (context, _) {
        if (!gamepadConnected()) return child;
        const glyphSize = 18.0;
        final left = Padding(
          padding: axis == Axis.horizontal
              ? const EdgeInsets.only(left: 2, right: 4)
              : const EdgeInsets.only(top: 6, bottom: 4),
          child: const GamepadGlyph(
            action: GamepadAction.shoulderL,
            size: glyphSize,
          ),
        );
        final right = Padding(
          padding: axis == Axis.horizontal
              ? const EdgeInsets.only(left: 4, right: 2)
              : const EdgeInsets.only(top: 4, bottom: 6),
          child: const GamepadGlyph(
            action: GamepadAction.shoulderR,
            size: glyphSize,
          ),
        );
        if (axis == Axis.horizontal) {
          return Row(
            children: [
              left,
              Expanded(child: child),
              right,
            ],
          );
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            child,
            Positioned(top: 6, child: left),
            Positioned(bottom: 6, child: right),
          ],
        );
      },
    );
  }
}

/// Зазор над иконками нижнего меню. Бейдж счётчика выступает на 4px вверх,
/// поэтому сверху оставляем запас, чтобы кружок не упирался в край панели.
@visibleForTesting
const double mobileBottomNavIconPadTop = 8;

/// Зазор под иконками, перед подписью выбранной вкладки.
@visibleForTesting
const double mobileBottomNavIconPadBottom = 6;

/// Высота полосы иконок. Вся полоса и подпись под ней — одна зона нажатия,
/// не маленький кружок вокруг глифа.
const double _navIconBandHeight = 46;

const double _navPillHeight = 34;

const double _navIconSize = 26;

const double _phoneLandscapeNavWidth = 56;

/// Боковое меню телефона в альбоме: та же плашка и зажим, что у нижнего меню,
/// только палец едет по вертикали.
class _PhoneLandscapeNav extends StatefulWidget {
  const _PhoneLandscapeNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.offline,
    required this.unreadChats,
    required this.incomingFriends,
    required this.gamesMyTurn,
    required this.gameInvitesCount,
    required this.homeBadgeCount,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool offline;
  final int unreadChats;
  final int incomingFriends;
  final int gamesMyTurn;
  final int gameInvitesCount;
  final int homeBadgeCount;

  @override
  State<_PhoneLandscapeNav> createState() => _PhoneLandscapeNavState();
}

class _PhoneLandscapeNavState extends State<_PhoneLandscapeNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move;
  double _animFrom = 0;
  double _animTo = 0;
  double _dragCenter = 0;
  var _dragging = false;
  var _dragMoved = false;
  int? _activePointer;
  int _pressedIndex = 0;
  double _barExtent = 0;
  int _count = 1;

  @override
  void initState() {
    super.initState();
    _pressedIndex = widget.selectedIndex;
    _animFrom = widget.selectedIndex.toDouble();
    _animTo = _animFrom;
    _dragCenter = _animFrom;
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _PhoneLandscapeNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex && !_dragging) {
      _pressedIndex = widget.selectedIndex;
      _goTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  double _shownT() {
    final t = Curves.easeOutCubic.transform(_move.value.clamp(0.0, 1.0));
    return _animFrom + (_animTo - _animFrom) * t;
  }

  void _goTo(double target) {
    final current = _dragging ? _dragCenter : _shownT();
    _dragging = false;
    _animFrom = current;
    _animTo = target;
    if ((current - target).abs() < 0.02) {
      _move.value = 1;
      setState(() {});
      return;
    }
    _move.forward(from: 0);
    setState(() {});
  }

  void _pointer(double along, {required bool commit}) {
    final extent = _barExtent;
    final count = _count;
    if (extent <= 0 || count <= 0) return;
    final slot = extent / count;
    final index = (along / slot).floor().clamp(0, count - 1);
    setState(() {
      _dragging = true;
      _dragCenter = (along / slot - 0.5).clamp(0.0, (count - 1).toDouble());
    });
    if (commit || index != _pressedIndex) {
      _pressedIndex = index;
      widget.onTap(index);
    }
  }

  void _endDrag() {
    if (!_dragging) return;
    _goTo(_pressedIndex.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems(context, offline: widget.offline);
    final count = navItems.length;
    final safeIndex = widget.selectedIndex.clamp(0, count - 1);
    final active = _dragging ? _pressedIndex.clamp(0, count - 1) : safeIndex;
    // Listener, не GestureDetector: вертикальный drag на узком рейле
    // проигрывает арену первому касанию (веб, край экрана iOS). Вкладка
    // должна смениться в тот же момент, что и в нижнем меню.
    return SizedBox(
      width: _phoneLandscapeNavWidth,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_activePointer != null) return;
          _activePointer = event.pointer;
          _dragMoved = false;
          _pointer(event.localPosition.dy, commit: true);
        },
        onPointerMove: (event) {
          if (event.pointer != _activePointer) return;
          if (event.delta != Offset.zero) _dragMoved = true;
          _pointer(event.localPosition.dy, commit: false);
        },
        onPointerUp: (event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          _endDrag();
        },
        onPointerCancel: (event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          if (!_dragMoved) _endDrag();
        },
        child: AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 0.0;
                _barExtent = height;
                _count = count;
                final slot = count == 0 || height <= 0 ? height : height / count;
                final travel = _dragging ? _dragCenter : _shownT();
                final top = travel * slot + (slot - _navPillHeight) / 2;
                const pillWidth = 48.0;
                return SizedBox(
                  height: height,
                  width: _phoneLandscapeNavWidth,
                  child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (_phoneLandscapeNavWidth - pillWidth) / 2,
                      top: top,
                      width: pillWidth,
                      height: _navPillHeight,
                      child: const DecoratedBox(
                        key: ValueKey('phone-landscape-nav-pill'),
                        decoration: BoxDecoration(
                          color: AppColors.navPill,
                          borderRadius: BorderRadius.all(
                            Radius.circular(_navPillHeight / 2),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        for (var i = 0; i < count; i++)
                          Expanded(
                            child: Center(
                              child: _navIcon(
                                navItems[i],
                                widget.unreadChats,
                                widget.incomingFriends,
                                widget.gamesMyTurn,
                                widget.gameInvitesCount,
                                widget.homeBadgeCount,
                                selected: i == active,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Нижняя панель: иконки с переезжающей плашкой, как вкладки Telegram,
/// и одна подпись снизу.
class _MobileBottomNav extends StatefulWidget {
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
  State<_MobileBottomNav> createState() => _MobileBottomNavState();
}

class _MobileBottomNavState extends State<_MobileBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move;
  double _animFrom = 0;
  double _animTo = 0;
  double _dragCenter = 0;
  var _dragging = false;
  var _dragMoved = false;
  int _pressedIndex = 0;
  double _barWidth = 0;
  int _count = 1;

  @override
  void initState() {
    super.initState();
    _pressedIndex = widget.selectedIndex;
    _animFrom = widget.selectedIndex.toDouble();
    _animTo = _animFrom;
    _dragCenter = _animFrom;
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _MobileBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex && !_dragging) {
      _pressedIndex = widget.selectedIndex;
      _goTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  double _shownT() {
    final t = Curves.easeOutCubic.transform(_move.value.clamp(0.0, 1.0));
    return _animFrom + (_animTo - _animFrom) * t;
  }

  void _goTo(double target) {
    final current = _dragging ? _dragCenter : _shownT();
    _dragging = false;
    _animFrom = current;
    _animTo = target;
    if ((current - target).abs() < 0.02) {
      _move.value = 1;
      setState(() {});
      return;
    }
    _move.forward(from: 0);
    setState(() {});
  }

  void _pointer(double x, {required bool commit}) {
    final width = _barWidth;
    final count = _count;
    if (width <= 0 || count <= 0) return;
    final slot = width / count;
    final index = (x / slot).floor().clamp(0, count - 1);
    setState(() {
      _dragging = true;
      _dragCenter = (x / slot - 0.5).clamp(0.0, (count - 1).toDouble());
    });
    if (commit || index != _pressedIndex) {
      _pressedIndex = index;
      widget.onTap(index);
    }
  }

  void _endDrag() {
    if (!_dragging) return;
    _goTo(_pressedIndex.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems(context, offline: widget.offline);
    final count = navItems.length;
    final safeIndex = widget.selectedIndex.clamp(0, count - 1);
    final active = _dragging ? _pressedIndex.clamp(0, count - 1) : safeIndex;
    final label = navItems[active].label;
    return ExcludeFocus(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _GamepadTabShoulders(
          axis: Axis.horizontal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              _dragMoved = false;
              _pointer(details.localPosition.dx, commit: true);
            },
            onTapUp: (_) => _endDrag(),
            onTapCancel: () {
              if (!_dragMoved) _endDrag();
            },
            onHorizontalDragStart: (details) {
              _dragMoved = true;
              _pointer(details.localPosition.dx, commit: false);
            },
            onHorizontalDragUpdate: (details) {
              _dragMoved = true;
              _pointer(details.localPosition.dx, commit: false);
            },
            onHorizontalDragEnd: (_) => _endDrag(),
            onHorizontalDragCancel: _endDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        _barWidth = width;
                        _count = count;
                        final slot = count == 0 ? width : width / count;
                        final pillWidth = (slot - 8).clamp(36.0, 56.0);
                        final travel = _dragging ? _dragCenter : _shownT();
                        final left = travel * slot + (slot - pillWidth) / 2;
                        return SizedBox(
                          height: _navIconBandHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: left,
                                top: (_navIconBandHeight - _navPillHeight) / 2,
                                width: pillWidth,
                                height: _navPillHeight,
                                child: const DecoratedBox(
                                  key: ValueKey('mobile-bottom-nav-pill'),
                                  decoration: BoxDecoration(
                                    color: AppColors.navPill,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(_navPillHeight / 2),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (var i = 0; i < count; i++)
                                    Expanded(
                                      child: Center(
                                        child: _navIcon(
                                          navItems[i],
                                          widget.unreadChats,
                                          widget.incomingFriends,
                                          widget.gamesMyTurn,
                                          widget.gameInvitesCount,
                                          widget.homeBadgeCount,
                                          selected: i == active,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Row(
                    key: ValueKey(label),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -3),
                        child: Opacity(
                          opacity: widget.hairlinesOpacity.clamp(0.0, 1.0),
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
                          opacity: widget.hairlinesOpacity.clamp(0.0, 1.0),
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
          ),
        ),
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
  // Один размер у всех: плашка переезжает, глиф не прыгает под палец.
  final baseIcon = Icon(item.icon, color: iconColor, size: _navIconSize);

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
  // Кружок чуть выше иконки. Высоту панели не увеличиваем — иначе меню
  // толще. Родитель открытой панели этот выступ не клипует.
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
