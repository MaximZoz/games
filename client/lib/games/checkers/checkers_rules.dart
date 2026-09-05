import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Русские шашки (Russian draughts).
const String checkersModeRussian = 'russian';

/// Английские шашки (English draughts).
const String checkersModeEnglish = 'english';

/// Поддавки (Giveaway).
const String checkersModeGiveaway = 'giveaway';

/// Уголки (Corners).
const String checkersModeCorners = 'corners';

/// Режимы на карточке: русские → английские → поддавки → уголки.
const List<String> checkersModes = <String>[
  checkersModeRussian,
  checkersModeEnglish,
  checkersModeGiveaway,
  checkersModeCorners,
];

String checkersNormalizeMode(String? mode) {
  switch ((mode ?? '').trim().toLowerCase()) {
    case checkersModeEnglish:
      return checkersModeEnglish;
    case checkersModeGiveaway:
      return checkersModeGiveaway;
    case checkersModeCorners:
      return checkersModeCorners;
    default:
      return checkersModeRussian;
  }
}

String checkersNextMode(String? mode) {
  final current = checkersNormalizeMode(mode);
  final idx = checkersModes.indexOf(current);
  return checkersModes[(idx < 0 ? 0 : idx + 1) % checkersModes.length];
}

/// Подпись режима на карточке и в правилах.
String checkersModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (checkersNormalizeMode(mode)) {
    case checkersModeEnglish:
      return t.gamesCheckersModeEnglish;
    case checkersModeGiveaway:
      return t.gamesCheckersModeGiveaway;
    case checkersModeCorners:
      return t.gamesCheckersModeCorners;
    default:
      return t.gamesCheckersModeRussian;
  }
}

/// Строки правил шашек — карточка и диалог.
List<String> checkersRuleLines({
  required String gameMode,
  required int turnTimeSec,
  required int stakeBronze,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  final mode = checkersNormalizeMode(gameMode);
  return [
    t.rulesCheckersPlayers,
    t.rulesCheckersMode(checkersModeLabel(mode, t)),
    turnTimeSec == 0
        ? t.rulesNoTimeLimit
        : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
    if (stakeBronze > 0) rulesStakeLine(stakeBronze, t),
    t.rulesCheckersIntro,
    switch (mode) {
      checkersModeEnglish => t.rulesCheckersPlayEnglish,
      checkersModeGiveaway => t.rulesCheckersPlayGiveaway,
      checkersModeCorners => t.rulesCheckersPlayCorners,
      _ => t.rulesCheckersPlayRussian,
    },
  ];
}
