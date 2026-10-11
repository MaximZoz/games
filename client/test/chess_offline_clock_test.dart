import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_offline_session.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';

void main() {
  late DateTime now;
  OfflineChessSession? session;

  tearDown(() => session?.dispose());

  OfflineChessSession open(String mode) {
    now = DateTime.utc(2026, 1, 1);
    return OfflineChessSession.create(
      humanUserId: 'me',
      gameMode: mode,
      now: () => now,
    );
  }

  const e4 = ChessMove(
    from: ChessSquare(1, 4),
    to: ChessSquare(3, 4),
  );

  test('пуля с ботом стартует с 3+2, как онлайн', () {
    final s = session = open(chessModeBullet);
    final view = s.view;
    expect(view.hasClock, isTrue);
    expect(view.clockIncMs, 2000);
    expect(view.clockMs0, 3 * 60 * 1000);
    expect(view.clockMs1, 3 * 60 * 1000);
    expect(view.clockRunning, 0);
  });

  test('ход списывает время и добавляет прибавку', () {
    final s = session = open(chessModeBullet);
    now = now.add(const Duration(seconds: 5));
    s.move(e4);
    // 180000 - 5000 + 2000
    expect(s.view.clockMs0, 177000);
    expect(s.view.clockRunning, 1);
    s.debugRunBotTurn();
    // бот сходил мгновенно по тестовым часам: 180000 + 2000
    expect(s.view.clockMs1, 182000);
    expect(s.view.clockRunning, 0);
  });

  test('пока бот думает, его часы уменьшаются каждую секунду', () {
    final s = session = open(chessModeBlitz);
    var notices = 0;
    s.addListener(() => notices++);
    s.move(e4);
    expect(s.view.clockRunning, 1);
    final bank = s.view.clockMs1;
    now = now.add(const Duration(seconds: 3));
    s.debugPublishRunningClock();
    expect(notices, greaterThan(0));
    expect(s.view.clockMs1, bank - 3000);
    expect(s.view.clockRunning, 1);
    expect(s.view.clockMs0, 5 * 60 * 1000);
  });

  test('блиц 5+0 без прибавки', () {
    final s = session = open(chessModeBlitz);
    expect(s.view.clockMs0, 5 * 60 * 1000);
    expect(s.view.clockIncMs, 0);
    now = now.add(const Duration(seconds: 2));
    s.move(e4);
    expect(s.view.clockMs0, 5 * 60 * 1000 - 2000);
  });

  test('время вышло — поражение по времени', () {
    final s = session = open(chessModeBullet);
    now = now.add(const Duration(minutes: 4));
    s.move(e4);
    final view = s.view;
    expect(view.isOver, isTrue);
    expect(view.isTimeout, isTrue);
    expect(view.winnerIndex, 1);
    expect(view.clockMs0, 0);
    expect(view.clockRunning, -1);
  });
}
