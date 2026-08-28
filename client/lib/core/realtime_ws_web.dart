// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

import 'realtime_socket.dart';

class _WebRealtimeSocket implements RealtimeSocket {
  _WebRealtimeSocket(Uri uri) : _socket = html.WebSocket(uri.toString()) {
    _socket.onOpen.listen((_) {
      if (_closed || _connectedController.isClosed) return;
      _connectedController.add(null);
    });
    _socket.onMessage.listen((event) {
      if (_closed || _controller.isClosed) return;
      final data = event.data;
      if (data is String) {
        _controller.add(data);
      } else if (data != null) {
        _controller.add(data.toString());
      }
    });

    _socket.onError.listen((_) {
      if (_closed || _controller.isClosed) return;
      _controller.addError(StateError('websocket error'));
    });

    _socket.onClose.listen((_) {
      _finish();
    });
  }

  final html.WebSocket _socket;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  final StreamController<void> _connectedController =
      StreamController<void>.broadcast();
  bool _closed = false;

  @override
  Stream<String> get messages => _controller.stream;

  @override
  Stream<void> get connected => _connectedController.stream;

  @override
  bool get isOpen => _socket.readyState == html.WebSocket.OPEN;

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _socket.close();
    _finish();
  }

  void _finish() {
    if (!_connectedController.isClosed) {
      _connectedController.close();
    }
    if (_controller.isClosed) return;
    _controller.close();
  }
}

RealtimeSocket createRealtimeSocket(Uri uri) {
  return _WebRealtimeSocket(uri);
}
