import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Строки правил выбранного режима — соответствуют движку.
List<String> dominoRuleLines({
  required int players,
  required int turnTimeSec,
  int stakeBronze = 0,
  bool offlineBot = false,
  String mode = dominoModeKozel,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  final normalized = dominoNormalizeMode(mode);
  return [
    t.rulesUnoPlayers(players),
    t.rulesDominoMode(dominoModeLabel(normalized, t)),
    if (offlineBot)
      t.rulesDominoOffline
    else
      turnTimeSec == 0 ? t.rulesNoTimeLimit : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
    ..._modeLines(normalized, t),
    if (stakeBronze > 0) rulesStakeLine(stakeBronze, t),
  ];
}

List<String> _modeLines(String mode, AppLocalizations t) {
  switch (mode) {
    case dominoModeClassic:
      return [
        t.rulesDominoClassicDeal,
        t.rulesDominoClassicOpen,
        t.rulesDominoPlay,
        t.rulesDominoDraw,
        t.rulesDominoClassicScore,
        t.rulesDominoClassicFish,
        t.rulesDominoClassicMatch,
      ];
    case dominoModeSea:
      return [
        t.rulesDominoSeaSame,
        t.rulesDominoPlay,
        t.rulesDominoDraw,
        t.rulesDominoSeaScore,
        t.rulesDominoSeaWipe,
        t.rulesDominoSeaBlank,
        t.rulesDominoSeaSix,
        t.rulesDominoSeaMatch,
      ];
    default:
      return [
        t.rulesDominoDeal,
        t.rulesDominoOpen,
        t.rulesDominoPlay,
        t.rulesDominoDraw,
        t.rulesDominoScore,
        t.rulesDominoFish,
        t.rulesDominoMatch,
      ];
  }
}
