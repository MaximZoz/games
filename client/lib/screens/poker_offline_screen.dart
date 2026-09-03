import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/poker/poker_offline_session.dart';
import 'package:multigames_client/screens/poker_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн покер: тот же [PokerGameScreen], что и онлайн, с локальными ботами.
class PokerOfflineScreen extends ConsumerStatefulWidget {
  const PokerOfflineScreen({super.key, this.playerCount = 2});

  final int playerCount;

  @override
  ConsumerState<PokerOfflineScreen> createState() => _PokerOfflineScreenState();
}

class _PokerOfflineScreenState extends ConsumerState<PokerOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final existing = OfflinePokerRegistry.instance.current;
    if (existing != null) {
      _gameId = existing.gameId;
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    final players = widget.playerCount.clamp(2, 6);
    final session = OfflinePokerSession.create(
      humanUserId: user?.id ?? 'local:player',
      playerCount: players,
      humanDisplayName: user?.displayName,
      humanAvatarKind: user?.avatarKind,
      humanAvatarValue: user?.avatarValue,
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
    return PokerGameScreen(gameId: id);
  }
}
