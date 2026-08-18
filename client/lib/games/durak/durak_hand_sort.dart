import 'package:multigames_client/games/durak/card.dart';

/// Сортировка руки как на сервере: не-козыри по масти/рангу, затем козыри.
int compareDurakHandCards(PlayingCard a, PlayingCard b, Suit trump) {
  final at = a.suit == trump ? 1 : 0;
  final bt = b.suit == trump ? 1 : 0;
  if (at != bt) return at.compareTo(bt);
  final s = a.suit.index.compareTo(b.suit.index);
  if (s != 0) return s;
  return a.rank.compareTo(b.rank);
}

void sortDurakHand(List<PlayingCard> hand, Suit trump) {
  hand.sort((a, b) => compareDurakHandCards(a, b, trump));
}

/// Младший козырь в руке — им определяется первый ход.
PlayingCard? lowestTrumpInHand(Iterable<PlayingCard> hand, Suit trump) {
  PlayingCard? best;
  for (final c in hand) {
    if (c.suit != trump) continue;
    if (best == null || c.rank.value < best.rank.value) best = c;
  }
  return best;
}

/// У кого младший козырь среди всех рук; null — козыря ни у кого нет.
int? lowestTrumpOwner(List<List<PlayingCard>> hands, Suit trump) {
  int? owner;
  PlayingCard? best;
  for (var p = 0; p < hands.length; p++) {
    final card = lowestTrumpInHand(hands[p], trump);
    if (card == null) continue;
    if (best == null || card.rank.value < best.rank.value) {
      best = card;
      owner = p;
    }
  }
  return owner;
}

/// Если козыря нет — игроки по кругу берут по одной с верха колоды
/// (открытый козырь в конце не трогаем), пока козырь не появится.
/// Возвращает, у кого младший козырь после добора.
int? drawUntilTrumpAppears({
  required List<List<PlayingCard>> hands,
  required List<PlayingCard> deck,
  required Suit trump,
}) {
  var owner = lowestTrumpOwner(hands, trump);
  if (owner != null) return owner;
  while (owner == null && deck.length > 1) {
    for (var p = 0; p < hands.length; p++) {
      if (deck.length <= 1) break;
      hands[p].add(deck.removeAt(0));
      owner = lowestTrumpOwner(hands, trump);
      if (owner != null) return owner;
    }
  }
  return owner;
}

/// Свежая партия: руки полные (6+ добор козыря), стол пуст — крутить раздачу.
bool shouldAnimateDurakOpeningDeal({
  required bool isOver,
  required bool tableIsEmpty,
  required int bitoCount,
  required int myIndex,
  required int myHandLen,
  required List<int> handCounts,
  required int deckSize,
  required int deckCount,
}) {
  if (isOver || !tableIsEmpty || bitoCount > 0) return false;
  if (myIndex < 0 || myHandLen < 6) return false;
  final n = handCounts.length;
  if (n < 2) return false;
  const handSize = 6;
  var total = 0;
  var minH = 1 << 20;
  var maxH = 0;
  for (final c in handCounts) {
    if (c < handSize) return false;
    total += c;
    if (c < minH) minH = c;
    if (c > maxH) maxH = c;
  }
  if (maxH - minH > 1) return false;
  if (myHandLen != handCounts[myIndex]) return false;
  final expectedDeck = deckSize - total;
  return deckCount == expectedDeck && expectedDeck >= 0;
}
