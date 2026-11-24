import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/game_rules_template.dart';
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
  return gameRuleLines(
    stakeBronze: offlineBot ? 0 : stakeBronze,
    players: players,
    mode: t.gamesPokerModeHoldem,
    turnTimeSec: offlineBot ? 0 : turnTimeSec,
    l10n: t,
    rules: [
      t.rulesPokerIntro,
      t.rulesPokerPlay,
      t.rulesPokerWin,
      t.rulesPokerTable,
    ],
  );
}
