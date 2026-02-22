import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_ws.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final chatsUnreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<int>.value(0);
  }

  final controller = StreamController<int>();
  RealtimeSocket? socket;
  StreamSubscription<String>? socketSubscription;
  Timer? reconnectTimer;

  Future<void> load() async {
    try {
      final chats = await ref.read(chatsRepositoryProvider).listChats(limit: 100, offset: 0);
      final unread = chats.fold<int>(0, (sum, item) => sum + item.unreadCount);
      if (!controller.isClosed) controller.add(unread);
    } catch (_) {
      if (!controller.isClosed) controller.add(0);
    }
  }

  void scheduleReconnect() {
    if (reconnectTimer != null || controller.isClosed) return;
    reconnectTimer = Timer(const Duration(seconds: 2), () {
      reconnectTimer = null;
      unawaited(connect());
    });
  }

  Future<void> connect() async {
    await socketSubscription?.cancel();
    socket?.close();
    socket = null;

    final token = await ref.read(authRepositoryProvider).getAccessToken();
    if (token == null || token.isEmpty) return;

    final uri = buildWebSocketUri(
      '/api/ws',
      queryParameters: {'access_token': token},
    );
    final nextSocket = connectRealtimeSocket(uri);
    socket = nextSocket;
    socketSubscription = nextSocket.messages.listen(
      (raw) {
        try {
          final payload = jsonDecode(raw);
          if (payload is! Map) return;
          final type = payload['type']?.toString() ?? '';
          if (type == 'chat_message' || type == 'chat_list_changed' || type == 'chat_read') {
            unawaited(load());
          }
        } catch (_) {}
      },
      onError: (_) => scheduleReconnect(),
      onDone: scheduleReconnect,
      cancelOnError: false,
    );
  }

  load();
  unawaited(connect());

  ref.onDispose(() {
    reconnectTimer?.cancel();
    unawaited(socketSubscription?.cancel());
    socket?.close();
    controller.close();
  });

  return controller.stream;
});
