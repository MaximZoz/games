// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Настраивает Telegram Mini App: expand + disableVerticalSwipes.
///
/// Без этого вертикальный скролл списков (чаты/друзья) часто перехватывается
/// оболочкой Telegram и сворачивает bottom sheet вместо прокрутки контента.
void configureTelegramWebApp() {
  try {
    final telegram = js.context['Telegram'];
    if (telegram == null) return;
    final webApp = telegram['WebApp'];
    if (webApp == null) return;

    if (webApp.hasProperty('ready')) {
      webApp.callMethod('ready');
    }
    if (webApp.hasProperty('expand')) {
      webApp.callMethod('expand');
    }
    if (webApp.hasProperty('disableVerticalSwipes')) {
      webApp.callMethod('disableVerticalSwipes');
    }
  } catch (_) {
    // Вне Telegram WebView или на старых клиентах — игнорируем.
  }
}
