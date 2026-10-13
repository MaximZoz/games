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
}
