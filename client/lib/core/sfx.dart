import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'haptics.dart';
import 'sfx_html_stub.dart' if (dart.library.html) 'sfx_html_web.dart' as html_sfx;
import 'sfx_io_stub.dart' if (dart.library.io) 'sfx_io.dart' as io_sfx;

/// Короткий набор эффектов. Сэмплы — Kenney Interface Sounds (CC0),
/// плюс голосовое «Уно!».
enum SfxId {
  uiTap,
  notify,
  cardDraw,
  cardPlay,
  cardLand,
  unoCall,
  unoSpecial,
  chip,
  place,
  hit,
  miss,
  sink,
  win,
  coins,
  deny,
  tick,
  yourTurn,
}

/// Категории звука в настройках: игры / уведомления / ход.
enum SfxCategory {
  games,
  notifications,
  turn,
}

/// Порог оставшегося времени хода для вибрации (80% / 50% / 20%).
enum TurnTimerMark {
  p80(0.8),
  p50(0.5),
  p20(0.2);

  const TurnTimerMark(this.remainingRatio);

  final double remainingRatio;
}

/// Категория сэмпла. Раздача (`cardDraw`) считается игровой, как `cardPlay`.
@visibleForTesting
SfxCategory sfxCategoryOf(SfxId id) {
  switch (id) {
    case SfxId.notify:
      return SfxCategory.notifications;
    case SfxId.yourTurn:
    case SfxId.tick:
      return SfxCategory.turn;
    default:
      return SfxCategory.games;
  }
}

/// Пересечения 80/50/20% остатка между двумя кадрами таймера.
@visibleForTesting
List<TurnTimerMark> crossedTurnTimerMarks(
  double previousRatio,
  double nextRatio,
) {
  return [
    for (final mark in TurnTimerMark.values)
      if (previousRatio > mark.remainingRatio &&
          nextRatio <= mark.remainingRatio)
        mark,
  ];
}

/// Вибрация раз в секунду, когда осталось ≤5 с.
@visibleForTesting
bool shouldBuzzTurnSecond({
  required int remainingSeconds,
  required int? lastBuzzedSecond,
}) {
  return remainingSeconds > 0 &&
      remainingSeconds <= 5 &&
      lastBuzzedSecond != remainingSeconds;
}

abstract final class Sfx {
  static final SfxController instance = SfxController();

  static void play(SfxId id) => instance.play(id);

  static void setEnabled(bool enabled) => instance.setEnabled(enabled);
}

class SfxController {
  SfxController({
    this.debounce = const Duration(milliseconds: 80),
  });

  final Duration debounce;

  @visibleForTesting
  static const assetPaths = <SfxId, String>{
    SfxId.uiTap: 'assets/sfx/ui_tap.wav',
    SfxId.notify: 'assets/sfx/notify.wav',
    SfxId.cardDraw: 'assets/sfx/card_draw.wav',
    SfxId.cardPlay: 'assets/sfx/card_play.wav',
    SfxId.cardLand: 'assets/sfx/card_land.wav',
    SfxId.unoCall: 'assets/sfx/uno_call.wav',
    SfxId.unoSpecial: 'assets/sfx/uno_special.wav',
    SfxId.chip: 'assets/sfx/chip.wav',
    SfxId.place: 'assets/sfx/place.wav',
    SfxId.hit: 'assets/sfx/hit.wav',
    SfxId.miss: 'assets/sfx/miss.wav',
    SfxId.sink: 'assets/sfx/sink.wav',
    SfxId.win: 'assets/sfx/win.wav',
    SfxId.coins: 'assets/sfx/coins.wav',
    SfxId.deny: 'assets/sfx/deny.wav',
    SfxId.tick: 'assets/sfx/tick.wav',
    SfxId.yourTurn: 'assets/sfx/your_turn.wav',
  };

  final Map<SfxId, String> _dataUris = {};
  Completer<void>? _preloadDone;
  bool _enabled = true;
  bool _games = true;
  bool _notifications = true;
  bool _turn = true;
  DateTime? _lastAt;
  SfxId? _lastId;

