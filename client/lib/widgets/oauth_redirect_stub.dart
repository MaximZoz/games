import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _pendingKey = 'mg_oauth_pending_state';

String? _pendingMemory;

bool get isIosStandalonePwa => false;

Object? openOAuthWindowBlank() => null;

void navigateOAuthWindow(Object? handle, String url) {
  openOAuthExternal(url);
}

void closeOAuthWindow(Object? handle) {}

/// Android/iOS: открыть OAuth во внешнем браузере / Custom Tabs.
void openOAuthExternal(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  // ignore: discarded_futures
  launchUrl(uri, mode: LaunchMode.externalApplication);
}

({String authorizeUrl, String state})? fetchOAuthPollStartSync(String url) =>
    null;

void saveOAuthPendingState(String state) {
  _pendingMemory = state;
  // ignore: discarded_futures
  SharedPreferences.getInstance().then((p) => p.setString(_pendingKey, state));
}

String? readOAuthPendingState() => _pendingMemory;

/// Подтянуть pending state после cold start (вернуться из браузера).
Future<void> hydrateOAuthPendingState() async {
  if (_pendingMemory != null && _pendingMemory!.isNotEmpty) return;
  try {
    final p = await SharedPreferences.getInstance();
    final v = (p.getString(_pendingKey) ?? '').trim();
    if (v.isNotEmpty) _pendingMemory = v;
  } catch (_) {}
}

void clearOAuthPendingState() {
  _pendingMemory = null;
  // ignore: discarded_futures
  SharedPreferences.getInstance().then((p) => p.remove(_pendingKey));
}
