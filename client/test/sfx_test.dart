import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('у каждого SfxId есть wav', () {
    expect(SfxController.assetPaths.keys.toSet(), SfxId.values.toSet());
  });

  test('одинаковый sfx не дублируется чаще debounce', () {
    final c = SfxController();
    final t0 = DateTime.utc(2026, 1, 1);
    expect(c.shouldPlay(SfxId.uiTap, t0), isTrue);
    expect(
      c.shouldPlay(SfxId.uiTap, t0.add(const Duration(milliseconds: 20))),
      isFalse,
    );
    expect(
      c.shouldPlay(SfxId.cardPlay, t0.add(const Duration(milliseconds: 20))),
      isTrue,
    );
    expect(
      c.shouldPlay(SfxId.uiTap, t0.add(const Duration(milliseconds: 80))),
      isTrue,
    );
  });

  test('Sfx.play в widget-тестах не бросает', () {
    Sfx.setEnabled(true);
    Sfx.play(SfxId.uiTap);
    Sfx.play(SfxId.cardPlay);
  });

  test('soundEnabledProvider по умолчанию включён и сохраняется', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(soundEnabledProvider), isTrue);
    await container.read(soundEnabledProvider.notifier).set(false);
    expect(container.read(soundEnabledProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sound_enabled'), isFalse);
  });

  test('soundEnabledProvider читает сохранённое выключение', () async {
    SharedPreferences.setMockInitialValues({'sound_enabled': false});
    final notifier = SoundEnabledNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifier.state, isFalse);
  });
}