  bool get enabled => _enabled;

  @visibleForTesting
  /// «Ваш ход» с часов стола и с бейджа не должны звучать парой.
  static const yourTurnDebounce = Duration(milliseconds: 900);

  bool shouldPlay(SfxId id, DateTime now) {
    final window = id == SfxId.yourTurn ? yourTurnDebounce : debounce;
    if (_lastId == id &&
        _lastAt != null &&
        now.difference(_lastAt!) < window) {
      return false;
    }
    _lastId = id;
    _lastAt = now;
    return true;
  }

  bool get _inWidgetTest {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding');
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (enabled) warmup();
  }

  void setCategories({
    bool? games,
    bool? notifications,
    bool? turn,
  }) {
    if (games != null) _games = games;
    if (notifications != null) _notifications = notifications;
    if (turn != null) _turn = turn;
  }

  /// Мастер и категория. Без debounce — для настроек и тестов.
  bool allows(SfxId id) {
    if (!_enabled) return false;
    switch (sfxCategoryOf(resolveId(id))) {
      case SfxCategory.games:
        return _games;
      case SfxCategory.notifications:
        return _notifications;
      case SfxCategory.turn:
        return _turn;
    }
  }

  void warmup({bool unlock = true}) {
    if (!_enabled || _inWidgetTest) return;
    if (unlock) html_sfx.htmlSfxUnlock();
    io_sfx.ioSfxWarmup();
    unawaited(_preload());
  }

  /// AssetSource на Android/iOS — путь без префикса `assets/`.
  @visibleForTesting
  static String assetSourcePath(String assetPath) {
    const prefix = 'assets/';
    return assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;
  }

  /// Раздача из колоды звучит как полёт в сброс (`cardPlay`).
  @visibleForTesting
  static SfxId resolveId(SfxId id) =>
      id == SfxId.cardDraw ? SfxId.cardPlay : id;

  void play(SfxId id) {
    if (_inWidgetTest) return;
    id = resolveId(id);
    if (!allows(id)) return;
    final now = DateTime.now();
    if (!shouldPlay(id, now)) return;
    if (io_sfx.ioSfxSupported) {
      final path = assetPaths[id];
      if (path != null) {
        io_sfx.ioSfxPlay(assetSourcePath(path), volume: _volumeFor(id));
      }
      return;
    }
    final uri = _dataUris[id];
    if (uri == null) {
      unawaited(_preload().then((_) {
        final ready = _dataUris[id];
        if (ready != null && _enabled) {
          html_sfx.htmlSfxPlay(ready, volume: _volumeFor(id));
        }
      }));
      return;
    }
    html_sfx.htmlSfxPlay(uri, volume: _volumeFor(id));
  }

  static double _volumeFor(SfxId id) {
    switch (id) {
      case SfxId.tick:
        return 0.28;
      case SfxId.yourTurn:
        return 0.5;
      default:
        return 0.55;
    }
  }

  Future<void> _preload() async {
    if (_dataUris.length == assetPaths.length) return;
    final inflight = _preloadDone;
    if (inflight != null) return inflight.future;
    final done = Completer<void>();
    _preloadDone = done;
    try {
      for (final entry in assetPaths.entries) {
        if (_dataUris.containsKey(entry.key)) continue;
        final bytes = await rootBundle.load(entry.value);
        _dataUris[entry.key] =
            'data:audio/wav;base64,${base64Encode(bytes.buffer.asUint8List())}';
      }
      done.complete();
    } catch (_) {
      _preloadDone = null;
      if (!done.isCompleted) done.complete();
    }
  }
}

/// Рост бейджа (чаты / заявки / инвайты) → один notify, не на первом кадре.
abstract final class AlertSfx {
  static void playNotify() {
    Sfx.play(SfxId.notify);
    Haptics.play(HapticKind.notify);
  }

  static void playYourTurn() {
    Sfx.play(SfxId.yourTurn);
    Haptics.play(HapticKind.yourTurn);
  }

  static bool shouldPlayCountBump(int? previous, int next) {
    return previous != null && next > previous;
  }

