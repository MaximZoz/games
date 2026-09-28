import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';

/// Назад в AppBar: круглая обводка поверх иконки, не овал слота leading.
class GamepadBackButton extends StatelessWidget {
  const GamepadBackButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: GamepadFocusBlock(
          radius: 20,
          borderWidth: 2,
          shape: GamepadHighlightShape.circle,
          onActivate: onPressed,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onPressed,
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}
