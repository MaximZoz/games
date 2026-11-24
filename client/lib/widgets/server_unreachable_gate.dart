import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/server_link.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/server_unreachable_dialog.dart';

/// Следит за связью с сервером и предлагает повторить или уйти в офлайн.
///
/// Диалог один на всё приложение: сбой любого запроса к API сначала
/// подтверждается проверкой сервера, чтобы одиночный таймаут не пугал.
class ServerUnreachableGate extends ConsumerStatefulWidget {
  const ServerUnreachableGate({super.key, required this.child});

  final Widget child;

  /// После закрытия без выбора молчим столько, чтобы не мешать игре.
  static const quietAfterDismiss = Duration(seconds: 45);

  @override
  ConsumerState<ServerUnreachableGate> createState() =>
      _ServerUnreachableGateState();
}

class _ServerUnreachableGateState extends ConsumerState<ServerUnreachableGate> {
  bool _busy = false;
  DateTime? _quietUntil;

  @override
  void initState() {
    super.initState();
    ServerLink.instance.failures.addListener(_onApiFailure);
  }

  @override
  void dispose() {
    ServerLink.instance.failures.removeListener(_onApiFailure);
    super.dispose();
  }

  void _onApiFailure() {
    unawaited(_prompt(confirm: true));
  }

  bool _shouldPrompt() {
    if (!mounted) return false;
    if (ref.read(isOfflineProvider)) return false;
    // Гость видит ошибку прямо в форме входа, офлайн ему недоступен.
    if (ref.read(authStateProvider).valueOrNull == null) return false;
    final quietUntil = _quietUntil;
    return quietUntil == null || DateTime.now().isAfter(quietUntil);
  }

  Future<void> _prompt({required bool confirm}) async {
    if (_busy || !_shouldPrompt()) return;
    _busy = true;
    try {
      final notifier = ref.read(offlineModeProvider.notifier);
      if (confirm) {
        final reachable = await notifier.checkServerNow();
        if (reachable || !_shouldPrompt()) return;
      }
      if (!mounted) return;
      final choice = await showServerUnreachableDialog(context);
      if (!mounted) return;
      switch (choice) {
        case ServerUnreachableChoice.goOffline:
          // Роутер сам уводит с лобби, чатов и сетевых партий.
          await notifier.setPreference(OfflinePreference.offline);
        case ServerUnreachableChoice.reconnected:
          showAppSnackBar(
            context,
            message: context.l10n.serverReachableAgain,
            kind: AppSnackKind.success,
            icon: Icons.cloud_done_rounded,
          );
          unawaited(ref.read(authStateProvider.notifier).ensureSessionFresh());
        case null:
          _quietUntil =
              DateTime.now().add(ServerUnreachableGate.quietAfterDismiss);
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Фоновые проверки сами заметили потерю связи — подтверждать не нужно.
    ref.listen<OfflineModeState>(offlineModeProvider, (prev, next) {
      if (next.isOffline || next.hasNetwork) return;
      if (prev != null && !prev.hasNetwork) return;
      scheduleMicrotask(() => unawaited(_prompt(confirm: false)));
    });
    return widget.child;
  }
}
