/// Нативный Sign in with Apple (iOS). На web — stub.
library;

export 'apple_native_sign_in_stub.dart'
    if (dart.library.io) 'apple_native_sign_in_io.dart';
