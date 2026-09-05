import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/connect4/connect4_engine.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

String connect4ModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  return Connect4Engine.normalizeMode(mode) == Connect4Engine.modeWide
      ? t.gamesConnect4ModeWide
      : t.gamesConnect4ModeClassic;
}

List<String> connect4RuleLines({
  required String gameMode,
  required int turnTimeSec,
  required int stakeBronze,
  required AppLocalizations l10n,
  bool offline = false,
}) {
  final mode = Connect4Engine.normalizeMode(gameMode);
  final (cols, rows) = Connect4Engine.sizeForMode(mode);
  return [
    l10n.rulesConnect4Players,
    l10n.rulesConnect4Mode(connect4ModeLabel(mode, l10n)),
    if (offline) l10n.rulesConnect4OfflineBot else l10n.rulesConnect4Time(formatTurnTime(turnTimeSec)),
    if (!offline && stakeBronze > 0) rulesStakeLine(stakeBronze, l10n),
    l10n.rulesConnect4Intro(cols, rows),
    l10n.rulesConnect4Play,
    l10n.rulesConnect4Win,
  ];
}
