import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/offline_ttt_session.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн крестики: тот же [TicTacToeGameScreen], что и онлайн, с ботами.
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
  String? _gameId;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final session = await OfflineTttSession.create(
      humanUserId: me,
      variant: widget.variant,
      gridSize: widget.gridSize,
      swapRule: widget.swapRule,
      firstMoveRestriction: widget.firstMoveRestriction,
    );
    if (!mounted) {
      session.dispose();
      return;
    }
    setState(() {
      _gameId = session.gameId;
      _starting = false;
    });
  }

  @override
  void dispose() {
    final id = _gameId;
    if (id != null) {
      OfflineTttRegistry.instance.get(id)?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_starting || _gameId == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentStart),
        ),
      );
    }
    return TicTacToeGameScreen(gameId: _gameId!);
  }
}
