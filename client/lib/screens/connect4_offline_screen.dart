import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/connect4/connect4_engine.dart';
import 'package:multigames_client/games/connect4/connect4_offline_session.dart';
import 'package:multigames_client/screens/connect4_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн «четыре в ряд»: тот же экран, что онлайн, только с ботом.
class Connect4OfflineScreen extends ConsumerStatefulWidget {
  const Connect4OfflineScreen({super.key, required this.gameMode});

  final String gameMode;

  @override
  ConsumerState<Connect4OfflineScreen> createState() =>
      _Connect4OfflineScreenState();
}

class _Connect4OfflineScreenState extends ConsumerState<Connect4OfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final mode = Connect4Engine.normalizeMode(widget.gameMode);
    final existing = OfflineConnect4Registry.instance.current;
    if (existing != null && existing.gameMode == mode) {
      _gameId = existing.gameId;
      return;
    }
    OfflineConnect4Registry.instance.disposeAll();
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final session = OfflineConnect4Session.create(
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
    return Connect4GameScreen(gameId: id);
  }
}
