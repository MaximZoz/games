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
      expect(pbx, contains('name = "$name"'), reason: 'pbxproj must define $name');
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
    final workflow = File('../.github/workflows/ios-testflight.yml').readAsStringSync();
    final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
    final info = File('ios/Runner/Info.plist').readAsStringSync();

    expect(workflow, contains('runs-on: macos-26'));
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
      expect(workflow, contains(secret), reason: 'workflow must require $secret');
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
    expect(fastfile, contains('match('));
    expect(fastfile, contains('produce('));
    expect(fastfile, contains('Spaceship::ConnectAPI::App.find'));
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
    final codeWf =
        File('../.github/workflows/ios-testflight-code.yml').readAsStringSync();
    expect(codeWf, contains('fastlane ios public_code'));
    expect(codeWf, contains('runs-on: ubuntu-latest'));
    expect(codeWf, contains('com.zozugames.app.dev'));
    expect(codeWf, contains('TESTFLIGHT_CONTACT_PHONE'));
    final appFw = File('ios/Flutter/AppFrameworkInfo.plist').readAsStringSync();
    expect(appFw, contains('<key>MinimumOSVersion</key>'));
    expect(appFw, contains('<string>13.0</string>'));
  });

  test('iOS delegates compile on Flutter 3.27', () {
    final app = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final scene = File('ios/Runner/SceneDelegate.swift').readAsStringSync();
    expect(app, contains('GeneratedPluginRegistrant.register'));
    expect(app, isNot(contains('FlutterImplicitEngine')));
    expect(scene, contains('UIWindowSceneDelegate'));
    expect(scene, isNot(contains('FlutterSceneDelegate')));
  });
}
