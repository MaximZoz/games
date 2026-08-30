import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/durak/card.dart';

/// Пока карта на overlay, слот в веере остаётся, но лицо скрыто.
/// Иначе на iOS/Impeller остаётся «призрак» вытащенной карты.
bool fanSlotHidesFace({
  required PlayingCard card,
  PlayingCard? liftedCard,
  PlayingCard? peekCard,
  bool hidePeekUnderOverlay = false,
  Set<PlayingCard>? parentHidden,
}) {
  if (liftedCard != null && card == liftedCard) return true;
  if (hidePeekUnderOverlay && peekCard != null && card == peekCard) {
    return true;
  }
  return parentHidden?.contains(card) == true;
}

/// Ключ слота. При hide меняется — Impeller обязан выбросить слой лица.
/// Нельзя оставлять тот же key и только подменить ребёнка на SizedBox.
Key fanSlotPaintKey({
  required PlayingCard card,
  required bool hidden,
}) {
  return ValueKey<String>(
    'fan-slot-${card.rank.value}-${card.suit.name}-${hidden ? 'h' : 'v'}',
  );
}

/// Peek/hide — мгновенно. Не переключать Positioned ↔ AnimatedPositioned:
/// на iOS старый слой остаётся в веере, overlay рисует вторую копию.
Duration fanSlotMoveDuration({required bool instant}) {
  return Duration(milliseconds: instant ? 0 : 340);
}
