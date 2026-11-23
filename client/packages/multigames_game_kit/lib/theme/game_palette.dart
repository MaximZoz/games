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

  static const LinearGradient tableGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [tableTop, tableBottom],
  );

  static const LinearGradient pieceBackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pieceBackStart, pieceBackEnd],
  );
}
