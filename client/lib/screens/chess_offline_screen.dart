import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/chess/chess_engine.dart';
import 'package:multigames_client/games/chess/chess_offline_session.dart';
import 'package:multigames_client/screens/chess_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн-шахматы: тот же экран, что онлайн, только с ботом.
class ChessOfflineScreen extends ConsumerStatefulWidget {
  const ChessOfflineScreen({super.key, required this.gameMode});

  final String gameMode;

  @override
  ConsumerState<ChessOfflineScreen> createState() => _ChessOfflineScreenState();
}

class _ChessOfflineScreenState extends ConsumerState<ChessOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final mode = ChessEngine.normalizeMode(widget.gameMode);
    final existing = OfflineChessRegistry.instance.current;
    if (existing != null && existing.gameMode == mode) {
      _gameId = existing.gameId;
      return;
    }
    OfflineChessRegistry.instance.disposeAll();
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final session = OfflineChessSession.create(
      humanUserId: me,
      gameMode: mode,
    );
    _gameId = session.gameId;
  }

  @override
  Widget build(BuildContext context) {
    final id = _gameId;
    if (id == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentStart),
        ),
      );
    }
    return ChessGameScreen(gameId: id);
  }
}
