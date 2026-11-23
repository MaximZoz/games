import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/game_rules_template.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Время на расстановку флота (как на сервере `battleshipSetupSec`).
const int kBattleshipSetupTimeSec = 60;

/// Строки правил «Морского боя» — карточка, лобби, приглашение, экран игры.
List<String> battleshipRuleLines({
  required int turnTimeSec,
  required int stakeBronze,
  bool offlineBot = false,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return gameRuleLines(
    stakeBronze: offlineBot ? 0 : stakeBronze,
    players: 2,
    mode: t.gamesModeClassic,
    turnTimeSec: offlineBot ? 0 : turnTimeSec,
    l10n: t,
    rules: [
      if (offlineBot)
        t.rulesNardyOfflineBot
      else
        t.rulesBattleshipSetupTime(formatTurnTime(kBattleshipSetupTimeSec)),
      t.rulesBattleshipIntro,
      if (!offlineBot) t.rulesBattleshipSetup,
      t.rulesBattleshipPlay,
      t.rulesBattleshipWin,
    ],
  );
}
