import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/utils/user_error.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final friendsSnapshotProvider =
    StreamProvider.autoDispose<FriendsSnapshot>((ref) {
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
  FriendsSnapshot? latest;
  var transientFailures = 0;
  Timer? recoverTimer;
  late final Future<void> Function() load;

  void scheduleRecover(Duration delay) {
    recoverTimer?.cancel();
    recoverTimer = Timer(delay, () => unawaited(load()));
  }

  load = () async {
    if (loadInFlight) return;
    recoverTimer?.cancel();
    loadInFlight = true;
    try {
      final snapshot = await repo.getFriends();
      latest = snapshot;
      transientFailures = 0;
      if (!controller.isClosed) controller.add(snapshot);
    } catch (e, st) {
      final action = loadFailureAction(
        error: e,
        hasData: latest != null,
        failures: transientFailures,
      );
      if (action == LoadFailureAction.retrySoon) {
        transientFailures++;
        scheduleRecover(Duration(milliseconds: 700 * transientFailures));
      } else if (action == LoadFailureAction.showError) {
        if (!controller.isClosed) controller.addError(e, st);
        if (isTransientLoadError(e)) {
          scheduleRecover(const Duration(seconds: 12));
        }
      } else if (isTransientLoadError(e)) {
        scheduleRecover(const Duration(seconds: 12));
      }
    } finally {
      loadInFlight = false;
    }
  };

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
    recoverTimer?.cancel();
    keepAliveLink.close();
    unawaited(controller.close());
  });

  return controller.stream;
});

final friendsIncomingCountProvider = Provider<int>((ref) {
  final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
  return snapshot?.incoming.length ?? 0;
});

/// Общее количество зарегистрированных пользователей. Обновляется каждые 30 сек,
/// только когда пользователь находится на экране «Друзья».
///
/// Вне экрана — `null` (не `0`), иначе при открытии «Друзья» мелькает 0.
/// Повторный опрос не сбрасывает провайдер: бейдж остаётся на месте.
final totalUsersCountProvider =
    AsyncNotifierProvider.autoDispose<TotalUsersCountNotifier, int?>(
        TotalUsersCountNotifier.new);

class TotalUsersCountNotifier extends AutoDisposeAsyncNotifier<int?> {
  static const _pollInterval = Duration(seconds: 30);
  Timer? _pollTimer;
  int _generation = 0;
  bool _disposeHooked = false;

  @override
  Future<int?> build() async {
    _pollTimer?.cancel();
    final generation = ++_generation;
    if (!_disposeHooked) {
      _disposeHooked = true;
      ref.onDispose(() {
        _generation++;
        _pollTimer?.cancel();
        _pollTimer = null;
      });
    }
    final user = ref.watch(authStateProvider).valueOrNull;
    final path = ref.watch(currentRoutePathProvider);
    final onFriends = path == '/friends';
    if (user == null || !onFriends) return null;
    final count = await ref.read(friendsRepositoryProvider).getUsersCount();
    if (generation != _generation) return count;
    _schedulePoll(generation);
    return count;
  }

  void _schedulePoll(int generation) {
    _pollTimer?.cancel();
    if (generation != _generation) return;
    _pollTimer = Timer(_pollInterval, () {
      unawaited(_poll(generation));
    });
  }

  Future<void> _poll(int generation) async {
    if (generation != _generation) return;
    try {
      final count = await ref.read(friendsRepositoryProvider).getUsersCount();
      if (generation != _generation) return;
      state = AsyncData(count);
    } catch (_) {
      // Последнее число остаётся на бейдже.
    }
    if (generation != _generation) return;
    _schedulePoll(generation);
  }
}

Future<void> refreshFriendsSnapshot(WidgetRef ref) async {
  ref.invalidate(friendsSnapshotProvider);
  await ref.read(friendsSnapshotProvider.future);
}
