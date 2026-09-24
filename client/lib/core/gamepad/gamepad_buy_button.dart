import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';

/// Кнопка «Купить»: фиолетовая рамка снаружи, сама кнопка не наезжает на неё.
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
      radius: 22,
      borderWidth: 2.2,
      onActivate: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(168, 48),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
