import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';
import 'package:multigames_client/games/durak/durak_offline_session.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/screens/durak_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн Дурак: тот же [DurakGameScreen], что и онлайн, с локальными ботами.
class DurakOfflineScreen extends ConsumerStatefulWidget {
  const DurakOfflineScreen({
    super.key,
    this.deckSize = 36,
    this.playerCount = 2,
    this.mode = durakModePodkidnoi,
  });

  final int deckSize;
  final int playerCount;
  final String mode;

  @override
  ConsumerState<DurakOfflineScreen> createState() => _DurakOfflineScreenState();
}

class _DurakOfflineScreenState extends ConsumerState<DurakOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final existing = OfflineDurakRegistry.instance.current;
    if (existing != null) {
      _gameId = existing.gameId;
      return;
    }
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final players = widget.playerCount.clamp(2, 4);
    final deck = durakClampDeckForPlayers(players, widget.deckSize);
    final session = OfflineDurakSession.create(
      humanUserId: me,
      deckSize: deck,
      playerCount: players,
      mode: widget.mode == durakModePerevodnoi
          ? durakModePerevodnoi
          : durakModePodkidnoi,
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
    return DurakGameScreen(gameId: id);
  }
}
