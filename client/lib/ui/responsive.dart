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

/// Смайлики и коллекции: 3 колонки на одном экране (не 4 — колесо прыгает рядом).
int shopTileColumns(BuildContext context) => 3;
