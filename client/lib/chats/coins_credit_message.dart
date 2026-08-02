/// Токен чата: `[coins_credit:<grantId>|<amountBronze>|<reason>]`
/// или `[coins_credit:<grantId>|<amountBronze>|<reason>|claimed]`.
final RegExp coinsCreditTokenRe = RegExp(
  r'^\[coins_credit:([0-9a-fA-F-]{36})\|(-?\d+)\|([^|\]]*)(?:\|(claimed))?\]$',
);

class CoinsCreditPayload {
  const CoinsCreditPayload({
    required this.grantId,
    required this.amountBronze,
    required this.reason,
    required this.claimed,
  });

  final String grantId;
  final int amountBronze;
  final String reason;
  final bool claimed;
}

CoinsCreditPayload? parseCoinsCreditMessage(String body) {
  final m = coinsCreditTokenRe.firstMatch(body.trim());
  if (m == null) return null;
  final amount = int.tryParse(m.group(2) ?? '');
  if (amount == null) return null;
  return CoinsCreditPayload(
    grantId: m.group(1)!.trim(),
    amountBronze: amount,
    reason: (m.group(3) ?? '').trim(),
    claimed: m.group(4) == 'claimed',
  );
}

bool isCoinsCreditMessage(String body) =>
    parseCoinsCreditMessage(body) != null;
