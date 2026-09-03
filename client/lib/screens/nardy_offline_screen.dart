import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/games/nardy/nardy_offline_session.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/screens/nardy_game_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Офлайн-нарды: тот же [NardyGameScreen], что и онлайн, только с ботом.
class NardyOfflineScreen extends ConsumerStatefulWidget {
  const NardyOfflineScreen({super.key, required this.gameMode});

  final String gameMode;

  @override
  ConsumerState<NardyOfflineScreen> createState() => _NardyOfflineScreenState();
}

class _NardyOfflineScreenState extends ConsumerState<NardyOfflineScreen> {
  String? _gameId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameId != null) return;
    final mode = nardyNormalizeMode(widget.gameMode);
    final existing = OfflineNardyRegistry.instance.current;
    if (existing != null && existing.gameMode == mode) {
      _gameId = existing.gameId;
      return;
    }
    // Режим сменился — старую партию не продолжаем.
    OfflineNardyRegistry.instance.disposeAll();
    final me = ref.read(authStateProvider).valueOrNull?.id ?? 'local:player';
    final session = OfflineNardySession.create(
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
    return NardyGameScreen(gameId: id);
  }
}
