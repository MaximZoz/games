import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
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
              child: IgnorePointer(
                  child: GamepadGlyph(action: action, size: size)),
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
    this.action2,
    this.family,
  });

  final GamepadAction action;
  final GamepadAction? action2;
  final String text;
  final GamepadFamily? family;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GamepadGlyph(action: action, family: family, size: 18),
        if (action2 != null) ...[
          const SizedBox(width: 4),
          GamepadGlyph(action: action2!, family: family, size: 18),
        ],
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

/// Больше не рисует рамку и A на случайном фокусе (нижнее меню, списки).
/// Рамки только у точечных целей ([GamepadHinted] и блоки фокуса).
///
/// Слушает [GamepadService.activityTick], чтобы `animateTo` скролла
/// получал кадр — без отрисовки.
class GamepadHintsOverlay extends StatefulWidget {
  const GamepadHintsOverlay({super.key});

  @override
  State<GamepadHintsOverlay> createState() => _GamepadHintsOverlayState();
}

class _GamepadHintsOverlayState extends State<GamepadHintsOverlay> {
  @override
  void initState() {
    super.initState();
    GamepadService.instance.activityTick.addListener(_refresh);
  }

  @override
  void dispose() {
    GamepadService.instance.activityTick.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
