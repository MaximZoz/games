import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/l10n/display_names.dart';

/// Локальные уведомления на Android, пока приложение в фоне (WS ещё жив).
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

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventsProvider,
      (_, next) {
    if (lifecycle.isForeground) return;
    if (!ref.read(webPushEnabledProvider)) return;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) return;
    final event = next.valueOrNull;
    if (event == null) return;
    final cats = ref.read(webPushCategoriesProvider);
    final mapped = _mapEvent(event, meId: me.id, cats: cats);
    if (mapped == null) return;
    showLocalNotification(title: mapped.$1, body: mapped.$2);
  });
});

class _NotifyLifecycle with WidgetsBindingObserver {
  AppLifecycleState _state = AppLifecycleState.resumed;

  /// Только полностью открытое приложение. `inactive` — шторка / уход в фон.
  bool get isForeground => _state == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _state = state;
  }
}

(String, String)? _mapEvent(
  Map<String, dynamic> event, {
  required String? meId,
  required WebPushCategoryPrefs cats,
}) {
  final l10n = LocaleService.l10n;
  final type = event['type']?.toString() ?? '';
  if (type == 'chat_message') {
    if (!cats.chat) return null;
    final message = event['message'];
    final senderId = message is Map
        ? message['sender_user_id']?.toString()
        : event['sender_user_id']?.toString();
    if (senderId != null && meId != null && senderId == meId) return null;
    final name = localizeDisplayName(
      (message is Map ? message['sender_name'] : event['sender_name'])
          ?.toString(),
    );
    final body = message is Map
        ? (message['body'] ?? message['text'] ?? '').toString()
        : (event['body'] ?? event['text'] ?? '').toString();
    return (
      name.isNotEmpty ? name : l10n.settingsPushChat,
      body.trim().isEmpty ? l10n.settingsNotifications : body.trim(),
    );
  }
  if (type == 'game_invite') {
    if (!cats.games) return null;
    final name = localizeDisplayName(event['creator_name']?.toString());
    return (l10n.settingsPushGames, name);
  }
  if (type == 'friends_updated') {
    if (!cats.friends) return null;
    if (event['incoming'] != true && event['request'] != true) return null;
    return (l10n.settingsPushFriends, l10n.settingsNotifications);
  }
  if (type == 'coins_granted') {
    if (!cats.rewards) return null;
    return (l10n.settingsPushRewards, l10n.settingsNotifications);
  }
  return null;
}
