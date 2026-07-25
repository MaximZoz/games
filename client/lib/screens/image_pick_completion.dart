import 'dart:async';

/// Resolves a browser file-pick operation from several browser signals.
///
/// Browser file pickers are not consistent about which event they emit when
/// dismissed, so focus/visibility signals are treated as cancellation only
/// after a short grace period. The hard timeout is the final safety net for
/// browsers that emit no dismissal event at all.
class ImagePickCompletion<T> {
  ImagePickCompletion({
    required Duration resumeGracePeriod,
    required Duration hardTimeout,
  }) : _resumeGracePeriod = resumeGracePeriod {
    _hardTimeoutTimer = Timer(hardTimeout, timeout);
  }

  final Duration _resumeGracePeriod;
  final Completer<T?> _completer = Completer<T?>();
  late Timer _hardTimeoutTimer;
  Timer? _resumeTimer;
  bool _selectionStarted = false;

  Future<T?> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void selectionStarted() {
    if (isCompleted) return;
    _selectionStarted = true;
    _resumeTimer?.cancel();
  }

  void complete(T value) {
    if (isCompleted) return;
    _finish(() => _completer.complete(value));
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (isCompleted) return;
    _finish(() => _completer.completeError(error, stackTrace));
  }

  void cancel() {
    if (isCompleted || _selectionStarted) return;
    _finish(() => _completer.complete(null));
  }

  void timeout() {
    if (isCompleted) return;
    _finish(() => _completer.complete(null));
  }

  void resumed() {
    if (isCompleted || _selectionStarted) return;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeGracePeriod, cancel);
  }

  void _finish(void Function() complete) {
    _hardTimeoutTimer.cancel();
    _resumeTimer?.cancel();
    complete();
  }
}
