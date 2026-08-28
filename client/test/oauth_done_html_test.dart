import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('oauth_done.html keeps PWA tokens out of Safari', () {
    final html = File('web/oauth_done.html').readAsStringSync();
    expect(html, contains("params.get('pwa') === '1'"));
    expect(html, contains('isStandalone'));
    expect(html, contains('Откройте Zozu Games с экрана «Домой»'));
    expect(html, isNot(contains("location.replace('/login?' + q);")));
  });
}
