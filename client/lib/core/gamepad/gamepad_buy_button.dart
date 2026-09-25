import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Кнопка «Купить»: фиолетовая обводка лежит на рамке кнопки.
class GamepadBuyButton extends StatelessWidget {
  const GamepadBuyButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.autofocus = true,
  });

  final VoidCallback onPressed;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      autofocus: autofocus,
      radius: AppRadius.button,
      borderWidth: 2.2,
      onActivate: onPressed,
      child: Builder(
        builder: (context) {
          final on = GamepadFocusBlock.watchOf(context)?.highlighted ?? false;
          return FilledButton(
            onPressed: onPressed,
            style: AppButtonStyles.of(
              minimumSize: const Size(168, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              radius: AppRadius.button,
            ).copyWith(
              side: WidgetStatePropertyAll(
                on
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.buttonBorder),
              ),
            ),
            child: Text(label),
          );
        },
      ),
    );
  }
}
