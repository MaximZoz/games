/// Заглушка окна OAuth для VM-тестов.
class OAuthWindowHandle {
  const OAuthWindowHandle();
}

OAuthWindowHandle? openOAuthWindowBlank() => const OAuthWindowHandle();

void navigateOAuthWindow(OAuthWindowHandle? handle, String url) {}

void closeOAuthWindow(OAuthWindowHandle? handle) {}
