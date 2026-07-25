import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_visibility_stub.dart'
    if (dart.library.html) 'realtime_visibility_web.dart' as visibility;
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
  var disposed = false;
  var disconnectedDueToVisibility = false;
  void Function()? cancelVisibilityListener;
  void emitAfterFrame(Map<String, dynamic> data) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!disposed && !controller.isClosed) controller.add(data);
      });
    });
  }

  RealtimeSocket? socket;
  StreamSubscription<String>? socketSubscription;
  Timer? reconnectTimer;
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
    emitAfterFrame(const {'type': 'realtime_connected'});

    cancelVisibilityListener?.call();
    cancelVisibilityListener = visibility.setupRealtimeVisibilityDisconnect(
      hiddenTimeout: const Duration(seconds: 90),
      onHiddenTimeout: () {
        if (disposed || socket == null) return;
        disconnectedDueToVisibility = true;
        socket?.close();
        unawaited(socketSubscription?.cancel());
        socket = null;
      },
      onVisible: () {
        if (disposed) return;
        if (disconnectedDueToVisibility) {
          disconnectedDueToVisibility = false;
          unawaited(connect());
        }
      },
    );

    socketSubscription = nextSocket.messages.listen(
      (raw) {
        try {
          final payload = jsonDecode(raw);
          if (payload is! Map) return;
          final event = Map<String, dynamic>.from(payload);
          emitAfterFrame(event);
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
    if (disposed || disconnectedDueToVisibility) return;
    if (reconnectTimer != null || controller.isClosed) return;
    reconnectTimer = Timer(const Duration(seconds: 2), () {
      reconnectTimer = null;
      if (!disposed && !disconnectedDueToVisibility) {
        unawaited(connect());
      }
    });
  };

  unawaited(connect());

  ref.onDispose(() {
    disposed = true;
    keepAliveLink.close();
    reconnectTimer?.cancel();
    cancelVisibilityListener?.call();
    unawaited(socketSubscription?.cancel());
    socket?.close();
    unawaited(controller.close());
  });

  return controller.stream;
});