  /// Открытая комната чата (`/chats/<id>`), не список и не «Заблокированные».
  static bool isReadingChat(String path) {
    final segs = path
        .split('?')
        .first
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    if (segs.length < 2 || segs[0] != 'chats') return false;
    final id = segs[1];
    return id.isNotEmpty && id != 'blocked';
  }

  /// Новый unread, но не при входе в уже открытое сообщение (иначе второй ping).
  static bool shouldPlayChatUnread({
    required int? previous,
    required int next,
    required String path,
  }) {
    return shouldPlayCountBump(previous, next) && !isReadingChat(path);
  }
}

/// Партия (онлайн или офлайн), не список игр и не лобби.
@visibleForTesting
bool isGamePlayPath(String path) {
  final segs = path
      .split('?')
      .first
      .split('/')
      .where((part) => part.isNotEmpty)
      .toList();
  if (segs.length < 3 || segs[0] != 'games') return false;
  if (segs[2] == 'offline') return true;
  return segs.length >= 4 && segs[2] == 'game';
}

/// Бейдж «ваш ход» в шелле не дублирует звук, если уже открыта партия.
abstract final class MyTurnBadgeSfx {
  static bool isOnGameBoard(String path) => isGamePlayPath(path);

  static bool shouldPlay({
    required int? previousCount,
    required int nextCount,
    required String path,
  }) {
    return AlertSfx.shouldPlayCountBump(previousCount, nextCount) &&
        !isOnGameBoard(path);
  }
}

/// С другого экрана игровые события звучат как уведомление, не как тик хода.
abstract final class GameAwaySfx {
  static bool _wasMyTurn = false;
  static String? _gameId;
  static DateTime? _lastPlayAt;

  @visibleForTesting
  static const debounce = Duration(milliseconds: 800);

  @visibleForTesting
  static void reset() {
    _wasMyTurn = false;
    _gameId = null;
    _lastPlayAt = null;
  }

  static bool isWatchingBoard(String path, String? gameId) {
    if (!isGamePlayPath(path)) return false;
    final id = (gameId ?? '').trim();
    if (id.isEmpty) return true;
    final p = path.toLowerCase();
    final needle = id.toLowerCase();
    return p.contains('/game/$needle') || p.contains('/offline');
  }

  /// Запомнить ход. true — только что стал моим.
  static bool noteMyTurn({
    required bool isMyTurn,
    String? gameId,
  }) {
    final id = (gameId ?? '').trim();
    final sameGame = id.isEmpty || id == _gameId;
    final was = sameGame && _wasMyTurn;
    _wasMyTurn = isMyTurn;
    if (id.isNotEmpty) _gameId = id;
    if (!isMyTurn) return false;
    return !was;
  }

  static bool shouldPlayNotify({
    required String path,
    required String? gameId,
    required bool becameMyTurn,
    DateTime? now,
  }) {
    if (!becameMyTurn) return false;
    if (isWatchingBoard(path, gameId)) return false;
    final at = now ?? DateTime.now();
    if (_lastPlayAt != null && at.difference(_lastPlayAt!) < debounce) {
      return false;
    }
    _lastPlayAt = at;
    return true;
  }

  static void playIfNeeded({
    required String path,
    required String? gameId,
    required bool isMyTurn,
  }) {
    final became = noteMyTurn(isMyTurn: isMyTurn, gameId: gameId);
    if (!shouldPlayNotify(
      path: path,
      gameId: gameId,
      becameMyTurn: became,
    )) {
      return;
    }
    AlertSfx.playNotify();
  }
}

/// Осталось ≤5 с — тики молчат, один сигнал «ваш ход».
@visibleForTesting
bool crossedTurnFiveSeconds({
  required int previousRemainingMs,
  required int nextRemainingMs,
}) {
  return previousRemainingMs > 5000 &&
      nextRemainingMs <= 5000 &&
      nextRemainingMs > 0;
}

