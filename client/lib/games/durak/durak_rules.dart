import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Подпись режима игры «Дурак».
String durakModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  return mode == 'perevodnoi'
      ? t.gamesDurakModePerevodnoi
      : t.gamesDurakModePodkidnoi;
}

/// Подпись размера колоды.
String durakDeckLabel(int n, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (n) {
    case 24:
      return t.gamesDurakDeck24;
    case 52:
      return t.gamesDurakDeck52;
    default:
      return t.gamesDurakDeck36;
  }
}

/// Допустимые размеры колоды: вдвоём — 24/36, втроём/вчетвером — 36/52.
List<int> durakDeckSizesForPlayers(int players) =>
    players <= 2 ? const [24, 36] : const [36, 52];

/// Подогнать колоду под число игроков (если текущая недоступна → 36).
int durakClampDeckForPlayers(int players, int deckSize) {
  final allowed = durakDeckSizesForPlayers(players);
  if (allowed.contains(deckSize)) return deckSize;
  return 36;
}

/// Строки правил «Дурака» — единый источник для карточки игры, приглашения
/// и экрана лобби. [offlineBot] убирает ставку и время на ход.
List<String> durakRuleLines({
  required String mode,
  required int players,
  required int deckSize,
  required int turnTimeSec,
  required int stakeBronze,
  bool offlineBot = false,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return [
    t.rulesDurakMode(durakModeLabel(mode, t)),
    t.rulesDurakPlayersDeck(players, durakDeckLabel(deckSize, t)),
    if (offlineBot)
      t.rulesDurakOfflineBot
    else ...[
      turnTimeSec == 0
          ? t.rulesNoTimeLimit
          : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
      if (stakeBronze > 0) t.rulesStake('$stakeBronze'),
    ],
    t.rulesDurakAttack,
    t.rulesDurakBeat,
    t.rulesDurakLoser,
  ];
}
