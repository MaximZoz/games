import 'dart:math' as math;
import 'dart:ui';

/// Геометрия рядов пар на столе дурака.
///
/// Вынесена из экрана, потому что одни и те же числа нужны и вёрстке стола,
/// и расчёту точки посадки летящей карты: разойдутся — карта сядет мимо.

/// Высота слота пары (карта атаки + карта защиты со сдвигом).
double durakTablePairHeight(Size cardSize) => cardSize.height + 20;

/// Обычный вертикальный шаг между рядами (без наезда).
double durakTableNormalRowStep(Size cardSize) =>
    durakTablePairHeight(cardSize) + 10;

/// Наезд «кромкой»: от предыдущего ряда виден ранг с мастью.
double durakTableCompactPeek(Size cardSize) => cardSize.height * 0.40;

/// Y-координата верха ряда [row] (0-based) при [rowCount] рядах.
///
/// [compact] — телефон в альбоме: между шапкой соперников и кнопкой действия
/// остаётся ~90 px, обычный шаг не помещается уже на втором ряду, поэтому
/// ряды всегда идут «кромкой».
double durakTableRowTop(
  Size cardSize,
  int row,
  int rowCount, {
  required bool compact,
}) {
  if (row <= 0) return 0;
  final peek = durakTableCompactPeek(cardSize);
  if (compact) return row * peek;
  if (rowCount < 3) return row * durakTableNormalRowStep(cardSize);
  // Ряд 1 (второй): чуть ниже, чтобы читалась масть у первого ряда.
  if (row == 1) return peek;
  // Ряд 2+ (третий…): как обычно относительно предыдущего полного ряда.
  return peek + (row - 1) * durakTableNormalRowStep(cardSize);
}

/// Полная высота стопки рядов.
double durakTableStackHeight(
  Size cardSize,
  int rowCount, {
  required bool compact,
}) {
  if (rowCount <= 0) return 0;
  return durakTableRowTop(cardSize, rowCount - 1, rowCount, compact: compact) +
      durakTablePairHeight(cardSize);
}

/// Раскладывать ряды стопкой с наездом, а не колонкой с зазором.
bool durakTableUsesRowStack(int rowCount, {required bool compact}) =>
    rowCount >= 3 || (compact && rowCount >= 2);

/// Минимальная высота коридора стола: хотя бы одна пара + воздух.
double durakTableAreaMinHeight(Size cardSize) =>
    durakTablePairHeight(cardSize) + 12;

/// Не отдавать кнопке весь стол: иначе пары получают 0 px и «исчезают».
double durakClampedTableBottomReserve({
  required double reserve,
  required double boardHeight,
  required Size cardSize,
}) {
  final minTable = durakTableAreaMinHeight(cardSize);
  final maxReserve = math.max(0.0, boardHeight - minTable);
  if (reserve < 0) return 0;
  if (reserve > maxReserve) return maxReserve;
  return reserve;
}

/// Серверную пару не рисуем, пока атака ещё в полёте / optimistic.
///
/// Иначе карта вспыхивает на столе до посадки overlay. Если overlay
/// не стартовал, caller сразу снимает [flyingToTable] — слот не зависает.
/// [remoteFlying] — чужой overlay уже летит или ход ещё ждёт FX.
bool durakKeepServerTablePair({
  required bool optimistic,
  required bool flyingToTable,
  bool remoteFlying = false,
}) {
  return !optimistic && !flyingToTable && !remoteFlying;
}

/// Новую чужую атаку прячем, пока busy/replay не успели запустить полёт.
bool durakHideDeferredRemoteAttack({
  required bool existedOnPrevTable,
  required bool optimistic,
  required bool localFlying,
  required bool fxDeferred,
}) {
  if (optimistic || localFlying || existedOnPrevTable) return false;
  return fxDeferred;
}

/// Чья рука кинула новую атаку: подкид — thrower, иначе attacker.
int durakRemoteAttackFromSeat({
  required int attackerIndex,
  required int throwerIndex,
}) =>
    throwerIndex >= 0 ? throwerIndex : attackerIndex;

/// Слот атаки скрыт, пока свой или чужой overlay ещё в полёте.
bool durakTableAttackSlotInFlight({
  required bool localFlying,
  required bool remoteFlying,
}) =>
    localFlying || remoteFlying;

/// Защиту не рисуем, пока свой отбой или remote-полёт ещё на overlay.
bool durakTableDefenseHiddenDuringFlight({
  required bool localDefendLock,
  required bool remoteDefenseFlying,
}) =>
    localDefendLock || remoteDefenseFlying;

/// Пока overlay летит, слот opacity 0 — лицо ведёт полёт.
double durakTableSlotOpacity({required bool inFlight}) => inFlight ? 0 : 1;

/// Pending — якорь посадки даже после WS: серверную пару прячем до конца fly.
bool durakNeedsPendingAttackSlot({required bool attackAlreadyOnTable}) {
  return attackAlreadyOnTable || !attackAlreadyOnTable;
}