/// Интервал тика: 80% → 800 мс, 50%/20% → 500 мс. Последние 5 с — без тиков.
@visibleForTesting
int turnTickIntervalMs({
  required int remainingMs,
  required int totalMs,
}) {
  if (remainingMs <= 0 || remainingMs <= 5000) return 0;
  if (totalMs > 0) {
    if (remainingMs * 2 <= totalMs) return 500;
    if (remainingMs * 5 <= totalMs * 4) return 800;
  }
  return 1000;
}

/// Тик часов на своём ходе и сигнал «ваш ход» (без двойного звука).
abstract final class TurnClockSfx {
  static bool _wasMyTurn = false;
  static DateTime? _lastTickAt;
  static double? _lastRatio;
  static int? _lastSecondBuzz;
  static int? _lastRemainingMs;

  @visibleForTesting
  static void Function(SfxId id)? debugOnPlay;

  @visibleForTesting
  static void Function(HapticKind kind)? debugOnHaptic;

  @visibleForTesting
  static void reset() {
    _wasMyTurn = false;
    _lastTickAt = null;
    _lastRatio = null;
    _lastSecondBuzz = null;
    _lastRemainingMs = null;
    debugOnPlay = null;
    debugOnHaptic = null;
  }

  static void sync({
    required bool isMyTurn,
    required int remainingSeconds,
    required bool clockVisible,
    bool hasTimer = true,
    bool announceOnly = false,
    int turnTimeSec = 0,
    int? remainingMs,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final leftMs = remainingMs ?? remainingSeconds * 1000;
    final totalMs = turnTimeSec > 0 ? turnTimeSec * 1000 : 0;
    final ratio = totalMs > 0 ? (leftMs / totalMs).clamp(0.0, 1.0) : null;
    if (!isMyTurn) {
      _wasMyTurn = false;
      _lastTickAt = null;
      _lastRatio = null;
      _lastSecondBuzz = null;
      _lastRemainingMs = null;
      return;
    }
    if (!_wasMyTurn) {
      _wasMyTurn = true;
      if (!announceOnly) {
        _lastTickAt = at;
      }
      // Скрытая вкладка IndexedStack не должна пищать: с другого экрана
      // звучит GameAwaySfx (notify).
      if (clockVisible) {
        _play(SfxId.yourTurn);
        _haptic(HapticKind.yourTurn);
      }
      _lastRatio = ratio;
      _lastRemainingMs = leftMs;
      _lastSecondBuzz =
          hasTimer && remainingSeconds <= 5 ? remainingSeconds : null;
      return;
    }
    if (announceOnly) return;
    if (hasTimer) {
      if (ratio != null && _lastRatio != null) {
        if (crossedTurnTimerMarks(_lastRatio!, ratio).isNotEmpty) {
          _haptic(HapticKind.timerMark);
        }
      }
      if (ratio != null) _lastRatio = ratio;
      final prevLeft = _lastRemainingMs;
      if (prevLeft != null &&
          crossedTurnFiveSeconds(
            previousRemainingMs: prevLeft,
            nextRemainingMs: leftMs,
          )) {
        _play(SfxId.yourTurn);
        _haptic(HapticKind.timerMark);
      }
      _lastRemainingMs = leftMs;
      if (shouldBuzzTurnSecond(
        remainingSeconds: remainingSeconds,
        lastBuzzedSecond: _lastSecondBuzz,
      )) {
        _lastSecondBuzz = remainingSeconds;
        _haptic(HapticKind.timerSecond);
      }
    } else {
      _lastRemainingMs = leftMs;
    }
    if (!clockVisible || !hasTimer || remainingSeconds <= 0) return;
    if (leftMs <= 5000) return;
    final interval = turnTickIntervalMs(remainingMs: leftMs, totalMs: totalMs);
    if (interval <= 0) return;
    if (_lastTickAt != null &&
        at.difference(_lastTickAt!) < Duration(milliseconds: interval)) {
      return;
    }
    _lastTickAt = at;
    _play(SfxId.tick);
  }

  static void _play(SfxId id) {
    debugOnPlay?.call(id);
    Sfx.play(id);
  }

  static void _haptic(HapticKind kind) {
    debugOnHaptic?.call(kind);
    Haptics.play(kind);
  }
}
