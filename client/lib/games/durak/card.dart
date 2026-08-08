import 'dart:math';

/// Масти в порядке отображения.
enum Suit {
  hearts, // ♥
  diamonds, // ♦
  clubs, // ♣
  spades, // ♠
}

const _suitSymbols = <Suit, String>{
  Suit.hearts: '♥',
  Suit.diamonds: '♦',
  Suit.clubs: '♣',
  Suit.spades: '♠',
};

extension SuitLabel on Suit {
  String get symbol => _suitSymbols[this]!;
  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

/// Ранг карты: значение возрастает от 2 (двойка) до 14 (туз).
class Rank implements Comparable<Rank> {
  const Rank(this.value) : assert(value >= 2 && value <= 14);

  final int value;

  static const two = Rank(2);
  static const three = Rank(3);
  static const four = Rank(4);
  static const five = Rank(5);
  static const six = Rank(6);
  static const seven = Rank(7);
  static const eight = Rank(8);
  static const nine = Rank(9);
  static const ten = Rank(10);
  static const jack = Rank(11);
  static const queen = Rank(12);
  static const king = Rank(13);
  static const ace = Rank(14);

  String get label {
    switch (value) {
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 14:
        return 'A';
      default:
        return value.toString();
    }
  }

  @override
  int compareTo(Rank other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Rank && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Игральная карта.
class PlayingCard {
  const PlayingCard(this.rank, this.suit);

  final Rank rank;
  final Suit suit;

  /// Козырная (masть козыря).
  bool isTrump(Suit trumpSuit) => suit == trumpSuit;

  /// Бьёт ли эта карта [target] при козыре [trump].
  bool beats(PlayingCard target, Suit trump) {
    if (isTrump(trump) && !target.isTrump(trump)) return true;
    if (!isTrump(trump) && target.isTrump(trump)) return false;
    if (suit != target.suit) return false;
    return rank.value > target.rank.value;
  }

  @override
  String toString() => '${rank.label}${suit.symbol}';

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);
}

/// Полная колода. Для «Дурака» стандартно 36 (от 6), иногда 24 (от 9) или 52 (от 2).
class Deck {
  Deck(this.cards);

  factory Deck.standard(int size, {int? seed}) {
    assert(size == 24 || size == 36 || size == 52, 'unsupported deck size');
    final minValue = switch (size) {
      24 => 9,
      36 => 6,
      52 => 2,
      _ => 6,
    };
    final list = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (var v = minValue; v <= 14; v++) {
        list.add(PlayingCard(Rank(v), suit));
      }
    }
    list.shuffle(seed == null ? Random.secure() : Random(seed));
    return Deck(list);
  }

  final List<PlayingCard> cards;

  bool get isEmpty => cards.isEmpty;
  bool get isNotEmpty => cards.isNotEmpty;
  int get length => cards.length;

  /// Верхняя карта колоды (следующая для добора).
  PlayingCard get top => cards.first;

  /// Взять до [n] карт с верха.
  List<PlayingCard> take(int n) {
    final k = n > cards.length ? cards.length : n;
    final out = cards.sublist(0, k);
    cards.removeRange(0, k);
    return out;
  }
}
