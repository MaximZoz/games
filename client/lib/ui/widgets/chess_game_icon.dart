import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Иконка «Шахматы» — белый конь.
///
/// На фиолетовом бейдже карточки родитель уже даёт фон, поэтому при
/// [color] == белый рисуем только коня. В остальных местах — конь на
/// фиолетовой плашке.
class ChessGameIcon extends StatelessWidget {
  const ChessGameIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;

  /// Белый — только фигура (фон даёт родитель). Иначе плашка фиолетовая.
  final Color? color;

  /// Запасной [IconData] для мест, где нужен только символ.
  static const IconData iconData = Icons.castle_rounded;

  static const String _asset = 'assets/chess/pieces/w_knight.svg';

  bool get _bare => color == Colors.white;

  @override
  Widget build(BuildContext context) {
    final knight = SvgPicture.asset(
      _asset,
      width: size * (_bare ? 1 : 0.78),
      height: size * (_bare ? 1 : 0.78),
      fit: BoxFit.contain,
    );
    if (_bare) {
      return SizedBox(width: size, height: size, child: knight);
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentStart,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: knight,
    );
  }
}
