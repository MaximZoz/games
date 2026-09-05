import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_offline_session.dart';
import 'package:multigames_client/screens/checkers_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн-шашки: тот же экран, что онлайн, только с ботом.
class CheckersOfflineScreen extends ConsumerStatefulWidget {
  const CheckersOfflineScreen({super.key, required this.gameMode});

  final String gameMode;

  @override
  ConsumerState<CheckersOfflineScreen> createState() =>
      _CheckersOfflineScreenState();
}

class _CheckersOfflineScreenState extends ConsumerState<CheckersOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final mode = CheckersEngine.normalizeMode(widget.gameMode);
    final existing = OfflineCheckersRegistry.instance.current;
    if (existing != null && existing.gameMode == mode) {
      _gameId = existing.gameId;
      return;
    }
    OfflineCheckersRegistry.instance.disposeAll();
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final session = OfflineCheckersSession.create(
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
    return CheckersGameScreen(gameId: id);
  }
}
