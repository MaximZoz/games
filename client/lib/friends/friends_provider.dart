import 'dart:async';

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_ws.dart';
import 'package:multigames_client/friends/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final friendsSnapshotProvider = StreamProvider.autoDispose<FriendsSnapshot>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return Stream<FriendsSnapshot>.value(
      FriendsSnapshot(
        friends: const [],
        incoming: const [],
        outgoing: const [],
      ),
    );
  }

  final repo = ref.watch(friendsRepositoryProvider);
  final controller = StreamController<FriendsSnapshot>();
  RealtimeSocket? socket;
  StreamSubscription<String>? socketSubscription;
  Timer? reconnectTimer;
  var loadInFlight = false;
  late void Function() scheduleReconnect;

  Future<void> load() async {
    if (loadInFlight) return;
    loadInFlight = true;
    try {
      final snapshot = await repo.getFriends();
      if (!controller.isClosed) controller.add(snapshot);
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
          if (type == 'friends_updated') {
            unawaited(load());
          }
        } catch (_) {}
      },
      onError: (_) => scheduleReconnect(),
      onDone: scheduleReconnect,
      cancelOnError: false,
    );

    // После реконнекта догружаем актуальное состояние.
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

final friendsIncomingCountProvider = Provider<int>((ref) {
  final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
  return snapshot?.incoming.length ?? 0;
});

Future<void> refreshFriendsSnapshot(WidgetRef ref) async {
  ref.invalidate(friendsSnapshotProvider);
  await ref.read(friendsSnapshotProvider.future);
}
