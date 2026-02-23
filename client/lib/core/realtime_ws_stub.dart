import 'dart:async';

import 'realtime_socket.dart';

class _NoopRealtimeSocket implements RealtimeSocket {
  @override
  Stream<String> get messages => const Stream<String>.empty();

  @override
  bool get isOpen => false;

  @override
  void close() {}
}

RealtimeSocket createRealtimeSocket(Uri uri) {
  return _NoopRealtimeSocket();
}
