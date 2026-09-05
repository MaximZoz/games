import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

String checkersModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  return CheckersEngine.normalizeMode(mode) == CheckersEngine.modeGiveaway
      ? t.gamesCheckersModeGiveaway
      : t.gamesCheckersModeRussian;
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
    l10n.rulesCheckersIntro,
    l10n.rulesCheckersPlay,
    l10n.rulesCheckersWin,
  ];
}
