import 'package:flutter/foundation.dart';
import 'package:multigames_client/games/durak/card.dart';

/// Пока карта на overlay или вытаскивается, слот в веере без лица.
/// Иначе на iOS/Impeller (PWA) остаётся «призрак» рядом с копией под пальцем.
bool fanSlotHidesFace({
  required PlayingCard card,
  PlayingCard? liftedCard,
  PlayingCard? peekCard,
  Set<PlayingCard>? parentHidden,
}) {
  if (liftedCard != null && card == liftedCard) return true;
  if (peekCard != null && card == peekCard) return true;
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

/// Отдельный слой лица при вытаскивании — не слот веера.
Key fanPeekOverlayKey(PlayingCard card) {
  return ValueKey<String>(
    'fan-peek-${card.rank.value}-${card.suit.name}',
  );
}

/// Peek/hide — мгновенно. Не переключать Positioned ↔ AnimatedPositioned:
/// на iOS старый слой остаётся в веере, overlay рисует вторую копию.
Duration fanSlotMoveDuration({required bool instant}) {
  return Duration(milliseconds: instant ? 0 : 340);
}
