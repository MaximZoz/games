import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/src/telegram_web_app_stub.dart';

void main() {
  test('configureTelegramWebApp stub is a no-op outside web', () {
    // На VM/тестах используется stub — не должен бросать.
    expect(() => configureTelegramWebApp(), returnsNormally);
  });
}
