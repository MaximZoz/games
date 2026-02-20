import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final friendsSnapshotProvider = FutureProvider.autoDispose<FriendsSnapshot>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getFriends();
});
