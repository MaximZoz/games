import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  static const String _sourceAll = '__all__';
  static const List<_CopyLimitSpec> _copyLimitOptions = [
    _CopyLimitSpec(label: '120', value: 120),
    _CopyLimitSpec(label: '500', value: 500),
    _CopyLimitSpec(label: '1000', value: 1000),
    _CopyLimitSpec(label: 'Все', value: null),
  ];
  static const List<_LogWindowSpec> _logWindows = [
    _LogWindowSpec(title: 'Последние 5 минут', duration: Duration(minutes: 5)),
    _LogWindowSpec(title: 'Последние 15 минут', duration: Duration(minutes: 15)),
    _LogWindowSpec(title: 'Последний 1 час', duration: Duration(hours: 1)),
    _LogWindowSpec(title: 'Последние 24 часа', duration: Duration(hours: 24)),
  ];

  String? _error;
  String? _success;
  Timer? _messageTimer;
  late final TabController _tabController;
  String? _selectedLogUserId;
  String _selectedLogSource = _sourceAll;
  int? _copyLimit = 120;
  AsyncValue<List<AdminLogItem>> _logsState = const AsyncValue.loading();
  int _logRequestID = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
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
      _loadLogs();
    }
  }

  Future<void> _loadLogs() async {
    final requestID = ++_logRequestID;
    setState(() {
      _logsState = const AsyncValue.loading();
    });

    final repo = ref.read(adminRepositoryProvider);
    try {
      final now = DateTime.now().toUtc();
      final logs = await repo.listLogs(
        limit: 2000,
        userId: _selectedLogUserId,
        source: _selectedLogSource == _sourceAll ? null : _selectedLogSource,
        from: now.subtract(const Duration(hours: 24)),
        to: now,
      );
      if (!mounted || requestID != _logRequestID) return;
      setState(() {
        _logsState = AsyncValue.data(logs);
      });
    } catch (e, st) {
      if (e is AdminException && e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) {
          _showMessage('Сессия истекла. Войдите заново.', null);
          context.go('/login');
        }
        return;
      }
      if (!mounted || requestID != _logRequestID) return;
      setState(() {
        _logsState = AsyncValue.error(e, st);
      });
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
        if (e is AdminException) {
          await _handleAdminException(e);
        } else {
          _showMessage(e.toString(), null);
        }
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
        if (e is AdminException) {
          await _handleAdminException(e);
        } else {
          _showMessage(e.toString(), null);
        }
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
        if (e is AdminException) {
          await _handleAdminException(e);
        } else {
          _showMessage(e.toString(), null);
        }
      }
    }
  }

  Future<void> _handleAdminException(AdminException e) async {
    if (e.statusCode == 401) {
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      _showMessage('Сессия истекла. Войдите заново.', null);
      context.go('/login');
      return;
    }
    _showMessage(e.message, null);
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

  String _sanitizeOneLine(String value) {
    return value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  }

  String _logPreviewLine(AdminLogItem log) {
    final method = [
      if (log.httpMethod != null && log.httpMethod!.isNotEmpty) log.httpMethod!,
      if (log.path != null && log.path!.isNotEmpty) log.path!,
    ].join(' ');
    final status = log.statusCode?.toString() ?? 'n/a';
    final duration = log.durationMs != null ? '${log.durationMs}ms' : '-';
    return '[${_formatEventTime(log.eventTime)}] '
        '${log.source.toUpperCase()} '
        '$status $duration '
        '${_sanitizeOneLine(log.methodName)}'
        '${method.isEmpty ? '' : ' ($method)'}';
  }

  String _activeLogUserLabel(List<AdminUserItem> users) {
    if (_selectedLogUserId == null) return 'Все пользователи';
    final selected = users.where((u) => u.id == _selectedLogUserId).toList();
    if (selected.isEmpty) return _selectedLogUserId!;
    final user = selected.first;
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return '${user.displayName} (${user.email})';
    }
    return user.email;
  }

  String _activeLogSourceLabel() {
    switch (_selectedLogSource) {
      case 'frontend':
        return 'Только frontend';
      case 'backend':
        return 'Только backend';
      default:
        return 'Все источники';
    }
  }

  String _copyLimitLabel() {
    if (_copyLimit == null) return 'Все';
    return '$_copyLimit';
  }

  List<AdminLogItem> _applyCopyLimit(List<AdminLogItem> logs) {
    if (_copyLimit == null) return List<AdminLogItem>.from(logs);
    return logs.take(_copyLimit!).toList();
  }

  List<AdminLogItem> _logsForWindow(
      List<AdminLogItem> logs, Duration duration, DateTime nowUtc) {
    final threshold = nowUtc.subtract(duration);
    return logs.where((log) {
      final dt = DateTime.tryParse(log.eventTime)?.toUtc();
      if (dt == null) return false;
      return !dt.isBefore(threshold);
    }).toList();
  }

  Future<void> _copyLogsWindow({
    required String windowTitle,
    required String userLabel,
    required List<AdminLogItem> logs,
  }) async {
    final capped = _applyCopyLimit(logs);
    final sb = StringBuffer()
      ..writeln('Окно: $windowTitle')
      ..writeln('Пользователь: $userLabel')
      ..writeln('Лимит копирования: ${_copyLimitLabel()}')
      ..writeln(
          'Скопировано: ${capped.length} из ${logs.length} (время UTC: ${DateTime.now().toUtc().toIso8601String()})')
      ..writeln('---');

    for (final log in capped) {
      sb.writeln(_logPreviewLine(log));
      if (log.message != null && log.message!.isNotEmpty) {
        sb.writeln('message: ${_sanitizeOneLine(log.message!)}');
      }
      if (log.metadata != null && log.metadata!.isNotEmpty) {
        sb.writeln('metadata: ${jsonEncode(log.metadata)}');
      }
      sb.writeln('');
    }

    await Clipboard.setData(ClipboardData(text: sb.toString()));
    if (!mounted) return;
    _showMessage(
      null,
      'Скопировано ${capped.length} логов из "$windowTitle" (лимит ${_copyLimitLabel()})',
    );
  }

  Future<void> _copyAllWindows({
    required List<AdminLogItem> logs,
    required String userLabel,
    required String sourceLabel,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final sb = StringBuffer()
      ..writeln('Окна логов (все):')
      ..writeln('Пользователь: $userLabel')
      ..writeln('Источник: $sourceLabel')
      ..writeln('Лимит копирования: ${_copyLimitLabel()}')
      ..writeln('UTC: ${nowUtc.toIso8601String()}')
      ..writeln('---');

    int totalCopied = 0;
    for (final window in _logWindows) {
      final windowLogs = _logsForWindow(logs, window.duration, nowUtc);
      final capped = _applyCopyLimit(windowLogs);
      totalCopied += capped.length;

      sb.writeln();
      sb.writeln('### ${window.title} | ${windowLogs.length} шт');
      if (capped.isEmpty) {
        sb.writeln('нет записей');
        continue;
      }
      for (final log in capped) {
        sb.writeln(_logPreviewLine(log));
        if (log.message != null && log.message!.isNotEmpty) {
          sb.writeln('message: ${_sanitizeOneLine(log.message!)}');
        }
        if (log.metadata != null && log.metadata!.isNotEmpty) {
          sb.writeln('metadata: ${jsonEncode(log.metadata)}');
        }
        sb.writeln('');
      }
      if (windowLogs.length > capped.length) {
        sb.writeln('... обрезано: ещё ${windowLogs.length - capped.length} записей');
      }
    }

    await Clipboard.setData(ClipboardData(text: sb.toString()));
    if (!mounted) return;
    _showMessage(
      null,
      'Скопировано все окна: $totalCopied логов (лимит ${_copyLimitLabel()})',
    );
  }

  Widget _buildLogWindowCard({
    required _LogWindowSpec window,
    required List<AdminLogItem> logs,
    required String userLabel,
  }) {
    final previewLogs = logs.take(window.previewLimit).toList();
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  window.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: AppColors.textSecondary),
                ),
                child: Text(
                  '${logs.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: logs.isEmpty
                    ? null
                    : () => _copyLogsWindow(
                          windowTitle: window.title,
                          userLabel: userLabel,
                          logs: logs,
                        ),
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Скопировать логи этого окна',
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (logs.isEmpty)
            const Text(
              'Нет записей в этом промежутке',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else ...[
            for (final log in previewLogs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SelectableText(
                  _logPreviewLine(log),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (logs.length > previewLogs.length)
              Text(
                '... ещё ${logs.length - previewLogs.length} записей',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
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

  Widget _buildLogsTab(AsyncValue<List<AdminUserItem>> usersAsync) {
    final users = usersAsync.valueOrNull ?? const <AdminUserItem>[];
    final selectedValue = (_selectedLogUserId != null &&
            users.any((u) => u.id == _selectedLogUserId))
        ? _selectedLogUserId!
        : '__all__';
    final sourceValue = (_selectedLogSource == 'frontend' ||
            _selectedLogSource == 'backend')
        ? _selectedLogSource
        : _sourceAll;
    final userLabel = _activeLogUserLabel(users);
    final sourceLabel = _activeLogSourceLabel();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GradientCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(14),
          animate: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Логи по пользователю и промежуткам',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedValue,
                dropdownColor: AppColors.surfaceCard,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                iconEnabledColor: AppColors.textPrimary,
                decoration: const InputDecoration(
                  labelText: 'Пользователь',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '__all__',
                    child: Text('Все пользователи'),
                  ),
                  ...users.map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(
                        (u.displayName != null && u.displayName!.isNotEmpty)
                            ? '${u.displayName} (${u.email})'
                            : u.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  final nextUserID = value == '__all__' ? null : value;
                  if (nextUserID == _selectedLogUserId) return;
                  setState(() {
                    _selectedLogUserId = nextUserID;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: sourceValue,
                dropdownColor: AppColors.surfaceCard,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                iconEnabledColor: AppColors.textPrimary,
                decoration: const InputDecoration(
                  labelText: 'Источник',
                ),
                items: const [
                  DropdownMenuItem(
                    value: _sourceAll,
                    child: Text('Все источники'),
                  ),
                  DropdownMenuItem(
                    value: 'frontend',
                    child: Text('Frontend'),
                  ),
                  DropdownMenuItem(
                    value: 'backend',
                    child: Text('Backend'),
                  ),
                ],
                onChanged: (value) {
                  final nextSource = value ?? _sourceAll;
                  if (nextSource == _selectedLogSource) return;
                  setState(() {
                    _selectedLogSource = nextSource;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _copyLimitOptions
                    .map(
                      (opt) => ChoiceChip(
                        label: Text('Копировать: ${opt.label}'),
                        selected: _copyLimit == opt.value,
                        selectedColor: AppColors.accentSoft,
                        checkmarkColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: _copyLimit == opt.value
                              ? AppColors.accentStart
                              : AppColors.textSecondary.withOpacity(0.4),
                        ),
                        labelStyle: const TextStyle(color: AppColors.textPrimary),
                        onSelected: (_) {
                          if (_copyLimit == opt.value) return;
                          setState(() {
                            _copyLimit = opt.value;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        userLabel,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.source_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        sourceLabel,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.content_copy_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Лимит: ${_copyLimitLabel()}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  AppButton(
                    onPressed: _logsState.valueOrNull == null ||
                            _logsState.valueOrNull!.isEmpty
                        ? null
                        : () => _copyAllWindows(
                              logs: _logsState.valueOrNull!,
                              userLabel: userLabel,
                              sourceLabel: sourceLabel,
                            ),
                    label: 'Скопировать всё',
                  ),
                  IconButton(
                    onPressed: _loadLogs,
                    tooltip: 'Обновить логи',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (usersAsync.hasError)
                Text(
                  'Не удалось подгрузить список пользователей: ${usersAsync.error}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _logsState.when(
          data: (logs) {
            final nowUtc = DateTime.now().toUtc();
            if (logs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Логи не найдены для выбранного фильтра',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final window in _logWindows) ...[
                  _buildLogWindowCard(
                    window: window,
                    logs: _logsForWindow(logs, window.duration, nowUtc),
                    userLabel: userLabel,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.accentStart,
              ),
            ),
          ),
          error: (err, _) => Padding(
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
      ],
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
                  _buildLogsTab(usersAsync),
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

class _LogWindowSpec {
  const _LogWindowSpec({
    required this.title,
    required this.duration,
  });

  final String title;
  final Duration duration;
  int get previewLimit => 8;
}

class _CopyLimitSpec {
  const _CopyLimitSpec({
    required this.label,
    required this.value,
  });

  final String label;
  final int? value;
}
