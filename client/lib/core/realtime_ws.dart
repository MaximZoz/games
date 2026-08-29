import 'realtime_socket.dart';
import 'realtime_ws_stub.dart'
    if (dart.library.html) 'realtime_ws_web.dart'
    if (dart.library.io) 'realtime_ws_io.dart' as impl;

export 'realtime_socket.dart';

RealtimeSocket connectRealtimeSocket(Uri uri) => impl.createRealtimeSocket(uri);
