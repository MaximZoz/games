import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Классические шахматы.
const String chessModeClassic = 'classic';

/// Шахматы-960 (Фишер).
const String chessMode960 = 'chess960';

/// Антишахматы (взятие обязательно, цель — отдать фигуры).
const String chessModeAntichess = 'antichess';

const List<String> chessAllModes = [
  chessModeClassic,
  chessMode960,
  chessModeAntichess,
];

String chessNormalizeMode(String? raw) {
  switch (raw) {
    case chessMode960:
    case chessModeAntichess:
      return raw!;
    default:
      return chessModeClassic;
  }
}

String chessNextMode(String? raw) {
  final cur = chessNormalizeMode(raw);
  return chessAllModes[(chessAllModes.indexOf(cur) + 1) % chessAllModes.length];
}

String chessModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (chessNormalizeMode(mode)) {
    case chessMode960:
      return t.gamesChessMode960;
    case chessModeAntichess:
      return t.gamesChessModeAntichess;
    default:
      return t.gamesChessModeClassic;
  }
}

String chessPlayLine(String mode, AppLocalizations l10n) {
  switch (chessNormalizeMode(mode)) {
    case chessMode960:
      return l10n.rulesChessPlay960;
    case chessModeAntichess:
      return l10n.rulesChessPlayAntichess;
    default:
      return l10n.rulesChessPlayClassic;
  }
}

String chessDrawLine(String mode, AppLocalizations l10n) {
  switch (chessNormalizeMode(mode)) {
    case chessMode960:
      return l10n.rulesChessDraw960;
    case chessModeAntichess:
      return l10n.rulesChessDrawAntichess;
    default:
      return l10n.rulesChessDrawClassic;
  }
}

/// Строки правил только выбранного режима.
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
    if (offline)
      l10n.rulesNoTimeLimit
    else if (turnTimeSec == 0)
      l10n.rulesNoTimeLimit
    else
      l10n.rulesTurnTime(formatTurnTime(turnTimeSec)),
    if (!offline && stakeBronze > 0) rulesStakeLine(stakeBronze, l10n),
    chessPlayLine(mode, l10n),
    chessDrawLine(mode, l10n),
  ];
}
