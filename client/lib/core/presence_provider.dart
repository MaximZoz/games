import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Локальные overrides от user_online/user_offline (переопределяют fetched).
final _presenceOverridesProvider = StateProvider<Map<String, PresenceEntry>>((ref) => {});

/// Все ID пользователей, для которых нужен presence: пиры в чатах + друзья.
final _presenceUserIdsProvider = Provider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {};
  final ids = <String>{};
  final chats = ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
  for (final c in chats) {
    if (c.user.id.isNotEmpty) ids.add(c.user.id);
  }
  final friendsSnap = ref.watch(friendsSnapshotProvider).valueOrNull;
  if (friendsSnap != null) {
    for (final f in friendsSnap.friends) {
      if (f.user.id.isNotEmpty) ids.add(f.user.id);
    }
    for (final r in friendsSnap.incoming) {
      if (r.user.id.isNotEmpty) ids.add(r.user.id);
    }
    for (final r in friendsSnap.outgoing) {
      if (r.user.id.isNotEmpty) ids.add(r.user.id);
    }
  }
  return ids;
});

/// Presence через StreamProvider — как chatsListProvider и friendsSnapshotProvider.
/// При user_online/user_offline вызываем load() и controller.add() — UI обновляется.
final presenceMapProvider = StreamProvider.autoDispose<Map<String, PresenceEntry>>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return Stream<Map<String, PresenceEntry>>.value(const {});
  }
  ref.watch(_presenceUserIdsProvider);

  final controller = StreamController<Map<String, PresenceEntry>>();
  var loadInFlight = false;
  Map<String, PresenceEntry>? lastFetched;

  void emitMerged(Map<String, PresenceEntry> fetched, Map<String, PresenceEntry> overrides) {
    final merged = Map<String, PresenceEntry>.from(fetched);
    for (final e in overrides.entries) {
      merged[e.key] = e.value;
    }
    if (!controller.isClosed) controller.add(merged);
  }

  Future<void> load() async {
    if (loadInFlight) return;
    loadInFlight = true;
    try {
      final userIds = ref.read(_presenceUserIdsProvider);
      if (userIds.isEmpty) {
        if (!controller.isClosed) controller.add(const {});
      } else {
        final fetched = await ref.read(presenceRepositoryProvider).getPresence(userIds.toList());
        lastFetched = fetched;
        final overrides = ref.read(_presenceOverridesProvider);
        emitMerged(fetched, overrides);
      }
    } catch (_) {
      if (!controller.isClosed) controller.add(lastFetched ?? const {});
    } finally {
      loadInFlight = false;
    }
  }

  void emitWithOverride(String uid, PresenceEntry entry) {
    final overrides = Map<String, PresenceEntry>.from(ref.read(_presenceOverridesProvider));
    overrides[uid] = entry;
    ref.read(_presenceOverridesProvider.notifier).state = overrides;
    final fetched = lastFetched ?? {};
    final merged = Map<String, PresenceEntry>.from(fetched);
    for (final e in overrides.entries) {
      merged[e.key] = e.value;
    }
    if (!controller.isClosed) controller.add(merged);
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventsProvider, (_, next) {
    final type = next.valueOrNull?['type']?.toString() ?? '';
    final uid = next.valueOrNull?['user_id']?.toString();
    if (type == 'user_online' || type == 'user_offline') {
      if (uid != null && uid.isNotEmpty) {
        final online = type == 'user_online';
        final lastSeen = next.valueOrNull?['last_seen_at']?.toString();
        emitWithOverride(uid, PresenceEntry(online: online, lastSeenAt: lastSeen));
      }
    } else if (type == 'realtime_connected') {
      unawaited(load());
    }
    // chat_message больше не триггерит полный reload presence —
    // в multi/групповом чате это давало шторм запросов на каждое сообщение.
  });

  final refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(load()));

  unawaited(load());

  ref.onDispose(() {
    refreshTimer.cancel();
    keepAliveLink.close();
    unawaited(controller.close());
  });

  return controller.stream;
});

/// Принудительно обновить presence с API.
void refreshPresence(WidgetRef ref) {
  ref.invalidate(presenceMapProvider);
}

/// Сброс локальных overrides при смене аккаунта.
void clearPresenceOverrides(Ref ref) {
  ref.read(_presenceOverridesProvider.notifier).state = const {};
}
