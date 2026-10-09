import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Классика — контроль партии 60+0.
const String chessModeClassic = 'classic';

/// Рапид — контроль партии 10+0.
const String chessModeRapid = 'rapid';

/// Блиц — контроль партии 5+0 (5 минут).
const String chessModeBlitz = 'blitz';

/// Пуля — контроль партии 3+2.
const String chessModeBullet = 'bullet';

const List<String> chessAllModes = [
  chessModeClassic,
  chessModeRapid,
  chessModeBlitz,
  chessModeBullet,
];

/// Лимит на ход: 20 с, 1 мин, без лимита.
const List<int> chessTurnTimeOptions = [20, 60, 0];

int chessNormalizeTurnTime(int? raw) {
  if (raw != null && chessTurnTimeOptions.contains(raw)) return raw;
  return 60;
}

String chessNormalizeMode(String? raw) {
  switch (raw) {
    case chessModeRapid:
    case chessModeBlitz:
    case chessModeBullet:
      return raw!;
    default:
      return chessModeClassic;
  }
}

String chessNextMode(String? raw) {
  final cur = chessNormalizeMode(raw);
  return chessAllModes[(chessAllModes.indexOf(cur) + 1) % chessAllModes.length];
}

int chessNextTurnTime(int? raw) {
  final cur = chessNormalizeTurnTime(raw);
  return chessTurnTimeOptions[
      (chessTurnTimeOptions.indexOf(cur) + 1) % chessTurnTimeOptions.length];
}

String chessModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (chessNormalizeMode(mode)) {
    case chessModeRapid:
      return t.gamesChessModeRapid;
    case chessModeBlitz:
      return t.gamesChessModeBlitz;
    case chessModeBullet:
      return t.gamesChessModeBullet;
    default:
      return t.gamesChessModeClassic;
  }
}

String chessClockNotation(String mode) {
  switch (chessNormalizeMode(mode)) {
    case chessModeRapid:
      return '10+0';
    case chessModeBlitz:
      return '5+0';
    case chessModeBullet:
      return '3+2';
    default:
      return '60+0';
  }
}

/// Щелчки часов — только в блице. Звук включается отдельно, пока идут
/// часы самого игрока.
bool chessBlitzClockAudible(String? mode) =>
    chessNormalizeMode(mode) == chessModeBlitz;

/// База и прибавка на ход, мс. classic 60+0, rapid 10+0, blitz 5+0, bullet 3+2.
(int, int) chessClockBudgetMs(String? mode) {
  switch (chessNormalizeMode(mode)) {
    case chessModeRapid:
      return (10 * 60 * 1000, 0);
    case chessModeBlitz:
      return (5 * 60 * 1000, 0);
    case chessModeBullet:
      return (3 * 60 * 1000, 2 * 1000);
    default:
      return (60 * 60 * 1000, 0);
  }
}

String chessClockLine(String mode, AppLocalizations l10n) {
  switch (chessNormalizeMode(mode)) {
    case chessModeRapid:
      return l10n.rulesChessClockRapid;
    case chessModeBlitz:
      return l10n.rulesChessClockBlitz;
    case chessModeBullet:
      return l10n.rulesChessClockBullet;
    default:
      return l10n.rulesChessClockClassic;
  }
}

String chessPlayLine(String mode, AppLocalizations l10n) {
  switch (chessNormalizeMode(mode)) {
    default:
      return l10n.rulesChessPlayClassic;
  }
}

String chessDrawLine(String mode, AppLocalizations l10n) {
  switch (chessNormalizeMode(mode)) {
    default:
      return l10n.rulesChessDrawClassic;
  }
}

/// Строки правил только выбранного контроля времени.
List<String> chessRuleLines({
  required String gameMode,
  required int turnTimeSec,
  required int stakeBronze,
  required AppLocalizations l10n,
  bool offline = false,
}) {
  final mode = chessNormalizeMode(gameMode);
  return [
    l10n.rulesChessPlayers,
    l10n.rulesChessMode(chessModeLabel(mode, l10n)),
    chessClockLine(mode, l10n),
    if (!offline && turnTimeSec == 0)
      l10n.rulesNoTimeLimit
    else if (!offline)
      l10n.rulesTurnTime(formatTurnTime(turnTimeSec)),
    if (!offline && stakeBronze > 0) rulesStakeLine(stakeBronze, l10n),
    chessPlayLine(mode, l10n),
    chessDrawLine(mode, l10n),
  ];
}
