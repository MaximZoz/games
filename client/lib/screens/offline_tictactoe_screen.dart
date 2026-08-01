import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/offline_tictactoe.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLastHumanStarted = 'offline_ttt_last_human_started';

/// Локальная игра с ботом: без ставок, наград и API.
class OfflineTicTacToeScreen extends ConsumerStatefulWidget {
  const OfflineTicTacToeScreen({
    super.key,
    this.gridSize = 3,
    this.swapRule = false,
    this.firstMoveRestriction = false,
  });

  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;

  @override
  ConsumerState<OfflineTicTacToeScreen> createState() =>
      _OfflineTicTacToeScreenState();
}

class _OfflineTicTacToeScreenState extends ConsumerState<OfflineTicTacToeScreen> {
  OfflineTicTacToeGame? _game;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  Future<void> _restart() async {
    setState(() => _starting = true);
    // По умолчанию в офлайне чередуем первого; чип ⇄=выкл — всегда игрок.
    var humanStarts = true;
    final alternate = widget.swapRule;
    if (alternate) {
      final prefs = await SharedPreferences.getInstance();
      final lastHumanStarted = prefs.getBool(_keyLastHumanStarted) ?? false;
      humanStarts = !lastHumanStarted;
      await prefs.setBool(_keyLastHumanStarted, humanStarts);
    }
    if (!mounted) return;
    setState(() {
      _game = OfflineTicTacToeGame(
        gridSize: widget.gridSize.clamp(3, 8),
        firstMoveRestriction: widget.firstMoveRestriction,
        humanStarts: humanStarts,
      );
      _starting = false;
    });
  }

  void _onCell(int index) {
    final game = _game;
    if (game == null || !game.playHuman(index)) return;
    setState(() {});
  }

  String _statusText(BuildContext context) {
    final game = _game;
    if (game == null) return '';
    final l10n = context.l10n;
    switch (game.status) {
      case 'x_won':
        return game.humanMark == 'x'
            ? l10n.gameYouWon
            : l10n.offlineBotWon;
      case 'o_won':
        return game.humanMark == 'o'
            ? l10n.gameYouWon
            : l10n.offlineBotWon;
      case 'draw':
        return l10n.gameDraw;
      default:
        return game.isHumanTurn ? l10n.gamesMyTurn : l10n.offlineBotThinking;
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.go('/games');
    final game = _game;

    return SwipeBackScope(
      onBack: goBack,
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
          title: Text(
            context.l10n.offlineGameTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
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
                            child: Builder(
                              builder: (context) {
                                final n = game.gridSize;
                                final win =
                                    game.winningCells?.toSet() ?? const <int>{};
                                final markSize = n <= 3
                                    ? 42.0
                                    : (n <= 5 ? 32.0 : 22.0);
                                return GridView.builder(
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: n,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: n * n,
                                  itemBuilder: (context, index) {
                                    final mark = game.board[index];
                                    final isWin = win.contains(index);
                                    return Material(
                                      color: isWin
                                          ? AppColors.accentSoft
                                          : AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: game.isHumanTurn && mark.isEmpty
                                            ? () => _onCell(index)
                                            : null,
                                        child: Center(
                                          child: mark.isEmpty
                                              ? const SizedBox.shrink()
                                              : CustomPaint(
                                                  size: Size.square(markSize),
                                                  painter: _OfflineMarkPainter(
                                                    isX: mark == 'x',
                                                    color: mark == 'x'
                                                        ? AppColors.accentStart
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
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

/// X/O через Canvas — без unicode-глифов шрифта Syne (иначе «tofu» □✕).
class _OfflineMarkPainter extends CustomPainter {
  _OfflineMarkPainter({required this.isX, required this.color});

  final bool isX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isX) {
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
    } else {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - strokeWidth) / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OfflineMarkPainter old) =>
      old.isX != isX || old.color != color;
}
