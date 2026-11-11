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

/// Карта уже лежит на столе — не прятать как «новый remote».
bool durakTableCardAlreadyVisible({
  required bool seated,
  required bool existedOnKnownTable,
  bool alreadyShown = false,
}) =>
    seated || existedOnKnownTable || alreadyShown;

/// Новую чужую атаку прячем, пока busy/replay не успели запустить полёт.
bool durakHideDeferredRemoteAttack({
  required bool existedOnPrevTable,
  required bool optimistic,
  required bool localFlying,
  required bool fxDeferred,
  bool seated = false,
  bool alreadyShown = false,
  bool locallyCommitted = false,
}) {
  if (locallyCommitted ||
      optimistic ||
      localFlying ||
      durakTableCardAlreadyVisible(
        seated: seated,
        existedOnKnownTable: existedOnPrevTable,
        alreadyShown: alreadyShown,
      )) {
    return false;
  }
  return fxDeferred;
}

/// Пустой кадр сервера не сбрасывает seated, пока свой ход ещё на столе.
bool durakShouldClearSeatedOnEmptyTable({
  required bool hidingTable,
  required bool takeHold,
  required bool localPlayActive,
}) =>
    !hidingTable && !takeHold && !localPlayActive;

/// В prev оставляем севшую карту, даже если id ещё в remote-наборе.
bool durakKeepVisibleCardInPrevTable({
  required bool remoteFlying,
  required bool seated,
  bool alreadyShown = false,
}) =>
    seated || alreadyShown || !remoteFlying;

/// После hide/schedule сажаем всё, что уже не летит — иначе следующий
/// кадр снова пометит карту remote и погасит слот в 0.
bool durakSeatUnhiddenTableCard({
  required bool remoteFlying,
  required bool localFlying,
}) =>
    !remoteFlying && !localFlying;

/// Показанную карту не выкидываем из памяти, пока она ещё своя или на столе.
bool durakKeepShownTableId({
  required bool onLiveTable,
  required bool localAttack,
  required bool optimisticDefense,
}) =>
    onLiveTable || localAttack || optimisticDefense;

/// Remote-id не должен прятать уже севшую / свою / летящую локально карту.
bool durakShouldHideRemoteTableCard({
  required bool markedRemoteFlying,
  required bool seated,
  required bool optimistic,
  required bool localFlying,
  bool alreadyShown = false,
}) {
  if (!markedRemoteFlying) return false;
  if (seated || optimistic || localFlying || alreadyShown) return false;
  return true;
}

/// Карту из prev не сажаем, пока она в remote-полёте.
///
/// Иначе слот получает opacity 1, overlay ещё летит — вспышка на столе
/// (подкид «появился, потом полетел»; карта мигает при переводе).
bool durakShouldSeatPrevTableCard({
  required bool remoteFlying,
  bool alreadyShown = false,
}) =>
    alreadyShown || !remoteFlying;

/// Чужой полёт только для новой карты. Уже лежавшую при своём переводе
/// не переигрываем — иначе слот гаснет и карта «пропадает, потом появляется».
bool durakShouldScheduleRemoteTableFlight({
  required bool existedOnPrevTable,
  required bool seated,
  required bool optimistic,
  required bool localFlying,
  bool alreadyShown = false,
  bool locallyCommitted = false,
}) {
  if (locallyCommitted ||
      optimistic ||
      localFlying ||
      seated ||
      alreadyShown ||
      existedOnPrevTable) {
    return false;
  }
  return true;
}

/// FX стола ждём только на свой ход / overlay.
///
/// Карта, вытянутая из веера, сюда не входит: иначе чужой подкид/перевод
/// не виден, пока игрок держит карту.
bool durakTableFxDeferred({
  required bool fxScheduled,
  required bool busy,
  required bool localAttackHold,
  required bool cardFlightActive,
}) =>
    fxScheduled || busy || localAttackHold || cardFlightActive;

/// Подсказку перевода/атаки не кладём в ряд пар.
///
/// Иначе 2 карты + слот = 3 ячейки, на drop слот на кадр пропадает —
/// лежащие карты едут влево-вправо, а при переводе ещё и моргают.
bool durakDropHintOccupiesPairSlot() => false;

