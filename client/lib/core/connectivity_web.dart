import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Текущее состояние сети в браузере.
bool readDeviceOnline() => web.window.navigator.onLine;

/// События online/offline браузера.
Stream<bool> deviceOnlineStream() {
  final controller = StreamController<bool>.broadcast();

  void onOnline(web.Event _) {
    if (!controller.isClosed) controller.add(true);
  }

  void onOffline(web.Event _) {
    if (!controller.isClosed) controller.add(false);
  }

  final onlineJs = onOnline.toJS;
  final offlineJs = onOffline.toJS;
  web.window.addEventListener('online', onlineJs);
  web.window.addEventListener('offline', offlineJs);
  controller.onCancel = () {
    web.window.removeEventListener('online', onlineJs);
    web.window.removeEventListener('offline', offlineJs);
  };
  return controller.stream;
}
