import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/push_notification_nav_stub.dart'
    if (dart.library.html)
        'package:multigames_client/core/push_notification_nav_web.dart'
    if (dart.library.io)
        'package:multigames_client/core/push_notification_nav_io.dart'
    show clearPushNotificationsForChat;
import 'package:multigames_client/core/realtime_events_provider.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Всегда активный ACK доставки входящих по WebSocket (не зависит от экрана чатов).
final chatDeliveryAckProvider = Provider.autoDispose<void>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return;
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      if (event['type']?.toString() != 'chat_message') return;

      final chatID = event['chat_id']?.toString() ?? '';
      final messageRaw = event['message'];
      final senderID =
          messageRaw is Map ? messageRaw['sender_user_id']?.toString() : null;
      if (chatID.isEmpty ||
          senderID == null ||
          senderID.isEmpty ||
          senderID == user.id) {
        return;
      }

      unawaited(() async {
        try {
          await ref.read(chatsRepositoryProvider).markDelivered(chatID);
        } catch (_) {}
      }());
    },
  );

  ref.onDispose(keepAliveLink.close);
});

/// Откладывает emit на 2 frame'а, чтобы dispose виджетов успел завершиться.
Future<void> _emitAfterFrame(void Function() fn) async {
  final c = Completer<void>();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      fn();
      if (!c.isCompleted) c.complete();
    });
  });
  return c.future;
}

/// Кэш списка чатов для переиспользования при переходе список ↔ чат.
final chatsListCacheProvider =
    StateProvider<({List<ChatPreviewItem> chats, DateTime at})?>((ref) => null);

/// Чаты, которые пользователь только что прочитал локально
/// (пока серверный список ещё может отдавать старый unread).
final locallyReadChatIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Локально сбросить unread в кэше списка (без сетевого reload).
void markChatReadInChatsCache(WidgetRef ref, String chatId) {
  final id = chatId.trim();
  if (id.isEmpty) return;
  final cache = ref.read(chatsListCacheProvider);
  if (cache != null) {
    var changed = false;
    final chats = cache.chats.map((c) {
      if (c.chatID != id || c.unreadCount == 0) return c;
      changed = true;
      return c.copyWith(unreadCount: 0);
    }).toList(growable: false);
    if (changed) {
      ref.read(chatsListCacheProvider.notifier).state =
          (chats: chats, at: cache.at);
    }
  }
  final prev = ref.read(locallyReadChatIdsProvider);
  if (!prev.contains(id)) {
    ref.read(locallyReadChatIdsProvider.notifier).state = {...prev, id};
  }
  // Прочитали чат — убрать висящие push-баннеры этого диалога из шторки.
  clearPushNotificationsForChat(id);
}

/// Убрать чат из локального кэша списка (очистка/блок из комнаты на десктопе).
/// [ChatsScreen] слушает [chatRemovedIdProvider] и сразу обновляет боковую панель.
void removeChatFromChatsCache(WidgetRef ref, String chatId) {
  final id = chatId.trim();
  if (id.isEmpty) return;
  final cache = ref.read(chatsListCacheProvider);
  if (cache != null) {
    final chats =
        cache.chats.where((c) => c.chatID != id).toList(growable: false);
    if (chats.length != cache.chats.length) {
      ref.read(chatsListCacheProvider.notifier).state = (
        chats: chats,
        at: DateTime.now(),
      );
    }
  }
  ref.read(chatRemovedIdProvider.notifier).state = id;
}

/// Последний локально удалённый chatId (сайдбар десктопа / список).
final chatRemovedIdProvider = StateProvider<String?>((ref) => null);

/// Состояние свёрнутости боковой панели чатов на десктопе (сохраняется при навигации).
final chatsSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final chatsListProvider = StreamProvider.autoDispose<List<ChatPreviewItem>>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return Stream<List<ChatPreviewItem>>.value(const []);
  }

  final controller = StreamController<List<ChatPreviewItem>>();
  var loadInFlight = false;
  var loadQueued = false;

  Future<void> load() async {
    if (loadInFlight) {
      loadQueued = true;
      return;
    }
    loadInFlight = true;
    try {
      do {
        loadQueued = false;
        try {
          final chats = await ref
              .read(chatsRepositoryProvider)
              .listChats(limit: 10, offset: 0);
          final localRead = ref.read(locallyReadChatIdsProvider);
          if (localRead.isNotEmpty) {
            final next = <String>{...localRead};
            for (final c in chats) {
              if (next.contains(c.chatID) && c.unreadCount == 0) {
                next.remove(c.chatID);
              }
            }
            if (next.length != localRead.length) {
              ref.read(locallyReadChatIdsProvider.notifier).state = next;
            }
          }
          final visible = applyLocallyReadChats(chats, localRead);
          await _emitAfterFrame(() {
            if (!controller.isClosed) controller.add(visible);
          });
        } catch (e, st) {
          await _emitAfterFrame(() {
            if (!controller.isClosed) controller.addError(e, st);
          });
        }
      } while (loadQueued);
    } finally {
      loadInFlight = false;
    }
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final type = event['type']?.toString() ?? '';
      if (type == 'chat_message') {
        // Новое входящее — снять локальный «прочитано», чтобы бейдж снова вырос.
        final chatID = event['chat_id']?.toString() ?? '';
        final messageRaw = event['message'];
        final senderID = messageRaw is Map
            ? messageRaw['sender_user_id']?.toString()
            : null;
        if (chatID.isNotEmpty &&
            senderID != null &&
            senderID.isNotEmpty &&
            senderID != user.id) {
          final local = ref.read(locallyReadChatIdsProvider);
          if (local.contains(chatID)) {
            final next = <String>{...local}..remove(chatID);
            ref.read(locallyReadChatIdsProvider.notifier).state = next;
          }
        }
        unawaited(load());
        return;
      }
      if (type == 'chat_message_updated') {
        // Правка текста — обновить превью в списке чатов.
        unawaited(load());
        return;
      }
      if (type == 'chat_message_deleted') {
        unawaited(load());
        return;
      }
      if (type == 'chat_list_changed' ||
          type == 'chat_read' ||
          type == 'chat_delivered' ||
          type == 'realtime_connected') {
        unawaited(load());
      }
    },
  );

  unawaited(load());

  ref.onDispose(() {
    keepAliveLink.close();
    unawaited(controller.close());
  });

  return controller.stream;
});

