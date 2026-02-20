import 'package:flutter/material.dart';

/// Брейкпоинты: mobile < 700, desktop >= 700.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 700;
}

bool isNarrow(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  // На iPhone в landscape width часто > 700, но это всё ещё мобильный сценарий.
  final isLandscapePhone = size.height < 500 && size.shortestSide < Breakpoints.mobile;
  return size.width < Breakpoints.mobile || isLandscapePhone;
}

bool isWide(BuildContext context) {
  return !isNarrow(context);
}
