import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/game_turn_action.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Строки правил «Уно» — соответствуют движку (7 карт, без стека +2,
/// оспаривание +4, добор одной, вдвоём до 100, при 3+ игроках до 200).
List<String> unoRuleLines({
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
      t.rulesUnoOfflineBot
    else ...[
      turnTimeSec == 0
          ? t.rulesNoTimeLimit
          : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
    ],
    t.rulesUnoIntro,
    t.rulesUnoPlay,
    t.rulesUnoWild,
    t.rulesUnoDraw,
    t.rulesUnoCall,
    t.rulesUnoScoring,
    if (stakeBronze > 0) rulesStakeLine(stakeBronze, t),
  ];
}

/// Кнопка и колода «Взять» активны только пока можно взять и нет запроса в полёте.
bool unoDrawControlEnabled({
  required bool busy,
  required bool canTake,
}) =>
    !busy && canTake;

/// Второй тап «Взять» после смены хода — не показывать «Сейчас не ваш ход».
bool isStaleUnoDrawError(Object error) => isStaleNotYourTurnError(error);
