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

/// Свежая партия: руки по 6, стол пуст — крутить раздачу из колоды в веер.
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
  if (myIndex < 0 || myHandLen <= 0) return false;
  final n = handCounts.length;
  if (n < 2) return false;
  const handSize = 6;
  if (myHandLen != handSize) return false;
  for (final c in handCounts) {
    if (c != handSize) return false;
  }
  final expectedDeck = deckSize - n * handSize;
  return deckCount == expectedDeck && expectedDeck >= 0;
}
