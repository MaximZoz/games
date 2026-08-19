import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Строки правил «Уно» для карточки на экране игр.
List<String> unoRuleLines({
  required int players,
  required int turnTimeSec,
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
    t.rulesUnoWin,
  ];
}
