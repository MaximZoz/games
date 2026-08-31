import 'package:flutter/material.dart';

/// Брейкпоинты: mobile < 700, desktop >= 700.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 700;
}

bool isNarrow(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  // Для телефонов ориентируемся на shortestSide:
  // в landscape width может быть большой, но shortestSide остаётся "мобильным".
  return size.shortestSide < Breakpoints.mobile;
}

bool isWide(BuildContext context) {
  return !isNarrow(context);
}

/// Телефон в горизонтальной ориентации (не планшет/десктоп).
bool isPhoneLandscape(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return isNarrow(context) && size.width > size.height;
}

/// Планшет (wide, но не большой десктоп).
bool isTablet(BuildContext context) {
  if (!isWide(context)) return false;
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 1100;
}

/// Нужна «плитка» (десктоп / планшет / телефон landscape).
bool useDesktopTiles(BuildContext context) {
  return isWide(context) || isPhoneLandscape(context);
}

/// Смайлики и коллекции: 3 колонки на портрете/десктопе (не 4 — колесо прыгает).
/// В phone landscape больше колонок, чтобы сетка заняла ширину.
int shopTileColumns(BuildContext context, {double? maxWidth}) {
  if (isPhoneLandscape(context)) {
    final w = maxWidth ?? MediaQuery.sizeOf(context).width;
    return (w / 96).floor().clamp(4, 7);
  }
  return 3;
}

/// Ряды смайликов на одной странице — чтобы сетка заняла высоту экрана.
int shopTileRows(BuildContext context, {double? maxHeight}) {
  if (isPhoneLandscape(context) || isWide(context)) {
    final h = maxHeight ?? MediaQuery.sizeOf(context).height;
    return (h / 108).floor().clamp(2, 5);
  }
  return 3;
}
