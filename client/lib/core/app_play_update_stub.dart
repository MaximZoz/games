/// Заглушка: не Android (web / тесты без io-плагина).
Future<bool> supportsPlayInAppUpdate() async => false;

Future<bool> isPlayStoreUpdateAvailable() async => false;

/// @returns true если обновление запущено/завершено через Play.
Future<bool> applyPlayStoreUpdate() async => false;
