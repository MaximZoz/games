import 'package:flutter/material.dart';
import 'package:multigames_client/games/checkers/checkers_board.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';

/// Разница шашек и дамок: мои минус соперника.
///
/// Положительное число — перевес, отрицательное — отставание.
class CheckersMaterialDiff {
  const CheckersMaterialDiff({required this.men, required this.kings});

  final int men;
  final int kings;

  @override
  bool operator ==(Object other) =>
      other is CheckersMaterialDiff &&
      other.men == men &&
      other.kings == kings;

  @override
  int get hashCode => Object.hash(men, kings);
}

CheckersMaterialDiff checkersMaterialDiff(List<int> board, int seat) {
  var myMen = 0;
  var myKings = 0;
  var theirMen = 0;
  var theirKings = 0;
  for (final piece in board) {
    final owner = CheckersEngine.owner(piece);
    if (owner < 0) continue;
    final king = CheckersEngine.isKing(piece);
    if (owner == seat) {
      if (king) {
        myKings++;
      } else {
        myMen++;
      }
    } else if (king) {
      theirKings++;
    } else {
      theirMen++;
    }
  }
  return CheckersMaterialDiff(men: myMen - theirMen, kings: myKings - theirKings);
}

/// Одна шашка и `+N`/`−N`, одна дамка и своя цифра. Ноль не показываем.
class CheckersMaterialLine extends StatelessWidget {
  const CheckersMaterialLine({
    super.key,
    required this.board,
    required this.seat,
  });

  final List<int> board;
  final int seat;

  @override
  Widget build(BuildContext context) {
    if (seat < 0) return const SizedBox.shrink();
    final diff = checkersMaterialDiff(board, seat);
    if (diff.men == 0 && diff.kings == 0) return const SizedBox.shrink();
    final man = seat == 0 ? CheckersEngine.whiteMan : CheckersEngine.blackMan;
    final king =
        seat == 0 ? CheckersEngine.whiteKing : CheckersEngine.blackKing;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (diff.men != 0) ...[
            _piece(man),
            _count(diff.men),
          ],
          if (diff.kings != 0) ...[
            if (diff.men != 0) const SizedBox(width: 8),
            _piece(king),
            _count(diff.kings),
          ],
        ],
      ),
    );
  }

  Widget _piece(int piece) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CheckersPieceView(piece: piece),
    );
  }

  Widget _count(int n) {
    final text = n > 0 ? '+$n' : '$n';
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5C6770),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
