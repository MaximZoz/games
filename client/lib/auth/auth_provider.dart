import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/profile_extra.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getStoredUser();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthStateNotifier(ref);
});

/// Значение daily_reward из WebSocket (при подключении и после claim). Null = ещё не получено.
final dailyRewardFromRealtimeProvider = StateProvider<bool?>((ref) => null);

/// Доступна ли ежедневная награда (20 бронзы). Приоритет у значения из WebSocket.
final dailyRewardAvailableProvider = FutureProvider<bool>((ref) async {
  final fromWs = ref.watch(dailyRewardFromRealtimeProvider);
  if (fromWs != null) return fromWs;
  final repo = ref.watch(authRepositoryProvider);
  return repo.getDailyRewardAvailable();
});

/// Расширенные данные профиля — берём напрямую из AuthUser (данные уже в БД).
final profileExtraProvider = Provider<AsyncValue<ProfileExtra?>>((ref) {
  return ref.watch(authStateProvider).whenData((user) {
    if (user == null) return null;
    return ProfileExtra(
      age: user.age,
      gender: user.gender,
      about: user.about,
      avatarKind: AvatarKind.values.firstWhere(
        (e) => e.name == user.avatarKind,
        orElse: () => AvatarKind.letter,
      ),
      avatarValue: user.avatarValue,
    );
  });
});

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final Ref _ref;

  Future<void> _loadUser() async {
    final repo = _ref.read(authRepositoryProvider);
    try {
      final cached = await repo.getStoredUser();
      state = AsyncValue.data(cached);
      final fresh = await repo.fetchCurrentUser();
      if (fresh != null) {
        state = AsyncValue.data(fresh);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.register(email: email, password: password, displayName: displayName);
    state = AsyncValue.data(result.user);
  }

  Future<void> login({required String email, required String password}) async {
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.login(email: email, password: password);
    state = AsyncValue.data(result.user);
  }

  Future<void> logout() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    final repo = _ref.read(authRepositoryProvider);
    try {
      final user = await repo.fetchCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    await updateProfile(displayName: displayName);
  }

  /// Забирает ежедневную награду (20 бронзы). После успеха обновляет состояние и balance.
  Future<int?> claimDailyReward() async {
    final repo = _ref.read(authRepositoryProvider);
    final newBalance = await repo.claimDailyReward();
    _ref.read(dailyRewardFromRealtimeProvider.notifier).state = false;
    _ref.invalidate(dailyRewardAvailableProvider);
    if (newBalance == null) return null;
    final user = state.valueOrNull;
    if (user != null) {
      final updated = AuthUser(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        isAdmin: user.isAdmin,
        age: user.age,
        gender: user.gender,
        about: user.about,
        avatarKind: user.avatarKind,
        avatarValue: user.avatarValue,
        balanceBronze: newBalance,
      );
      state = AsyncValue.data(updated);
      await repo.updateStoredUser(updated);
    }
    return newBalance;
  }

  /// Обновляет профиль пользователя на бэкенде. Все поля сохраняются в БД.
  Future<void> updateProfile({
    String? displayName,
    ProfileExtra? extra,
  }) async {
    final repo = _ref.read(authRepositoryProvider);
    final user = state.valueOrNull;
    if (user == null) return;
    try {
      final updated = await repo.updateProfile(
        displayName: displayName ?? user.displayName,
        age: extra?.age,
        gender: extra?.gender,
        about: extra?.about,
        avatarKind: extra?.avatarKind.name,
        avatarValue: extra?.avatarValue,
      );
      state = AsyncValue.data(updated);
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        state = const AsyncValue.data(null);
      }
      rethrow;
    }
  }
}
