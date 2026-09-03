import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Открыть экранную клавиатуру для уже смонтированного поля.
///
/// Браузер (и особенно iOS WebKit) показывает IME только если фокус пришёл
/// из жеста пользователя. Поэтому фокус запрашивается сразу в обработчике
/// тапа, а не в post-frame колбэке, и следом идёт `TextInput.show` — иначе
/// поле «открыто», а клавиатуры нет.
void openSoftKeyboard(FocusNode node) {
  if (!node.hasFocus) node.requestFocus();
  // Фокус применяется в микротаске, и только после этого поле подключает
  // текстовый клиент. `TextInput.show` до подключения — пустой вызов,
  // поэтому просим клавиатуру следующей микротаской: тот же жест, но уже
  // с готовым клиентом.
  scheduleMicrotask(requestSoftKeyboard);
}

/// Попросить платформу показать клавиатуру для текущего текстового клиента.
void requestSoftKeyboard() {
  try {
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  } catch (_) {
    // Нет подключённого клиента — покажется при фокусе поля.
  }
}
