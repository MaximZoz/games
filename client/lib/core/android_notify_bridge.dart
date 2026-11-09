import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/android_notify_map.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/phone_notification_badge.dart';
import 'package:multigames_client/core/push_nav_paths.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';

String? _lastIosTraySync;

/// Локальные уведомления на Android и iPhone, пока приложение в фоне (WS ещё жив).
/// Как PWA: баннер не рисуем в момент открытия приложения.
final androidNotifyBridgeProvider = Provider<void>((ref) {
  if (kIsWeb || !localNotificationsSupported()) return;

  final lifecycle = _NotifyLifecycle();
  WidgetsBinding.instance.addObserver(lifecycle);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(lifecycle));

  void syncSession(AuthUser? user) {
    if (user == null) {
      setLocalNotifySessionActive(false);
      unawaited(cancelAllLocalNotifications());
      return;
    }
    setLocalNotifySessionActive(true);
    if (ref.read(webPushEnabledProvider)) {
      unawaited(requestLocalNotificationPermission());
    }
  }

  syncSession(ref.read(authStateProvider).valueOrNull);
  ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (prev, next) {
    syncSession(next.valueOrNull);
  });
  ref.listen<bool>(webPushEnabledProvider, (prev, next) {
    if (next && ref.read(authStateProvider).valueOrNull != null) {
      unawaited(requestLocalNotificationPermission());
    }
  });

  String? awayTurnTag;
  final ios = defaultTargetPlatform == TargetPlatform.iOS;

  bool trayAway(AppLifecycleState state) =>
      shouldShowPhoneTrayBanner(state, ios: ios);

  Future<void> showAwayTurn() async {
    if (!ref.read(webPushEnabledProvider)) return;
    if (!ref.read(webPushCategoriesProvider).games) return;
    final active = ref.read(activeGameProvider).valueOrNull;
    if (active == null || active.type != 'game' || !active.isMyTurn) return;
    final id = active.gameId?.trim() ?? '';
    if (id.isEmpty) return;
    final l10n = LocaleService.l10n;
    final tag = 'game_turn_$id';
    awayTurnTag = tag;
    await showLocalNotification(
      title: l10n.gamesMyTurn,
      body: l10n.settingsPushGames,
      tag: tag,
      id: notificationIdForTag(tag),
      payload: encodeNotificationPayload(
        url: '/games/${active.gameType}/game/$id',
        tag: tag,
      ),
    );
  }

  void clearAwayTurn() {
    final tag = awayTurnTag;
    awayTurnTag = null;
    if (tag == null) return;
    unawaited(cancelLocalNotificationsForTag(tag));
  }

  lifecycle.onChange = (next) {
    if (trayAway(next)) {
      unawaited(showAwayTurn());
      return;
    }
    if (next == AppLifecycleState.resumed) clearAwayTurn();
  };

  ref.listen<int>(gamesMyTurnCountProvider, (prev, next) {
    if (next <= 0) {
      clearAwayTurn();
      return;
    }
    if ((prev ?? 0) > 0) return;
    if (!trayAway(lifecycle.state)) return;
    unawaited(showAwayTurn());
  });

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventsProvider,
      (_, next) {
    if (!shouldShowPhoneTrayBanner(
      lifecycle.state,
      ios: defaultTargetPlatform == TargetPlatform.iOS,
    )) {
      return;
    }
    if (!ref.read(webPushEnabledProvider)) return;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) return;
    final event = next.valueOrNull;
    if (event == null) return;
    final cats = ref.read(webPushCategoriesProvider);
    final mapped = mapAndroidNotifyEvent(event, meId: me.id, cats: cats);
    if (mapped == null) return;
    if (pathsMatch(ref.read(currentRoutePathProvider), mapped.url)) return;
    showLocalNotification(
      title: mapped.title,
      body: mapped.body,
      tag: mapped.tag,
      id: notificationIdForTag(mapped.tag),
      payload: encodeNotificationPayload(
        url: mapped.url,
        tag: mapped.tag,
        chatId: mapped.chatId,
      ),
    );
  });
});

