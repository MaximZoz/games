/// Высота перекрытия виртуальной клавиатуры в браузере (px). На non-web всегда 0.
double readBrowserKeyboardInset() => 0;

/// Подписка на изменение inset. На non-web — no-op, возвращает null.
void Function()? listenBrowserKeyboardInset(void Function(double inset) onChanged) {
  return null;
}

/// Сброс scroll окна (iOS Safari двигает страницу к focused input).
void resetBrowserScrollForKeyboard() {}
