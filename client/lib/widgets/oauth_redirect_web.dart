import 'package:web/web.dart' as web;

void openOAuthUrl(String url) {
  web.window.location.assign(url);
}
