import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/realtime_ws.dart';

void main() {
  test('VM/Android uses a live socket factory, not the no-op stub', () {
    final socket = connectRealtimeSocket(Uri.parse('ws://127.0.0.1:1/api/ws'));
    addTearDown(socket.close);
    expect(socket.messages, isA<Stream<String>>());
    expect(socket.connected, isA<Stream<void>>());
    expect(socket.isOpen, isFalse);
  });

  test('failed connect ends the stream so the client can reconnect', () async {
    final socket = connectRealtimeSocket(Uri.parse('ws://127.0.0.1:1/api/ws'));
    addTearDown(socket.close);
    var finished = false;
    final sub = socket.messages.listen(
      (_) {},
      onError: (_) => finished = true,
      onDone: () => finished = true,
    );
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(finished, isTrue);
  });
}
