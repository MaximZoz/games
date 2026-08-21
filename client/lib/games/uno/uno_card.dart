import 'dart:math';

enum UnoColor {
  red('red'),
  yellow('yellow'),
  green('green'),
  blue('blue'),
  wild('wild');

  const UnoColor(this.wireName);
  final String wireName;

  bool get isPlayableColor => this != UnoColor.wild;

  static UnoColor parse(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return values.firstWhere(
      (color) => color.wireName == raw,
      orElse: () => UnoColor.wild,
    );
  }
}

enum UnoCardKind {
  number('number'),
  skip('skip'),
  reverse('reverse'),
  drawTwo('draw_two'),
  wild('wild'),
  wildDrawFour('wild_draw_four');

  const UnoCardKind(this.wireName);
  final String wireName;

  bool get isWild =>
      this == UnoCardKind.wild || this == UnoCardKind.wildDrawFour;

  static UnoCardKind parse(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return values.firstWhere(
      (kind) => kind.wireName == raw,
      orElse: () => UnoCardKind.number,
    );
  }
}

class UnoCard {
  const UnoCard({
    required this.id,
    required this.color,
    required this.kind,
    this.number = 0,
  });

  final String id;
  final UnoColor color;
  final UnoCardKind kind;
  final int number;

  bool get isWild => kind.isWild;

  bool get isDrawStack =>
      kind == UnoCardKind.drawTwo || kind == UnoCardKind.wildDrawFour;

  bool stacksOn(UnoCard top) => isDrawStack && kind == top.kind;

  int get points => switch (kind) {
        UnoCardKind.number => number,
        UnoCardKind.skip || UnoCardKind.reverse || UnoCardKind.drawTwo => 20,
        UnoCardKind.wild || UnoCardKind.wildDrawFour => 50,
      };

  bool matches(UnoCard top, UnoColor currentColor) {
    if (isWild) return true;
    if (color == currentColor) return true;
    if (kind == UnoCardKind.number && top.kind == UnoCardKind.number) {
      return number == top.number;
    }
    return kind == top.kind && !kind.isWild;
  }

  factory UnoCard.fromJson(Map<String, dynamic> json) {
    return UnoCard(
      id: (json['id'] ?? '').toString(),
      color: UnoColor.parse(json['color']),
      kind: UnoCardKind.parse(json['kind']),
      number: (json['number'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.wireName,
        'kind': kind.wireName,
        'number': number,
      };

  @override
  bool operator ==(Object other) =>
      other is UnoCard &&
      id == other.id &&
      color == other.color &&
      kind == other.kind &&
      number == other.number;

  @override
  int get hashCode => Object.hash(id, color, kind, number);

  @override
  String toString() =>
      'UnoCard($id, ${color.wireName}, ${kind.wireName}, $number)';
}

/// Builds a standard 108-card UNO deck.
List<UnoCard> buildUnoDeck({int? seed, bool shuffle = true}) {
  final deck = <UnoCard>[];
  const colors = [
    UnoColor.red,
    UnoColor.yellow,
    UnoColor.green,
    UnoColor.blue,
  ];

  for (final color in colors) {
    deck.add(UnoCard(
      id: '${color.wireName}-0',
      color: color,
      kind: UnoCardKind.number,
    ));
    for (var number = 1; number <= 9; number++) {
      for (var copy = 1; copy <= 2; copy++) {
        deck.add(UnoCard(
          id: '${color.wireName}-$number-$copy',
          color: color,
          kind: UnoCardKind.number,
          number: number,
        ));
      }
    }
    for (final kind in const [
      UnoCardKind.skip,
      UnoCardKind.reverse,
      UnoCardKind.drawTwo,
    ]) {
      for (var copy = 1; copy <= 2; copy++) {
        deck.add(UnoCard(
          id: '${color.wireName}-${kind.wireName}-$copy',
          color: color,
          kind: kind,
        ));
      }
    }
  }

  for (var copy = 1; copy <= 4; copy++) {
    deck
      ..add(UnoCard(
        id: 'wild-$copy',
        color: UnoColor.wild,
        kind: UnoCardKind.wild,
      ))
      ..add(UnoCard(
        id: 'wild-draw-four-$copy',
        color: UnoColor.wild,
        kind: UnoCardKind.wildDrawFour,
      ));
  }

  if (shuffle) deck.shuffle(Random(seed));
  return deck;
}
