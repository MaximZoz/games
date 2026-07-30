/// Результат OAuth из popup. `null` = ушли полным редиректом (или отмена).
Future<Map<String, String>?> openOAuthUrl(String url) async => null;

/// В popup: передать результат opener и закрыть. На VM — false.
bool completeOAuthPopup(Map<String, String> params) => false;
