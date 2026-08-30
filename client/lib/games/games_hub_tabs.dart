/// Анимация TabBarView «Игры ↔ Лобби» — короче дефолтных 300 мс Flutter.
const Duration gamesLobbyTabAnimation = Duration(milliseconds: 150);

/// Вкладка хаба по позиции анимации (0 = игры, 1 = лобби).
///
/// Во время свайпа [TabController.index] ещё старый, пока страница не
/// доедет. Берём [animation.value], чтобы переключатель не ждал конца.
int gamesLobbyTabIndexForAnimation(double value) => value >= 0.5 ? 1 : 0;
