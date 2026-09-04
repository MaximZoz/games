import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Короткие нарды (встречные, с боем).
const String nardyModeShort = 'short';

/// Длинные нарды (с одной головы, без боя).
const String nardyModeLong = 'long';

String nardyNormalizeMode(String? mode) =>
    mode == nardyModeLong ? nardyModeLong : nardyModeShort;

/// Подпись режима на карточке и в правилах.
String nardyModeLabel(String mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  return nardyNormalizeMode(mode) == nardyModeLong
      ? t.gamesNardyModeLong
      : t.gamesNardyModeShort;
}

/// Строки правил нард — карточка и диалог.
List<String> nardyRuleLines({
  required String gameMode,
  required int turnTimeSec,
  required int stakeBronze,
  bool offline = false,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  final mode = nardyNormalizeMode(gameMode);
  return [
    t.rulesNardyPlayers,
    t.rulesNardyMode(nardyModeLabel(mode, t)),
    turnTimeSec == 0
        ? t.rulesNoTimeLimit
        : t.rulesTurnTime(formatTurnTime(turnTimeSec)),
    if (stakeBronze > 0) rulesStakeLine(stakeBronze, t),
    t.rulesNardyIntro,
    mode == nardyModeLong ? t.rulesNardyPlayLong : t.rulesNardyPlayShort,
    if (mode == nardyModeLong) t.rulesNardySixPrime,
    t.rulesNardyWin,
    if (offline) t.rulesNardyOfflineBot,
  ];
}

/// Можно подтвердить ход вручную: кубики брошены, легальных ходов больше нет.
bool nardyCanEndTurn({
  required bool isMyTurn,
  required bool isOver,
  required bool needsRoll,
  required bool hasLegalMoves,
}) =>
    isMyTurn && !isOver && !needsRoll && !hasLegalMoves;

/// Показать «Готово» / «Пропустить», только если автоподтверждение выключено.
bool nardyShouldShowEndTurn({
  required bool autoConfirm,
  required bool isMyTurn,
  required bool isOver,
  required bool needsRoll,
  required bool hasLegalMoves,
}) =>
    !autoConfirm &&
    nardyCanEndTurn(
      isMyTurn: isMyTurn,
      isOver: isOver,
      needsRoll: needsRoll,
      hasLegalMoves: hasLegalMoves,
    );

/// После всех ходов (или если ходить нечем) сразу отдать ход сопернику.
bool nardyShouldAutoEndTurn({
  required bool autoConfirm,
  required bool isMyTurn,
  required bool isOver,
  required bool needsRoll,
  required bool hasLegalMoves,
}) =>
    autoConfirm &&
    nardyCanEndTurn(
      isMyTurn: isMyTurn,
      isOver: isOver,
      needsRoll: needsRoll,
      hasLegalMoves: hasLegalMoves,
    );
