import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatStakeAmount, formatTurnTime;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Время на расстановку флота (как на сервере `battleshipSetupSec`).
const int kBattleshipSetupTimeSec = 60;

/// Строки правил «Морского боя» — карточка, лобби, приглашение, экран игры.
List<String> battleshipRuleLines({
  required int turnTimeSec,
  required int stakeBronze,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return [
    t.rulesBattleshipPlayers,
    t.rulesBattleshipSetupTime(formatTurnTime(kBattleshipSetupTimeSec)),
    turnTimeSec == 0
        ? t.rulesNoTimeLimit
        : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
    if (stakeBronze > 0) t.rulesStake(formatStakeAmount(stakeBronze)),
    t.rulesBattleshipIntro,
    t.rulesBattleshipSetup,
    t.rulesBattleshipPlay,
    t.rulesBattleshipWin,
  ];
}
