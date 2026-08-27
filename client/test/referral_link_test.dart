import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/referral_link.dart';
import 'package:multigames_client/core/api_config.dart';

void main() {
  test('buildReferralShareUrl', () {
    final url = buildReferralShareUrl(
      userId: '550e8400-e29b-41d4-a716-446655440000',
      baseUri: Uri.parse('https://example.com/games'),
    );
    expect(
      url,
      'https://example.com/register?ref=550e8400-e29b-41d4-a716-446655440000',
    );
  });

  test('shareLinkBaseUri is https/http for native default API_BASE', () {
    // VM-тесты = не web → берётся apiBaseUrl (localhost по умолчанию).
    expect(shareLinkBaseUri.scheme, anyOf('http', 'https'));
    expect(shareLinkBaseUri.host, isNotEmpty);
  });
}
