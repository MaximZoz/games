/// Проверка/установка обновления через Google Play In-App Updates.
///
/// На web / iOS / desktop — no-op (см. stub). На Android — официальный Play API.
library;

export 'app_play_update_stub.dart'
    if (dart.library.io) 'app_play_update_io.dart';