/// Скрытую на время busy карту пора снова показать: она уже своя или сидит.
///
/// Не смотрим «уже была в prev»: после своего хода prev могут обновить
/// вместе с чужим подкидом, и тогда карта вспыхнет без полёта.
bool durakShouldRevealDeferredRemoteCard({
  required bool hiddenAsRemote,
  required bool seated,
  required bool optimistic,
  required bool localFlying,
  bool alreadyShown = false,
}) {
  if (!hiddenAsRemote) return false;
  return seated || optimistic || localFlying || alreadyShown;
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
/// [keepVisible] — севшая/своя пара: не выкидывать из дерева, даже если
/// флаг seated на кадр сбросился (перевод иначе моргает лежащую карту).
bool durakSeatedTablePairInLayout({
  required bool seated,
  bool reserveForFlight = false,
  bool keepVisible = false,
}) =>
    seated || reserveForFlight || keepVisible;

/// Сдвиг уже лежащих пар в финальную сетку — один твин, без второго рывка.
const Duration kDurakTablePairSlideDuration = Duration(milliseconds: 180);

/// Зазор в ряду: если пары не влезают, наезжают, без scale.
double durakTableEffectiveGap({
  required Size cardSize,
  required int rowLen,
  required double maxWidth,
  double gap = 10,
}) {
  if (rowLen <= 1) return gap;
  final pairW = durakTablePairSlotWidth(cardSize);
  final neededW = rowLen * pairW + (rowLen - 1) * gap;
  if (neededW <= maxWidth) return gap;
  return ((maxWidth - rowLen * pairW) / (rowLen - 1))
      .clamp(-(pairW * 0.55), gap);
}

/// Локальный origin слота пары в финальной сетке (как посадка overlay).
Offset durakTablePairSlotOrigin({
  required double maxWidth,
  required Size cardSize,
  required int pairIndex,
  required int pairCount,
  required bool compact,
  int cols = 2,
  double gap = 10,
}) {
  final n = pairCount < 1 ? 1 : pairCount;
  final rows = (n + cols - 1) ~/ cols;
  final stackH = durakTableStackHeight(cardSize, rows, compact: compact);
  final card = durakEstimateAttackLandRect(
    tableCenter: Offset(maxWidth / 2, stackH / 2),
    cardSize: cardSize,
    pairIndex: pairIndex,
    pairCount: n,
    compact: compact,
    cols: cols,
    gap: gap,
    maxWidth: maxWidth,
  );
  return Offset(card.left - 4, card.top);
}

/// Финальный rect атаки в сетке стола — тот же расчёт, что у рядов.
Rect durakEstimateAttackLandRect({
  required Offset tableCenter,
  required Size cardSize,
  required int pairIndex,
  required int pairCount,
  required bool compact,
  int cols = 2,
  double gap = 10,
  double? maxWidth,
}) {
  final n = pairCount < 1 ? 1 : pairCount;
  final idx = pairIndex < 0 ? 0 : (pairIndex > n - 1 ? n - 1 : pairIndex);
  final pairW = durakTablePairSlotWidth(cardSize);
  final col = idx % cols;
  final row = idx ~/ cols;
  final rowLen =
      (row * cols + cols <= n) ? cols : (n - row * cols).clamp(1, cols);
  final usedGap = maxWidth == null
      ? gap
      : durakTableEffectiveGap(
          cardSize: cardSize,
          rowLen: rowLen,
          maxWidth: maxWidth,
          gap: gap,
        );
  final rowWidth = rowLen * pairW + (rowLen - 1) * usedGap;
  final rowLeft = tableCenter.dx - rowWidth / 2;
  final pairLeft = rowLeft + col * (pairW + usedGap);
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

/// Слот пустой, только пока overlay летит и карта ещё не села.
///
/// Не seated и не inFlight — всё равно показать: иначе перевод на кадр
/// выкидывает лежащую карту из дерева (моргание).
bool durakTableSlotBlankUntilLand({
  required bool seated,
  required bool inFlight,
}) =>
    inFlight && !seated;

/// Opacity слота: прячем только летящую ещё не севшую карту.
double durakSeatedTableSlotOpacity({
  required bool seated,
  required bool inFlight,
}) =>
    durakTableSlotBlankUntilLand(seated: seated, inFlight: inFlight) ? 0 : 1;

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

/// Подтверждённый подкид сажаем только после полёта.
///
/// Офлайн обновляет стол сразу, пока overlay ещё в воздухе. Если сесть
/// раньше, слот перестаёт быть пустым и карта видна дважды.
bool durakSeatConfirmedAttack({
  required bool onTable,
  required bool stillFlying,
}) =>
    onTable && !stillFlying;

/// Свой подкид ещё не сел: не запускать чужой FX и не перерисовывать ход.
bool durakHoldTableFxForLocalAttack({
  required bool optimisticAttack,
  required bool flyingToTable,
}) =>
    optimisticAttack || flyingToTable;
