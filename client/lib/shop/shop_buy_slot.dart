import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/l10n.dart';

/// Кнопка покупки: пока запрос идёт — «…», как у эликсира.
/// Разовая покупка после успеха — только слово «Есть», без кнопки.
class ShopBuySlot extends StatelessWidget {
  const ShopBuySlot({
    super.key,
    required this.onBuy,
    this.busy = false,
    this.owned = false,
    this.once = false,
    this.buyLabel,
  });

  final VoidCallback onBuy;
  final bool busy;
  final bool owned;

  /// true — предмет покупается один раз (коллекция, рамка, ставка, пак).
  final bool once;
  final String? buyLabel;

  @override
  Widget build(BuildContext context) {
    if (once && owned) {
      return Text(
        context.l10n.shopHave,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
        ),
      );
    }
    return FilledButton(
      onPressed: busy ? null : onBuy,
      child: Text(busy ? '…' : (buyLabel ?? context.l10n.shopBuy)),
    );
  }
}
