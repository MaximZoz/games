import 'package:flutter/material.dart';

/// Брейкпоинты: mobile < 700, desktop >= 700.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 700;
}

bool isNarrow(BuildContext context) {
  return MediaQuery.sizeOf(context).width < Breakpoints.mobile;
}

bool isWide(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
}
