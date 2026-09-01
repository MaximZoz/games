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
