import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/push_nav_paths.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/l10n/display_names.dart';

class AndroidNotifySpec {
  const AndroidNotifySpec({
    required this.title,
    required this.body,
    required this.url,
    required this.tag,
    this.chatId,
  });

  final String title;
  final String body;
  final String url;
  final String tag;
  final String? chatId;
}

/// Как PWA: баннер только когда приложение реально в фоне, не в момент открытия.
bool shouldShowAndroidTrayBanner(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.hidden:
    case AppLifecycleState.detached:
      return true;
    case AppLifecycleState.resumed:
    case AppLifecycleState.inactive:
      return false;
  }
}

/// iOS часто остаётся в [AppLifecycleState.inactive], когда приложение уже
/// ушло с экрана (свайп домой), и до paused баннер не успевает.
bool shouldShowPhoneTrayBanner(AppLifecycleState state, {required bool ios}) {
  if (ios && state == AppLifecycleState.inactive) return true;
  return shouldShowAndroidTrayBanner(state);
}

AndroidNotifySpec? mapAndroidNotifyEvent(
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
    final chatId = (event['chat_id'] ??
            (message is Map ? message['chat_id'] : null))
        ?.toString()
        .trim() ??
        '';
    if (chatId.isEmpty) return null;
    final name = localizeDisplayName(
      (message is Map ? message['sender_name'] : event['sender_name'])
          ?.toString(),
    );
    final body = message is Map
        ? (message['body'] ?? message['text'] ?? '').toString()
        : (event['body'] ?? event['text'] ?? '').toString();
    return AndroidNotifySpec(
      title: name.isNotEmpty ? name : l10n.settingsPushChat,
      body: body.trim().isEmpty ? l10n.settingsNotifications : body.trim(),
      url: attachChatPeerName('/chats/$chatId', name),
      tag: 'chat_$chatId',
      chatId: chatId,
    );
  }
  if (type == 'game_invite') {
    if (!cats.games) return null;
    final name = localizeDisplayName(event['creator_name']?.toString());
    final lobbyId = event['lobby_id']?.toString().trim() ?? '';
    var gameType = event['game_type']?.toString().trim() ?? '';
    if (gameType.isEmpty) gameType = 'tictactoe';
    final url = lobbyId.isEmpty
        ? '/games'
        : '/games/$gameType/lobby/$lobbyId';
    return AndroidNotifySpec(
      title: l10n.settingsPushGames,
      body: name.isNotEmpty ? name : l10n.settingsNotifications,
      url: url,
      tag: lobbyId.isEmpty ? 'game_invite' : 'game_invite_$lobbyId',
    );
  }
  if (type == 'friends_updated') {
    if (!cats.friends) return null;
    if (event['incoming'] != true && event['request'] != true) return null;
    return AndroidNotifySpec(
      title: l10n.settingsPushFriends,
      body: l10n.settingsNotifications,
      url: '/friends?tab=incoming',
      tag: 'friend_request',
    );
  }
  if (type == 'coins_granted') {
    if (!cats.rewards) return null;
    return AndroidNotifySpec(
      title: l10n.settingsPushRewards,
      body: l10n.settingsNotifications,
      url: '/coins/login',
      tag: 'daily_reward',
    );
  }
  return null;
}
