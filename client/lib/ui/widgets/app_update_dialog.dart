import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';

const appUpdateNotesKey = ValueKey<String>('app-update-notes');
const appUpdateConfirmKey = ValueKey<String>('app-update-confirm');
const appUpdateCloseKey = ValueKey<String>('app-update-close');

/// Окно «что нового». [allowClose] — кнопка «Закрыть» (настройки).
/// Без неё окно только обновляет приложение (автопоказ в оболочке).
Future<bool> showAppUpdatePromptDialog(
  BuildContext context, {
  required String whatsNew,
  bool allowClose = false,
}) async {
  final go = await showDialog<bool>(
    context: context,
    barrierDismissible: allowClose,
    builder: (ctx) => AppUpdatePromptDialog(
      whatsNew: whatsNew,
      allowClose: allowClose,
    ),
  );
  return go == true;
}

class AppUpdatePromptDialog extends StatelessWidget {
  const AppUpdatePromptDialog({
    super.key,
    required this.whatsNew,
    required this.allowClose,
  });

  final String whatsNew;
  final bool allowClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = whatsNew.trim();
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 380;
    final maxHeight = size.height * (compact ? 0.78 : 0.85);

    Widget button({
      required String label,
      required bool confirm,
      required Key key,
    }) {
      return FramedButton(
        key: key,
        label: label,
        expanded: true,
        minHeight: compact ? 40 : 44,
        fontSize: compact ? 13 : 14,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 10,
        ),
        onPressed: () => Navigator.of(context).pop(confirm),
      );
    }

    final close = allowClose
        ? button(
            label: l10n.commonClose,
            confirm: false,
            key: appUpdateCloseKey,
          )
        : null;
    final update = button(
      label: l10n.appUpdateOk,
      confirm: true,
      key: appUpdateConfirmKey,
    );
    final actions = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              update,
              if (close != null) ...[
                const SizedBox(height: 8),
                close,
              ],
            ],
          )
        : Row(
            children: [
              if (close != null) ...[
                Expanded(child: close),
                const SizedBox(width: 12),
              ],
              Expanded(child: update),
            ],
          );

    final notesStyle = TextStyle(
      color: AppColors.textSecondary.withValues(alpha: 0.95),
      height: 1.35,
      fontSize: compact ? 12.5 : 13.5,
    );

    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action == GamepadAction.confirm) {
          Navigator.of(context).pop(true);
          return true;
        }
        if (allowClose &&
            (action == GamepadAction.cancel || action == GamepadAction.menu)) {
          Navigator.of(context).pop(false);
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
                Text(
                  l10n.appUpdateTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 18 : 20,
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                Flexible(
                  fit: FlexFit.loose,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      Text(
                        l10n.appUpdateBody,
                        style: TextStyle(fontSize: compact ? 13 : 14),
                      ),
                      if (notes.isNotEmpty) ...[
                        SizedBox(height: compact ? 10 : 14),
                        Text(
                          l10n.appUpdateWhatsNew,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 13 : 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(notes, key: appUpdateNotesKey, style: notesStyle),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
