import 'package:flutter/material.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';

/// Иконка типа игры — те же, что на карточках «Игры».
class GameTypeIcon extends StatelessWidget {
  const GameTypeIcon({
    super.key,
    required this.gameType,
    this.size = 24,
    this.color,
  });

  final String gameType;
  final double size;
  final Color? color;

  /// Material-иконка без зеркала (для мест, где нужен только [IconData]).
  static IconData iconDataOf(String gameType) {
    switch (gameType.trim()) {
      case 'durak':
        return DurakGameIcon.iconData;
      case 'battleship':
        return Icons.directions_boat_filled_rounded;
      case 'poker':
        return Icons.casino_rounded;
      case 'tictactoe':
        return Icons.grid_3x3_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (gameType.trim()) {
      case 'durak':
        return DurakGameIcon(size: size, color: color);
      default:
        return Icon(iconDataOf(gameType), size: size, color: color);
    }
  }
}
