import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_card.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
import 'package:multigames_client/games/uno/uno_seats.dart';

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
      'last_round_winner_user_id': 'p0',
      'last_round_points': 42,
      'last_round_number': 3,
      'status': 'between_rounds',
    });

    expect(view.myIndex, 1);
    expect(view.isBetweenRounds, isTrue);
    expect(view.isMyTurn, isFalse);
    expect(view.lastRoundWinnerUserId, 'p0');
    expect(view.lastRoundPoints, 42);
    expect(view.lastEventType, 'wd4_reveal');
    expect(view.lastEventCard?.color, UnoColor.red);
    expect(view.lastDrawCount, 4);
    expect(view.eventSeq, 9);
  });

  test('shouldAnimateRemoteUnoPlay skips own just-played card', () {
    const players = [
      UnoPlayerView(
        id: 'me',
        seat: 0,
        hand: [],
        handCount: 5,
        score: 0,
        saidUno: false,
        forfeited: false,
      ),
      UnoPlayerView(
        id: 'opp',
        seat: 1,
        hand: [],
        handCount: 6,
        score: 0,
        saidUno: false,
        forfeited: false,
      ),
    ];
    expect(
      shouldAnimateRemoteUnoPlay(
        lastEventType: 'play',
        lastEventActor: 'me',
        viewerUserId: 'me',
        myIndex: 0,
        players: players,
        topCardId: 'card-7',
        localPlayCardId: 'card-7',
      ),
      isFalse,
    );
    expect(
      shouldAnimateRemoteUnoPlay(
        lastEventType: 'play',
        lastEventActor: 'opp',
        viewerUserId: 'me',
        myIndex: 0,
        players: players,
        topCardId: 'card-9',
        localPlayCardId: 'card-7',
      ),
      isTrue,
    );
    expect(
      shouldAnimateRemoteUnoPlay(
        lastEventType: '',
        lastEventActor: 'opp',
        viewerUserId: 'me',
        myIndex: 0,
        players: players,
        topCardId: 'card-7',
        localPlayCardId: 'card-7',
      ),
      isFalse,
    );
    expect(
      shouldAnimateRemoteUnoPlay(
        lastEventType: 'play',
        lastEventActor: 'opp',
        viewerUserId: 'me',
        myIndex: 0,
        players: players,
        topCardId: 'opp-card',
        lastEventCardId: 'card-7',
        localPlayCardId: 'card-7',
        localPlayedIds: {'card-7'},
      ),
      isFalse,
    );
  });

  test('unoVisibleHand hides cards already flying to discard', () {
    const hand = [
      UnoCard(
          id: 'a', color: UnoColor.red, kind: UnoCardKind.number, number: 1),
      UnoCard(
          id: 'b', color: UnoColor.blue, kind: UnoCardKind.number, number: 2),
    ];
    expect(unoVisibleHand(hand, const {}).map((c) => c.id), ['a', 'b']);
    expect(unoVisibleHand(hand, {'a'}).map((c) => c.id), ['b']);
    expect(
      unoVisibleHand(hand, {'a', 'b'}).map((c) => c.id),
      isEmpty,
    );
  });

  test('unoVisibleDiscard keeps old pile until override arrives', () {
    const oldTop = UnoCard(
      id: 'old',
      color: UnoColor.green,
      kind: UnoCardKind.number,
      number: 5,
    );
    const flying = UnoCard(
      id: 'new',
      color: UnoColor.red,
      kind: UnoCardKind.number,
      number: 7,
    );
    expect(
      unoVisibleDiscard(serverTop: flying, override: oldTop)?.id,
      'old',
    );
    expect(
      unoVisibleDiscard(serverTop: oldTop, override: flying)?.id,
      'new',
    );
    expect(unoVisibleDiscard(serverTop: oldTop)?.id, 'old');
  });

  test('opponent seats go clockwise from the hero', () {
    expect(
      unoOpponentSeatOrder(myIndex: 0, playerCount: 4, direction: 1),
      [1, 2, 3],
    );
    expect(
      unoOpponentSeatOrder(myIndex: 2, playerCount: 4, direction: 1),
      [3, 0, 1],
    );
    expect(
      unoOpponentSeatOrder(myIndex: 1, playerCount: 3, direction: -1),
      [0, 2],
    );
  });

  test('в альбоме соперники делятся по боковым колонкам, сверху никого', () {
    expect(unoLandscapeSideColumns(const []), [[], []]);
    expect(unoLandscapeSideColumns(const [1]), [
      [1],
      <int>[],
    ]);
    expect(unoLandscapeSideColumns(const [1, 2]), [
      [1],
      [2],
    ]);
    // Трое: двое слева, один справа — верхнего места нет.
    expect(unoLandscapeSideColumns(const [1, 2, 3]), [
      [1, 2],
      [3],
    ]);
    // Порядок мест сохраняется: колонки — это разрез исходного списка.
    final seats = unoOpponentSeatOrder(
      myIndex: 0,
      playerCount: 4,
      direction: 1,
    );
    final columns = unoLandscapeSideColumns(seats);
    expect([...columns[0], ...columns[1]], seats);
    expect(columns[0].length - columns[1].length, inInclusiveRange(0, 1));
  });

  test('timeout loss is detected for the eliminated player', () {
    final view = UnoGameView.fromJson({
      'id': 'g-timeout',
      'players': [
        {
          'user_id': 'me',
          'seat': 0,
          'hand': <Map<String, Object>>[],
          'hand_count': 4,
          'score': 0,
          'forfeited': true,
        },
        {
          'user_id': 'opp',
          'seat': 1,
          'hand': <Map<String, Object>>[],
          'hand_count': 3,
          'score': 0,
        },
      ],
      'my_index': 0,
      'status': 'over',
      'winner_user_ids': ['opp'],
      'is_timeout': true,
      'stake_bronze': 2,
    });
    expect(view.iLostOnTimeout, isTrue);
    expect(view.iWon, isFalse);
  });

  test('shouldPlayUnoCallSfx plays once per new call_uno event', () {
    expect(
      shouldPlayUnoCallSfx(
        eventSeq: 4,
        heardSeq: 3,
        lastEventType: 'call_uno',
      ),
      isTrue,
    );
    expect(
      shouldPlayUnoCallSfx(
        eventSeq: 4,
        heardSeq: 4,
        lastEventType: 'call_uno',
      ),
      isFalse,
    );
    expect(
      shouldPlayUnoCallSfx(
        eventSeq: 5,
        heardSeq: 4,
        lastEventType: 'play',
      ),
      isFalse,
    );
  });
}
