import 'package:multigames_client/core/gamepad/gamepad_action.dart';

/// Попап перехватывает стик: вкладки игр/лобби не листаем.
bool gamesGamepadAllowsHubScroll({
  required bool popupOpen,
  required bool exclusive,
  bool routeCovered = false,
}) {
  return !popupOpen && !exclusive && !routeCovered;
}

/// Влево/вправо правого стика — вкладки «Игры» / «Лобби».
bool gamesHubScrollSwitchesTab(GamepadAction action) {
  return action == GamepadAction.scrollLeft ||
      action == GamepadAction.scrollRight;
}

/// Вверх/вниз правого стика — страница карточек.
bool gamesHubScrollPagesCards(GamepadAction action) {
  return action == GamepadAction.scrollUp ||
      action == GamepadAction.scrollDown;
}

/// Правый стик: предыдущая / следующая вкладка хаба.
int gamesHubTabIndexAfterScroll({
  required int index,
  required int length,
  required GamepadAction action,
}) {
  if (length <= 0) return 0;
  if (length == 1) return 0;
  if (action == GamepadAction.scrollLeft) {
    return (index - 1 + length) % length;
  }
  if (action == GamepadAction.scrollRight) {
    return (index + 1) % length;
  }
  return index.clamp(0, length - 1);
}
