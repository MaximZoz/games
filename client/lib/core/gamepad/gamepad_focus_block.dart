import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Карточка/блок, по которому ходит геймпад: одна цель, обводка по рамке.
class GamepadFocusBlock extends StatelessWidget {
  const GamepadFocusBlock({
    super.key,
    required this.child,
    this.onActivate,
    this.radius = 22,
    this.borderWidth = 2,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final double radius;
  final double borderWidth;
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
        debugLabel: 'GamepadFocusBlock',
        skipTraversal: onActivate == null,
        descendantsAreFocusable: false,
        descendantsAreTraversable: false,
        child: Builder(
          builder: (context) {
            return ListenableBuilder(
              listenable: Listenable.merge([
                GamepadService.instance.devices,
                GamepadService.instance.activityTick,
              ]),
              builder: (context, _) {
                final focused = Focus.of(context).hasPrimaryFocus;
                final show = focused && gamepadConnected();
                // Рамка карточки: внешний радиус = radius + borderWidth.
                final outerRadius = radius + borderWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    child,
                    if (show)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(outerRadius),
                              border: Border.all(
                                color: AppColors.accentStart,
                                width: borderWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
