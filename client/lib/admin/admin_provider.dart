import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(authRepository: ref.watch(authRepositoryProvider));
});

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUserItem>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listUsers();
});
