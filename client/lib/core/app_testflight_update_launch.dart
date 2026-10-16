/// Открыть TestFlight на странице приложения, чтобы поставить новую сборку.
library;

export 'app_testflight_update_launch_stub.dart'
    if (dart.library.io) 'app_testflight_update_launch_io.dart';
