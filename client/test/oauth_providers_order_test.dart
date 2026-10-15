import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/apple_native_sign_in.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_config.dart';
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

  test('dev API host uses the dev return scheme', () {
    expect(
      oauthAppReturnSchemeForHost('multigameszozu-dev.fly.dev'),
      'zozugames-dev',
    );
    expect(oauthAppReturnSchemeForHost('localhost'), 'zozugames-dev');
    expect(
      oauthAppReturnSchemeForHost('multigameszozu.fly.dev'),
      'zozugames',
    );
  });

  test('oauth errors keep the server or platform message', () {
    expect(
      readableOauthError(AuthException(401, 'Неверные данные Apple'), 'fallback'),
      'Неверные данные Apple',
    );
    expect(
      readableOauthError(
        AppleSignInUnavailableException('Sign in with Apple (1000)'),
        'fallback',
      ),
      'Sign in with Apple (1000)',
    );
    expect(
      readableOauthError(
        PlatformException(code: 'apple_auth', message: 'not available'),
        'fallback',
      ),
      'not available',
    );
    expect(
      readableOauthError(AppleSignInUnavailableException(), 'fallback'),
      'fallback',
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
