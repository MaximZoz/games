import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_buy_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/l10n/l10n.dart';

/// Диалог подтверждения: A — да, любая другая кнопка геймпада — закрыть.
Future<bool> showGamepadConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      var closed = false;
      void close([bool ok = false]) {
        if (closed) return;
        closed = true;
        final nav = Navigator.of(dialogContext);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (nav.canPop()) nav.pop(ok);
        });
      }

      return GamepadScope(
        exclusive: true,
        onAction: (action) {
          if (action == GamepadAction.confirm) {
            close(true);
          } else {
            close(false);
          }
          return true;
        },
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => close(false),
              child: Text(cancelLabel ?? context.l10n.commonCancel),
            ),
            GamepadBuyButton(
              onPressed: () => close(true),
              label: confirmLabel,
            ),
          ],
        ),
      );
    },
  );
  return result == true;
}

/// Обёртка диалога: любая кнопка геймпада закрывает только его.
Widget wrapGamepadDismissDialog({
  required VoidCallback onDismiss,
  required Widget child,
}) {
  var closed = false;
  return GamepadScope(
    exclusive: true,
    onAction: (_) {
      if (closed) return true;
      closed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => onDismiss());
      return true;
    },
    child: child,
  );
}
