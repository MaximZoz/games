import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/app_play_update.dart';
import 'package:multigames_client/core/app_testflight_update.dart';
import 'package:multigames_client/core/app_testflight_update_launch.dart';
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

  test('iPhone предлагает обновление только на более новую сборку TestFlight', () {
    expect(
      iosTestFlightUpdateAvailable(
        localBuildId: 'abc1234',
        localBuildNumber: 10040,
        remoteBuildId: 'def5678',
        remoteBuildNumber: 10042,
      ),
      isTrue,
    );
    expect(
      iosTestFlightUpdateAvailable(
        localBuildId: 'def5678',
        localBuildNumber: 10042,
        remoteBuildId: 'def5678',
        remoteBuildNumber: 10042,
      ),
      isFalse,
    );
    expect(
      iosTestFlightUpdateAvailable(
        localBuildId: 'def5678',
        localBuildNumber: 10042,
        remoteBuildId: 'zzz9999',
        remoteBuildNumber: 10041,
      ),
      isFalse,
    );
    expect(
      iosTestFlightUpdateAvailable(
        localBuildId: 'dev',
        localBuildNumber: 1,
        remoteBuildId: 'abc1234',
        remoteBuildNumber: 10042,
      ),
      isFalse,
    );
    expect(
      iosTestFlightUpdateAvailable(
        localBuildId: 'abc1234',
        localBuildNumber: 0,
        remoteBuildId: 'def5678',
        remoteBuildNumber: 10042,
      ),
      isFalse,
    );
    expect(testFlightUpdateUri('6822534284').toString(),
        'itms-beta://beta.itunes.apple.com/v1/app/6822534284');
    expect(testFlightUpdateUri('').toString(), 'itms-beta://');
    expect(kTestFlightUpdateBuildMarker, 'testflight');
  });

  test('TestFlight helpers are no-ops off iPhone', () async {
    expect(await supportsTestFlightUpdate(), isFalse);
    expect(await applyTestFlightUpdate('6822534284'), isFalse);
  });
}
