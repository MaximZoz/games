import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_ws.dart';

/// Общий поток событий realtime (WebSocket), чтобы не открывать отдельный сокет
/// под каждый экран/провайдер.
final realtimeEventsProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return const Stream<Map<String, dynamic>>.empty();
  }

  final controller = StreamController<Map<String, dynamic>>();
  RealtimeSocket? socket;
  StreamSubscription<String>? socketSubscription;
  Timer? reconnectTimer;
  var disposed = false;
  late void Function() scheduleReconnect;

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
    if (!controller.isClosed) {
      controller.add(const {'type': 'realtime_connected'});
    }
    socketSubscription = nextSocket.messages.listen(
      (raw) {
        if (controller.isClosed) return;
        try {
          final payload = jsonDecode(raw);
          if (payload is! Map) return;
          controller.add(Map<String, dynamic>.from(payload));
        } catch (_) {
          // Игнорируем невалидные фреймы, чтобы не ронять соединение.
        }
      },
      onError: (_) => scheduleReconnect(),
      onDone: scheduleReconnect,
      cancelOnError: false,
    );
  }

  scheduleReconnect = () {
    if (disposed || reconnectTimer != null || controller.isClosed) return;
    reconnectTimer = Timer(const Duration(seconds: 2), () {
      reconnectTimer = null;
      if (!disposed) {
        unawaited(connect());
      }
    });
  };

  unawaited(connect());

  ref.onDispose(() {
    disposed = true;
    keepAliveLink.close();
    reconnectTimer?.cancel();
    unawaited(socketSubscription?.cancel());
    socket?.close();
    unawaited(controller.close());
  });

  return controller.stream;
});
