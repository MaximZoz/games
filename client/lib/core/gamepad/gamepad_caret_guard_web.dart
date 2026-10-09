import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool _blocks = false;
bool _installed = false;

/// На web каретка живёт в скрытом `<input>`: preventDefault в capture,
/// иначе браузер сдвигает курсор стрелками левого стика.
void installGamepadCaretGuard() {
  if (_installed) return;
  _installed = true;
  void onKey(web.Event event) {
    if (!_blocks) return;
    final key = (event as web.KeyboardEvent).key;
    if (key != 'ArrowLeft' &&
        key != 'ArrowRight' &&
        key != 'ArrowUp' &&
        key != 'ArrowDown') {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
  }

  final jsHandler = onKey.toJS;
  web.document.addEventListener('keydown', jsHandler, true.toJS);
  web.document.addEventListener('keyup', jsHandler, true.toJS);
}

void setGamepadKeyboardBlocksTextArrows(bool blocks) {
  _blocks = blocks;
  if (blocks) installGamepadCaretGuard();
}
