/// Системный лист входа (iOS ASWebAuthenticationSession). На web — stub.
library;

export 'system_auth_session_stub.dart'
    if (dart.library.io) 'system_auth_session_io.dart';
