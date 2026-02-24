import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final friendsSnapshotProvider = StreamProvider.autoDispose<FriendsSnapshot>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return Stream<FriendsSnapshot>.value(
      FriendsSnapshot(
        friends: const [],
        incoming: const [],
        outgoing: const [],
      ),
    );
  }

  final repo = ref.watch(friendsRepositoryProvider);
  final controller = StreamController<FriendsSnapshot>();
  var loadInFlight = false;

  Future<void> load() async {
    if (loadInFlight) return;
    loadInFlight = true;
    try {
      final snapshot = await repo.getFriends();
      if (!controller.isClosed) controller.add(snapshot);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    } finally {
      loadInFlight = false;
    }
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final type = next.valueOrNull?['type']?.toString() ?? '';
      if (type == 'friends_updated' || type == 'realtime_connected') {
        unawaited(load());
      }
    },
  );

  unawaited(load());

  ref.onDispose(() {
    keepAliveLink.close();
    unawaited(controller.close());
  });

  return controller.stream;
});

final friendsIncomingCountProvider = Provider<int>((ref) {
  final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
  return snapshot?.incoming.length ?? 0;
});

Future<void> refreshFriendsSnapshot(WidgetRef ref) async {
  ref.invalidate(friendsSnapshotProvider);
  await ref.read(friendsSnapshotProvider.future);
}
