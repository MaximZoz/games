import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multigames_client/games/checkers/checkers_board_layout.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';

const Color _kLightSquare = Color(0xFFF0D9B5);
const Color _kDarkSquare = Color(0xFFB58863);
const Color _kSelectTint = Color(0xFF65A30D);
const Color _kOriginTint = Color(0xFFCA8A04);
const Color _kCaptureDot = Color(0xFFDC2626);
const Color _kWhitePiece = Color(0xFFF8F4EA);
const Color _kWhiteEdge = Color(0xFFD6C7A1);
const Color _kBlackPiece = Color(0xFF3B2414);
const Color _kBlackEdge = Color(0xFF1A1008);

/// Доска 8×8: клетки рисуются одной сеткой, чтобы не было щелей и кривых квадратов.
class CheckersBoard extends StatelessWidget {
  const CheckersBoard({
    super.key,
    required this.game,
    required this.selected,
    required this.flip,
    required this.onSquareTap,
    this.cursor,
  });

  final CheckersGameView game;
  final CheckersSquare? selected;
  final bool flip;
  final void Function(int r, int c) onSquareTap;
  final CheckersSquare? cursor;

  @override
  Widget build(BuildContext context) {
    final targets = <CheckersSquare>{
      if (selected != null)
        for (final m in game.legalMoves)
          if (m.from == selected) m.to,
    };
    final captureTargets = <CheckersSquare>{
      if (selected != null)
        for (final m in game.legalMoves)
          if (m.from == selected && m.jumped.isNotEmpty) m.to,
    };
    final origins = <CheckersSquare>{
      for (final m in game.legalMoves) m.from,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(side * 0.03),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CheckersBoardPainter(
                        flip: flip,
                        selected: selected,
                        cursor: cursor,
                        targets: targets,
                        captureTargets: captureTargets,
                        origins: origins,
                        lastFromR: game.lastFromR,
                        lastFromC: game.lastFromC,
                        lastToR: game.lastToR,
                        lastToC: game.lastToC,
                      ),
                    ),
                  ),
                  for (var visR = 0; visR < CheckersEngine.size; visR++)
                    for (var visC = 0; visC < CheckersEngine.size; visC++)
                      _pieceLayer(
                        side: side,
                        visR: visR,
                        visC: visC,
                      ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final sq = checkersSquareAtLocal(
                          side: side,
                          dx: details.localPosition.dx,
                          dy: details.localPosition.dy,
                          flip: flip,
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

  Widget _pieceLayer({
    required double side,
    required int visR,
    required int visC,
  }) {
    final sq = checkersBoardSquare(visR: visR, visC: visC, flip: flip);
    final piece = sq.r * CheckersEngine.size + sq.c < game.board.length
        ? game.board[sq.r * CheckersEngine.size + sq.c]
        : 0;
    if (piece <= 0) return const SizedBox.shrink();
    final rect = checkersCellRect(side, visR, visC);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(rect.shortestSide * 0.11),
          child: _CheckersPiece(piece: piece),
        ),
      ),
    );
  }
}

class _CheckersBoardPainter extends CustomPainter {
  _CheckersBoardPainter({
    required this.flip,
    required this.selected,
    required this.cursor,
    required this.targets,
    required this.captureTargets,
    required this.origins,
    required this.lastFromR,
    required this.lastFromC,
    required this.lastToR,
    required this.lastToC,
  });

  final bool flip;
  final CheckersSquare? selected;
  final CheckersSquare? cursor;
  final Set<CheckersSquare> targets;
  final Set<CheckersSquare> captureTargets;
  final Set<CheckersSquare> origins;
  final int lastFromR;
  final int lastFromC;
  final int lastToR;
  final int lastToC;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final fill = Paint()..isAntiAlias = false;
    for (var visR = 0; visR < CheckersEngine.size; visR++) {
      for (var visC = 0; visC < CheckersEngine.size; visC++) {
        final sq = checkersBoardSquare(visR: visR, visC: visC, flip: flip);
        final dark = CheckersEngine.dark(sq.r, sq.c);
        final paintRect = checkersCellPaintRect(side, visR, visC);
        final cell = checkersCellRect(side, visR, visC);
        fill.color = dark ? _kDarkSquare : _kLightSquare;
        canvas.drawRect(paintRect, fill);
        final isSelected = selected == sq;
        final last = (lastFromR == sq.r && lastFromC == sq.c) ||
            (lastToR == sq.r && lastToC == sq.c);
        if (isSelected || last) {
          fill.color = (isSelected ? _kSelectTint : AppColors.accentStart)
              .withValues(alpha: 0.28);
          canvas.drawRect(paintRect, fill);
        } else if (origins.contains(sq)) {
          fill.color = _kOriginTint.withValues(alpha: 0.18);
          canvas.drawRect(paintRect, fill);
        }
        if (cursor == sq) {
          canvas.drawRect(
            paintRect.deflate(1.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = AppColors.accentStart,
          );
        }
        if (targets.contains(sq)) {
          final dot = checkersTargetDotSize(cell.shortestSide);
          canvas.drawCircle(
            cell.center,
            dot / 2,
            Paint()
              ..isAntiAlias = true
              ..color = (captureTargets.contains(sq) ? _kCaptureDot : _kSelectTint)
                  .withValues(alpha: 0.78),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckersBoardPainter oldDelegate) =>
      oldDelegate.flip != flip ||
      oldDelegate.selected != selected ||
      oldDelegate.cursor != cursor ||
      oldDelegate.lastFromR != lastFromR ||
      oldDelegate.lastFromC != lastFromC ||
      oldDelegate.lastToR != lastToR ||
      oldDelegate.lastToC != lastToC ||
      !setEquals(oldDelegate.targets, targets) ||
      !setEquals(oldDelegate.captureTargets, captureTargets) ||
      !setEquals(oldDelegate.origins, origins);
}

class _CheckersPiece extends StatelessWidget {
  const _CheckersPiece({required this.piece});

  final int piece;

  @override
  Widget build(BuildContext context) {
    final white = piece == CheckersEngine.whiteMan ||
        piece == CheckersEngine.whiteKing;
    final king = CheckersEngine.isKing(piece);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crown = constraints.biggest.shortestSide * 0.42;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: white ? _kWhitePiece : _kBlackPiece,
            border: Border.all(
              color: white ? _kWhiteEdge : _kBlackEdge,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: king
              ? Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: crown.clamp(10, 22),
                    color: white
                        ? const Color(0xFFB45309)
                        : const Color(0xFFFBBF24),
                  ),
                )
              : null,
        );
      },
    );
  }
}
