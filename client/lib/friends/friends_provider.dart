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

Future<int> _loadIncomingCount(FriendsRepository repo) async {
  try {
    final snapshot = await repo.getFriends();
    return snapshot.incoming.length;
  } catch (_) {
    return 0;
  }
}

final friendsIncomingCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    yield 0;
    return;
  }

  final repo = ref.watch(friendsRepositoryProvider);
  yield await _loadIncomingCount(repo);

  var disposed = false;
  ref.onDispose(() {
    disposed = true;
  });

  while (!disposed) {
    await Future<void>.delayed(const Duration(seconds: 30));
    if (disposed) break;
    yield await _loadIncomingCount(repo);
  }
});
