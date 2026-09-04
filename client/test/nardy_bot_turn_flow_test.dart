import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

/// Доиграть свой ход целиком и передать очередь боту.
void _finishMyTurn(OfflineNardySession session) {
  for (var guard = 0; guard < 20; guard++) {
    final view = session.view;
    if (!view.isMyTurn || view.isOver) return;
    if (view.needsRoll) {
      session.applyLocalAction({'action': 'roll'});
      continue;
    }
    if (view.legalMoves.isEmpty) {
      session.applyLocalAction({'action': 'end_turn'});
      return;
    }
    final mv = view.legalMoves.first;
    session.applyLocalAction({
      'action': 'move',
      'from': mv.from,
      'die': mv.die,
    });
  }
}

int _oppCheckers(NardyGameView view) {
  var total = 0;
  for (final point in view.board) {
    if (point < 0) total -= point;
  }
  return total;
}

List<int> _oppLayout(NardyGameView view) =>
    [for (final point in view.board) point < 0 ? -point : 0];

void main() {
  tearDown(OfflineNardyRegistry.instance.disposeAll);

  testWidgets('бот реально двигает шашки, а не только бросает кубики',
      (tester) async {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeShort,
    );
    _finishMyTurn(session);
    expect(session.view.turn, 1, reason: 'очередь должна уйти боту');

    final before = _oppLayout(session.view);
    // Прогоняем таймеры бота: бросок и все его шашки.
    for (var tick = 0; tick < 12 && session.view.turn == 1; tick++) {
      await tester.pump(OfflineNardySession.botStepDelay);
    }

    expect(session.view.turn, 0, reason: 'бот обязан вернуть ход');
    expect(_oppLayout(session.view), isNot(before),
        reason: 'бот должен переставить хотя бы одну шашку');
    expect(_oppCheckers(session.view), 15);
  });

  testWidgets('ход бота приходит несколькими кадрами', (tester) async {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeLong,
    );
    _finishMyTurn(session);
    expect(session.view.turn, 1);

    var frames = 0;
    void onChange() => frames++;
    session.addListener(onChange);
    addTearDown(() => session.removeListener(onChange));

    for (var tick = 0; tick < 12 && session.view.turn == 1; tick++) {
      await tester.pump(OfflineNardySession.botStepDelay);
    }

    expect(session.view.turn, 0);
    expect(frames, greaterThanOrEqualTo(3),
        reason: 'бросок, шашки и закрытие хода — разные кадры');
  });

  testWidgets('несколько ходов подряд: бот каждый раз ходит', (tester) async {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeShort,
    );
    for (var round = 0; round < 4; round++) {
      _finishMyTurn(session);
      if (session.view.isOver) break;
      expect(session.view.turn, 1, reason: 'круг $round: очередь у бота');
      final before = _oppLayout(session.view);
      for (var tick = 0; tick < 12 && session.view.turn == 1; tick++) {
        await tester.pump(OfflineNardySession.botStepDelay);
      }
      expect(session.view.turn, 0, reason: 'круг $round: ход вернулся');
      expect(_oppLayout(session.view), isNot(before),
          reason: 'круг $round: бот должен был сходить');
    }
  });
}
