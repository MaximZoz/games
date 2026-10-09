export 'gamepad_caret_guard_stub.dart'
    if (dart.library.html) 'gamepad_caret_guard_web.dart'
    if (dart.library.js_interop) 'gamepad_caret_guard_web.dart';
