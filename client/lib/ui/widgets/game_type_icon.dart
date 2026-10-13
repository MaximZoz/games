import 'package:flutter/material.dart';
import 'package:multigames_client/ui/widgets/checkers_game_icon.dart';
import 'package:multigames_client/ui/widgets/chess_game_icon.dart';
import 'package:multigames_client/ui/widgets/domino_game_icon.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/ui/widgets/nardy_game_icon.dart';
import 'package:multigames_client/ui/widgets/poker_game_icon.dart';
import 'package:multigames_client/ui/widgets/uno_game_icon.dart';

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
        return PokerGameIcon.iconData;
      case 'uno':
        return Icons.style_rounded;
      case 'domino':
        return Icons.grid_view_rounded;
      case 'nardy':
        return NardyGameIcon.iconData;
      case 'checkers':
        return CheckersGameIcon.iconData;
      case 'chess':
        return ChessGameIcon.iconData;
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
      case 'poker':
        return PokerGameIcon(size: size, color: color);
      case 'uno':
        return UnoGameIcon(size: size);
      case 'domino':
        return DominoGameIcon(size: size);
      case 'nardy':
        return NardyGameIcon(size: size, color: color);
      case 'checkers':
        return CheckersGameIcon(size: size, color: color);
      case 'chess':
        return ChessGameIcon(size: size, color: color);
      default:
        return Icon(iconDataOf(gameType), size: size, color: color);
    }
  }
}
