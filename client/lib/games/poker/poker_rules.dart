import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Строки правил покера — единый источник для карточки игры, приглашения
/// и экрана лобби. [offlineBot] убирает ставку и время на ход.
List<String> pokerRuleLines({
  required int players,
  required int turnTimeSec,
  required int stakeBronze,
  bool offlineBot = false,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return [
    t.rulesPokerPlayers(players),
    if (!offlineBot) ...[
      turnTimeSec == 0
          ? t.rulesNoTimeLimit
          : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
      if (stakeBronze > 0) t.rulesStake('$stakeBronze'),
    ],
    t.rulesPokerIntro,
    t.rulesPokerPlay,
    t.rulesPokerWin,
  ];
}
