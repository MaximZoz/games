import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'realtime_socket.dart';

class _IoRealtimeSocket implements RealtimeSocket {
  _IoRealtimeSocket(Uri uri) {
    unawaited(_connect(uri));
  }

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  final StreamController<void> _connectedController =
      StreamController<void>.broadcast();
  bool _closed = false;

  Future<void> _connect(Uri uri) async {
    try {
      final socket = await WebSocket.connect(uri.toString())
          .timeout(const Duration(seconds: 8));
      if (_closed) {
        await socket.close();
        return;
      }
      _socket = socket;
      if (!_connectedController.isClosed) {
        _connectedController.add(null);
      }
      _subscription = socket.listen(
        (data) {
          if (_closed || _controller.isClosed) return;
          if (data is String) {
            _controller.add(data);
          } else if (data is List<int>) {
            _controller.add(utf8.decode(data));
          } else if (data != null) {
            _controller.add(data.toString());
          }
        },
        onError: (Object _) {
          if (_closed || _controller.isClosed) return;
          _controller.addError(StateError('websocket error'));
        },
        onDone: _finish,
        cancelOnError: false,
      );
    } catch (e) {
      if (_closed) return;
      if (!_controller.isClosed) {
        _controller.addError(e);
      }
      // Иначе onDone/onError могут не прийти — реконнект не стартует.
      _finish();
    }
  }

  @override
  Stream<String> get messages => _controller.stream;

  @override
  Stream<void> get connected => _connectedController.stream;

  @override
  bool get isOpen => _socket?.readyState == WebSocket.open;

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      unawaited(socket.close());
    }
    _finish();
  }

  void _finish() {
    if (!_connectedController.isClosed) {
      unawaited(_connectedController.close());
    }
    if (_controller.isClosed) return;
    unawaited(_controller.close());
  }
}

RealtimeSocket createRealtimeSocket(Uri uri) {
  return _IoRealtimeSocket(uri);
}
