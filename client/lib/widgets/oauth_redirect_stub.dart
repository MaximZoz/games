bool get isIosStandalonePwa => false;

Object? openOAuthWindowBlank() => null;

void navigateOAuthWindow(Object? handle, String url) {}

void closeOAuthWindow(Object? handle) {}

/// iOS PWA: открыть OAuth во внешнем Safari (не WKWebView).
void openOAuthExternal(String url) {}

({String authorizeUrl, String state})? fetchOAuthPollStartSync(String url) =>
    null;

void saveOAuthPendingState(String state) {}

String? readOAuthPendingState() => null;

void clearOAuthPendingState() {}
