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
