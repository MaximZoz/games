import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';

const serverUnreachableRetryKey = ValueKey<String>('server-unreachable-retry');
const serverUnreachableOfflineKey =
    ValueKey<String>('server-unreachable-offline');
const serverUnreachableStillDownKey =
    ValueKey<String>('server-unreachable-still-down');

/// Чем закончился диалог «нет связи с сервером».
enum ServerUnreachableChoice {
  /// Сервер снова отвечает.
  reconnected,

  /// Пользователь выбрал офлайн режим.
  goOffline,
}

/// Диалог без связи с сервером. `null` — закрыли без выбора.
Future<ServerUnreachableChoice?> showServerUnreachableDialog(
  BuildContext context,
) {
  return showDialog<ServerUnreachableChoice>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const ServerUnreachableDialog(),
  );
}

class ServerUnreachableDialog extends ConsumerStatefulWidget {
  const ServerUnreachableDialog({super.key});

  @override
  ConsumerState<ServerUnreachableDialog> createState() =>
      _ServerUnreachableDialogState();
}

class _ServerUnreachableDialogState
    extends ConsumerState<ServerUnreachableDialog> {
  bool _stillDown = false;
  bool _closed = false;

  void _close([ServerUnreachableChoice? choice]) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(choice);
  }

  Future<void> _retry() async {
    final ok = await ref.read(offlineModeProvider.notifier).checkServerNow();
    if (!mounted || _closed) return;
    if (ok) {
      _close(ServerUnreachableChoice.reconnected);
      return;
    }
    setState(() => _stillDown = true);
  }

  @override
  Widget build(BuildContext context) {
    // Фоновая проверка вернула связь, пока диалог открыт — закрываем сами.
    ref.listen<OfflineModeState>(offlineModeProvider, (prev, next) {
      if (next.isOffline) {
        _close();
        return;
      }
      if (next.hasNetwork && prev != null && !prev.hasNetwork) {
        _close(ServerUnreachableChoice.reconnected);
      }
    });

    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 380;
    final maxHeight = size.height * 0.85;

    Widget button({
      required Key key,
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return FramedButton(
        key: key,
        label: label,
        icon: icon,
        expanded: true,
        minHeight: compact ? 40 : 44,
        fontSize: compact ? 13 : 14,
        iconSize: compact ? 18 : 20,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 10,
        ),
        onPressed: onPressed,
      );
    }

    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action == GamepadAction.confirm) {
          _retry();
          return true;
        }
        if (action == GamepadAction.cancel || action == GamepadAction.menu) {
          _close();
          return true;
        }
        return true;
      },
      child: Dialog(
        backgroundColor: AppColors.surfaceCard,
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24,
          vertical: compact ? 16 : 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 20,
              compact ? 16 : 20,
              compact ? 16 : 20,
              compact ? 12 : 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.accentStart,
                      size: compact ? 24 : 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.serverUnreachableTitle,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 18 : 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                Flexible(
                  fit: FlexFit.loose,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      Text(
                        l10n.serverUnreachableBody,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: compact ? 13 : 14,
                          height: 1.35,
                        ),
                      ),
                      if (_stillDown) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.serverUnreachableStillDown,
                          key: serverUnreachableStillDownKey,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 12.5 : 13.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                // Колонкой: подписи кнопок в части языков длинные.
                button(
                  key: serverUnreachableRetryKey,
                  label: l10n.commonRetry,
                  icon: Icons.refresh_rounded,
                  onPressed: _retry,
                ),
                const SizedBox(height: 8),
                button(
                  key: serverUnreachableOfflineKey,
                  label: l10n.serverUnreachableGoOffline,
                  icon: Icons.cloud_off_rounded,
                  onPressed: () => _close(ServerUnreachableChoice.goOffline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
