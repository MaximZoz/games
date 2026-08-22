import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _poolSize = 8;
final List<web.HTMLAudioElement> _pool = [];
var _next = 0;

web.HTMLAudioElement _element() {
  if (_pool.length < _poolSize) {
    final audio = web.document.createElement('audio') as web.HTMLAudioElement;
    audio.preload = 'auto';
    _pool.add(audio);
    return audio;
  }
  final audio = _pool[_next % _pool.length];
  _next++;
  return audio;
}

void _start(web.HTMLAudioElement audio) {
  try {
    audio.play().toDart.then((_) {}, onError: (_) {});
  } catch (_) {}
}

/// Разблокировка автозапуска Safari / Chrome / iOS PWA — в том же жесте, без await.
void htmlSfxUnlock() {
  try {
    final audio = _element()
      ..src = _kSilentWav
      ..volume = 0;
    _start(audio);
  } catch (_) {}
}

void htmlSfxPlay(String dataUri, {double volume = 1}) {
  try {
    final audio = _element()
      ..src = dataUri
      ..volume = volume.clamp(0, 1).toDouble();
    try {
      audio.currentTime = 0;
    } catch (_) {}
    _start(audio);
  } catch (_) {}
}

/// 0.05 с тишины, 8-bit mono 8 kHz — только чтобы открыть Audio на жесте.
const _kSilentWav =
    'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAESsAACJWAAACABAAZGF0YQAAAAA=';
