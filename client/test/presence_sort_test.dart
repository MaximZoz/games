import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/core/presence_sort.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  group('comparePresenceOnlineFirst', () {
    test('online before offline', () {
      final online = PresenceEntry(online: true);
      final offline = PresenceEntry(
        online: false,
        lastSeenAt: DateTime.now().toUtc().toIso8601String(),
      );
      expect(comparePresenceOnlineFirst(online, offline), lessThan(0));
      expect(comparePresenceOnlineFirst(offline, online), greaterThan(0));
    });

    test('offline: more recent lastSeen first', () {
      final recent = PresenceEntry(
        online: false,
        lastSeenAt: DateTime.now().toUtc().toIso8601String(),
      );
      final old = PresenceEntry(
        online: false,
        lastSeenAt: DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      );
      expect(comparePresenceOnlineFirst(recent, old), lessThan(0));
      expect(comparePresenceOnlineFirst(old, recent), greaterThan(0));
    });

    test('null lastSeen after known offline', () {
      final known = PresenceEntry(
        online: false,
        lastSeenAt: DateTime.now().toUtc().toIso8601String(),
      );
      final unknown = PresenceEntry(online: false);
      expect(comparePresenceOnlineFirst(known, unknown), lessThan(0));
      expect(comparePresenceOnlineFirst(unknown, known), greaterThan(0));
    });
  });

  group('formatPresenceStatus', () {
    test('online', () {
      expect(
        formatPresenceStatus(PresenceEntry(online: true)),
        'Онлайн',
      );
    });

    test('offline relative', () {
      final entry = PresenceEntry(
        online: false,
        lastSeenAt: DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      );
      expect(formatPresenceStatus(entry), '5 мин назад');
    });
  });

  group('sortByPresenceOnlineFirst', () {
    test('orders ids online → recent → old', () {
      final now = DateTime.now().toUtc();
      final presence = {
        'a': PresenceEntry(online: false, lastSeenAt: now.subtract(const Duration(days: 30)).toIso8601String()),
        'b': PresenceEntry(online: true),
        'c': PresenceEntry(online: false, lastSeenAt: now.subtract(const Duration(hours: 1)).toIso8601String()),
      };
      final ids = ['a', 'b', 'c'];
      sortByPresenceOnlineFirst(ids, (id) => id, presence);
      expect(ids, ['b', 'c', 'a']);
    });
  });
}
