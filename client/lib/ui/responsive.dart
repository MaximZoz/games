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
