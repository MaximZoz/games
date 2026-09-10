import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

String checkersModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (CheckersEngine.normalizeMode(mode)) {
    case CheckersEngine.modeEnglish:
      return t.gamesCheckersModeEnglish;
    case CheckersEngine.modeGiveaway:
      return t.gamesCheckersModeGiveaway;
    case CheckersEngine.modeCorners:
      return t.gamesCheckersModeCorners;
    default:
      return t.gamesCheckersModeRussian;
  }
}

String checkersPlayLine(String mode, AppLocalizations l10n) {
  switch (CheckersEngine.normalizeMode(mode)) {
    case CheckersEngine.modeEnglish:
      return l10n.rulesCheckersPlayEnglish;
    case CheckersEngine.modeGiveaway:
      return l10n.rulesCheckersPlayGiveaway;
    case CheckersEngine.modeCorners:
      return l10n.rulesCheckersPlayCorners;
    default:
      return l10n.rulesCheckersPlay;
  }
}

List<String> checkersRuleLines({
  required String gameMode,
  required int turnTimeSec,
  required int stakeBronze,
  required AppLocalizations l10n,
  bool offline = false,
}) {
  final mode = CheckersEngine.normalizeMode(gameMode);
  return [
    l10n.rulesCheckersPlayers,
    l10n.rulesCheckersMode(checkersModeLabel(mode, l10n)),
    if (offline)
      l10n.rulesCheckersOfflineBot
    else
      l10n.rulesCheckersTime(formatTurnTime(turnTimeSec)),
    if (!offline && stakeBronze > 0) rulesStakeLine(stakeBronze, l10n),
    if (mode != CheckersEngine.modeCorners) l10n.rulesCheckersIntro,
    checkersPlayLine(mode, l10n),
    if (mode == CheckersEngine.modeCorners) ...[
      l10n.rulesCheckersPlayCornersNoReturn,
      l10n.rulesCheckersPlayCornersLeaveHome,
    ],
    if (mode != CheckersEngine.modeCorners) l10n.rulesCheckersWin,
  ];
}
