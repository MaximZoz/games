import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';

void main() {
  test('инвайты и ходы эмитим сразу, без кадра задержки', () {
    expect(shouldEmitRealtimeImmediately('game_invite'), isTrue);
    expect(shouldEmitRealtimeImmediately('invite_cancelled'), isTrue);
    expect(shouldEmitRealtimeImmediately('game_state'), isTrue);
    expect(shouldEmitRealtimeImmediately('game_started'), isTrue);
    expect(shouldEmitRealtimeImmediately('realtime_connected'), isTrue);
    expect(shouldEmitRealtimeImmediately('lobby_updated'), isFalse);
    expect(shouldEmitRealtimeImmediately('presence'), isFalse);
  });
}
