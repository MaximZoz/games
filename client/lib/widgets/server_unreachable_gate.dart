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
/// Пока связи нет и офлайн не выбран, каждый сбой снова поднимает диалог.
class ServerUnreachableGate extends ConsumerStatefulWidget {
  const ServerUnreachableGate({super.key, required this.child});

  final Widget child;

  /// Сколько раз подряд вернуть диалог, если его сняли без выбора.
  /// Дальше ждём следующего сбоя API, чтобы не мигать окном бесконечно.
  static const maxReopens = 3;

  @override
  ConsumerState<ServerUnreachableGate> createState() =>
      _ServerUnreachableGateState();
}

class _ServerUnreachableGateState extends ConsumerState<ServerUnreachableGate> {
  bool _busy = false;

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
    return ref.read(authStateProvider).valueOrNull != null;
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
      var reopens = 0;
      while (true) {
        if (!mounted) return;
        final choice = await showServerUnreachableDialog(context);
        if (!mounted) return;
        switch (choice) {
          case ServerUnreachableChoice.goOffline:
            // Роутер сам уводит с лобби, чатов и сетевых партий.
            await notifier.setPreference(OfflinePreference.offline);
            return;
          case ServerUnreachableChoice.reconnected:
            showAppSnackBar(
              context,
              message: context.l10n.serverReachableAgain,
              kind: AppSnackKind.success,
              icon: Icons.cloud_done_rounded,
            );
            unawaited(
              ref.read(authStateProvider.notifier).ensureSessionFresh(),
            );
            return;
          case null:
            // Окно сняли без выбора: чужой pop либо смена маршрута под ним.
            // Связи всё ещё нет — возвращаем выбор на экран.
            if (!_shouldPrompt()) return;
            if (ref.read(offlineModeProvider).hasNetwork) return;
            if (++reopens > ServerUnreachableGate.maxReopens) return;
            await WidgetsBinding.instance.endOfFrame;
        }
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
