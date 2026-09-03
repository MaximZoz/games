import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException;
import 'package:multigames_client/games/nardy/nardy_bot.dart';
import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';

void main() {
  tearDown(OfflineNardyRegistry.instance.disposeAll);

  test('офлайн-партия стартует с броском и ходом игрока', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeLong,
    );
    final view = session.view;
    expect(view.myIndex, 0);
    expect(view.playerIds, ['me', nardyBotUserId]);
    expect(view.gameMode, nardyModeLong);
    expect(view.rolled, isNotEmpty);
    expect(view.isMyTurn, isTrue);
    expect(view.legalMoves, isNotEmpty);
    expect(view.stakeBronze, 0);
  });

  test('реестр узнаёт свои офлайн-партии', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeShort,
    );
    expect(OfflineNardyRegistry.instance.isOffline(session.gameId), isTrue);
    expect(OfflineNardyRegistry.instance.isOffline('some-uuid'), isFalse);
    expect(OfflineNardyRegistry.instance.get(session.gameId), same(session));
  });

  test('ход игрока применяется и передаёт очередь боту', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeLong,
    );
    // Доигрываем все кубики игрока — очередь должна уйти боту.
    for (var i = 0; i < 8 && session.view.isMyTurn; i++) {
      final moves = session.view.legalMoves;
      if (moves.isEmpty) {
        session.applyLocalAction({'action': 'end_turn'});
        break;
      }
      final mv = moves.first;
      session.applyLocalAction({
        'action': 'move',
        'from': mv.from,
        'die': mv.die,
      });
    }
    expect(session.view.isMyTurn, isFalse);
    expect(session.view.turn, 1);
  });

  test('нелегальный ход отклоняется', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeLong,
    );
    expect(
      () => session.applyLocalAction({
        'action': 'move',
        'from': 7,
        'die': 6,
      }),
      throwsA(isA<GamesException>()),
    );
  });

  test('сдача завершает партию победой бота', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeShort,
    );
    session.forfeit();
    final view = session.view;
    expect(view.isOver, isTrue);
    expect(view.winnerIndex, 1);
    expect(view.winnerUserId, nardyBotUserId);
    expect(view.isForfeit, isTrue);
  });

  test('повтор начинает новую партию', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeShort,
    );
    session.forfeit();
    expect(session.view.isOver, isTrue);
    session.restart();
    expect(session.view.isOver, isFalse);
    expect(session.view.off, [0, 0]);
  });

  test('ход бота отыгрывается целиком', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeLong,
    );
    while (session.view.isMyTurn && !session.view.isOver) {
      final moves = session.view.legalMoves;
      if (moves.isEmpty) {
        session.applyLocalAction({'action': 'end_turn'});
        break;
      }
      final mv = moves.first;
      session.applyLocalAction({
        'action': 'move',
        'from': mv.from,
        'die': mv.die,
      });
    }
    expect(session.view.turn, 1);
    session.debugRunBotTurn();
    expect(session.engine.turn, anyOf(0, 1));
    expect(session.view.rolled, isNotEmpty);
  });

  test('счёт шашек не ломается за длинную серию ходов', () {
    final session = OfflineNardySession.create(
      humanUserId: 'me',
      gameMode: nardyModeShort,
    );
    for (var i = 0; i < 300 && !session.view.isOver; i++) {
      final view = session.view;
      if (view.isMyTurn) {
        if (view.needsRoll) {
          session.applyLocalAction({'action': 'roll'});
          continue;
        }
        if (view.legalMoves.isEmpty) {
          session.applyLocalAction({'action': 'end_turn'});
          continue;
        }
        final mv = view.legalMoves.first;
        session.applyLocalAction({
          'action': 'move',
          'from': mv.from,
          'die': mv.die,
        });
      } else {
        session.debugRunBotTurn();
      }
      for (var seat = 0; seat < 2; seat++) {
        var total = session.engine.bar[seat] + session.engine.off[seat];
        for (var t = 0; t < nardyPoints; t++) {
          total += session.engine.countAt(seat, t);
        }
        expect(total, nardyCheckers);
      }
    }
  });
}
