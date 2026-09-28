import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_arrows.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Поле входа: рамка геймпада и клавиатура при наведении.
class GamepadFieldBlock extends StatelessWidget {
  const GamepadFieldBlock({
    super.key,
    required this.inputFocus,
    required this.child,
    this.autofocus = false,
  });

  final FocusNode inputFocus;
  final Widget child;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      autofocus: autofocus,
      radius: AppRadius.input,
      borderWidth: 2.2,
      descendantsFocusable: true,
      attachKeyboard: true,
      inputFocus: inputFocus,
      onActivate: () {
        inputFocus.requestFocus();
        GamepadKeyboardController.instance.show();
      },
      child: ListenableBuilder(
        listenable: GamepadKeyboardController.instance,
        builder: (context, _) {
          return Shortcuts(
            shortcuts: GamepadKeyboardController.instance.visible
                ? gamepadKeyboardTextShortcuts
                : const <ShortcutActivator, Intent>{},
            child: child,
          );
        },
      ),
    );
  }
}

/// Кнопка или ссылка формы входа с обводкой по своей рамке.
class GamepadActionBlock extends StatelessWidget {
  const GamepadActionBlock({
    super.key,
    required this.onActivate,
    required this.child,
    this.radius = AppRadius.button,
    this.outlined = false,
  });

  final VoidCallback onActivate;
  final Widget child;
  final double radius;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      outlined: outlined,
      radius: radius,
      borderWidth: 2.2,
      onActivate: onActivate,
      child: child,
    );
  }
}
