import 'package:flutter/widgets.dart';

/// Высота клавиатуры, которой можно доверять при раскладке.
///
/// iOS PWA иногда отдаёт `viewInsets.bottom` больше реальной клавиатуры
/// (Safari считает его от layout viewport, пока страница проскроллена).
/// Если вычесть такое значение, экрану остаётся полоска в несколько пикселей:
/// виден только тулбар, а список и поле ввода схлопываются в ноль.
///
/// Клавиатура не занимает больше [maxFraction] высоты экрана, поэтому
/// всё, что выше, — заведомо мусор. Порог высокий: в альбоме клавиатура
/// честно забирает две трети экрана, и ограничивать её нельзя.
double sanitizeKeyboardInset({
  required double inset,
  required double viewportHeight,
  double maxFraction = 0.85,
}) {
  if (inset <= 0 || !inset.isFinite) return 0;
  if (viewportHeight <= 0 || !viewportHeight.isFinite) return inset;
  final limit = viewportHeight * maxFraction;
  return inset > limit ? limit : inset;
}

/// Клавиатура действительно открыта (мелкие значения — safe area, не IME).
bool keyboardIsOpen(double inset) => inset >= 80;

/// Метка «клавиатуру уже вычли выше по дереву».
///
/// Вложенные Scaffold'ы (список чатов, переписка, друзья) не должны вычитать
/// её второй раз: экрану остаётся высота без двух клавиатур.
class KeyboardInsetScope extends InheritedWidget {
  const KeyboardInsetScope({
    super.key,
    required this.handled,
    required super.child,
  });

  final bool handled;

  static bool handledOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<KeyboardInsetScope>();
    return scope?.handled ?? false;
  }

  @override
  bool updateShouldNotify(KeyboardInsetScope oldWidget) =>
      oldWidget.handled != handled;
}
