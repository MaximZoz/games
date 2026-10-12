import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Строки правил «Козла» — соответствуют движку.
List<String> dominoRuleLines({
  required int players,
  required int turnTimeSec,
  int stakeBronze = 0,
  bool offlineBot = false,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return [
    t.rulesUnoPlayers(players),
    if (offlineBot)
      t.rulesDominoOffline
    else
      turnTimeSec == 0 ? t.rulesNoTimeLimit : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
    t.rulesDominoDeal,
    t.rulesDominoOpen,
    t.rulesDominoPlay,
    t.rulesDominoDraw,
    t.rulesDominoScore,
    t.rulesDominoFish,
    t.rulesDominoMatch,
    if (stakeBronze > 0) rulesStakeLine(stakeBronze, t),
  ];
}
