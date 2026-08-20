import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/uno/uno_offline_session.dart';
import 'package:multigames_client/screens/uno_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

class UnoOfflineScreen extends ConsumerStatefulWidget {
  const UnoOfflineScreen({super.key, this.playerCount = 2});

  final int playerCount;

  @override
  ConsumerState<UnoOfflineScreen> createState() => _UnoOfflineScreenState();
}

class _UnoOfflineScreenState extends ConsumerState<UnoOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final session = OfflineUnoSession.create(
      humanUserId: user?.id ?? 'local:player',
      playerCount: widget.playerCount,
      humanDisplayName: user?.displayName,
      humanAvatarKind: user?.avatarKind,
      humanAvatarValue: user?.avatarValue,
    );
    _gameId = session.gameId;
  }

  @override
  void dispose() {
    final gameId = _gameId;
    if (gameId != null) {
      OfflineUnoRegistry.instance.get(gameId)?.dispose();
    }
    super.dispose();
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
    return UnoGameScreen(gameId: gameId);
  }
}
