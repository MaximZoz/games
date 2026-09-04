import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('автоподтверждение запоминается локально', () async {
    SharedPreferences.setMockInitialValues({});
    final n = PrefBoolNotifier('nardy_auto_confirm', defaultValue: false);
    await Future<void>.delayed(Duration.zero);
    expect(n.state, isFalse);
    await n.set(true);
    expect(n.state, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('nardy_auto_confirm'), isTrue);

    final again = PrefBoolNotifier('nardy_auto_confirm', defaultValue: false);
    await Future<void>.delayed(Duration.zero);
    expect(again.state, isTrue);
  });
}
