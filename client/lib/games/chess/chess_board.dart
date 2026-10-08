import 'package:flutter/material.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';

const Color _kLightSquare = Color(0xFFEBECD0);
const Color _kDarkSquare = Color(0xFF739552);
const Color _kLastMove = Color(0xFFF6EB72);
const Color _kSelect = Color(0xFF8BC34A);
const Color _kCheck = Color(0xFFE57373);

/// Отображение клетки доски на экранные координаты и обратно.
class ChessBoardGeometry {
  const ChessBoardGeometry({required this.side, required this.flip});

  final double side;
  final bool flip;

  double get cell => side / ChessEngine.size;

  /// Прямоугольник клетки доски (r,c) на экране.
  Rect rectOf(int r, int c) {
    final visR = flip ? r : ChessEngine.size - 1 - r;
    final visC = flip ? ChessEngine.size - 1 - c : c;
    return Rect.fromLTWH(visC * cell, visR * cell, cell, cell);
  }

  /// Клетка доски под точкой на экране (или null вне доски).
  ChessSquare? squareAt(double dx, double dy) {
    if (dx < 0 || dy < 0 || dx >= side || dy >= side) return null;
    final visC = (dx / cell).floor().clamp(0, ChessEngine.size - 1);
    final visR = (dy / cell).floor().clamp(0, ChessEngine.size - 1);
    final r = flip ? visR : ChessEngine.size - 1 - visR;
    final c = flip ? ChessEngine.size - 1 - visC : visC;
    return ChessSquare(r, c);
  }
}

/// Шахматная доска 8×8 с подсветкой, легальными ходами и координатами.
class ChessBoard extends StatelessWidget {
  const ChessBoard({
    super.key,
    required this.game,
    required this.selected,
    required this.flip,
    required this.onSquareTap,
    this.cursor,
  });

  final ChessGameView game;
  final ChessSquare? selected;
  final bool flip;
  final void Function(int r, int c) onSquareTap;
  final ChessSquare? cursor;

