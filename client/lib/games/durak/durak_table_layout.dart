import 'dart:math' as math;
import 'dart:ui';

/// Геометрия рядов пар на столе дурака.
///
/// Вынесена из экрана, потому что одни и те же числа нужны и вёрстке стола,
/// и расчёту точки посадки летящей карты: разойдутся — карта сядет мимо.

/// Смещение защиты относительно атаки на столе.
const Offset kDurakDefendOffset = Offset(10, 14);

/// Ширина слота пары: SizedBox(w+18) + горизонтальный padding 4+4.
///
/// Одна и та же цифра нужна и рядам стола, и точке посадки полёта —
/// иначе карта садится «рядом», потом слот появляется и лицо прыгает.
double durakTablePairSlotWidth(Size cardSize) => cardSize.width + 26;

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
  bool seated = false,
}) {
  if (optimistic || localFlying || existedOnPrevTable || seated) return false;
  return fxDeferred;
}

/// Remote-id не должен прятать уже севшую / свою / летящую локально карту.
bool durakShouldHideRemoteTableCard({
  required bool markedRemoteFlying,
  required bool seated,
  required bool optimistic,
  required bool localFlying,
}) {
  if (!markedRemoteFlying) return false;
  if (seated || optimistic || localFlying) return false;
  return true;
}

/// Карту из prev не сажаем, пока она в remote-полёте.
///
/// Иначе слот получает opacity 1, overlay ещё летит — вспышка на столе
/// (подкид «появился, потом полетел»; карта мигает при переводе).
bool durakShouldSeatPrevTableCard({required bool remoteFlying}) =>
    !remoteFlying;

/// FX стола ждём: свой ход, overlay или карта вытянута из веера.
bool durakTableFxDeferred({
  required bool fxScheduled,
  required bool busy,
  required bool localAttackHold,
  required bool cardFlightActive,
  required bool holdingFanCard,
}) =>
    fxScheduled ||
    busy ||
    localAttackHold ||
    cardFlightActive ||
    holdingFanCard;

/// Скрытую на время busy карту пора снова показать: она уже своя или сидит.
///
/// Не смотрим «уже была в prev»: после своего хода prev могут обновить
/// вместе с чужим подкидом, и тогда карта вспыхнет без полёта.
bool durakShouldRevealDeferredRemoteCard({
  required bool hiddenAsRemote,
  required bool seated,
  required bool optimistic,
  required bool localFlying,
}) {
  if (!hiddenAsRemote) return false;
  return seated || optimistic || localFlying;
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

/// Карта, которая уже лежала на столе, не должна пропадать из вёрстки.
///
/// Новая атака (перевод, подкид) тоже занимает слот сразу — [reserveForFlight].
/// Иначе стол перестроится только после посадки, и карта прыгнет.
bool durakSeatedTablePairInLayout({
  required bool seated,
  bool reserveForFlight = false,
}) =>
    seated || reserveForFlight;

/// Финальный rect атаки в сетке стола — тот же расчёт, что у рядов.
Rect durakEstimateAttackLandRect({
  required Offset tableCenter,
  required Size cardSize,
  required int pairIndex,
  required int pairCount,
  required bool compact,
  int cols = 2,
  double gap = 10,
}) {
  final n = pairCount < 1 ? 1 : pairCount;
  final idx = pairIndex < 0 ? 0 : (pairIndex > n - 1 ? n - 1 : pairIndex);
  final pairW = durakTablePairSlotWidth(cardSize);
  final col = idx % cols;
  final row = idx ~/ cols;
  final rowLen =
      (row * cols + cols <= n) ? cols : (n - row * cols).clamp(1, cols);
  final rowWidth = rowLen * pairW + (rowLen - 1) * gap;
  final rowLeft = tableCenter.dx - rowWidth / 2;
  final pairLeft = rowLeft + col * (pairW + gap);
  final rows = (n + cols - 1) ~/ cols;
  final colH = durakTableStackHeight(cardSize, rows, compact: compact);
  final pairTop = tableCenter.dy -
      colH / 2 +
      durakTableRowTop(cardSize, row, rows, compact: compact);
  return Rect.fromLTWH(
    pairLeft + 4,
    pairTop,
    cardSize.width,
    cardSize.height,
  );
}

/// Цель отбоя: финальный оффсет защиты относительно атаки.
Rect durakEstimateDefenseLandRect(Rect attackRect) => Rect.fromLTWH(
      attackRect.left + kDurakDefendOffset.dx,
      attackRect.top + kDurakDefendOffset.dy,
      attackRect.width,
      attackRect.height,
    );

/// Opacity слота: севшая карта всегда видна, летящая — только в overlay.
double durakSeatedTableSlotOpacity({
  required bool seated,
  required bool inFlight,
}) {
  if (seated) return 1;
  return inFlight ? 0 : 0;
}

/// Защиту не рисуем, пока свой отбой или remote-полёт ещё на overlay.
bool durakTableDefenseHiddenDuringFlight({
  required bool localDefendLock,
  required bool remoteDefenseFlying,
}) =>
    localDefendLock || remoteDefenseFlying;

/// Пока overlay летит, слот opacity 0 — лицо ведёт полёт.
double durakTableSlotOpacity({required bool inFlight}) => inFlight ? 0 : 1;

/// Pending — якорь посадки, пока overlay летит. После посадки, если карта
/// уже на столе сервера, слот не дублируем — иначе вспышка при снятии optimistic.
bool durakNeedsPendingAttackSlot({
  required bool attackAlreadyOnTable,
  bool stillFlying = false,
}) {
  if (stillFlying) return true;
  return !attackAlreadyOnTable;
}

/// Свой подкид ещё не сел: не запускать чужой FX и не перерисовывать ход.
bool durakHoldTableFxForLocalAttack({
  required bool optimisticAttack,
  required bool flyingToTable,
}) =>
    optimisticAttack || flyingToTable;
