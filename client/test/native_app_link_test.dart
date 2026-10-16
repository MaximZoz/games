import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/native_app_link.dart';

const _android =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
const _androidWebView =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile Safari/537.36';
const _iphone =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

void main() {
  const lobby = 'https://zozugames.com/games/tictactoe/lobby/'
      '324b097b-65ba-43bd-9bef-58c86d91ea79?mode=invite';

  test('android handoff keeps lobby path and names the prod package', () {
    final handoff = nativeAppHandoffFor(
      page: Uri.parse(lobby),
      userAgent: _android,
    );
    expect(handoff, isNotNull);
    expect(handoff!.preferAndroidIntent, isTrue);
    expect(
      handoff.customUri,
      'zozugames://zozugames.com/games/tictactoe/lobby/'
      '324b097b-65ba-43bd-9bef-58c86d91ea79?mode=invite',
    );
    expect(handoff.androidIntentUri, contains('scheme=zozugames;'));
    expect(handoff.androidIntentUri, contains('package=com.zozugames.app;'));
    expect(
      handoff.androidIntentUri,
      contains('intent://zozugames.com/games/tictactoe/lobby/'),
    );
    expect(handoff.androidIntentUri, contains('S.browser_fallback_url='));
    expect(handoff.androidIntentUri, contains('web%3D1'));
    expect(handoff.customUri, isNot(contains('web=1')));
  });

  test('dev host uses the dev scheme and package', () {
    final handoff = nativeAppHandoffFor(
      page: Uri.parse(
        'https://multigameszozu-dev.fly.dev/games/durak/lobby/lob-1?mode=invite',
      ),
      userAgent: _android,
    );
    expect(handoff!.customUri,
        startsWith('zozugames-dev://zozugames.com/games/durak/lobby/lob-1'));
    expect(
        handoff.androidIntentUri, contains('package=com.zozugames.app.dev;'));
    expect(handoff.androidIntentUri, contains('scheme=zozugames-dev;'));
  });

  test('iphone uses the custom scheme and does not auto-open', () {
    final page = Uri.parse(lobby);
    final handoff = nativeAppHandoffFor(page: page, userAgent: _iphone);
    expect(handoff!.preferAndroidIntent, isFalse);
    expect(handoff.launchUri, handoff.customUri);
    expect(
      shouldAutoOpenNativeApp(
        page: page,
        userAgent: _iphone,
        standalone: false,
        alreadyAttempted: false,
      ),
      isFalse,
    );
  });

  test('android chrome auto-opens once, webview and desktop do not', () {
    final page = Uri.parse(lobby);
    expect(
      shouldAutoOpenNativeApp(
        page: page,
        userAgent: _android,
        standalone: false,
        alreadyAttempted: false,
      ),
      isTrue,
    );
    expect(
      shouldAutoOpenNativeApp(
        page: page,
        userAgent: _android,
        standalone: false,
        alreadyAttempted: true,
      ),
      isFalse,
    );
    expect(
      shouldAutoOpenNativeApp(
        page: page,
        userAgent: _android,
        standalone: true,
        alreadyAttempted: false,
      ),
      isFalse,
    );
    expect(
      shouldAutoOpenNativeApp(
        page: Uri.parse('$lobby&web=1'),
        userAgent: _android,
        standalone: false,
        alreadyAttempted: false,
      ),
      isFalse,
    );
    expect(
      shouldAutoOpenNativeApp(
        page: page,
        userAgent: _androidWebView,
        standalone: false,
        alreadyAttempted: false,
      ),
      isFalse,
    );
    expect(
      nativeAppHandoffFor(
        page: page,
        userAgent: 'Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0.0.0',
      ),
      isNull,
    );
  });

  test('browser login url keeps invite mode inside redirect', () {
    // go_router пишет redirect без кодирования второго «?».
    final page = Uri.parse(
      'http://127.0.0.1:7357/login?redirect=/games/tictactoe/lobby/abc?mode=invite',
    );
    expect(
      nativeAppHandoffFor(page: page, userAgent: _iphone)?.customUri,
      'zozugames-dev://zozugames.com/games/tictactoe/lobby/abc?mode=invite',
    );
  });

  test('login redirect still points at the lobby', () {
    final page = Uri.parse(
      'https://zozugames.com/login?redirect=${Uri.encodeComponent('/games/tictactoe/lobby/abc?mode=invite')}',
    );
    final target = nativeAppHandoffPage(page);
    expect(target?.path, '/games/tictactoe/lobby/abc');
    expect(target?.queryParameters['mode'], 'invite');
    expect(
      nativeAppHandoffFor(page: page, userAgent: _iphone)?.customUri,
      'zozugames://zozugames.com/games/tictactoe/lobby/abc?mode=invite',
    );
  });

  test('games catalog and oauth callback are not a lobby handoff', () {
    expect(
      nativeAppHandoffFor(
        page: Uri.parse('https://zozugames.com/games'),
        userAgent: _android,
      ),
      isNull,
    );
    expect(
        externalAppLinkRedirect(Uri.parse('zozugames://oauth-done')), isNull);
    expect(
      externalAppLinkRedirect(
        Uri.parse(
          '/games/tictactoe/lobby/abc?mode=invite',
        ),
      ),
      isNull,
    );
  });

  test('malformed custom-scheme path is rewritten to the lobby location', () {
    expect(
      externalAppLinkRedirect(
        Uri.parse(
          '/zozugames.com/games/tictactoe/lobby/abc?mode=invite',
        ),
      ),
      '/games/tictactoe/lobby/abc?mode=invite',
    );
  });

  test('index.html auto-open matches the dart handoff', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('zozu_native_attempt'));
    expect(html, contains('com.zozugames.app.dev'));
    expect(html, contains('com.zozugames.app'));
    expect(html, contains('zozugames-dev'));
    expect(html, contains("scheme=' + scheme"));
    expect(html, contains('browser_fallback_url'));
  });

  test('android and ios claim https game links', () {
    final main =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final prod =
        File('android/app/src/prod/AndroidManifest.xml').readAsStringSync();
    final dev =
        File('android/app/src/dev/AndroidManifest.xml').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();

    expect(main, contains('android:scheme="\${appUrlScheme}"'));
    expect(main, contains('flutter_deeplinking_enabled'));
    expect(main, contains('/games/.*/lobby/.*'));
    expect(prod, contains('android:host="zozugames.com"'));
    expect(prod, contains('android:host="www.zozugames.com"'));
    expect(prod, contains('android:autoVerify="true"'));
    expect(prod, isNot(contains('multigameszozu-dev')));
    expect(dev, contains('android:host="multigameszozu-dev.fly.dev"'));
    expect(dev, isNot(contains('android:host="zozugames.com"')));
    expect(
        gradle, contains('manifestPlaceholders["appUrlScheme"] = "zozugames"'));
    expect(gradle,
        contains('manifestPlaceholders["appUrlScheme"] = "zozugames-dev"'));
    expect(entitlements, contains('applinks:zozugames.com'));
    expect(entitlements, contains('applinks:www.zozugames.com'));
  });
}
