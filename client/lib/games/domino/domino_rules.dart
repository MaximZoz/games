import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';
import 'package:multigames_client/games/game_rules_template.dart';
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
  return gameRuleLines(
    stakeBronze: offlineBot ? 0 : stakeBronze,
    players: players,
    mode: dominoModeLabel(normalized, t),
    turnTimeSec: offlineBot ? 0 : turnTimeSec,
    l10n: t,
    rules: [
      ..._modeLines(normalized, t),
      if (offlineBot) t.rulesDominoOffline,
    ],
  );
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
