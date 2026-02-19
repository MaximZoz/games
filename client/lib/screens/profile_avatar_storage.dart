// Conditional export: IO implementation when dart:io available, stub for web.
export 'profile_avatar_storage_io.dart'
    if (dart.library.html) 'profile_avatar_storage_stub.dart';
