import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/games_repository.dart' show variantLabel;
import 'package:multigames_client/games/offline_tictactoe.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLastHumanStarted = 'offline_ttt_last_human_started';

/// Локальная игра с ботом(ами): без ставок, наград и API.
class OfflineTicTacToeScreen extends ConsumerStatefulWidget {
  const OfflineTicTacToeScreen({
    super.key,
    this.variant = variantClassic,
    this.gridSize = 3,
    this.swapRule = false,
    this.firstMoveRestriction = false,
  });

  final String variant;
  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;

  @override
  ConsumerState<OfflineTicTacToeScreen> createState() =>
      _OfflineTicTacToeScreenState();
}

class _OfflineTicTacToeScreenState
    extends ConsumerState<OfflineTicTacToeScreen> {
  OfflineTicTacToeGame? _game;
  bool _starting = true;
  bool _botThinking = false;
  Timer? _botTimer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  Future<void> _restart() async {
    _botTimer?.cancel();
    setState(() {
      _starting = true;
      _botThinking = false;
    });
    // По умолчанию в офлайне чередуем первого; для multi — человек всегда X.
    var humanStarts = true;
    final cfg = configForVariant(widget.variant);
    final alternate = widget.swapRule && cfg.maxPlayers <= 2;
    if (alternate) {
      final prefs = await SharedPreferences.getInstance();
      final lastHumanStarted = prefs.getBool(_keyLastHumanStarted) ?? false;
      humanStarts = !lastHumanStarted;
      await prefs.setBool(_keyLastHumanStarted, humanStarts);
    }
    if (!mounted) return;
    setState(() {
      _game = OfflineTicTacToeGame(
        variant: widget.variant,
        gridSize: widget.gridSize,
        firstMoveRestriction: widget.firstMoveRestriction,
        humanStarts: humanStarts,
      );
      _starting = false;
    });
    _scheduleBotIfNeeded();
  }

  void _scheduleBotIfNeeded() {
    _botTimer?.cancel();
    final game = _game;
    if (game == null || game.isFinished || game.isHumanTurn) {
      setState(() => _botThinking = false);
      return;
    }
    setState(() => _botThinking = true);
    _botTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final g = _game;
      if (g == null || g.isFinished || g.isHumanTurn) {
        setState(() => _botThinking = false);
        return;
      }
      g.applyBotMove();
      setState(() {});
      _scheduleBotIfNeeded();
    });
  }

  void _onCell(int index) {
    final game = _game;
    if (game == null || _botThinking || !game.playHuman(index)) return;
    setState(() {});
    _scheduleBotIfNeeded();
  }

  String _statusText(BuildContext context) {
    final game = _game;
    if (game == null) return '';
    final l10n = context.l10n;
    if (game.status == 'draw') return l10n.gameDraw;
    if (game.status.endsWith('_won')) {
      final winner = game.status.replaceAll('_won', '');
      if (winner == game.humanMark) return l10n.gameYouWon;
      return l10n.offlineBotWon;
    }
    if (_botThinking || !game.isHumanTurn) return l10n.offlineBotThinking;
    return l10n.gamesMyTurn;
  }

  Color _markColor(String mark) {
    switch (mark) {
      case 'x':
        return AppColors.accentStart;
      case 'o':
        return AppColors.textPrimary;
      case 't':
        return const Color(0xFF2E7D32);
      case 's':
        return const Color(0xFFC62828);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.go('/games');
    final game = _game;
    final title = variantLabel(parseVariant(widget.variant));

    return SwipeBackScope(
      onBack: goBack,
      opaqueEdge: false,
      edgeWidth: 16,
      triggerDistance: 44,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
            tooltip: context.l10n.commonBack,
          ),
          title: Column(
            children: [
              Text(
                context.l10n.offlineGameTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _starting || game == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Text(
                        context.l10n.offlineGameHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusText(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: game.isUltimate
                                ? _UltimateBoard(
                                    game: game,
                                    onCell: _onCell,
                                    markColor: _markColor,
                                    interactive:
                                        game.isHumanTurn && !_botThinking,
                                  )
                                : _LineBoard(
                                    game: game,
                                    onCell: _onCell,
                                    markColor: _markColor,
                                    interactive:
                                        game.isHumanTurn && !_botThinking,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: goBack,
                              child: Text(context.l10n.commonBack),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _restart,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentStart,
                              ),
                              child: Text(context.l10n.offlinePlayAgain),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LineBoard extends StatelessWidget {
  const _LineBoard({
    required this.game,
    required this.onCell,
    required this.markColor,
    required this.interactive,
  });

  final OfflineTicTacToeGame game;
  final void Function(int) onCell;
  final Color Function(String) markColor;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final n = game.gridSize;
    final win = game.winningCells?.toSet() ?? const <int>{};
    final markSize = n <= 3 ? 42.0 : (n <= 5 ? 32.0 : (n <= 8 ? 18.0 : 14.0));
    final gap = n >= 10 ? 2.0 : (n >= 8 ? 3.0 : 4.0);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: n,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
      ),
      itemCount: n * n,
      itemBuilder: (context, index) {
        final mark = game.board[index];
        final isWin = win.contains(index);
        return Material(
          color: isWin ? AppColors.accentSoft : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(n <= 5 ? 10 : 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(n <= 5 ? 10 : 4),
            onTap: interactive && mark.isEmpty ? () => onCell(index) : null,
            child: Center(
              child: mark.isEmpty
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      size: Size.square(markSize),
                      painter: _OfflineMarkPainter(
                        mark: mark,
                        color: markColor(mark),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _UltimateBoard extends StatelessWidget {
  const _UltimateBoard({
    required this.game,
    required this.onCell,
    required this.markColor,
    required this.interactive,
  });

  final OfflineTicTacToeGame game;
  final void Function(int) onCell;
  final Color Function(String) markColor;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final legal = interactive
        ? newEngine(variantUltimate)
            .legalCells(
              GameEngineState(
                board: game.board,
                turn: game.turn,
                status: 'active',
                nextBoard: game.nextBoard,
                metaBoard: game.metaBoard,
              ),
            )
            .toSet()
        : const <int>{};
    final win = game.winningCells?.toSet() ?? const <int>{};
    final metaWin = game.metaWinCells?.toSet() ?? const <int>{};

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          for (var bigRow = 0; bigRow < 3; bigRow++)
            Expanded(
              child: Row(
                children: [
                  for (var bigCol = 0; bigCol < 3; bigCol++)
                    Expanded(
                      child: _buildSub(
                        sub: bigRow * 3 + bigCol,
                        legal: legal,
                        win: win,
                        metaWin: metaWin,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSub({
    required int sub,
    required Set<int> legal,
    required Set<int> win,
    required Set<int> metaWin,
  }) {
    final meta = sub < game.metaBoard.length ? game.metaBoard[sub] : '';
    final forced = game.nextBoard;
    final highlight = forced < 0 || forced == sub;
    final metaWon = metaWin.contains(sub);
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: metaWon
            ? AppColors.accentSoft
            : (highlight
                ? AppColors.accentSoft.withValues(alpha: 0.35)
                : AppColors.textSecondary.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? AppColors.accentStart.withValues(alpha: 0.55)
              : AppColors.textSecondary.withValues(alpha: 0.2),
          width: highlight ? 2 : 1,
        ),
      ),
      child: meta.isNotEmpty && meta != 'd'
          ? Center(
              child: CustomPaint(
                size: const Size.square(36),
                painter: _OfflineMarkPainter(
                  mark: meta,
                  color: markColor(meta),
                ),
              ),
            )
          : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(3),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 9,
              itemBuilder: (context, local) {
                final index = sub * 9 + local;
                final mark = game.board[index];
                final isWin = win.contains(index);
                final canTap = interactive && legal.contains(index);
                return Material(
                  color: isWin
                      ? AppColors.accentSoft
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: canTap ? () => onCell(index) : null,
                    child: Center(
                      child: mark.isEmpty
                          ? const SizedBox.shrink()
                          : CustomPaint(
                              size: const Size.square(14),
                              painter: _OfflineMarkPainter(
                                mark: mark,
                                color: markColor(mark),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Метки X/O/T/S через Canvas — без unicode-глифов шрифта.
class _OfflineMarkPainter extends CustomPainter {
  _OfflineMarkPainter({required this.mark, required this.color});

  final String mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (mark) {
      case 'o':
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          (size.width - strokeWidth) / 2,
          paint,
        );
      case 't':
        final pad = size.width * 0.18;
        canvas.drawLine(
          Offset(pad, pad),
          Offset(size.width - pad, pad),
          paint,
        );
        canvas.drawLine(
          Offset(size.width / 2, pad),
          Offset(size.width / 2, size.height - pad),
          paint,
        );
      case 's':
        final pad = size.width * 0.2;
        final path = Path()
          ..moveTo(size.width - pad, pad)
          ..quadraticBezierTo(
            pad,
            pad,
            pad,
            size.height / 2,
          )
          ..quadraticBezierTo(
            size.width - pad,
            size.height / 2,
            size.width - pad,
            size.height - pad,
          )
          ..quadraticBezierTo(
            pad,
            size.height - pad,
            pad,
            size.height - pad,
          );
        canvas.drawPath(path, paint);
      case 'x':
      default:
        final padding = size.width * 0.15;
        canvas.drawLine(
          Offset(padding, padding),
          Offset(size.width - padding, size.height - padding),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - padding, padding),
          Offset(padding, size.height - padding),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _OfflineMarkPainter old) =>
      old.mark != mark || old.color != color;
}
