// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// При скрытии вкладки на hiddenTimeout отключает realtime (для корректного offline).
/// При возврате во вкладку — вызывает onVisible (чтобы переподключиться).
void Function()? setupRealtimeVisibilityDisconnect({
  required Duration hiddenTimeout,
  required void Function() onHiddenTimeout,
  required void Function() onVisible,
}) {
  Timer? timer;

  void handleVisibilityChange([_]) {
    if (html.document.visibilityState == 'visible') {
      timer?.cancel();
      timer = null;
      onVisible();
    } else {
      timer?.cancel();
      timer = Timer(hiddenTimeout, () {
        timer = null;
        onHiddenTimeout();
      });
    }
  }

  html.document.addEventListener('visibilitychange', handleVisibilityChange);

  return () {
    timer?.cancel();
    html.document.removeEventListener('visibilitychange', handleVisibilityChange);
  };
}
