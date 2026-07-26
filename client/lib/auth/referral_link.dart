/// Публичная ссылка приглашения друга: регистрация с `?ref=<userId>`.
String buildReferralShareUrl({
  required String userId,
  required Uri baseUri,
}) {
  final id = userId.trim();
  final origin = baseUri.origin;
  return '$origin/register?ref=${Uri.encodeQueryComponent(id)}';
}

const referralBonusBronze = 50;
