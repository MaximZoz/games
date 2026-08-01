import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/achievements/achievements_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';

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
  final offline = ref.watch(isOfflineProvider);
  if (offline) {
    final cached = await OfflineDiskCache.loadAchievements(auth.id);
    return sortAchievements(cached ?? const []);
  }
  try {
    final items = await ref.watch(achievementsRepositoryProvider).list();
    final sorted = sortAchievements(items);
    await OfflineDiskCache.saveAchievements(auth.id, sorted);
    return sorted;
  } catch (_) {
    final cached = await OfflineDiskCache.loadAchievements(auth.id);
    if (cached != null) return sortAchievements(cached);
    rethrow;
  }
});

final achievementsUnclaimedCountProvider =
    FutureProvider<int>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return 0;
  final offline = ref.watch(isOfflineProvider);
  if (offline) {
    final cached = await OfflineDiskCache.loadAchievements(auth.id);
    if (cached == null) return 0;
    return cached.where((e) => e.isUnlocked).length;
  }
  try {
    return await ref.watch(achievementsRepositoryProvider).unclaimedCount();
  } catch (_) {
    final cached = await OfflineDiskCache.loadAchievements(auth.id);
    if (cached != null) {
      return cached.where((e) => e.isUnlocked).length;
    }
    rethrow;
  }
});
