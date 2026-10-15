class SystemAuthSessionException implements Exception {
  SystemAuthSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Web: системного листа нет.
Future<bool> startSystemAuthSession({
  required String url,
  required String callbackScheme,
}) async {
  throw SystemAuthSessionException('Sign-in sheet is not available');
}

Future<void> cancelSystemAuthSession() async {}
