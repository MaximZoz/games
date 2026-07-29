import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/profile_extra.dart';
import 'package:multigames_client/auth/session_cache.dart';
import 'package:multigames_client/core/web_push_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getStoredUser();
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthStateNotifier(ref);
});

/// Значение daily_reward из WebSocket (при подключении и после claim). Null = ещё не получено.
final dailyRewardFromRealtimeProvider = StateProvider<bool?>((ref) => null);

/// Полный статус ежедневной награды (серия, сумма).
final dailyRewardStatusProvider =
    FutureProvider<DailyRewardStatus>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return DailyRewardStatus.empty;
  }
  final repo = ref.watch(authRepositoryProvider);
  final status = await repo.getDailyRewardStatus();
  final fromWs = ref.watch(dailyRewardFromRealtimeProvider);
  if (fromWs == null) return status;
  return DailyRewardStatus(
    available: fromWs,
    streak: status.streak,
    nextStreak: status.nextStreak,
    nextRewardBronze: status.nextRewardBronze,
    milestonesBronze: status.milestonesBronze,
  );
});

/// Доступна ли ежедневная награда (из статуса / WebSocket).
final dailyRewardAvailableProvider = FutureProvider<bool>((ref) async {
  final status = await ref.watch(dailyRewardStatusProvider.future);
  return status.available;
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
    String? ref,
  }) async {
    clearUserScopedCaches(_ref);
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.register(
      email: email,
      password: password,
      displayName: displayName,
      ref: ref,
    );
    state = AsyncValue.data(result.user);
    // Новым аккаунтам по умолчанию включаем Web Push (запрос permission).
    unawaited(_enablePushForNewUser());
  }

  Future<void> _enablePushForNewUser() async {
    try {
      await _ref.read(webPushEnabledProvider.notifier).enableForNewUser();
    } catch (_) {}
  }

  Future<void> login({required String email, required String password}) async {
    clearUserScopedCaches(_ref);
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.login(email: email, password: password);
    state = AsyncValue.data(result.user);
  }

  Future<void> logout() async {
    // Сначала снять Web Push (нужен ещё живой access token).
    try {
      await _ref.read(webPushEnabledProvider.notifier).detachOnLogout();
    } catch (_) {}
    final repo = _ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
    clearUserScopedCaches(_ref);
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

  /// Обновляет баланс в state после клейма достижения / награды.
  Future<void> applyBalance(int balanceBronze) async {
    final user = state.valueOrNull;
    if (user == null) return;
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
      balanceBronze: balanceBronze,
    );
    state = AsyncValue.data(updated);
    await _ref.read(authRepositoryProvider).updateStoredUser(updated);
  }

  /// Забирает ежедневную награду по серии дней. После успеха обновляет balance.
  Future<DailyRewardClaimResult?> claimDailyReward() async {
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.claimDailyReward();
    _ref.read(dailyRewardFromRealtimeProvider.notifier).state = false;
    _ref.invalidate(dailyRewardStatusProvider);
    _ref.invalidate(dailyRewardAvailableProvider);
    if (result == null) return null;
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
        balanceBronze: result.balanceBronze,
      );
      state = AsyncValue.data(updated);
      await repo.updateStoredUser(updated);
    }
    return result;
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
        clearUserScopedCaches(_ref);
      }
      rethrow;
    }
  }
}
