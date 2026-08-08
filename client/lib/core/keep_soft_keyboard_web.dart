import 'dart:js_interop';
import 'dart:ui' show Rect;

import 'package:web/web.dart' as web;

/// Зоны (в CSS-пикселях viewport), тап по которым не должен снимать
/// фокус с поля ввода / сворачивать soft-keyboard на iOS WebKit.
List<Rect> _rects = const [];
bool _installed = false;

void installKeepSoftKeyboardGuard() {
  if (_installed) return;
  _installed = true;

  void onPointer(web.Event event) {
    if (_rects.isEmpty) return;
    final point = _eventClientPoint(event);
    if (point == null) return;
    final x = point.$1;
    final y = point.$2;
    for (final r in _rects) {
      if (x >= r.left && x <= r.right && y >= r.top && y <= r.bottom) {
        // Без preventDefault WebKit blur'ит <input> до Flutter onPressed —
        // клавиатура падает и потом снова выезжает при requestFocus.
        event.preventDefault();
        return;
      }
    }
  }

  final jsHandler = onPointer.toJS;
  // capture: раньше blur'а у focused input.
  web.document.addEventListener('mousedown', jsHandler, true.toJS);
  web.document.addEventListener('touchstart', jsHandler, true.toJS);
}

void setKeepSoftKeyboardRects(List<Rect> rects) {
  _rects = List<Rect>.from(rects);
}

void clearKeepSoftKeyboardRects() {
  _rects = const [];
}

(double, double)? _eventClientPoint(web.Event event) {
  final type = event.type;
  if (type == 'mousedown') {
    final e = event as web.MouseEvent;
    return (e.clientX.toDouble(), e.clientY.toDouble());
  }
  if (type == 'touchstart') {
    final e = event as web.TouchEvent;
    if (e.touches.length < 1) return null;
    final t = e.touches.item(0);
    if (t == null) return null;
    return (t.clientX.toDouble(), t.clientY.toDouble());
  }
  return null;
}
