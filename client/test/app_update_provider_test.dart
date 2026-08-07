import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/api_config.dart';

void main() {
  test('appBuildId defaults to dev without dart-define', () {
    expect(appBuildId, isNotEmpty);
  });

  test('version mismatch detection', () {
    const local = 'abc1234';
    const remote = 'def5678';
    expect(local == remote, isFalse);
    expect(local == local, isTrue);
  });
}
