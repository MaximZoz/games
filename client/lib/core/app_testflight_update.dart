/// Сравнение установленной IPA с последней сборкой TestFlight.
/// Номер сборки растёт только когда CI залил новую IPA, не при деплое сервера.
bool iosTestFlightUpdateAvailable({
  required String localBuildId,
  required int localBuildNumber,
  required String remoteBuildId,
  required int remoteBuildNumber,
}) {
  final localId = localBuildId.trim();
  final remoteId = remoteBuildId.trim();
  if (localId.isEmpty || localId == 'dev') return false;
  if (localBuildNumber <= 0 || remoteBuildNumber <= 0) return false;
  if (remoteId.isEmpty) return false;
  return remoteBuildNumber > localBuildNumber;
}

/// Страница этого приложения в TestFlight. Пустой id — просто открыть TestFlight.
Uri testFlightUpdateUri(String appleId) {
  final id = appleId.trim();
  if (RegExp(r'^\d{6,}$').hasMatch(id)) {
    return Uri.parse('itms-beta://beta.itunes.apple.com/v1/app/$id');
  }
  return Uri.parse('itms-beta://');
}
