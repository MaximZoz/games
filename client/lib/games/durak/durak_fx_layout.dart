/// Как показать итог партии дурака.
enum DurakFinishedChrome {
  /// Партия идёт — стол и веер на месте.
  playing,

  /// Портрет: статус и кнопки реванша столбиком над столом.
  stacked,

  /// Телефон в альбоме: статус и кнопки в ряд, веер и стол скрыты —
  /// иначе колонка съедает ~300 px высоты и остатки FX торчат по углам.
  landscapeRow,
}

DurakFinishedChrome durakFinishedChrome({
  required bool isOver,
  required bool phoneLandscape,
}) {
  if (!isOver) return DurakFinishedChrome.playing;
  if (phoneLandscape) return DurakFinishedChrome.landscapeRow;
  return DurakFinishedChrome.stacked;
}

/// В альбоме не гоняем 380 ms твины зоны веера: при смене размера они
/// тянут карты из старых слотов и накладываются на новый кадр.
Duration durakLayoutTweenDuration({required bool compact}) =>
    compact ? Duration.zero : const Duration(milliseconds: 380);

/// Низ кнопки «Бито»/«Взять» от низа стола. В альбоме — целиком над веером.
double durakActionButtonBottom({
  required bool compact,
  required double seatLift,
  required double fanCardH,
}) {
  if (!compact) return -seatLift + fanCardH + 10;
  // Запас больше высоты слота/свечения: иначе «Взять» садится на середину карт.
  return seatLift + fanCardH + 36;
}

/// Сколько высоты отдать столу под слот кнопки в альбоме.
double durakBoardBottomReserve({
  required bool compact,
  required double actionBtnBottom,
  required double actionSlotH,
  required double fanZoneH,
}) {
  if (!compact) return 0;
  final extra = actionBtnBottom + actionSlotH + 10 - fanZoneH;
  return extra < 0 ? 0.0 : extra;
}

/// В альбоме колода и бита не выглядывают за край — иначе обрезок и «призраки».
bool durakPilesPeekOffEdge({required bool compact}) => !compact;

/// Отступ колоды/биты от края доски.
double durakPileEdgeInset({required bool compact}) => compact ? 10.0 : 2.0;

/// Вернулись с другой вкладки на стол — снять застрявшие полёты.
bool shouldSnapDurakVisualOnResume({
  required String? previousPath,
  required String nextPath,
}) {
  final prev = previousPath?.trim() ?? '';
  if (prev.isEmpty) return false;
  if (_isDurakPlayPath(prev)) return false;
  return _isDurakPlayPath(nextPath);
}

/// Стол дурака сейчас на экране — иначе полёты no-op, а карты остаются скрытыми.
bool durakGameUiActive({
  required bool tickerEnabled,
  required String visiblePath,
  required String herePath,
}) {
  if (!tickerEnabled) return false;
  if (visiblePath.trim().isEmpty) return true;
  if (!_isDurakPlayPath(visiblePath)) return false;
  return _isDurakPlayPath(herePath);
}

/// Полёт/busy слишком долго — вёрстка «пропала», нужен snap к серверу.
bool durakVisualLooksStuck({
  required bool busy,
  required bool fxScheduled,
  required bool flightActive,
  required bool hidingTable,
}) =>
    busy || fxScheduled || flightActive || hidingTable;

/// В альбоме snap раньше: застрявший кадр сразу режет колоду и кнопку.
int durakStuckSnapTicks({required bool compact}) => compact ? 2 : 3;

bool _isDurakPlayPath(String path) {
  final clean = path.split('?').first;
  final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length < 3 || parts[0] != 'games') return false;
  if (parts[2] == 'offline') return true;
  return parts.length >= 4 && parts[2] == 'game';
}
