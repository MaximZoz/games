import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_arrows.dart';
import 'package:multigames_client/core/gamepad/gamepad_chrome.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
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
    this.borderWidth = 2.2,
    this.autofocus = false,
    this.focusable = true,
    this.outlined = true,
    this.descendantsFocusable = false,
    this.attachKeyboard = false,
    this.inputFocus,
    this.shape = GamepadHighlightShape.roundedRect,
    this.chrome,
    this.includeInEdgeFocus = true,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final double radius;
  final double borderWidth;
  final bool autofocus;
  final bool focusable;

  /// Рисовать фиолетовую обводку поверх ребёнка.
  /// Для [FilledButton] лучше `false` и [buttonSide] — рамка самой кнопки.
  final bool outlined;

  /// После перелистывания страницы не ставить фокус на этот блок
  /// (кнопка «Назад» в AppBar), если есть контент.
  final bool includeInEdgeFocus;

  /// Поле ввода внутри блока может получить фокус (клавиатура геймпада).
  final bool descendantsFocusable;

  /// При наведении открыть экранную клавиатуру геймпада.
  final bool attachKeyboard;
  final FocusNode? inputFocus;
  final GamepadHighlightShape shape;
  final GamepadChromeSlot? chrome;

  static GamepadFocusScope? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<GamepadFocusScope>();
  }

  /// Из `build`: подписка на фокус, чтобы рамка карточки скрывалась сразу.
  static GamepadFocusScope? watchOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GamepadFocusScope>();
  }

  /// Цвет рамки карточки: при фокусе геймпада её рисует обводка блока.
  static Color frameColor(BuildContext context, Color color) {
    final scope = watchOf(context) ?? maybeOf(context);
    if (scope != null && scope.highlighted) return Colors.transparent;
    return color;
  }

  /// Рамка кнопки: при фокусе геймпада та же [OutlinedBorder], только цвет.
  static BorderSide buttonSide(
    BuildContext context, {
    double width = 2.2,
  }) {
    final on = watchOf(context)?.highlighted ?? false;
    return on
        ? BorderSide(color: AppColors.accentStart, width: width)
        : const BorderSide(color: AppColors.buttonBorder);
  }

  @override
  State<GamepadFocusBlock> createState() => _GamepadFocusBlockState();
}

class _GamepadFocusBlockState extends State<GamepadFocusBlock> {
  late final FocusNode _focus;
  bool _keyboardAttached = false;

