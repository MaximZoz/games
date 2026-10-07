import 'package:flutter/widgets.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/framework/game_coming_soon_screen.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Дескриптор «Шахматы» — карточка, режимы и правила; партии ещё нет.
class ChessGame extends GameDescriptor {
  @override
  String get id => 'chess';

  @override
  String localizedName(AppLocalizations l10n) => l10n.gamesChess;

  @override
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      chessModeLabel(
        gameMode.isNotEmpty ? gameMode : variant,
        l10n,
      );

  @override
  int get sortOrder => 80;

  @override
  bool get supportsOffline => false;

  @override
  bool get comingSoon => true;

  @override
  bool supportsDrawOffer(int playerCount) => playerCount == 2;

  @override
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  }) =>
      GameComingSoonScreen(titleOf: (l10n) => l10n.gamesChess);

  @override
  Widget buildGameScreen({required String gameId}) =>
      GameComingSoonScreen(titleOf: (l10n) => l10n.gamesChess);
}
