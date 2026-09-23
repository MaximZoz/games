import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Карточка/блок, по которому ходит геймпад: одна цель, обводка по всей рамке.
class GamepadFocusBlock extends StatelessWidget {
  const GamepadFocusBlock({
    super.key,
    required this.child,
    this.onActivate,
    this.radius = 22,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final double radius;
  final bool autofocus;

  static GamepadFocusScope? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<GamepadFocusScope>();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadFocusScope(
      onActivate: onActivate,
      child: Focus(
        autofocus: autofocus,
        canRequestFocus: onActivate != null,
        skipTraversal: onActivate == null,
        descendantsAreFocusable: false,
        descendantsAreTraversable: false,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasPrimaryFocus;
            final show = focused && gamepadConnected();
            return AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: show ? AppColors.accentStart : Colors.transparent,
                  width: 2.2,
                ),
                boxShadow: show
                    ? [
                        BoxShadow(
                          color: AppColors.accentStart.withValues(alpha: 0.28),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class GamepadFocusScope extends InheritedWidget {
  const GamepadFocusScope({
    super.key,
    required this.onActivate,
    required super.child,
  });

  final VoidCallback? onActivate;

  @override
  bool updateShouldNotify(GamepadFocusScope oldWidget) {
    return onActivate != oldWidget.onActivate;
  }
}
