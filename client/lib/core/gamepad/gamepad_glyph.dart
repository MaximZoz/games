import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Кружок / капсула с подписью кнопки текущего геймпада.
class GamepadGlyph extends StatelessWidget {
  const GamepadGlyph({
    super.key,
    required this.action,
    this.size = 22,
    this.family,
  });

  final GamepadAction action;
  final double size;
  final GamepadFamily? family;

  @override
  Widget build(BuildContext context) {
    final look = gamepadButtonLook(action, family: family);
    final wide = look.label.length > 1;
    final height = size;
    final width = wide ? size * 1.45 : size;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: look.color,
        borderRadius: BorderRadius.circular(wide ? 7 : 99),
        boxShadow: [
          BoxShadow(
            color: look.color.withValues(alpha: 0.35),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        look.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: look.darkLabel ? const Color(0xFF1A1A1A) : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: wide ? size * 0.38 : size * 0.48,
          height: 1,
        ),
      ),
    );
  }
}

/// Бейдж кнопки в углу дочернего виджета, если геймпад активен.
class GamepadHinted extends StatelessWidget {
  const GamepadHinted({
    super.key,
    required this.action,
    required this.child,
    this.size = 20,
  });

  final GamepadAction action;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        GamepadService.instance.devices,
        GamepadService.instance.activityTick,
      ]),
      builder: (context, _) {
        if (!gamepadHintsWanted()) return child;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -4,
              top: -6,
              child: IgnorePointer(child: GamepadGlyph(action: action, size: size)),
            ),
          ],
        );
      },
    );
  }
}

/// Подсказка «нажми эту кнопку» рядом с текстом.
class GamepadHintLabel extends StatelessWidget {
  const GamepadHintLabel({
    super.key,
    required this.action,
    required this.text,
    this.family,
  });

  final GamepadAction action;
  final String text;
  final GamepadFamily? family;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GamepadGlyph(action: action, family: family, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

/// Короткая пара «клавиша + действие» без растягивания на всю ширину.
class GamepadHintChip extends StatelessWidget {
  const GamepadHintChip({
    super.key,
    required this.action,
    required this.text,
    this.family,
  });

  final GamepadAction action;
  final String text;
  final GamepadFamily? family;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GamepadGlyph(action: action, family: family, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Нижняя полоска подсказок и бейдж на сфокусированном элементе.
class GamepadHintsOverlay extends StatefulWidget {
  const GamepadHintsOverlay({super.key});

  @override
  State<GamepadHintsOverlay> createState() => _GamepadHintsOverlayState();
}

class _GamepadHintsOverlayState extends State<GamepadHintsOverlay> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_refresh);
    GamepadService.instance.devices.addListener(_refresh);
    GamepadService.instance.activityTick.addListener(_refresh);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_refresh);
    GamepadService.instance.devices.removeListener(_refresh);
    GamepadService.instance.activityTick.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!gamepadHintsWanted()) return const SizedBox.shrink();
    if (GamepadKeyboardController.instance.visible) {
      return const SizedBox.shrink();
    }
    final family = currentGamepadFamily();
    final highlight = _focusHighlight(context, family);
    if (highlight == null) return const SizedBox.shrink();
    return IgnorePointer(child: highlight);
  }

  Widget? _focusHighlight(BuildContext context, GamepadFamily family) {
    final node = FocusManager.instance.primaryFocus;
    if (!isGamepadFocusVisible(node)) return null;
    final ctx = node!.context;
    if (ctx == null || !ctx.mounted) return null;
    if (GamepadFocusBlock.maybeOf(ctx) != null) return null;
    if (ctx.findAncestorWidgetOfExactType<SnackBar>() != null) {
      return null;
    }
    final box = _highlightBox(ctx);
    if (box == null) return null;
    final overlayBox = context.findRenderObject();
    if (overlayBox is! RenderBox || !overlayBox.hasSize) return null;
    final size = MediaQuery.sizeOf(context);
    if (box.size.width > size.width * 0.94 &&
        box.size.height > size.height * 0.45) {
      return null;
    }
    if (box.size.width < 8 || box.size.height < 8) return null;
    final topLeft = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
    const pad = 3.0;
    return Stack(
      children: [
        Positioned(
            left: topLeft.dx - pad,
            top: topLeft.dy - pad,
            width: box.size.width + pad * 2,
            height: box.size.height + pad * 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentStart, width: 2),
              ),
            ),
          ),
        Positioned(
          left: (topLeft.dx + box.size.width - 10)
              .clamp(4.0, size.width - 28),
          top: (topLeft.dy - 8).clamp(4.0, size.height - 28),
          child: GamepadGlyph(
            action: GamepadAction.confirm,
            family: family,
            size: 20,
          ),
        ),
      ],
    );
  }

  RenderBox? _highlightBox(BuildContext ctx) {
    RenderBox? preferred;
    ctx.visitAncestorElements((el) {
      if (el.widget is InkWell || el.widget is GamepadFocusScope) {
        final ro = el.renderObject;
        if (ro is RenderBox && ro.hasSize && ro.attached) {
          preferred = ro;
          return false;
        }
      }
      return true;
    });
    final own = ctx.findRenderObject();
    if (own is! RenderBox || !own.hasSize || !own.attached) {
      return preferred;
    }
    if (preferred != null &&
        preferred!.size.height >= own.size.height &&
        preferred!.size.width >= own.size.width) {
      return preferred;
    }
    return own;
  }
}