/// iPhone: бейдж на иконке и снятие баннеров, которые в приложении уже погасли.
final iosTraySyncProvider = Provider<void>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  if (!localNotificationsSupported()) return;
  if (ref.watch(authStateProvider).valueOrNull == null) {
    _lastIosTraySync = null;
    return;
  }

  final chatsAsync = ref.watch(chatsListProvider);
  final friendsAsync = ref.watch(friendsSnapshotProvider);
  final invitesHydrated = ref.watch(gameInvitesHydratedProvider);
  final invites = ref.watch(gameInvitesProvider);
  final localRead = ref.watch(locallyReadChatIdsProvider);
  final dailyAsync = ref.watch(dailyRewardAvailableProvider);
  final incomeAsync = ref.watch(collectionIncomeProvider);
  final chatsReady = chatsAsync.hasValue;
  final friendsReady = friendsAsync.hasValue;
  final rewardsReady = dailyAsync.hasValue && incomeAsync.hasValue;
  if (!chatsReady && !friendsReady && !invitesHydrated) return;

  final chats = applyLocallyReadChats(
    chatsAsync.valueOrNull ?? const [],
    localRead,
  );
  final keepChats = <String>[
    for (final chat in chats)
      if (chat.unreadCount > 0) 'chat_${chat.chatID}',
  ];
  // Список — 10 диалогов, непрочитанные сверху. Пока страница целиком из
  // непрочитанных, ниже могут быть ещё: их баннеры не снимаем и бейдж с
  // сервера не занижаем. Как только в странице есть прочитанный (или она
  // короче лимита), непрочитанные — это вся выборка.
  const chatPage = 10;
  final chatsTruncated = chatsReady &&
      chats.length >= chatPage &&
      chats.every((chat) => chat.unreadCount > 0);
  final dropChats = <String>[
    for (final chat in chats)
      if (chat.unreadCount == 0) 'chat_${chat.chatID}',
    for (final id in localRead)
      if (!keepChats.contains('chat_$id')) 'chat_$id',
  ];
  final incoming = friendsAsync.valueOrNull?.incoming.length ?? 0;
  final keepInvites = <String>[
    for (final invite in invites)
      if (invite.lobbyId.trim().isNotEmpty)
        gameInviteNotificationTag(
          gameType: invite.gameType,
          lobbyId: invite.lobbyId,
        ),
  ];
  final badge = phoneNotificationBadge(
    chatsWithUnread: chatsReady ? keepChats.length : 0,
    incomingFriends: friendsReady ? incoming : 0,
    gameInvites: invitesHydrated ? keepInvites.length : 0,
    dailyReward: dailyAsync.valueOrNull == true ? 1 : 0,
    collectionIncome: incomeAsync.valueOrNull?.available == true ? 1 : 0,
  );
  // Пока статус наград не приехал, не затираем число, которое пуш уже
  // поставил на иконке.
  final applyBadge = chatsReady &&
      friendsReady &&
      invitesHydrated &&
      rewardsReady &&
      !chatsTruncated;
  final signature = [
    badge,
    applyBadge,
    chatsReady && !chatsTruncated,
    keepChats.join(','),
    dropChats.join(','),
    friendsReady && incoming == 0,
    invitesHydrated,
    keepInvites.join(','),
  ].join('|');
  if (_lastIosTraySync == signature) return;
  _lastIosTraySync = signature;
  unawaited(syncIosNotificationCenter(
    badge: badge,
    applyBadge: applyBadge,
    clearChatThreads: chatsReady && !chatsTruncated,
    keepChatTags: keepChats,
    dropChatTags: chatsTruncated ? dropChats : const [],
    clearFriendRequests: friendsReady && incoming == 0,
    clearGameInvites: invitesHydrated,
    keepInviteTags: keepInvites,
  ));
});

class _NotifyLifecycle with WidgetsBindingObserver {
  AppLifecycleState state = AppLifecycleState.resumed;
  void Function(AppLifecycleState next)? onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState next) {
    state = next;
    onChange?.call(next);
  }
}
