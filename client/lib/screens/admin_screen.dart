import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/admin/admin_provider.dart';
import 'package:multigames_client/admin/admin_repository.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String? _error;
  String? _success;

  Future<void> _setAdmin(AdminRepository repo, String userId, bool isAdmin) async {
    setState(() {
      _error = null;
      _success = null;
    });
    try {
      await repo.setAdmin(userId, isAdmin);
      if (mounted) {
        setState(() => _success = isAdmin ? 'Назначен админом' : 'Сняты права админа');
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is AdminException ? e.message : e.toString());
    }
  }

  Future<void> _resetPassword(AdminRepository repo, AdminUserItem user) async {
    final controller = TextEditingController();
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Сбросить пароль: ${user.email}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Новый пароль (мин. 6 символов)',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length >= 6) Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (done != true || !mounted) return;
    final newPassword = controller.text;
    if (newPassword.length < 6) return;
    setState(() {
      _error = null;
      _success = null;
    });
    try {
      await repo.resetPassword(user.id, newPassword);
      if (mounted) {
        setState(() => _success = 'Пароль обновлён');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is AdminException ? e.message : e.toString());
    }
  }

  Future<void> _deleteUser(AdminRepository repo, AdminUserItem user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text('Будет удалён аккаунт: ${user.email}. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() {
      _error = null;
      _success = null;
    });
    try {
      await repo.deleteUser(user.id);
      if (mounted) {
        setState(() => _success = 'Пользователь удалён');
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is AdminException ? e.message : e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Управление пользователями',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Обновить список',
                    onPressed: () => ref.invalidate(adminUsersProvider),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[800]))),
                    ],
                  ),
                ),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_success!, style: TextStyle(color: Colors.green[800])),
                ),
              ),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const Center(child: Text('Нет пользователей'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (u.displayName != null && u.displayName!.isNotEmpty)
                                          Text(
                                            u.displayName!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (u.isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Админ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple[900],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () => _setAdmin(repo, u.id, !u.isAdmin),
                                    child: Text(u.isAdmin ? 'Убрать админа' : 'Сделать админом'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _resetPassword(repo, u),
                                    child: const Text('Сбросить пароль'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _deleteUser(repo, u),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
                        const SizedBox(height: 16),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