final blockedUsersProvider = StreamProvider.autoDispose<List<BlockedChatUserItem>>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return Stream<List<BlockedChatUserItem>>.value(const []);
  }

  final controller = StreamController<List<BlockedChatUserItem>>();
  var loadInFlight = false;

  Future<void> load() async {
    if (loadInFlight) return;
    loadInFlight = true;
    try {
      final blocked = await ref.read(chatsRepositoryProvider).listBlockedUsers();
      await _emitAfterFrame(() {
        if (!controller.isClosed) controller.add(blocked);
      });
    } catch (e, st) {
      await _emitAfterFrame(() {
        if (!controller.isClosed) controller.addError(e, st);
      });
    } finally {
      loadInFlight = false;
    }
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final type = next.valueOrNull?['type']?.toString() ?? '';
      if (type == 'chat_list_changed' ||
          type == 'friends_updated' ||
          type == 'realtime_connected') {
        unawaited(load());
      }
    },
  );

  unawaited(load());

  ref.onDispose(() {
    keepAliveLink.close();
    unawaited(controller.close());
  });

  return controller.stream;
});

/// Сервер ещё отдаёт unread, а пользователь уже открыл чат — не поднимать бейдж.
List<ChatPreviewItem> applyLocallyReadChats(
  List<ChatPreviewItem> chats,
  Set<String> localRead,
) {
  if (localRead.isEmpty) return chats;
  return [
    for (final chat in chats)
      if (localRead.contains(chat.chatID) && chat.unreadCount > 0)
        chat.copyWith(unreadCount: 0)
      else
        chat,
  ];
}

final chatsUnreadCountProvider = Provider<int>((ref) {
  final chats =
      ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
  final localRead = ref.watch(locallyReadChatIdsProvider);
  return applyLocallyReadChats(chats, localRead).fold<int>(0, (sum, item) {
    return sum + item.unreadCount;
  });
});

final blockedUsersCountProvider = Provider<int>((ref) {
  final blocked = ref.watch(blockedUsersProvider).valueOrNull ?? const <BlockedChatUserItem>[];
  return blocked.length;
});

Future<void>? _refreshChatsInFlight;
DateTime? _lastChatsRefreshAt;
const _minChatsRefreshInterval = Duration(milliseconds: 400);

Future<void> refreshChatsList(
  WidgetRef ref, {
  bool force = false,
}) async {
  final inFlight = _refreshChatsInFlight;
  if (inFlight != null) {
    await inFlight;
    if (!force) return;
  }

  final now = DateTime.now();
  final lastRefreshAt = _lastChatsRefreshAt;
  if (!force &&
      lastRefreshAt != null &&
      now.difference(lastRefreshAt) < _minChatsRefreshInterval) {
    return;
  }

  late Future<void> request;
  request = () async {
    ref.invalidate(chatsListProvider);
    final chats = await ref.read(chatsListProvider.future);
    ref.read(chatsListCacheProvider.notifier).state = (
      chats: chats,
      at: DateTime.now(),
    );
    _lastChatsRefreshAt = DateTime.now();
  }();

  _refreshChatsInFlight = request;
  try {
    await request;
  } finally {
    if (identical(_refreshChatsInFlight, request)) {
      _refreshChatsInFlight = null;
    }
  }
}

Future<void>? _refreshBlockedUsersInFlight;
DateTime? _lastBlockedUsersRefreshAt;
const _minBlockedUsersRefreshInterval = Duration(milliseconds: 400);

Future<void> refreshBlockedUsers(
  WidgetRef ref, {
  bool force = false,
}) async {
  final inFlight = _refreshBlockedUsersInFlight;
  if (inFlight != null) {
    await inFlight;
    if (!force) return;
  }

  final now = DateTime.now();
  final lastRefreshAt = _lastBlockedUsersRefreshAt;
  if (!force &&
      lastRefreshAt != null &&
      now.difference(lastRefreshAt) < _minBlockedUsersRefreshInterval) {
    return;
  }

  late Future<void> request;
  request = () async {
    ref.invalidate(blockedUsersProvider);
    await ref.read(blockedUsersProvider.future);
    _lastBlockedUsersRefreshAt = DateTime.now();
  }();

  _refreshBlockedUsersInFlight = request;
  try {
    await request;
  } finally {
    if (identical(_refreshBlockedUsersInFlight, request)) {
      _refreshBlockedUsersInFlight = null;
    }
  }
}
