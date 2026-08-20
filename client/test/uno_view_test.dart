import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';

void main() {
  test('UnoGameView reads my_index and WD4 proof card', () {
    final view = UnoGameView.fromJson({
      'id': 'g1',
      'players': [
        {
          'user_id': 'p0',
          'seat': 0,
          'hand': [
            {'id': 'r7', 'color': 'red', 'kind': 'number', 'number': 7},
          ],
          'hand_count': 1,
          'score': 0,
        },
        {
          'user_id': 'p1',
          'seat': 1,
          'hand': [],
          'hand_count': 4,
          'score': 10,
        },
      ],
      'my_index': 1,
      'current_index': 1,
      'last_event_type': 'wd4_reveal',
      'last_event_actor': 'p0',
      'last_event_card': {
        'id': 'proof-red',
        'color': 'red',
        'kind': 'number',
        'number': 2,
      },
      'last_draw_user_id': 'p0',
      'last_draw_count': 4,
      'event_seq': 9,
    });

    expect(view.myIndex, 1);
    expect(view.isMyTurn, isTrue);
    expect(view.lastEventType, 'wd4_reveal');
    expect(view.lastEventCard?.color, UnoColor.red);
    expect(view.lastDrawCount, 4);
    expect(view.eventSeq, 9);
  });
}