  void _syncKeyboard(bool show) {
    if (!widget.attachKeyboard) return;
    if (show && !_keyboardAttached) {
      _keyboardAttached = true;
      final generation = GamepadKeyboardController.instance.generation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.attachKeyboard) return;
        if (GamepadKeyboardController.instance.generation != generation) {
          return;
        }
        if (!_focus.hasFocus) return;
        widget.inputFocus?.requestFocus();
        GamepadKeyboardController.instance.show();
      });
    } else if (!show && _keyboardAttached) {
      _keyboardAttached = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_focus.hasFocus || widget.inputFocus?.hasFocus == true) return;
        if (isEditableTextFocused()) return;
        GamepadKeyboardController.instance.hide();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(
      debugLabel: 'GamepadFocusBlock',
      canRequestFocus: widget.focusable,
      skipTraversal: !widget.focusable,
      descendantsAreFocusable: widget.descendantsFocusable,
      descendantsAreTraversable: false,
    );
    GamepadFocusRegistry.register(_focus);
    widget.inputFocus?.onKeyEvent = handleGamepadFieldArrowKey;
    final chrome = widget.chrome;
    if (chrome != null) {
      GamepadChromeRegistry.register(chrome, _focus);
    }
  }

  @override
  void didUpdateWidget(GamepadFocusBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focus.canRequestFocus = widget.focusable;
    _focus.skipTraversal = !widget.focusable;
    _focus.descendantsAreFocusable = widget.descendantsFocusable;
    if (oldWidget.inputFocus != widget.inputFocus) {
      oldWidget.inputFocus?.onKeyEvent = null;
      widget.inputFocus?.onKeyEvent = handleGamepadFieldArrowKey;
    }
    if (oldWidget.chrome != widget.chrome) {
      if (oldWidget.chrome != null) {
        GamepadChromeRegistry.unregister(oldWidget.chrome!, _focus);
      }
      if (widget.chrome != null) {
        GamepadChromeRegistry.register(widget.chrome!, _focus);
      }
    }
  }

  @override
  void dispose() {
    if (widget.chrome != null) {
      GamepadChromeRegistry.unregister(widget.chrome!, _focus);
    }
    GamepadFocusRegistry.unregister(_focus);
    widget.inputFocus?.onKeyEvent = null;
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        GamepadService.instance.devices,
        GamepadService.instance.activityTick,
        _focus,
      ]),
      builder: (context, _) {
        final show = _focus.hasFocus && gamepadConnected();
        _syncKeyboard(show);
        return GamepadFocusScope(
          onActivate: widget.onActivate,
          highlighted: show,
          focusNode: _focus,
          includeInEdgeFocus: widget.includeInEdgeFocus,
          child: Focus(
            focusNode: _focus,
            autofocus: widget.autofocus,
            canRequestFocus: widget.focusable,
            skipTraversal: !widget.focusable,
            descendantsAreFocusable: widget.descendantsFocusable,
            descendantsAreTraversable: false,
            child: !widget.outlined || !show
                ? widget.child
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      widget.child,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GamepadFocusOutlinePainter(
                              radius: widget.radius,
                              borderWidth: widget.borderWidth,
                              shape: widget.shape,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Обводка по контуру рамки: один RRect, без стыков сторон BoxDecoration.
class _GamepadFocusOutlinePainter extends CustomPainter {
  const _GamepadFocusOutlinePainter({
    required this.radius,
    required this.borderWidth,
    required this.shape,
  });

  final double radius;
  final double borderWidth;
  final GamepadHighlightShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = AppColors.accentStart.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..isAntiAlias = true;
    final paint = Paint()
      ..color = AppColors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final inset = borderWidth / 2;
    if (shape == GamepadHighlightShape.circle) {
      final r = math.max(0.0, math.min(size.width, size.height) / 2 - inset);
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, r, glow);
      canvas.drawCircle(center, r, paint);
      return;
    }
    final corner = math.max(0.0, radius - inset);
    final rrect = RRect.fromLTRBR(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
      Radius.circular(corner),
    );
    canvas.drawRRect(rrect, glow);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GamepadFocusOutlinePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shape != shape;
  }
}

/// Ряд или попап: стик не выходит из группы в заблокированных направлениях.
class GamepadNavGroup extends InheritedWidget {
  const GamepadNavGroup({
    super.key,
    required this.name,
    required super.child,
    this.exclusive = false,
  });

  final String name;

  /// Всплывашка: вверх/вниз/влево/вправо остаются внутри, пока её не закроют.
  final bool exclusive;

  static GamepadNavGroup? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GamepadNavGroup>();
  }

  static GamepadNavGroup? ofNode(FocusNode node) {
    final ctx = node.context;
    if (ctx == null) return null;
    return ctx.getInheritedWidgetOfExactType<GamepadNavGroup>();
  }

  /// Ближняя exclusive-группа, даже если поверх неё лежит обычный ряд.
  static GamepadNavGroup? exclusiveOfNode(FocusNode node) {
    final ctx = node.context;
    if (ctx == null) return null;
    GamepadNavGroup? found;
    ctx.visitAncestorElements((el) {
      final w = el.widget;
      if (w is GamepadNavGroup && w.exclusive) {
        found = w;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  bool updateShouldNotify(GamepadNavGroup oldWidget) {
    return name != oldWidget.name || exclusive != oldWidget.exclusive;
  }
}

class GamepadFocusScope extends InheritedWidget {
  const GamepadFocusScope({
    super.key,
    required this.onActivate,
    required this.highlighted,
    required this.focusNode,
    required super.child,
    this.includeInEdgeFocus = true,
  });

  final VoidCallback? onActivate;
  final bool highlighted;
  final FocusNode focusNode;
  final bool includeInEdgeFocus;

  @override
  bool updateShouldNotify(GamepadFocusScope oldWidget) {
    return onActivate != oldWidget.onActivate ||
        highlighted != oldWidget.highlighted ||
        focusNode != oldWidget.focusNode ||
        includeInEdgeFocus != oldWidget.includeInEdgeFocus;
  }
}
