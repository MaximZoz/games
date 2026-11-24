import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/game_rules_template.dart';
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
  return gameRuleLines(
    stakeBronze: offline ? 0 : stakeBronze,
    players: 2,
    mode: nardyModeLabel(mode, t),
    turnTimeSec: offline ? 0 : turnTimeSec,
    l10n: t,
    rules: [
      t.rulesNardyIntro,
      mode == nardyModeLong ? t.rulesNardyPlayLong : t.rulesNardyPlayShort,
      if (mode == nardyModeLong) t.rulesNardySixPrime,
      t.rulesNardyWin,
      if (offline) t.rulesNardyOfflineBot,
    ],
  );
}

/// Можно подтвердить ход вручную: кубики брошены, легальных ходов больше нет.
bool nardyCanEndTurn({
  required bool isMyTurn,
  required bool isOver,
  required bool needsRoll,
  required bool hasLegalMoves,
}) =>
    isMyTurn && !isOver && !needsRoll && !hasLegalMoves;

/// Чекбокс «Автоподтверждение» — только на своём ходе, пока партия идёт.
bool nardyShouldShowAutoConfirm({
  required bool isMyTurn,
  required bool isOver,
}) =>
    isMyTurn && !isOver;

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
