import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/admin/admin_provider.dart';
import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String? _error;
  String? _success;
  Timer? _messageTimer;

  void _showMessage(String? error, String? success) {
    _messageTimer?.cancel();
    setState(() {
      _error = error;
      _success = success;
    });
    if (error != null || success != null) {
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() {
          _error = null;
          _success = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _setAdmin(
      AdminRepository repo, String userId, bool isAdmin) async {
    _showMessage(null, null);
    try {
      await repo.setAdmin(userId, isAdmin);
      if (mounted) {
        _showMessage(null, isAdmin ? 'Назначен админом' : 'Сняты права админа');
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e is AdminException ? e.message : e.toString(), null);
      }
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
    _showMessage(null, null);
    try {
      await repo.resetPassword(user.id, newPassword);
      if (mounted) _showMessage(null, 'Пароль обновлён');
    } catch (e) {
      if (mounted) {
        _showMessage(e is AdminException ? e.message : e.toString(), null);
      }
    }
  }

  Future<void> _deleteUser(AdminRepository repo, AdminUserItem user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text(
            'Будет удалён аккаунт: ${user.email}. Это действие нельзя отменить.'),
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
    _showMessage(null, null);
    try {
      await repo.deleteUser(user.id);
      if (mounted) {
        _showMessage(null, 'Пользователь удалён');
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e is AdminException ? e.message : e.toString(), null);
      }
    }
  }

  Widget _buildUserCard(
    BuildContext context,
    AdminUserItem u,
    AdminRepository repo,
    String? currentUserId,
  ) {
    final nameOrEmail = (u.displayName != null && u.displayName!.isNotEmpty
            ? u.displayName!
            : u.email)
        .trim();
    final initial =
        nameOrEmail.isNotEmpty ? nameOrEmail.substring(0, 1).toUpperCase() : '?';
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (u.displayName != null && u.displayName!.isNotEmpty)
                      Text(
                        u.displayName!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (u.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius:
                        BorderRadius.circular(AppRadius.badge),
                    border: Border.all(color: AppColors.textSecondary),
                  ),
                  child: const Text(
                    'Админ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () => _deleteUser(repo, u),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                tooltip: 'Удалить',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Builder(
                builder: (context) {
                  final isSelf =
                      u.isAdmin && u.id == currentUserId;
                  final button = AppButton(
                    onPressed: isSelf
                        ? null
                        : () => _setAdmin(repo, u.id, !u.isAdmin),
                    label:
                        u.isAdmin ? 'Убрать админа' : 'Сделать админом',
                  );
                  return isSelf
                      ? Tooltip(
                          message: 'Нельзя снять права у себя',
                          child: button,
                        )
                      : button;
                },
              ),
              AppButton(
                onPressed: () => _resetPassword(repo, u),
                label: 'Сбросить пароль',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final repo = ref.read(adminRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.valueOrNull?.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                        'Пользователи',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Обновить список',
                      onPressed: () => ref.invalidate(adminUsersProvider),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child:
                      MessageBanner(message: _error!, type: BannerType.error),
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: MessageBanner(
                      message: _success!, type: BannerType.success),
                ),
              Expanded(
                child: usersAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'Нет пользователей',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    final width = MediaQuery.of(context).size.width;
                    final useGrid = width > 700;
                    if (useGrid) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, index) =>
                            _buildUserCard(context, users[index], repo, currentUserId),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildUserCard(context, u, repo, currentUserId),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentStart,
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red.shade700),
                          const SizedBox(height: 16),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ), // when
              ), // Expanded
            ],
          ),
        ),
    );
  }
}
