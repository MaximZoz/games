import 'package:multigames_client/games/chess/chess_engine.dart';

/// Перевес материала у одного игрока, как на lichess.
///
/// Показываются только фигуры, которых у этой стороны больше, чем у соперника
/// (иконка — цвет съеденной фигуры). `advantage` — перевес в пешках; 0, если
/// сторона не впереди по сумме.
class ChessMaterial {
  const ChessMaterial({required this.captured, required this.advantage});

  /// Коды фигур соперника, которых у этой стороны больше. Порядок: пешка,
  /// конь, слон, ладья, ферзь.
  final List<int> captured;

  /// Положительный перевес в пешках (п=1, к/с=3, л=5, ф=9). Иначе 0.
  final int advantage;

  static const empty = ChessMaterial(captured: [], advantage: 0);

  @override
  bool operator ==(Object other) =>
      other is ChessMaterial &&
      other.advantage == advantage &&
      _same(other.captured, captured);

  @override
  int get hashCode => Object.hash(advantage, Object.hashAll(captured));
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const List<int> _kindValue = [0, 1, 3, 3, 5, 9];

/// [seat] 0 — белые, 1 — чёрные.
ChessMaterial chessMaterialFor(List<int> board, int seat) {
  if (seat != 0 && seat != 1) return ChessMaterial.empty;
  final counts = List<int>.filled(13, 0);
  for (final piece in board) {
    if (piece >= ChessEngine.whitePawn && piece <= ChessEngine.blackKing) {
      counts[piece]++;
    }
  }
  int count(int color, int kind) => counts[kind + color * 6];

  final other = 1 - seat;
  final captured = <int>[];
  var score = 0;
  for (var kind = 1; kind <= 5; kind++) {
    final diff = count(seat, kind) - count(other, kind);
    score += diff * _kindValue[kind];
    if (diff > 0) {
      final taken = kind + other * 6;
      for (var i = 0; i < diff; i++) {
        captured.add(taken);
      }
    }
  }
  return ChessMaterial(
    captured: captured,
    advantage: score > 0 ? score : 0,
  );
}
