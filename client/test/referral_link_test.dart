import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/referral_link.dart';

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
}
