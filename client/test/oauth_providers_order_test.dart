import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/widgets/oauth_buttons.dart';

void main() {
  test('iOS puts Apple above Google even if the server omitted Apple', () {
    expect(
      visibleOAuthProviders(['google', 'yandex'], isIos: true),
      ['apple', 'google', 'yandex'],
    );
  });

  test('iOS does not duplicate Apple when the server already sent it', () {
    expect(
      visibleOAuthProviders(['google', 'apple'], isIos: true),
      ['apple', 'google'],
    );
  });

  test('Android / web keep the server order and do not inject Apple', () {
    expect(
      visibleOAuthProviders(['google'], isIos: false),
      ['google'],
    );
    expect(
      visibleOAuthProviders(['apple', 'google'], isIos: false),
      ['apple', 'google'],
    );
  });
}
