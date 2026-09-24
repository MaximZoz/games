import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Живые [FocusNode] карточек — без `debugLabel` (в релизе его нет).
class GamepadFocusRegistry {
  GamepadFocusRegistry._();

  static final Set<FocusNode> _nodes = <FocusNode>{};

  static List<FocusNode> get nodes => List<FocusNode>.unmodifiable(_nodes);

  static void register(FocusNode node) => _nodes.add(node);

  static void unregister(FocusNode node) => _nodes.remove(node);

  @visibleForTesting
  static void reset() => _nodes.clear();
}

enum GamepadHighlightShape { roundedRect, circle }

/// Карточка/блок, по которому ходит геймпад: одна цель, обводка по рамке.
class GamepadFocusBlock extends StatefulWidget {
  const GamepadFocusBlock({
    super.key,
    required this.child,
    this.onActivate,
    this.radius = 22,
    this.borderWidth = 2,
    this.autofocus = false,
    this.focusable = true,
    this.shape = GamepadHighlightShape.roundedRect,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final double radius;
  final double borderWidth;
  final bool autofocus;
  final bool focusable;
  final GamepadHighlightShape shape;

  static GamepadFocusScope? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<GamepadFocusScope>();
  }

  @override
  State<GamepadFocusBlock> createState() => _GamepadFocusBlockState();
}

class _GamepadFocusBlockState extends State<GamepadFocusBlock> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(
      debugLabel: 'GamepadFocusBlock',
      canRequestFocus: widget.focusable,
      skipTraversal: !widget.focusable,
      descendantsAreFocusable: false,
      descendantsAreTraversable: false,
    );
    GamepadFocusRegistry.register(_focus);
  }

  @override
  void didUpdateWidget(GamepadFocusBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focus.canRequestFocus = widget.focusable;
    _focus.skipTraversal = !widget.focusable;
  }

  @override
  void dispose() {
    GamepadFocusRegistry.unregister(_focus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamepadFocusScope(
      onActivate: widget.onActivate,
      child: Focus(
        focusNode: _focus,
        autofocus: widget.autofocus,
        canRequestFocus: widget.focusable,
        skipTraversal: !widget.focusable,
        descendantsAreFocusable: false,
        descendantsAreTraversable: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            GamepadService.instance.devices,
            GamepadService.instance.activityTick,
            _focus,
          ]),
          builder: (context, _) {
            final show = _focus.hasPrimaryFocus && gamepadConnected();
            // Рамка карточки: внешний радиус = radius + borderWidth.
            final outerRadius = widget.radius + widget.borderWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                widget.child,
                if (show)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: widget.shape == GamepadHighlightShape.circle
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accentStart,
                                  width: widget.borderWidth,
                                ),
                              )
                            : BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(outerRadius),
                                border: Border.all(
                                  color: AppColors.accentStart,
                                  width: widget.borderWidth,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
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
