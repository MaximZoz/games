import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/haptics.dart';
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

  test('тик часов только на своём видимом ходе и по интервалу', () {
    TurnClockSfx.reset();
    final played = <SfxId>[];
    TurnClockSfx.debugOnPlay = played.add;
    final t0 = DateTime.utc(2026, 8, 30, 12);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 12,
      remainingMs: 12000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0,
    );
    expect(played, [SfxId.yourTurn]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 12,
      remainingMs: 11800,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(milliseconds: 400)),
    );
    expect(played, [SfxId.yourTurn]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 11,
      remainingMs: 11000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 1)),
    );
    expect(played, [SfxId.yourTurn, SfxId.tick]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 10,
      remainingMs: 10000,
      turnTimeSec: 20,
      clockVisible: false,
      now: t0.add(const Duration(seconds: 2)),
    );
    expect(played, [SfxId.yourTurn, SfxId.tick]);

    TurnClockSfx.sync(
      isMyTurn: false,
      remainingSeconds: 9,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 3)),
    );
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 15,
      remainingMs: 15000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 4)),
    );
    expect(played, [SfxId.yourTurn, SfxId.tick, SfxId.yourTurn]);
    TurnClockSfx.reset();
  });

  test('интервал тика ускоряется на 80%, 50%, 20% и на 5 секундах', () {
    const total = 60000;
    expect(turnTickIntervalMs(remainingMs: 54000, totalMs: total), 1000);
    expect(turnTickIntervalMs(remainingMs: 48000, totalMs: total), 800);
    expect(turnTickIntervalMs(remainingMs: 30000, totalMs: total), 500);
    expect(turnTickIntervalMs(remainingMs: 12000, totalMs: total), 200);
    expect(turnTickIntervalMs(remainingMs: 5000, totalMs: 20000), 200);
    expect(turnTickIntervalMs(remainingMs: 0, totalMs: total), 0);
  });

  test('в красной зоне тик чаще секунды', () {
    TurnClockSfx.reset();
    final played = <SfxId>[];
    TurnClockSfx.debugOnPlay = played.add;
    final t0 = DateTime.utc(2026, 8, 30, 13);
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 4,
      remainingMs: 4000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0,
    );
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 3,
      remainingMs: 3700,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(milliseconds: 220)),
    );
    expect(played, [SfxId.yourTurn, SfxId.tick]);
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

  test('категории: игры / уведомления / ход', () {
    expect(sfxCategoryOf(SfxId.notify), SfxCategory.notifications);
    expect(sfxCategoryOf(SfxId.yourTurn), SfxCategory.turn);
    expect(sfxCategoryOf(SfxId.tick), SfxCategory.turn);
    expect(sfxCategoryOf(SfxId.cardPlay), SfxCategory.games);
    expect(sfxCategoryOf(SfxId.cardDraw), SfxCategory.games);
    expect(sfxCategoryOf(SfxId.hit), SfxCategory.games);
    expect(sfxCategoryOf(SfxId.win), SfxCategory.games);
  });

  test('allows уважает мастер и категории звука', () {
    final c = SfxController();
    expect(c.allows(SfxId.notify), isTrue);
    expect(c.allows(SfxId.cardPlay), isTrue);
    expect(c.allows(SfxId.yourTurn), isTrue);
    c.setCategories(notifications: false);
    expect(c.allows(SfxId.notify), isFalse);
    expect(c.allows(SfxId.cardPlay), isTrue);
    expect(c.allows(SfxId.yourTurn), isTrue);
    c.setCategories(games: false, notifications: true, turn: false);
    expect(c.allows(SfxId.cardPlay), isFalse);
    expect(c.allows(SfxId.notify), isTrue);
    expect(c.allows(SfxId.yourTurn), isFalse);
    expect(c.allows(SfxId.tick), isFalse);
    c.setEnabled(false);
    expect(c.allows(SfxId.notify), isFalse);
  });

  test('пороги 80/50/20 пересекаются при снижении остатка', () {
    expect(crossedTurnTimerMarks(0.9, 0.81), isEmpty);
    expect(crossedTurnTimerMarks(0.81, 0.8), [TurnTimerMark.p80]);
    expect(crossedTurnTimerMarks(0.8, 0.79), isEmpty);
    expect(crossedTurnTimerMarks(0.51, 0.5), [TurnTimerMark.p50]);
    expect(crossedTurnTimerMarks(0.21, 0.2), [TurnTimerMark.p20]);
    expect(
      crossedTurnTimerMarks(0.9, 0.15),
      [TurnTimerMark.p80, TurnTimerMark.p50, TurnTimerMark.p20],
    );
  });

  test('вибрация последней пяти секунд — раз в секунду, без нуля', () {
    expect(
      shouldBuzzTurnSecond(remainingSeconds: 6, lastBuzzedSecond: null),
      isFalse,
    );
    expect(
      shouldBuzzTurnSecond(remainingSeconds: 5, lastBuzzedSecond: null),
      isTrue,
    );
    expect(
      shouldBuzzTurnSecond(remainingSeconds: 5, lastBuzzedSecond: 5),
      isFalse,
    );
    expect(
      shouldBuzzTurnSecond(remainingSeconds: 4, lastBuzzedSecond: 5),
      isTrue,
    );
    expect(
      shouldBuzzTurnSecond(remainingSeconds: 0, lastBuzzedSecond: 1),
      isFalse,
    );
  });

  test('часы: ход, пороги 80/50/20 и секунды в конце', () {
    TurnClockSfx.reset();
    final played = <SfxId>[];
    final buzz = <HapticKind>[];
    TurnClockSfx.debugOnPlay = played.add;
    TurnClockSfx.debugOnHaptic = buzz.add;
    final t0 = DateTime.utc(2026, 8, 30, 14);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 20,
      remainingMs: 20000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0,
    );
    expect(played, [SfxId.yourTurn]);
    expect(buzz, [HapticKind.yourTurn]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 16,
      remainingMs: 16000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 4)),
    );
    expect(buzz, [HapticKind.yourTurn, HapticKind.timerMark]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 10,
      remainingMs: 10000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 10)),
    );
    expect(buzz, [
      HapticKind.yourTurn,
      HapticKind.timerMark,
      HapticKind.timerMark,
    ]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 4,
      remainingMs: 4000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 16)),
    );
    expect(buzz, [
      HapticKind.yourTurn,
      HapticKind.timerMark,
      HapticKind.timerMark,
      HapticKind.timerMark,
      HapticKind.timerSecond,
    ]);

    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 3,
      remainingMs: 3000,
      turnTimeSec: 20,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 17)),
    );
    expect(buzz.last, HapticKind.timerSecond);
    expect(buzz.where((k) => k == HapticKind.timerSecond).length, 2);
    TurnClockSfx.reset();
  });

  test('последние 5 секунд — вибрация на 5, 4, 3, 2, 1', () {
    TurnClockSfx.reset();
    final buzz = <HapticKind>[];
    TurnClockSfx.debugOnHaptic = buzz.add;
    final t0 = DateTime.utc(2026, 8, 30, 16);
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 6,
      remainingMs: 6000,
      turnTimeSec: 60,
      clockVisible: true,
      now: t0,
    );
    expect(buzz, [HapticKind.yourTurn]);
    for (var i = 0; i < 5; i++) {
      final left = 5 - i;
      TurnClockSfx.sync(
        isMyTurn: true,
        remainingSeconds: left,
        remainingMs: left * 1000,
        turnTimeSec: 60,
        clockVisible: true,
        now: t0.add(Duration(seconds: 1 + i)),
      );
    }
    expect(
      buzz.where((k) => k == HapticKind.timerSecond).length,
      5,
    );
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 0,
      remainingMs: 0,
      turnTimeSec: 60,
      clockVisible: true,
      now: t0.add(const Duration(seconds: 6)),
    );
    expect(
      buzz.where((k) => k == HapticKind.timerSecond).length,
      5,
    );
    TurnClockSfx.reset();
  });

  test('старт хода с 4 с не дублирует секундную вибрацию', () {
    TurnClockSfx.reset();
    final buzz = <HapticKind>[];
    TurnClockSfx.debugOnHaptic = buzz.add;
    TurnClockSfx.sync(
      isMyTurn: true,
      remainingSeconds: 4,
      remainingMs: 4000,
      turnTimeSec: 20,
      clockVisible: true,
      now: DateTime.utc(2026, 8, 30, 15),
    );
    expect(buzz, [HapticKind.yourTurn]);
    TurnClockSfx.reset();
  });

  test('хаптик yourTurn не чаще 900 мс', () {
    final c = HapticsController();
    final t0 = DateTime.utc(2026, 1, 1);
    expect(c.shouldPlay(HapticKind.yourTurn, t0), isTrue);
    expect(
      c.shouldPlay(
        HapticKind.yourTurn,
        t0.add(const Duration(milliseconds: 200)),
      ),
      isFalse,
    );
    expect(
      c.shouldPlay(
        HapticKind.notify,
        t0.add(const Duration(milliseconds: 200)),
      ),
      isTrue,
    );
    expect(
      c.shouldPlay(
        HapticKind.yourTurn,
        t0.add(const Duration(milliseconds: 900)),
      ),
      isTrue,
    );
  });

  test('категории звука и вибрация сохраняются', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(soundGamesEnabledProvider), isTrue);
    expect(container.read(soundNotificationsEnabledProvider), isTrue);
    expect(container.read(soundTurnEnabledProvider), isTrue);
    expect(container.read(hapticsEnabledProvider), isTrue);
    await container.read(soundGamesEnabledProvider.notifier).set(false);
    await container.read(hapticsEnabledProvider.notifier).set(false);
    expect(container.read(soundGamesEnabledProvider), isFalse);
    expect(container.read(hapticsEnabledProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sound_games_enabled'), isFalse);
    expect(prefs.getBool('haptics_enabled'), isFalse);
  });
}
