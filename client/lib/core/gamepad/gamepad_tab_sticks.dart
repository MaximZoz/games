import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Правый стик по краям вкладок — как LB/RB у нижнего меню.
class GamepadTabSticks extends StatelessWidget {
  const GamepadTabSticks({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamepadService.instance.devices,
      builder: (context, _) {
        if (!gamepadConnected()) return child;
        return Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, right: 4),
              child: GamepadGlyph(
                action: GamepadAction.scrollLeft,
                size: 18,
              ),
            ),
            Expanded(child: child),
            const Padding(
              padding: EdgeInsets.only(left: 4, right: 2),
              child: GamepadGlyph(
                action: GamepadAction.scrollRight,
                size: 18,
              ),
            ),
          ],
        );
      },
    );
  }
}
