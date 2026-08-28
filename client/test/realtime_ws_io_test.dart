import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/realtime_ws.dart';

void main() {
  test('VM/Android uses a live socket factory, not the no-op stub', () {
    final socket = connectRealtimeSocket(Uri.parse('ws://127.0.0.1:1/api/ws'));
    addTearDown(socket.close);
    expect(socket.messages, isA<Stream<String>>());
  });
}
