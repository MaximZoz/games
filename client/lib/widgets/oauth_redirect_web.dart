import 'package:web/web.dart' as web;

const _popupName = 'mg_oauth';

/// Хэндл окна, открытого синхронно в user-gesture (критично для iOS).
class OAuthWindowHandle {
  OAuthWindowHandle(this._window);
  final web.Window? _window;
}

/// Открыть пустое окно сразу по тапу (до await сети).
OAuthWindowHandle? openOAuthWindowBlank() {
  final win = web.window.open('about:blank', _popupName, 'popup=yes,width=480,height=720');
  if (win == null) return null;
  return OAuthWindowHandle(win);
}

void navigateOAuthWindow(OAuthWindowHandle? handle, String url) {
  final win = handle?._window;
  if (win != null) {
    try {
      win.location.href = url;
      return;
    } catch (_) {}
  }
  final opened = web.window.open(url, _popupName, 'popup=yes,width=480,height=720');
  if (opened == null) {
    web.window.location.assign(url);
  }
}

void closeOAuthWindow(OAuthWindowHandle? handle) {
  try {
    handle?._window?.close();
  } catch (_) {}
}
