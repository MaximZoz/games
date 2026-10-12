import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/domino/domino_offline_session.dart';
import 'package:multigames_client/screens/domino_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

class DominoOfflineScreen extends ConsumerStatefulWidget {
  const DominoOfflineScreen({super.key, this.playerCount = 2});

  final int playerCount;

  @override
  ConsumerState<DominoOfflineScreen> createState() =>
      _DominoOfflineScreenState();
}

class _DominoOfflineScreenState extends ConsumerState<DominoOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final existing = OfflineDominoRegistry.instance.current;
    if (existing != null) {
      _gameId = existing.gameId;
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    final session = OfflineDominoSession.create(
      humanUserId: user?.id ?? 'local:player',
      playerCount: widget.playerCount,
      humanDisplayName: user?.displayName,
      humanAvatarKind: user?.avatarKind,
      humanAvatarValue: user?.avatarValue,
    );
    _gameId = session.gameId;
  }

  @override
  Widget build(BuildContext context) {
    final gameId = _gameId;
    if (gameId == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentStart),
        ),
      );
    }
    return DominoGameScreen(gameId: gameId);
  }
}
