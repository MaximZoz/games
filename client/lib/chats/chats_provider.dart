import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepository(authRepository: ref.watch(authRepositoryProvider));
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

/// Кэш списка чатов для переиспользования при переходе список → чат (desktop split).
final chatsListCacheProvider = StateProvider<({List<ChatPreviewItem> chats, DateTime at})?>((ref) => null);

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

  Future<void> load() async {
    if (loadInFlight) return;
    loadInFlight = true;
    try {
      final chats = await ref.read(chatsRepositoryProvider).listChats(limit: 10, offset: 0);
      await _emitAfterFrame(() {
        if (!controller.isClosed) controller.add(chats);
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
      if (type == 'chat_message' ||
          type == 'chat_list_changed' ||
          type == 'chat_read' ||
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

final chatsUnreadCountProvider = Provider<int>((ref) {
  final chats = ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
  return chats.fold<int>(0, (sum, item) => sum + item.unreadCount);
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
    await ref.read(chatsListProvider.future);
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
