/// Нативный Google Sign-In (Android/iOS). На web — stub.
library;

export 'google_native_sign_in_stub.dart'
    if (dart.library.io) 'google_native_sign_in_io.dart';
