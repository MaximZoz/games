import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/core/sfx_io.dart';
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

  test('раздача из колоды звучит как полёт в сброс', () {
    expect(SfxController.resolveId(SfxId.cardDraw), SfxId.cardPlay);
    expect(SfxController.resolveId(SfxId.cardPlay), SfxId.cardPlay);
    expect(SfxController.resolveId(SfxId.uiTap), SfxId.uiTap);
  });

  test('Android AssetSource без префикса assets/', () {
    expect(
      SfxController.assetSourcePath('assets/sfx/hit.wav'),
      'sfx/hit.wav',
    );
    expect(SfxController.assetSourcePath('sfx/hit.wav'), 'sfx/hit.wav');
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

  test('yourTurn не дублируется чаще 900 мс', () {
    final c = SfxController();
    final t0 = DateTime.utc(2026, 1, 1);
    expect(c.shouldPlay(SfxId.yourTurn, t0), isTrue);
    expect(
      c.shouldPlay(SfxId.yourTurn, t0.add(const Duration(milliseconds: 200))),
      isFalse,
    );
    expect(
      c.shouldPlay(SfxId.yourTurn, t0.add(const Duration(milliseconds: 900))),
      isTrue,
    );
  });

  test('бейдж «ваш ход» молчит на экране партии', () {
    expect(
      MyTurnBadgeSfx.shouldPlay(
        previousCount: 0,
        nextCount: 1,
        path: '/games/poker/game/abc',
      ),
      isFalse,
    );
    expect(
      MyTurnBadgeSfx.shouldPlay(
        previousCount: 0,
        nextCount: 1,
        path: '/games/poker/offline',
      ),
      isFalse,
    );
    expect(
      MyTurnBadgeSfx.shouldPlay(
        previousCount: 0,
        nextCount: 1,
        path: '/chats',
      ),
      isTrue,
    );
    expect(
      MyTurnBadgeSfx.shouldPlay(
        previousCount: null,
        nextCount: 1,
        path: '/chats',
      ),
      isFalse,
    );
  });

  test('тик часов только на своём видимом ходе и раз в секунду', () {
    TurnClockSfx.reset();
    final played = <SfxId>[];
    TurnClockSfx.debugOnPlay = played.add;

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 12,
      clockVisible: true,
    );
    expect(played, [SfxId.yourTurn]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 12,
      clockVisible: true,
    );
    expect(played, [SfxId.yourTurn]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 11,
      clockVisible: true,
    );
    expect(played, [SfxId.yourTurn, SfxId.tick]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 10,
      clockVisible: false,
    );
    expect(played, [SfxId.yourTurn, SfxId.tick]);

    TurnClockSfx.sync(
      isMyTurn: false,
      remainingSeconds: 9,
      clockVisible: true,
    );
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 15,
      clockVisible: true,
    );
    expect(played, [SfxId.yourTurn, SfxId.tick, SfxId.yourTurn]);
    TurnClockSfx.reset();
  });

  test('бейдж уведомления только при росте счёта', () {
    expect(AlertSfx.shouldPlayCountBump(null, 3), isFalse);
    expect(AlertSfx.shouldPlayCountBump(0, 1), isTrue);
    expect(AlertSfx.shouldPlayCountBump(2, 2), isFalse);
    expect(AlertSfx.shouldPlayCountBump(3, 1), isFalse);
  });

  test('вход в открытое сообщение не играет второй notify', () {
    expect(AlertSfx.isReadingChat('/chats/abc'), isTrue);
    expect(AlertSfx.isReadingChat('/chats/abc?x=1'), isTrue);
    expect(AlertSfx.isReadingChat('/chats'), isFalse);
    expect(AlertSfx.isReadingChat('/chats/blocked'), isFalse);
    expect(
      AlertSfx.shouldPlayChatUnread(
        previous: 0,
        next: 1,
        path: '/chats/abc',
      ),
      isFalse,
    );
    expect(
      AlertSfx.shouldPlayChatUnread(
        previous: 0,
        next: 1,
        path: '/games',
      ),
      isTrue,
    );
  });

  test('soundEnabledProvider читает сохранённое выключение', () async {
    SharedPreferences.setMockInitialValues({'sound_enabled': false});
    final notifier = SoundEnabledNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifier.state, isFalse);
  });

  test('Android SFX — game/sonification, не media', () {
    final ctx = ioSfxAudioContext();
    expect(ctx.android.usageType, AndroidUsageType.game);
    expect(ctx.android.contentType, AndroidContentType.sonification);
    expect(
      ctx.android.audioFocus,
      AndroidAudioFocus.gainTransientMayDuck,
    );
  });
}
