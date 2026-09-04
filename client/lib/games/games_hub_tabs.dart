/// Анимация TabBarView «Игры ↔ Лобби» — короче дефолтных 300 мс Flutter.
const Duration gamesLobbyTabAnimation = Duration(milliseconds: 150);

/// Колонки карточек хаба: на телефоне всегда одна, иначе кнопки сжимаются.
int gamesHubTileColumns({
  required double maxWidth,
  required bool wide,
}) {
  if (!wide) return 1;
  const gap = 16.0;
  const minTile = 260.0;
  if (maxWidth < minTile * 2 + gap) return 1;
  return (maxWidth / (minTile + gap)).floor().clamp(1, 3);
}

/// Ширина карточки: одна колонка занимает всю доступную ширину.
double gamesHubTileWidth({
  required double maxWidth,
  required int cols,
}) {
  const gap = 16.0;
  if (cols <= 1) return maxWidth;
  return ((maxWidth - gap * (cols - 1)) / cols).clamp(260.0, 400.0);
}

/// Компактные отступы карточки, если она узкая.
/// Кнопки «Создать» / «Найти» всегда в один ряд.
bool gamesHubStackActions(double cardWidth) => cardWidth < 360;

/// Вкладка хаба по позиции анимации (0 = игры, 1 = лобби).
///
/// Во время свайпа [TabController.index] ещё старый, пока страница не
/// доедет. Берём [animation.value], чтобы переключатель не ждал конца.
int gamesLobbyTabIndexForAnimation(double value) => value >= 0.5 ? 1 : 0;
