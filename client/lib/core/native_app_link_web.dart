import 'package:multigames_client/core/native_app_link.dart';
import 'package:web/web.dart' as web;

String browserUserAgent() => web.window.navigator.userAgent;

bool browserIsStandalone() {
  // iOS PWA: apple-mobile-web-app-capable → display-mode standalone.
  if (web.window.matchMedia('(display-mode: standalone)').matches) {
    return true;
  }
  return web.window.matchMedia('(display-mode: fullscreen)').matches;
}

bool nativeAppBannerDismissed() =>
    web.window.sessionStorage.getItem(nativeAppBannerDismissedKey) == '1';

void dismissNativeAppBanner() {
  web.window.sessionStorage.setItem(nativeAppBannerDismissedKey, '1');
}

void openNativeAppHandoff(NativeAppHandoff handoff) {
  web.window.location.href = handoff.launchUri;
}
