import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/games/framework/game_registry.dart';

/// Хост в custom scheme. Путь `/games/…` при этом остаётся path, и go_router
/// открывает то же лобби, что и https-ссылка.
const String nativeAppLinkHost = 'zozugames.com';

const String prodAndroidPackage = 'com.zozugames.app';
const String devAndroidPackage = 'com.zozugames.app.dev';

/// Один раз за вкладку: Android уже пробовал `intent://`, повтор не крутит страницу.
const String nativeAppAttemptStorageKey = 'zozu_native_attempt';

/// Пользователь закрыл полоску «Открыть в приложении».
const String nativeAppBannerDismissedKey = 'zozu_hide_open_in_app';

/// Параметр fallback-адреса, чтобы Chrome не зацикливал intent.
const String nativeAppStayOnWebParam = 'web';

final RegExp _deepGamePath = RegExp(r'^/games/([^/]+)/(lobby|game)/([^/]+)$');

bool isAndroidUserAgent(String userAgent) =>
    RegExp(r'Android', caseSensitive: false).hasMatch(userAgent);

bool isIosUserAgent(String userAgent) =>
    RegExp(r'iPhone|iPad|iPod', caseSensitive: false).hasMatch(userAgent);

/// In-app WebView (Telegram и похожие) часто не понимает `intent://`.
bool isAndroidWebViewUserAgent(String userAgent) =>
    RegExp(r';\s*wv\)', caseSensitive: false).hasMatch(userAgent);

String androidPackageForHost(String host) =>
    oauthAppReturnSchemeForHost(host) == 'zozugames-dev'
        ? devAndroidPackage
        : prodAndroidPackage;

/// `/games/{игра}/lobby|game/{id}` для зарегистрированной игры.
bool isDeepGamePath(String path) {
  var clean = path.split('?').first.trim();
  if (clean.length > 1 && clean.endsWith('/')) {
    clean = clean.substring(0, clean.length - 1);
  }
  final match = _deepGamePath.firstMatch(clean);
  if (match == null) return false;
  final game = gameRegistry[match.group(1)!];
  return game != null && !game.comingSoon;
}

/// Путь лобби/партии внутри строки, которую движок иногда отдаёт целиком.
String? embeddedDeepGamePath(String raw) {
  final match =
      RegExp(r'/games/[^/]+/(?:lobby|game)/[^/?#\s]+').firstMatch(raw);
  if (match == null) return null;
  final path = match.group(0)!;
  if (!isDeepGamePath(path)) return null;
  return path;
}

/// Если платформа прислала custom scheme криво, вернуть обычный location.
/// Уже нормальный `/games/…` не трогаем — иначе redirect зациклится.
String? externalAppLinkRedirect(Uri uri) {
  if (isDeepGamePath(uri.path)) return null;
  if (uri.host == 'oauth-done') return null;
  final path = embeddedDeepGamePath(uri.toString());
  if (path == null) return null;
  if (!uri.hasQuery) return path;
  return '$path?${uri.query}';
}

/// Страница, которую надо открыть в приложении: само лобби или `redirect` после входа.
Uri? nativeAppHandoffPage(Uri page) {
  final direct = _withoutStayParam(page);
  if (isDeepGamePath(direct.path)) return direct;
  final redirect = page.queryParameters['redirect'];
  if (redirect == null || redirect.trim().isEmpty) return null;
  final inner = Uri.tryParse(redirect.trim());
  if (inner == null || inner.hasScheme) return null;
  final target = _withoutStayParam(inner);
  if (!isDeepGamePath(target.path)) return null;
  return target;
}

Uri _withoutStayParam(Uri uri) {
  if (!uri.queryParameters.containsKey(nativeAppStayOnWebParam)) return uri;
  final query = Map<String, String>.from(uri.queryParameters)
    ..remove(nativeAppStayOnWebParam);
  return uri.replace(queryParameters: query);
}

class NativeAppHandoff {
  const NativeAppHandoff({
    required this.customUri,
    required this.androidIntentUri,
    required this.preferAndroidIntent,
  });

  /// `zozugames://zozugames.com/games/…` — схема уже есть в установленном iOS.
  final String customUri;

  /// Явный пакет. Если приложения нет, Chrome открывает [browserFallback].
  final String androidIntentUri;

  final bool preferAndroidIntent;

  String get launchUri => preferAndroidIntent ? androidIntentUri : customUri;
}

/// Ссылка, которой браузер телефона передаёт лобби в установленное приложение.
///
/// На десктопе `null`: сайт остаётся сайтом. Сам факт установки спрашивает ОС,
/// не страница.
NativeAppHandoff? nativeAppHandoffFor({
  required Uri page,
  required String userAgent,
}) {
  final target = nativeAppHandoffPage(page);
  if (target == null) return null;
  final android = isAndroidUserAgent(userAgent);
  final ios = isIosUserAgent(userAgent);
  if (!android && !ios) return null;

  final scheme = oauthAppReturnSchemeForHost(page.host);
  final packageName = androidPackageForHost(page.host);
  final path = target.path;
  final query = target.hasQuery ? '?${target.query}' : '';
  final customUri = '$scheme://$nativeAppLinkHost$path$query';
  final fallback = page.replace(queryParameters: {
    ...page.queryParameters,
    nativeAppStayOnWebParam: '1',
  });
  final intent = 'intent://$nativeAppLinkHost$path$query'
      '#Intent;scheme=$scheme;package=$packageName;'
      'S.browser_fallback_url=${Uri.encodeComponent(fallback.toString())};end';
  return NativeAppHandoff(
    customUri: customUri,
    androidIntentUri: intent,
    preferAndroidIntent: android,
  );
}

/// Android Chrome сам уходит в приложение. WebView и iPhone оставляют кнопку.
bool shouldAutoOpenNativeApp({
  required Uri page,
  required String userAgent,
  required bool standalone,
  required bool alreadyAttempted,
}) {
  if (standalone || alreadyAttempted) return false;
  if (page.queryParameters[nativeAppStayOnWebParam] == '1') return false;
  if (!isAndroidUserAgent(userAgent) || isAndroidWebViewUserAgent(userAgent)) {
    return false;
  }
  return nativeAppHandoffFor(page: page, userAgent: userAgent) != null;
}