  @override
  Widget build(BuildContext context) {
    final targets = <ChessSquare>{
      if (selected != null)
        for (final m in game.legalMoves)
          if (m.from == selected) m.to,
    };
    final captureTargets = <ChessSquare>{
      if (selected != null)
        for (final m in game.legalMoves)
          if (m.from == selected &&
              game.board[m.to.r * ChessEngine.size + m.to.c] != ChessEngine.empty)
            m.to,
    };
    // Клетка короля под шахом — для подсветки.
    ChessSquare? checkSquare;
    if (game.inCheck && !game.isOver) {
      final king =
          game.turn == 1 ? ChessEngine.blackKing : ChessEngine.whiteKing;
      for (var i = 0; i < game.board.length; i++) {
        if (game.board[i] == king) {
          checkSquare = ChessSquare(i ~/ ChessEngine.size, i % ChessEngine.size);
          break;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final geo = ChessBoardGeometry(side: side, flip: flip);
        final pieces = <Widget>[];
        for (var i = 0; i < game.board.length; i++) {
          final piece = game.board[i];
          if (piece == ChessEngine.empty) continue;
          final r = i ~/ ChessEngine.size;
          final c = i % ChessEngine.size;
          final rect = geo.rectOf(r, c);
          pieces.add(Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: IgnorePointer(child: ChessPieceGlyph(piece: piece)),
          ));
        }
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(side * 0.02),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChessBoardPainter(
                        geo: geo,
                        selected: selected,
                        cursor: cursor,
                        targets: targets,
                        captureTargets: captureTargets,
                        lastFrom: game.lastFromR >= 0
                            ? ChessSquare(game.lastFromR, game.lastFromC)
                            : null,
                        lastTo: game.lastToR >= 0
                            ? ChessSquare(game.lastToR, game.lastToC)
                            : null,
                        checkSquare: checkSquare,
                      ),
                    ),
                  ),
                  ...pieces,
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final sq = geo.squareAt(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        );
                        if (sq != null) onSquareTap(sq.r, sq.c);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChessBoardPainter extends CustomPainter {
  _ChessBoardPainter({
    required this.geo,
    required this.selected,
    required this.cursor,
    required this.targets,
    required this.captureTargets,
    required this.lastFrom,
    required this.lastTo,
    required this.checkSquare,
  });

  final ChessBoardGeometry geo;
  final ChessSquare? selected;
  final ChessSquare? cursor;
  final Set<ChessSquare> targets;
  final Set<ChessSquare> captureTargets;
  final ChessSquare? lastFrom;
  final ChessSquare? lastTo;
  final ChessSquare? checkSquare;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..isAntiAlias = false;
    final cell = geo.cell;
    final labelStyle = TextStyle(
      fontSize: cell * 0.2,
      fontWeight: FontWeight.w700,
    );
    for (var r = 0; r < ChessEngine.size; r++) {
      for (var c = 0; c < ChessEngine.size; c++) {
        final rect = geo.rectOf(r, c);
        final dark = (r + c) % 2 == 0;
        fill.color = dark ? _kDarkSquare : _kLightSquare;
        canvas.drawRect(rect, fill);
        final sq = ChessSquare(r, c);
        if (sq == checkSquare) {
          fill.color = _kCheck.withValues(alpha: 0.72);
          canvas.drawRect(rect, fill);
        } else if (sq == selected) {
          fill.color = _kSelect.withValues(alpha: 0.5);
          canvas.drawRect(rect, fill);
        } else if (sq == lastFrom || sq == lastTo) {
          fill.color = _kLastMove.withValues(alpha: 0.5);
          canvas.drawRect(rect, fill);
        }
        if (sq == cursor) {
          canvas.drawRect(
            rect.deflate(1.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = AppColors.accentStart,
          );
        }
        _paintCoordinates(canvas, rect, r, c, dark, labelStyle);
      }
    }
    // Точки/кольца легальных ходов — поверх клеток.
    for (final sq in targets) {
      final rect = geo.rectOf(sq.r, sq.c);
      if (captureTargets.contains(sq)) {
        canvas.drawCircle(
          rect.center,
          cell * 0.46,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.09
            ..color = const Color(0x55000000),
        );
      } else {
        canvas.drawCircle(
          rect.center,
          cell * 0.16,
          Paint()
            ..isAntiAlias = true
            ..color = const Color(0x55000000),
        );
      }
    }
  }

  void _paintCoordinates(
    Canvas canvas,
    Rect rect,
    int r,
    int c,
    bool dark,
    TextStyle style,
  ) {
    final labelColor = dark ? _kLightSquare : _kDarkSquare;
    // Буквы файлов — на нижнем ряду визуально.
    final visR = geo.flip ? r : ChessEngine.size - 1 - r;
    final visC = geo.flip ? ChessEngine.size - 1 - c : c;
    if (visR == ChessEngine.size - 1) {
      final file = String.fromCharCode('a'.codeUnitAt(0) + c);
      _text(canvas, file, style.copyWith(color: labelColor),
          Offset(rect.right - rect.width * 0.26, rect.bottom - rect.height * 0.26));
    }
    if (visC == 0) {
      final rank = (r + 1).toString();
      _text(canvas, rank, style.copyWith(color: labelColor),
          Offset(rect.left + rect.width * 0.06, rect.top + rect.height * 0.04));
    }
  }

  void _text(Canvas canvas, String s, TextStyle style, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ChessBoardPainter old) =>
      old.geo.flip != geo.flip ||
      old.geo.side != geo.side ||
      old.selected != selected ||
      old.cursor != cursor ||
      old.lastFrom != lastFrom ||
      old.lastTo != lastTo ||
      old.checkSquare != checkSquare ||
      old.targets.length != targets.length ||
      old.captureTargets.length != captureTargets.length ||
      !old.targets.containsAll(targets);
}

/// Фигура глифом Unicode: заливка + контрастный контур для чёткости.
class ChessPieceGlyph extends StatelessWidget {
  const ChessPieceGlyph({super.key, required this.piece});

  final int piece;

  static const _glyphs = {
    ChessEngine.whitePawn: '♟',
    ChessEngine.whiteKnight: '♞',
    ChessEngine.whiteBishop: '♝',
    ChessEngine.whiteRook: '♜',
    ChessEngine.whiteQueen: '♛',
    ChessEngine.whiteKing: '♚',
    ChessEngine.blackPawn: '♟',
    ChessEngine.blackKnight: '♞',
    ChessEngine.blackBishop: '♝',
    ChessEngine.blackRook: '♜',
    ChessEngine.blackQueen: '♛',
    ChessEngine.blackKing: '♚',
  };

  @override
  Widget build(BuildContext context) {
    final glyph = _glyphs[piece] ?? '';
    if (glyph.isEmpty) return const SizedBox.shrink();
    final white = ChessEngine.colorOf(piece) == 0;
    final fill = white ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A);
    final stroke = white ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.biggest.shortestSide;
        final fontSize = s * 0.82;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                glyph,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = s * 0.045
                    ..color = stroke,
                ),
              ),
              Text(
                glyph,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.0,
                  color: fill,
                  shadows: const [
                    Shadow(color: Color(0x55000000), blurRadius: 1.5, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
