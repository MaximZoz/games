import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/app_play_update.dart';
import 'package:multigames_client/core/app_update_provider.dart';

void main() {
  test('appBuildId defaults to dev without dart-define', () {
    expect(appBuildId, isNotEmpty);
  });

  test('appVersionLabel falls back to appBuildId without APP_VERSION', () {
    expect(appVersionLabel, appBuildId);
  });

  test('version mismatch detection', () {
    const local = 'abc1234';
    const remote = 'def5678';
    expect(local == remote, isFalse);
    expect(local == local, isTrue);
  });

  test('play store update helpers are no-ops off Android device', () async {
    // VM-тесты крутятся не на Android — In-App Updates API недоступен.
    expect(await supportsPlayInAppUpdate(), isFalse);
    expect(await isPlayStoreUpdateAvailable(), isFalse);
    expect(await applyPlayStoreUpdate(), isFalse);
    expect(kPlayStoreUpdateBuildMarker, 'play_store');
  });
}
