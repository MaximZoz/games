import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_repository.dart';

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

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final Ref _ref;

  Future<void> _loadUser() async {
    final repo = _ref.read(authRepositoryProvider);
    try {
      final user = await repo.getStoredUser();
      state = AsyncValue.data(user);
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

  void refresh() {
    _loadUser();
  }
}
