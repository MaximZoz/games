import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS prod/dev flavors match Android applicationId', () {
    final prod = File('ios/Flutter/prod.xcconfig').readAsStringSync();
    final dev = File('ios/Flutter/dev.xcconfig').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(prod, contains('PRODUCT_BUNDLE_IDENTIFIER=com.zozugames.app\n'));
    expect(prod, contains('APP_DISPLAY_NAME=Zozu Games\n'));
    expect(prod, isNot(contains('com.zozugames.app.dev')));
    expect(dev, contains('PRODUCT_BUNDLE_IDENTIFIER=com.zozugames.app.dev\n'));
    expect(dev, contains('APP_DISPLAY_NAME=Zozu Games DEV\n'));

    expect(gradle, contains('applicationId = "com.zozugames.app"'));
    expect(gradle, contains('applicationId = "com.zozugames.app.dev"'));

    expect(info, contains('<string>\$(APP_DISPLAY_NAME)</string>'));
    expect(info, contains('<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>'));

    for (final name in [
      'Debug-prod',
      'Release-prod',
      'Profile-prod',
      'Debug-dev',
      'Release-dev',
      'Profile-dev',
    ]) {
      expect(podfile, contains("'$name'"), reason: 'Podfile must map $name');
      expect(pbx, contains('name = "$name"'),
          reason: 'pbxproj must define $name');
    }

    final prodScheme =
        File('ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme')
            .readAsStringSync();
    final devScheme =
        File('ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme')
            .readAsStringSync();
    expect(prodScheme, contains('buildConfiguration = "Debug-prod"'));
    expect(prodScheme, contains('buildConfiguration = "Release-prod"'));
    expect(prodScheme, contains('buildConfiguration = "Profile-prod"'));
    expect(devScheme, contains('buildConfiguration = "Debug-dev"'));
    expect(devScheme, contains('buildConfiguration = "Release-dev"'));
    expect(devScheme, contains('buildConfiguration = "Profile-dev"'));

    // Flavor Runner configs inherit bundle id from xcconfig — do not hardcode it.
    expect(
      RegExp(
        r'A1B100141000000000000014 /\* Debug-dev \*/ = \{[\s\S]*?name = "Debug-dev";',
      ).firstMatch(pbx)!.group(0)!,
      isNot(contains('PRODUCT_BUNDLE_IDENTIFIER')),
    );
  });

  test('iOS TestFlight CI covers both flavors without a local Mac', () {
    final workflow =
        File('../.github/workflows/ios-testflight.yml').readAsStringSync();
    final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
    final info = File('ios/Runner/Info.plist').readAsStringSync();

    expect(workflow, contains('runs-on: macos-26'));
    expect(workflow, contains('branches: [main, develop]'));
    expect(workflow, isNot(contains('cursor/fix-lobby-search-size-27ec')));
    expect(workflow, contains("'.github/workflows/ios-testflight.yml'"));
    expect(workflow, isNot(contains('!client/')));
    expect(workflow, contains('com.zozugames.app.dev'));
    expect(workflow, contains('com.zozugames.app'));
    expect(workflow, contains('https://multigameszozu-dev.fly.dev'));
    expect(workflow, contains('https://multigameszozu.fly.dev'));
    for (final secret in [
      'APP_STORE_CONNECT_KEY_ID',
      'APP_STORE_CONNECT_ISSUER_ID',
      'APP_STORE_CONNECT_API_KEY',
      'APPLE_TEAM_ID',
      'MATCH_PASSWORD',
    ]) {
      expect(workflow, contains(secret),
          reason: 'workflow must require $secret');
    }
    expect(fastfile, contains('upload_to_testflight'));
    expect(fastfile, contains('lane :public_code'));
    expect(fastfile, contains('public_link_enabled'));
    expect(fastfile, contains('TESTFLIGHT_CODE'));
    expect(fastfile, contains('tf_models'));
    expect(fastfile, contains('tf_redeem_from'));
    expect(fastfile, contains('tf_asc'));
    expect(fastfile, contains('usesNonExemptEncryption'));
    expect(fastfile, contains('betaRecruitmentCriteria'));
    expect(fastfile, contains('betaBuildLocalizations'));
    expect(fastfile, contains('betaAppReviewSubmissions'));
    expect(fastfile, contains('TESTFLIGHT_CONTACT_PHONE'));
    expect(fastfile, contains('tf_ensure_internal_group'));
    expect(fastfile, contains('tf_invite_asc_users'));
    expect(fastfile, contains('is_internal_group: true'));
    expect(fastfile, contains('sign_in_with_apple'));
    expect(fastfile, contains('tf_ensure_sign_in_with_apple'));
    expect(fastfile, contains('APPLE_ID_AUTH'));
    expect(fastfile, contains('com.apple.developer.applesignin'));
    expect(fastfile, contains('UserData/Provisioning Profiles'));
    expect(fastfile, contains('appstore_profile-path'));
    expect(fastfile, contains('match('));
    expect(fastfile, isNot(contains('produce(')));
    expect(fastfile, contains('Spaceship::ConnectAPI::App.find'));
    expect(fastfile, isNot(contains('App.create')));
    expect(fastfile, contains('does not allow \'CREATE\''));
    expect(fastfile, contains('tf_ensure_asc_app'));
    expect(fastfile, contains('want_readonly'));
    expect(fastfile, contains('ENV.delete("APP_STORE_CONNECT_API_KEY_PATH")'));
    expect(fastfile, contains('flutter", "build", "ipa"'));
    expect(fastfile, contains('File.expand_path("../..", __dir__)'));
    expect(fastfile, isNot(contains('"--"')),
        reason: 'flutter build ipa treats -- args as a target file');
    expect(info, contains('ITSAppUsesNonExemptEncryption'));
    expect(workflow, contains('BUILD_NAME="0.1.0"'));
    expect(workflow, contains('Select Xcode 26'));
    expect(workflow, contains('Xcode_26'));
    expect(workflow, contains('fastlane ios public_code'));
    expect(workflow, contains('Нет ветки match-certs'));
    expect(fastfile, contains('maximum number of available Distribution certificates'));
    expect(workflow, contains('runs-on: ubuntu-latest'));
    expect(workflow, contains('code_only:'));
    expect(File('../.github/workflows/ios-testflight-code.yml').existsSync(),
        isFalse);
    final appFw = File('ios/Flutter/AppFrameworkInfo.plist').readAsStringSync();
    expect(appFw, contains('<key>MinimumOSVersion</key>'));
    expect(appFw, contains('<string>15.0</string>'));
    expect(File('ios/Podfile').readAsStringSync(),
        contains("platform :ios, '15.0'"));
    expect(
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
      isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0')),
    );
  });

  test('iOS delegates compile on Flutter 3.27', () {
    final app = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final scene = File('ios/Runner/SceneDelegate.swift').readAsStringSync();
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
    expect(app, contains('GeneratedPluginRegistrant.register'));
    expect(app, contains('SharedPreferencesPlugin'));
    expect(app, contains('com.zozugames/session_store'));
    expect(app, contains('let messenger = controller.binaryMessenger'));
    expect(app, contains('com.zozugames/push'));
    expect(app, contains('setAPNSToken'));
    expect(app, contains('ZozuPush.capture'));
    expect(app, contains('takeTap'));
    expect(app, contains('notificationTap'));
    expect(app, contains('clearDelivered'));
    expect(app, contains('setBadgeCount'));
    expect(app, contains('applicationIconBadgeNumber'));
    expect(app, contains('didReceive response'));
    expect(scene, contains('ZozuPush.rememberResponse'));
    expect(scene, contains('scheduleTapReplay'));
    expect(app, contains('claimNotificationDelegate'));
    expect(app, contains('threadIdentifier'));
    expect(app, contains('tapReady'));
    expect(app, contains('deliverPendingTap'));
    expect(app, contains('"game_type"'));
    expect(app, contains('"lobby_id"'));
    expect(scene, contains('pendingOpenURLs'));
    expect(scene, contains('NSUserActivityTypeBrowsingWeb'));
    expect(app, isNot(contains('binaryMessenger else')));
    expect(app, contains('ZozuFlutterViewController'));
    expect(app, contains('com.zozugames/apple_sign_in'));
    expect(app, contains('ASAuthorizationAppleIDProvider'));
    expect(app, contains('ZozuAppleSignIn'));
    expect(app, contains('isKeyWindow'));
    expect(app, isNot(contains('registrar.viewController')));
    expect(app, isNot(contains('FlutterImplicitEngine')));
    expect(scene, contains('UIWindowSceneDelegate'));
    expect(scene, isNot(contains('FlutterSceneDelegate')));
    expect(scene, contains('openURLContexts'));
    expect(
      File('ios/Runner/Base.lproj/Main.storyboard').readAsStringSync(),
      contains('ZozuFlutterViewController'),
    );
    expect(scene, contains('FlutterAppDelegate'));

    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(entitlements, contains('com.apple.developer.applesignin'));
    expect(entitlements, contains('aps-environment'));
    expect(entitlements, contains('com.apple.developer.associated-domains'));
    expect(entitlements, contains('applinks:zozugames.com'));
    expect(plist, contains('FlutterDeepLinkingEnabled'));
    expect(fastfile, contains('tf_ensure_associated_domains'));
    expect(fastfile, contains('ASSOCIATED_DOMAINS'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));
    expect(plist, contains('remote-notification'));
    expect(fastfile, contains('tf_ensure_push_notifications'));
    expect(fastfile, contains('PUSH_NOTIFICATIONS'));
    expect(
        pbx, contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements'));
    expect(fastfile, contains('sign_in_with_apple'));
    expect(fastfile, contains('tf_ensure_sign_in_with_apple'));
    expect(fastfile, contains('APPLE_ID_AUTH'));
    expect(fastfile, contains('com.apple.developer.applesignin'));
    expect(fastfile, contains('UserData/Provisioning Profiles'));
    expect(fastfile, contains('appstore_profile-path'));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('sign_in_with_apple:')),
    );
    expect(
      File('lib/auth/apple_native_sign_in_io.dart').readAsStringSync(),
      contains('com.zozugames/apple_sign_in'),
    );
  });
}
