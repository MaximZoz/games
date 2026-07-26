import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/achievements/achievements_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(ref.watch(authRepositoryProvider));
});

final achievementsListProvider =
    FutureProvider.autoDispose<List<AchievementItem>>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return const [];
  return ref.watch(achievementsRepositoryProvider).list();
});

final achievementsUnclaimedCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return 0;
  return ref.watch(achievementsRepositoryProvider).unclaimedCount();
});
