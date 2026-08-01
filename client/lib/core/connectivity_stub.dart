import 'dart:async';

/// На non-web считаем устройство онлайн; уточнение — через probe API.
bool readDeviceOnline() => true;

Stream<bool> deviceOnlineStream() => const Stream<bool>.empty();
