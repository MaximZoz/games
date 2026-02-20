import 'dart:async';
import 'dart:convert';

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

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  String? _error;
  String? _success;
  Timer? _messageTimer;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showMessage(String? error, String? success) {
    _messageTimer?.cancel();
    setState(() {
      _error = error;
      _success = success;
    });
    if (error != null || success != null) {
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _error = null;
            _success = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      ref.invalidate(adminUsersProvider);
    } else {
      ref.invalidate(adminLogsProvider);
    }
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

  static const List<IconData> _presetAvatarIcons = [
    Icons.face_rounded,
    Icons.face_2_rounded,
    Icons.face_3_rounded,
    Icons.face_4_rounded,
    Icons.face_5_rounded,
    Icons.face_6_rounded,
    Icons.man_rounded,
    Icons.woman_rounded,
    Icons.elderly_rounded,
    Icons.elderly_woman_rounded,
    Icons.person_rounded,
    Icons.child_care_rounded,
  ];

  Widget _buildAvatar(AdminUserItem u) {
    final nameOrEmail = (u.displayName != null && u.displayName!.isNotEmpty
            ? u.displayName!
            : u.email)
        .trim();
    final initial =
        nameOrEmail.isNotEmpty ? nameOrEmail.substring(0, 1).toUpperCase() : '?';

    // Загруженное фото хранится с avatarKind = 'file'.
    // На web значение имеет вид 'base64,<данные>', на мобильном — путь к файлу.
    if (u.avatarKind == 'file' && u.avatarValue != null && u.avatarValue!.isNotEmpty) {
      String raw = u.avatarValue!;
      if (raw.startsWith('base64,')) raw = raw.substring(7);
      try {
        final bytes = base64Decode(raw);
        return CircleAvatar(
          radius: 22,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }

    // Пресет — индекс иконки
    if (u.avatarKind == 'preset' && u.avatarValue != null) {
      final index = int.tryParse(u.avatarValue!);
      if (index != null && index >= 0 && index < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[index], size: 22, color: AppColors.accentStart),
        );
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
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
    );
  }

  String _ageLabel(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$n лет';
    if (mod10 == 1) return '$n год';
    if (mod10 >= 2 && mod10 <= 4) return '$n года';
    return '$n лет';
  }

  Widget _buildProfileInfo(AdminUserItem u) {
    final chips = <Widget>[];

    if (u.age != null) {
      chips.add(_InfoChip(
        icon: Icons.cake_outlined,
        label: _ageLabel(u.age!),
      ));
    }

    if (u.gender != null && u.gender!.isNotEmpty) {
      final isMale = u.gender == 'Мужской';
      chips.add(_InfoChip(
        icon: isMale ? Icons.male_rounded : Icons.female_rounded,
        label: u.gender!,
        color: isMale ? Colors.blue.shade700 : Colors.pink.shade600,
      ));
    }

    if (chips.isEmpty && (u.about == null || u.about!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 4, children: chips),
          const SizedBox(height: 4),
        ],
        if (u.about != null && u.about!.isNotEmpty)
          Text(
            u.about!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    AdminUserItem u,
    AdminRepository repo,
    String? currentUserId,
  ) {
    final profileInfo = _buildProfileInfo(u);
    final hasProfile = u.age != null ||
        (u.gender != null && u.gender!.isNotEmpty) ||
        (u.about != null && u.about!.isNotEmpty);

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
              _buildAvatar(u),
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
          if (hasProfile) ...[
            const SizedBox(height: 10),
            profileInfo,
          ],
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

  String _formatEventTime(String value) {
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  Color _statusColor(int? statusCode) {
    if (statusCode == null) return AppColors.textSecondary;
    if (statusCode >= 500) return Colors.red.shade700;
    if (statusCode >= 400) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  Widget _buildLogCard(AdminLogItem log) {
    final statusText = log.statusCode?.toString() ?? 'n/a';
    final methodLine = [
      if (log.httpMethod != null && log.httpMethod!.isNotEmpty) log.httpMethod!,
      if (log.path != null && log.path!.isNotEmpty) log.path!,
    ].join(' ');
    final metadataText = (log.metadata == null || log.metadata!.isEmpty)
        ? null
        : jsonEncode(log.metadata);

    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: AppColors.textSecondary),
                ),
                child: Text(
                  log.source.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatEventTime(log.eventTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.methodName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (methodLine.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              methodLine,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.flag_rounded,
                label: statusText,
                color: _statusColor(log.statusCode),
              ),
              if (log.durationMs != null)
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '${log.durationMs} ms',
                ),
              if (log.userId != null && log.userId!.isNotEmpty)
                _InfoChip(
                  icon: Icons.person_outline_rounded,
                  label: log.userId!,
                ),
            ],
          ),
          if (log.message != null && log.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.message!,
              style: TextStyle(
                fontSize: 13,
                color: log.level == 'error'
                    ? Colors.red.shade700
                    : AppColors.textSecondary,
              ),
            ),
          ],
          if (metadataText != null && metadataText.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              metadataText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersTab(
    BuildContext context,
    AdminRepository repo,
    String? currentUserId,
    AsyncValue<List<AdminUserItem>> usersAsync,
  ) {
    return usersAsync.when(
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
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
      loading: () => const Center(
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
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade700),
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
    );
  }

  Widget _buildLogsTab(AsyncValue<List<AdminLogItem>> logsAsync) {
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(
            child: Text(
              'Логи пока пустые',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) => _buildLogCard(logs[index]),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: logs.length,
        );
      },
      loading: () => const Center(
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
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade700),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final logsAsync = ref.watch(adminLogsProvider);
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
                      'Админка',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Обновить текущую вкладку',
                    onPressed: _refreshCurrentTab,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Пользователи'),
                  Tab(text: 'Логи'),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: MessageBanner(message: _error!, type: BannerType.error),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: MessageBanner(message: _success!, type: BannerType.success),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(context, repo, currentUserId, usersAsync),
                  _buildLogsTab(logsAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: c),
        ),
      ],
    );
  }
}
