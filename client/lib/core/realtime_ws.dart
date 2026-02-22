import 'realtime_socket.dart';
import 'realtime_ws_stub.dart' if (dart.library.html) 'realtime_ws_web.dart' as impl;

export 'realtime_socket.dart';

RealtimeSocket connectRealtimeSocket(Uri uri) => impl.createRealtimeSocket(uri);
