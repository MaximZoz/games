import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multigames_client/games/checkers/checkers_board_layout.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_piece_tracker.dart';
import 'package:multigames_client/games/checkers/checkers_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';

const Color _kLightSquare = Color(0xFFF0D9B5);
const Color _kDarkSquare = Color(0xFFB58863);
const Color _kSelectTint = Color(0xFF65A30D);
const Color _kOriginTint = Color(0xFFCA8A04);
const Color _kCaptureDot = Color(0xFFDC2626);

/// Доска 8×8: клетки одной сеткой, шашки едут плавно.
class CheckersBoard extends StatefulWidget {
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

  static const Curve moveCurve = Curves.easeInOutCubic;

  @override
  State<CheckersBoard> createState() => _CheckersBoardState();
}

class _CheckersBoardState extends State<CheckersBoard> {
  final CheckersPieceTracker _tracker = CheckersPieceTracker();

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final flip = widget.flip;
    final selected = widget.selected;
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
    final spots = _tracker.spotsFor(
      game.board,
      lastFromR: game.lastFromR,
      lastFromC: game.lastFromC,
      lastToR: game.lastToR,
      lastToC: game.lastToC,
    );
    final duration = checkersMoveDuration(
      fromR: game.lastFromR,
      fromC: game.lastFromC,
      toR: game.lastToR,
      toC: game.lastToC,
    );
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
                        cursor: widget.cursor,
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
                  for (final spot in spots)
                    _animatedPiece(
                      side: side,
                      spot: spot,
                      flip: flip,
                      duration: duration,
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
                        if (sq != null) widget.onSquareTap(sq.r, sq.c);
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

  Widget _animatedPiece({
    required double side,
    required CheckersPieceSpot spot,
    required bool flip,
    required Duration duration,
  }) {
    final visR = flip ? CheckersEngine.size - 1 - spot.r : spot.r;
    final visC = flip ? CheckersEngine.size - 1 - spot.c : spot.c;
    final rect = checkersCellRect(side, visR, visC);
    final pad = rect.shortestSide * 0.08;
    return AnimatedPositioned(
      key: ValueKey('checkers-piece-${spot.id}'),
      duration: duration,
      curve: CheckersBoard.moveCurve,
      left: rect.left + pad,
      top: rect.top + pad,
      width: rect.width - pad * 2,
      height: rect.height - pad * 2,
      child: IgnorePointer(
        child: CheckersPieceView(piece: spot.piece),
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
              ..color =
                  (captureTargets.contains(sq) ? _kCaptureDot : _kSelectTint)
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

/// Точёная шашка: обод, канавка, блик; у дамки — корона.
class CheckersPieceView extends StatelessWidget {
  const CheckersPieceView({super.key, required this.piece});

  final int piece;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CheckersPiecePainter(piece: piece),
      child: const SizedBox.expand(),
    );
  }
}

class CheckersPiecePainter extends CustomPainter {
  CheckersPiecePainter({required this.piece});

  final int piece;

  @override
  void paint(Canvas canvas, Size size) {
    final white =
        piece == CheckersEngine.whiteMan || piece == CheckersEngine.whiteKing;
    final king = CheckersEngine.isKing(piece);
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final r = s * 0.46;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.18),
        width: r * 1.72,
        height: r * 0.42,
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );

    final body = white
        ? const [Color(0xFFFFF8EC), Color(0xFFE8D7B4), Color(0xFFC9B48A)]
        : const [Color(0xFF5A3A28), Color(0xFF2A1810), Color(0xFF140C08)];
    final rim = white ? const Color(0xFFB8956A) : const Color(0xFF8A5A2B);
    final groove = white ? const Color(0x66A07848) : const Color(0x88E8C878);
    final shine = white ? const Color(0xCCFFFFFF) : const Color(0x66F5E6C8);

    canvas.drawCircle(
      Offset(c.dx, c.dy + r * 0.06),
      r * 0.96,
      Paint()
        ..shader = RadialGradient(
          colors: [body[1], body[2]],
          radius: 0.85,
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [body[0], body[1], body[2]],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..color = rim,
    );
    canvas.drawCircle(
      c,
      r * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..color = groove,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - r * 0.22, c.dy - r * 0.28),
        width: r * 0.7,
        height: r * 0.32,
      ),
      Paint()..color = shine,
    );

    if (!king) return;
    final gold = white ? const Color(0xFFD97706) : const Color(0xFFFBBF24);
    final crownR = r * 0.42;
    final path = Path()
      ..moveTo(c.dx - crownR, c.dy + crownR * 0.15)
      ..lineTo(c.dx - crownR * 0.72, c.dy - crownR * 0.55)
      ..lineTo(c.dx - crownR * 0.28, c.dy - crownR * 0.08)
      ..lineTo(c.dx, c.dy - crownR * 0.72)
      ..lineTo(c.dx + crownR * 0.28, c.dy - crownR * 0.08)
      ..lineTo(c.dx + crownR * 0.72, c.dy - crownR * 0.55)
      ..lineTo(c.dx + crownR, c.dy + crownR * 0.15)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = gold
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = white ? const Color(0xFF92400E) : const Color(0xFFFDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025,
    );
  }

  @override
  bool shouldRepaint(covariant CheckersPiecePainter oldDelegate) =>
      oldDelegate.piece != piece;
}
