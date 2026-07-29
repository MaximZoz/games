import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/utils/relative_time.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  group('formatLastSeen', () {
    test('empty / invalid', () {
      expect(formatLastSeen(null), '');
      expect(formatLastSeen(''), '');
      expect(formatLastSeen('not-a-date'), '');
    });

    test('relative buckets', () {
      final now = DateTime.now();
      expect(
        formatLastSeenFromDateTime(now.subtract(const Duration(seconds: 10))),
        'только что',
      );
      expect(
        formatLastSeenFromDateTime(now.subtract(const Duration(minutes: 3))),
        '3 мин назад',
      );
      expect(
        formatLastSeenFromDateTime(now.subtract(const Duration(hours: 2))),
        '2 ч назад',
      );
      expect(
        formatLastSeenFromDateTime(now.subtract(const Duration(days: 1))),
        'вчера',
      );
      expect(
        formatLastSeenFromDateTime(now.subtract(const Duration(days: 3))),
        '3 дн. назад',
      );
      expect(
        formatLastSeenFromDateTime(now.subtract(const Duration(days: 10))),
        'неделю назад',
      );
    });
  });

  group('formatChatListDateTime', () {
    test('invalid → empty', () {
      expect(formatChatListDateTime(null), '');
      expect(formatChatListDateTime('bad'), '');
    });

    test('today shows time', () {
      final now = DateTime.now();
      final iso = DateTime(now.year, now.month, now.day, 9, 5)
          .toUtc()
          .toIso8601String();
      final out = formatChatListDateTime(iso);
      expect(out, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('yesterday label', () {
      final now = DateTime.now();
      final y = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      final iso = y.toUtc().toIso8601String();
      expect(formatChatListDateTime(iso), 'вчера');
    });
  });
}
