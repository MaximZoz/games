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

/// Высота полоски под системный status bar в [AppShell].
///
/// В альбоме партии тулбар оболочки прячем, но на Android часы и батарея
/// остаются поверх экрана. Их высоту нельзя обнулять вместе с тулбаром —
/// иначе рейл и шапка игры уезжают под системную панель. Ноль только когда
/// клавиатура съела вертикаль (профиль / друзья / чаты).
double shellStatusBarExtent({
  required double viewPaddingTop,
  required bool collapseForInput,
}) {
  if (collapseForInput) return 0;
  return viewPaddingTop < 0 ? 0 : viewPaddingTop;
}

/// Безопасные зоны для контента вкладки в альбоме телефона.
///
/// В портрете низ закрывает нижнее меню (оно само красит home indicator), а
/// сверху — тулбар. В альбоме меню нет, и содержимое экрана упирается прямо в
/// вырез сбоку и в полоску home indicator: карты и кнопки уезжают под них.
/// Левый inset, когда рейл на экране, вешает [landscapeRailLeadingInset] на
/// сам рейл — второй раз его в контент добавлять нельзя.
/// Верх (status bar) в альбоме резервирует [shellStatusBarExtent], не эта
/// функция: рейл стоит рядом с контентом и тоже должен уйти вниз.
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

/// Левый вырез / status bar в альбоме телефона, когда виден рейл.
///
/// На Android часы и камера сидят на коротком крае слева. Рейл в [Row]
/// стоит в x=0, а `NavigationRail.useSafeArea` смотрит в `MediaQuery.padding`,
/// который Scaffold обнуляет у body. Отступ берём из [viewPadding] и
/// вешаем на рейл, иначе иконки уезжают под системную панель.
///
/// На iOS (включая iOS Safari / PWA) в альбоме браузер отдаёт симметричный
/// горизонтальный `safe-area-inset-left/right` (~59 px), но системной строки
/// состояния слева нет — сдвигать кнопки меню от левого края не нужно.
double landscapeRailLeadingInset({
  required EdgeInsets viewPadding,
  required bool phoneLandscape,
  required bool railVisible,
  TargetPlatform? platform,
}) {
  if (!phoneLandscape || !railVisible) return 0;
  if (platform == TargetPlatform.iOS) return 0;
  return viewPadding.left < 0 ? 0 : viewPadding.left;
}

/// Насколько увести крайние кнопки шапки от скруглённых углов iPhone в альбоме.
///
/// Выход, новое сообщение, поиск друзей и монеты стоят в углах длинной стороны.
/// Радиус скругления срезает их внешний край — сдвигаем к центру экрана.
const double phoneLandscapeCornerInsetPx = 8;

double phoneLandscapeCornerInset({
  required bool phoneLandscape,
  required TargetPlatform? platform,
}) {
  if (!phoneLandscape || platform != TargetPlatform.iOS) return 0;
  return phoneLandscapeCornerInsetPx;
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

/// Минимальная высота ячейки смайла: эмодзи + название + цена + «Купить».
const shopEmojiMinCellHeight = 124.0;

/// Ряды смайликов на одной странице.
/// На десктопе всегда 3×3 и прокрутка страницами.
/// На телефоне в альбоме — всегда 2 ряда на всю страницу: три ряда
/// обрезаются шапкой, рейлом и safe area даже если «по экрану» влезают.
int shopTileRows(BuildContext context, {double? maxHeight}) {
  if (isPhoneLandscape(context)) {
    // maxHeight оставляем в сигнатуре: сетка передаёт реальную высоту.
    return maxHeight != null && maxHeight < shopEmojiMinCellHeight ? 1 : 2;
  }
  return 3;
}

/// Растягивать сетку смайликов на весь экран — только phone landscape.
bool shopEmojiFillViewport(BuildContext context) => isPhoneLandscape(context);
