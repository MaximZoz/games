import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

bool get ioSfxSupported => true;

/// Короткий SFX: game + transient focus. Иначе Android после нескольких
/// `AudioPlayer()` на выстрел перестаёт играть звук (прод).
AudioContext ioSfxAudioContext() {
  return AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );
}

class _IoSfxPool {
  static const _size = 4;

  final List<AudioPlayer> _players = [];
  int _next = 0;
  Future<void>? _init;

  Future<void> ensureReady() {
    return _init ??= _open();
  }

  Future<void> _open() async {
    final ctx = ioSfxAudioContext();
    await AudioPlayer.global.setAudioContext(ctx);
    for (var i = 0; i < _size; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setAudioContext(ctx);
      _players.add(player);
    }
  }

  Future<void> play(String sourcePath, double volume) async {
    try {
      await ensureReady();
      if (_players.isEmpty) return;
      final player = _players[_next % _players.length];
      _next++;
      await player.stop();
      await player.setVolume(volume.clamp(0, 1));
      await player.play(AssetSource(sourcePath));
    } catch (_) {
      // Прод не должен падать из‑за аудио; следующий слот пула ещё жив.
    }
  }
}

final _pool = _IoSfxPool();

void ioSfxWarmup() {
  unawaited(_pool.ensureReady());
}

void ioSfxPlay(String assetPath, {double volume = 1}) {
  unawaited(_pool.play(assetPath, volume));
}
