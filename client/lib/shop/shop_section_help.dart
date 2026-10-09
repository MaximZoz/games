import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
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
    builder: (dialogContext) => _ShopSectionHelpDialog(
      title: title,
      body: body,
    ),
  );
}

class _ShopSectionHelpDialog extends StatefulWidget {
  const _ShopSectionHelpDialog({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  State<_ShopSectionHelpDialog> createState() => _ShopSectionHelpDialogState();
}

class _ShopSectionHelpDialogState extends State<_ShopSectionHelpDialog> {
  final ScrollController _scroll = ScrollController();
  var _closed = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _nudge(int direction) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final next =
        (_scroll.offset + direction * 72).clamp(0.0, pos.maxScrollExtent);
    _scroll.animateTo(
      next,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action == GamepadAction.up ||
            action == GamepadAction.left ||
            action == GamepadAction.scrollUp ||
            action == GamepadAction.scrollLeft) {
          _nudge(-1);
          return true;
        }
        if (action.isDirection || action.isScroll) {
          _nudge(1);
          return true;
        }
        _close();
        return true;
      },
      child: AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          controller: _scroll,
          child: Text(
            widget.body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          GamepadFocusBlock(
            autofocus: true,
            radius: AppRadius.button,
            onActivate: _close,
            child: TextButton(
              onPressed: _close,
              child: Text(context.l10n.commonClose),
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка «i» в шапке коллекции или набора.
class ShopSectionHelpButton extends StatelessWidget {
  const ShopSectionHelpButton({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: GamepadFocusBlock(
        radius: 20,
        borderWidth: 2.2,
        shape: GamepadHighlightShape.circle,
        includeInEdgeFocus: false,
        stickSideTarget: true,
        onActivate: () => showShopSectionHelp(
          context: context,
          title: title,
          body: body,
        ),
        child: IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          tooltip: title,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => showShopSectionHelp(
            context: context,
            title: title,
            body: body,
          ),
        ),
      ),
    );
  }
}
