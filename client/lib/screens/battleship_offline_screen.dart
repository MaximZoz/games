import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/battleship/battleship_offline_session.dart';
import 'package:multigames_client/screens/battleship_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн Морской бой: тот же [BattleshipGameScreen], что и онлайн, с ботом.
class BattleshipOfflineScreen extends ConsumerStatefulWidget {
  const BattleshipOfflineScreen({super.key});

  @override
  ConsumerState<BattleshipOfflineScreen> createState() =>
      _BattleshipOfflineScreenState();
}

class _BattleshipOfflineScreenState
    extends ConsumerState<BattleshipOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final session = OfflineBattleshipSession.create(humanUserId: me);
    _gameId = session.gameId;
  }

  @override
  void dispose() {
    final id = _gameId;
    if (id != null) {
      OfflineBattleshipRegistry.instance.get(id)?.dispose();
    }
    super.dispose();
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
    return BattleshipGameScreen(gameId: id);
  }
}
