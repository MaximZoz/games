import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(authRepository: ref.watch(authRepositoryProvider));
});

/// Состояние списка пользователей админки: накопленные пользователи + total.
class AdminUsersState {
  const AdminUsersState({
    required this.users,
    required this.total,
    required this.query,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final List<AdminUserItem> users;
  final int total;
  final AdminUsersQuery query;
  final bool hasMore;
  final bool isLoadingMore;

  AdminUsersState copyWith({
    List<AdminUserItem>? users,
    int? total,
    AdminUsersQuery? query,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AdminUsersNotifier extends AutoDisposeAsyncNotifier<AdminUsersState> {
  @override
  Future<AdminUsersState> build() async {
    final repo = ref.watch(adminRepositoryProvider);
    final page = await repo.listUsers(const AdminUsersQuery());
    return AdminUsersState(
      users: page.users,
      total: page.total,
      query: const AdminUsersQuery(),
      hasMore: page.users.length >= 20 && page.users.length < page.total,
      isLoadingMore: false,
    );
  }

  AdminUsersState? get _current => state.valueOrNull;

  /// Сбросить запрос (поиск/сортировка/фильтр) и перезагрузить с первой страницы.
  Future<void> setQuery(AdminUsersQuery query) async {
    final repo = ref.read(adminRepositoryProvider);
    state = const AsyncLoading();
    try {
      final page = await repo.listUsers(query);
      state = AsyncData(AdminUsersState(
        users: page.users,
        total: page.total,
        query: query,
        hasMore: page.users.length >= query.limit && page.users.length < page.total,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Догрузить следующую страницу (пагинация по скроллу).
  Future<void> loadMore() async {
    final current = _current;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    final repo = ref.read(adminRepositoryProvider);
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextQuery = current.query.copyWith(offset: current.users.length);
      final page = await repo.listUsers(nextQuery);
      // Дедуп по id.
      final existing = {for (final u in current.users) u.id};
      final merged = [...current.users, ...page.users.where((u) => !existing.contains(u.id))];
      state = AsyncData(AdminUsersState(
        users: merged,
        total: page.total,
        query: current.query,
        hasMore: page.users.length >= current.query.limit && merged.length < page.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final adminUsersProvider =
    AutoDisposeAsyncNotifierProvider<AdminUsersNotifier, AdminUsersState>(
  AdminUsersNotifier.new,
);

/// Список диалогов поддержки.
final supportChatsProvider =
    FutureProvider.autoDispose<List<SupportChatItem>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listSupportChats();
});

/// Сумма непрочитанных обращений в поддержку (для бейджа у админа).
final supportUnreadTotalProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(supportChatsProvider).whenData(
        (items) => items.fold<int>(0, (sum, c) => sum + c.unreadCount),
      );
});

/// Следит за WS и обновляет inbox поддержки при новых сообщениях.
/// Нужно watch'ить в shell/админке, пока админ онлайн.
final supportInboxRealtimeProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventsProvider,
      (_, next) {
    next.whenData((event) {
      if (event['type'] == 'support_message') {
        ref.invalidate(supportChatsProvider);
      }
    });
  });
});
