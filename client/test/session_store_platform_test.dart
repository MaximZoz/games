import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/session_storage_io.dart';

void main() {
  test('копия сессии есть на iOS и Android', () {
    expect(nativeSessionStoreEnabled(ios: true, android: false), isTrue);
    expect(nativeSessionStoreEnabled(ios: false, android: true), isTrue);
    expect(nativeSessionStoreEnabled(ios: false, android: false), isFalse);
  });
}
