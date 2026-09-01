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

/// Высота тулбара AppShell: на телефоне компактнее, меньше пустого верха.
double shellToolbarHeight(BuildContext context) {
  return isNarrow(context) ? 48.0 : kToolbarHeight;
}

/// Высота AppBar игрового экрана: в альбоме телефона вертикали мало,
/// и каждый лишний пиксель шапки отнимается у стола.
double gameToolbarHeight(BuildContext context) =>
    isPhoneLandscape(context) ? 44.0 : kToolbarHeight;

/// Безопасные зоны для контента вкладки в альбоме телефона.
///
/// В портрете низ закрывает нижнее меню (оно само красит home indicator), а
/// сверху — тулбар. В альбоме меню нет, и содержимое экрана упирается прямо в
/// вырез сбоку и в полоску home indicator: карты и кнопки уезжают под них.
/// Левый inset съедает `NavigationRail` (у него свой `SafeArea`) — если рейл
/// на экране, второй раз его добавлять нельзя.
EdgeInsets landscapeContentSafeArea({
  required EdgeInsets viewPadding,
  required bool phoneLandscape,
  required bool railVisible,
}) {
  if (!phoneLandscape) return EdgeInsets.zero;
  return EdgeInsets.only(
    left: railVisible ? 0 : viewPadding.left,
    right: viewPadding.right,
    bottom: viewPadding.bottom,
  );
}

/// Клавиатура открыта в альбоме — вертикали почти нет, хром надо схлопнуть.
bool isLandscapeKeyboardOpen(
  BuildContext context, {
  double minInset = 80,
}) {
  final size = MediaQuery.sizeOf(context);
  final inset = MediaQuery.viewInsetsOf(context).bottom;
  return size.width > size.height && inset >= minInset;
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

/// Ряды смайликов на одной странице.
/// На десктопе всегда 3×3 и прокрутка страницами; заполнение высоты —
/// только телефон в альбоме (иначе карточки раздуваются и скролл ломается).
int shopTileRows(BuildContext context, {double? maxHeight}) {
  if (isPhoneLandscape(context)) {
    final h = maxHeight ?? MediaQuery.sizeOf(context).height;
    return (h / 108).floor().clamp(2, 5);
  }
  return 3;
}

/// Растягивать сетку смайликов на весь экран — только phone landscape.
bool shopEmojiFillViewport(BuildContext context) => isPhoneLandscape(context);
