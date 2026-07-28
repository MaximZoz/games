import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/achievements/achievements_repository.dart';

AchievementItem item(String code, String status) => AchievementItem(
      code: code,
      title: code,
      description: '',
      rewardBronze: 0,
      progress: 0,
      target: 1,
      status: status,
    );

void main() {
  test('sortAchievements: unlocked → locked → claimed', () {
    final sorted = sortAchievements([
      item('a', 'claimed'),
      item('b', 'locked'),
      item('c', 'unlocked'),
      item('d', 'locked'),
      item('e', 'unlocked'),
    ]);
    expect(sorted.map((e) => e.status).toList(), [
      'unlocked',
      'unlocked',
      'locked',
      'locked',
      'claimed',
    ]);
  });

  test('sortAchievements preserves relative order within rank', () {
    final sorted = sortAchievements([
      item('first', 'locked'),
      item('second', 'locked'),
    ]);
    expect(sorted[0].code, 'first');
    expect(sorted[1].code, 'second');
  });

  test('unknown status ranks last', () {
    final sorted = sortAchievements([
      item('x', 'weird'),
      item('y', 'unlocked'),
    ]);
    expect(sorted.first.status, 'unlocked');
    expect(sorted.last.status, 'weird');
  });
}
