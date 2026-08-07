import 'package:web/web.dart' as web;

/// Жёсткая перезагрузка страницы — подтянуть новый Flutter web build.
void reloadApp() {
  web.window.location.reload();
}
