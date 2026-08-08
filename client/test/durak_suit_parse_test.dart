import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';

void main() {
  group('DurakApiCard.toPlayingCard', () {
    test('letter suits map correctly', () {
      expect(const DurakApiCard(11, 'H').toPlayingCard().suit, Suit.hearts);
      expect(const DurakApiCard(11, 'D').toPlayingCard().suit, Suit.diamonds);
      expect(const DurakApiCard(11, 'C').toPlayingCard().suit, Suit.clubs);
      expect(const DurakApiCard(11, 'S').toPlayingCard().suit, Suit.spades);
    });

    test('legacy numeric suits map correctly (not all hearts)', () {
      expect(const DurakApiCard(6, '0').toPlayingCard().suit, Suit.hearts);
      expect(const DurakApiCard(6, '1').toPlayingCard().suit, Suit.diamonds);
      expect(const DurakApiCard(6, '2').toPlayingCard().suit, Suit.clubs);
      expect(const DurakApiCard(6, '3').toPlayingCard().suit, Suit.spades);
    });

    test('hand of mixed suits stays unique by suit+rank', () {
      final cards = [
        const DurakApiCard(11, 'H'),
        const DurakApiCard(11, 'D'),
        const DurakApiCard(7, 'C'),
        const DurakApiCard(7, 'S'),
      ].map((c) => c.toPlayingCard()).toList();
      final keys = cards.map((c) => '${c.rank.value}${c.suit.name}').toSet();
      expect(keys.length, 4);
      expect(cards.where((c) => c.suit == Suit.hearts).length, 1);
    });
  });
}
