import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_ws.dart';
import 'package:multigames_client/friends/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final friendsSnapshotProvider = FutureProvider.autoDispose<FriendsSnapshot>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getFriends();
});

Future<int> _loadIncomingCount(FriendsRepository repo) async {
  try {
    final snapshot = await repo.getFriends();
    return snapshot.incoming.length;
  } catch (_) {
    return 0;
  }
}

final friendsIncomingCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield 0;
    return;
  }

  final repo = ref.watch(friendsRepositoryProvider);
  final controller = StreamController<int>();
  RealtimeSocket? socket;
  StreamSubscription<String>? socketSubscription;
  Timer? reconnectTimer;

  Future<void> load() async {
    final count = await _loadIncomingCount(repo);
    if (!controller.isClosed) controller.add(count);
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
        if (!raw.contains('friends_updated')) return;
        unawaited(load());
      },
      onError: (_) => scheduleReconnect(),
      onDone: scheduleReconnect,
      cancelOnError: false,
    );
  }

  void scheduleReconnect() {
    if (reconnectTimer != null || controller.isClosed) return;
    reconnectTimer = Timer(const Duration(seconds: 2), () {
      reconnectTimer = null;
      unawaited(connect());
    });
  }

  await load();
  unawaited(connect());

  ref.onDispose(() {
    reconnectTimer?.cancel();
    unawaited(socketSubscription?.cancel());
    socket?.close();
    controller.close();
  });

  yield* controller.stream;
});
