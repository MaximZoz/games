import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Справка раздела магазина: стик листает текст, кнопки закрывают.
Future<void> showShopSectionHelp({
  required BuildContext context,
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var closed = false;
      void close() {
        if (closed) return;
        closed = true;
        final nav = Navigator.of(dialogContext);
        if (nav.canPop()) nav.pop();
      }

      return GamepadScope(
        exclusive: true,
        onAction: (action) {
          if (action.isDirection || action.isScroll) {
            return true;
          }
          close();
          return true;
        },
        child: AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: close,
              child: Text(context.l10n.commonClose),
            ),
          ],
        ),
      );
    },
  );
}
