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

final chatsListProvider = StreamProvider.autoDispose<List<ChatPreviewItem>>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return Stream<List<ChatPreviewItem>>.value(const []);
  }

  final controller = StreamController<List<ChatPreviewItem>>();
  RealtimeSocket? socket;
  StreamSubscription<String>? socketSubscription;
  Timer? reconnectTimer;
  var loadInFlight = false;
  late void Function() scheduleReconnect;

  Future<void> load() async {
    if (loadInFlight) return;
    loadInFlight = true;
    try {
      final chats = await ref.read(chatsRepositoryProvider).listChats(limit: 100, offset: 0);
      if (!controller.isClosed) controller.add(chats);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    } finally {
      loadInFlight = false;
    }
  }

  Future<void> connect() async {
    await socketSubscription?.cancel();
    socket?.close();
    socket = null;

    final token = await ref.read(authRepositoryProvider).getAccessToken();
    if (token == null || token.isEmpty) {
      scheduleReconnect();
      return;
    }

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

    // На переподключении догружаем состояние, чтобы не пропустить события в оффлайне.
    unawaited(load());
  }

  scheduleReconnect = () {
    if (reconnectTimer != null || controller.isClosed) return;
    reconnectTimer = Timer(const Duration(seconds: 2), () {
      reconnectTimer = null;
      unawaited(connect());
    });
  };

  unawaited(load());
  unawaited(connect());

  ref.onDispose(() {
    keepAliveLink.close();
    reconnectTimer?.cancel();
    unawaited(socketSubscription?.cancel());
    socket?.close();
    unawaited(controller.close());
  });

  return controller.stream;
});

final chatsUnreadCountProvider = Provider<int>((ref) {
  final chats = ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
  return chats.fold<int>(0, (sum, item) => sum + item.unreadCount);
});

Future<void> refreshChatsList(WidgetRef ref) async {
  ref.invalidate(chatsListProvider);
  await ref.read(chatsListProvider.future);
}
