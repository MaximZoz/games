import 'package:flutter/material.dart';
import 'package:multigames_ui/theme/app_theme.dart';

/// Единая палитра игровых столов.
///
/// Стол, фишки и подсветка во всех играх берутся отсюда, а не из литералов
/// в экране: новая игра выглядит как остальные, не выбирая свои цвета.
class GamePalette {
  GamePalette._();

  /// Поверхность стола: светлая лаванда поверх фона приложения.
  static const Color tableTop = Color(0xFFF4F2FF);
  static const Color tableBottom = Color(0xFFE4E8FA);
  static const Color tableBorder = AppColors.buttonBorder;

  /// Подписи и счётчики на столе.
  static const Color tableInk = Color(0xFF3F3D73);
  static const Color tableInkSoft = Color(0xFF7C7AA8);

  /// Лицо фишки (кость, карта, шашка).
  static const Color pieceFace = Color(0xFFFFFFFF);
  static const Color pieceFaceShade = Color(0xFFEFEEFA);
  static const Color pieceEdge = Color(0xFFB9B6E6);
  static const Color pieceInk = Color(0xFF26244A);

  /// Рубашка фишки — акцент приложения.
  static const Color pieceBackStart = AppColors.accentStart;
  static const Color pieceBackEnd = AppColors.accentEnd;
  static const Color pieceBackInk = Color(0xFFE0E7FF);

  /// Выбранная / доступная для хода фишка.
  static const Color highlight = AppColors.accentStart;
  static const Color highlightSoft = AppColors.accentSoft;

  /// Тень под фишкой.
  static const Color shadow = Color(0x2E3F3D73);

  /// Клетчатая доска (шахматы, шашки): светлая и тёмная клетка.
  static const Color boardLight = Color(0xFFEEF0FF);
  static const Color boardDark = Color(0xFF9396E6);

  /// Клетки последнего хода — янтарь, чуть разный на светлой и тёмной.
  static const Color boardMarkLight = Color(0xFFFCE588);
  static const Color boardMarkDark = Color(0xFFF2BE45);

  /// Точка «сюда можно пойти» и рамка курсора геймпада на светлой доске.
  static const Color boardDot = Color(0x7326244A);
  static const Color boardCursor = Color(0xFF312E81);

  /// Тёмное сукно: стол покера, доска нард, овал колоды Уно.
  static const Color feltTop = Color(0xFF5850BE);
  static const Color feltBottom = Color(0xFF3B3486);
  static const Color feltEdge = Color(0xFF2A2560);
  static const Color feltDeep = Color(0xFF241C3B);
  static const Color feltFrame = Color(0xFF3B2F63);

  /// Полосы на тёмном сукне (пункты нард): светлая и тёмная.
  static const Color feltStripeLight = Color(0xFF7C68C4);
  static const Color feltStripeDark = Color(0xFF43376F);
  static const Color feltInk = Color(0xFFFFFFFF);
  static const Color feltInkSoft = Color(0xB3FFFFFF);

  /// Тень под светлой подписью на сукне.
  static const Color feltShadow = Color(0x99000000);

  /// Плашка поверх сукна: место игрока, подпись банка.
  static const Color feltPlate = Color(0xFF1E1B4B);
  static const Color feltPlateDim = Color(0xFF34306B);

  /// Две стороны партии: светлые и тёмные фишки.
  static const Color sideLight = Color(0xFFF6F1FF);
  static const Color sideLightEdge = Color(0xFF9C8FD6);
  static const Color sideDark = Color(0xFF3730A3);
  static const Color sideDarkEdge = Color(0xFF1E1B4B);

  /// Объём круглой фишки: тень светлой стороны и блик тёмной.
  static const Color sideLightShade = Color(0xFFCFC8F2);
  static const Color sideDarkShine = Color(0xFF6D66D8);

  /// Янтарь — второй акцент: фишки банка, корона дамки, тёплая сторона
  /// на тёмной доске, «последний ход».
  static const Color amber = Color(0xFFFBBF24);
  static const Color amberDeep = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFDE68A);
  static const Color amberInk = Color(0xFF5C3B00);

  /// Опасность: шах, взятие, попадание, штраф.
  static const Color danger = Color(0xFFE53935);
  static const Color dangerDeep = Color(0xFFB71C1C);
  static const Color dangerSoft = Color(0xFFE57373);

  /// «Можно»: допустимая клетка, цель хода.
  static const Color go = Color(0xFF56E39F);
  static const Color goDeep = Color(0xFF12996A);

  /// Мягкое свечение в центре светлого стола (карточные игры).
  static const Color tableGlow = Color(0xFFC7D2FE);

  /// Вода Морского боя: обычная клетка и клетка, по которой идёт выстрел.
  static const Color water = tableGlow;
  static const Color waterSoft = highlightSoft;

  /// Курсор геймпада на тёмном сукне.
  static const Color focus = Color(0xFF7EE0FF);

  static const LinearGradient tableGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [tableTop, tableBottom],
  );

  static const LinearGradient feltGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [feltTop, feltBottom],
  );

  static const LinearGradient pieceBackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pieceBackStart, pieceBackEnd],
  );
}
