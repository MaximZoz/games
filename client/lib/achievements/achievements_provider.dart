import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/achievements/achievements_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(ref.watch(authRepositoryProvider));
});

/// Сортировка при открытии: сначала «Забрать», потом прогресс, потом полученные.
List<AchievementItem> sortAchievements(List<AchievementItem> items) {
  int rank(String status) {
    switch (status) {
      case 'unlocked':
        return 0;
      case 'locked':
        return 1;
      case 'claimed':
        return 2;
      default:
        return 3;
    }
  }

  final copy = List<AchievementItem>.from(items);
  copy.sort((a, b) => rank(a.status).compareTo(rank(b.status)));
  return copy;
}

/// Кэш списка (не autoDispose) — при повторном входе сразу есть данные.
final achievementsListProvider =
    FutureProvider<List<AchievementItem>>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return const [];
  final items = await ref.watch(achievementsRepositoryProvider).list();
  return sortAchievements(items);
});

final achievementsUnclaimedCountProvider =
    FutureProvider<int>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return 0;
  return ref.watch(achievementsRepositoryProvider).unclaimedCount();
});
