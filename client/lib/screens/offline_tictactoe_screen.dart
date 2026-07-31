import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/offline_tictactoe.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

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
  late OfflineTicTacToeGame _game;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    setState(() {
      _game = OfflineTicTacToeGame(
        gridSize: widget.gridSize.clamp(3, 8),
        swapRule: widget.swapRule,
        firstMoveRestriction: widget.firstMoveRestriction,
      );
    });
  }

  void _onCell(int index) {
    if (!_game.playHuman(index)) return;
    setState(() {});
  }

  String _statusText(BuildContext context) {
    final l10n = context.l10n;
    switch (_game.status) {
      case 'x_won':
        return _game.humanMark == 'x'
            ? l10n.gameYouWon
            : l10n.offlineBotWon;
      case 'o_won':
        return _game.humanMark == 'o'
            ? l10n.gameYouWon
            : l10n.offlineBotWon;
      case 'draw':
        return l10n.gameDraw;
      default:
        return _game.isHumanTurn ? l10n.gamesMyTurn : l10n.offlineBotThinking;
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.go('/games');
    final n = _game.gridSize;
    final win = _game.winningCells?.toSet() ?? const <int>{};

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
            child: Column(
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
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: n,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: n * n,
                        itemBuilder: (context, index) {
                          final mark = _game.board[index];
                          final isWin = win.contains(index);
                          return Material(
                            color: isWin
                                ? AppColors.accentSoft
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _game.isHumanTurn && mark.isEmpty
                                  ? () => _onCell(index)
                                  : null,
                              child: Center(
                                child: Text(
                                  mark == 'x'
                                      ? '✕'
                                      : mark == 'o'
                                          ? '○'
                                          : '',
                                  style: TextStyle(
                                    fontSize: n <= 3 ? 36 : (n <= 5 ? 28 : 18),
                                    fontWeight: FontWeight.w800,
                                    color: mark == 'x'
                                        ? AppColors.accentStart
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
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
