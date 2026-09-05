import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/admin/admin_provider.dart';
import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/chat_room_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Экран админки: пользователи (поиск/сортировка/пагинация/действия) и поддержка.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AdminOpenSupportChat?>(adminOpenSupportChatProvider, (_, next) {
      if (next != null) {
        _tabController.animateTo(1);
      }
    });
    return Scaffold(
      backgroundColor: AppColors.surfaceUnified,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceUnified,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Админка',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Пользователи'),
            Tab(text: 'Поддержка'),
          ],
          labelColor: AppColors.accentStart,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentStart,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _UsersTab(),
          _SupportTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Таб «Пользователи»: поиск, сортировка, пагинация, действия.
// ──────────────────────────────────────────────────────────────────────────
class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _sort = 'created_at';
  String _order = 'desc';
  String _adminFilter = 'all';
  String _frozenFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(adminUsersProvider.notifier).loadMore();
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyQuery);
  }

  AdminUsersQuery _currentQuery() {
    return AdminUsersQuery(
      q: _searchController.text.trim(),
      sort: _sort,
      order: _order,
      adminFilter: _adminFilter,
      frozenFilter: _frozenFilter,
    );
  }

  void _applyQuery() {
    ref.read(adminUsersProvider.notifier).setQuery(_currentQuery());
  }

  void _changeSort() {
    setState(() {
      _sort = _nextSort(_sort);
      _order = 'desc';
    });
    _applyQuery();
  }

  String _nextSort(String s) {
    switch (s) {
      case 'created_at':
        return 'last_seen';
      case 'last_seen':
        return 'email';
      default:
        return 'created_at';
    }
  }

  void _cycleAdminFilter() {
    setState(() {
      _adminFilter = _adminFilter == 'all'
          ? 'admin'
          : _adminFilter == 'admin'
              ? 'user'
              : 'all';
    });
    _applyQuery();
  }

  void _cycleFrozenFilter() {
    setState(() {
      _frozenFilter = _frozenFilter == 'all'
          ? 'frozen'
          : _frozenFilter == 'frozen'
              ? 'active'
              : 'all';
    });
    _applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final currentUserId = authState?.id;
    final repo = ref.watch(adminRepositoryProvider);
    final async = ref.watch(adminUsersProvider);

    return Column(
      children: [
        // Панель поиска + фильтров.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по email или нику',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.accentStart.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.accentStart.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentStart),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                ),
                onChanged: (_) => _scheduleSearch(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipButton(
                      label: _sortLabel(),
                      icon: _sortIcon(),
                      onTap: _changeSort,
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: _adminFilter == 'admin'
                          ? 'Админы'
                          : _adminFilter == 'user'
                              ? 'Пользователи'
                              : 'Все роли',
                      onTap: _cycleAdminFilter,
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: _frozenFilter == 'frozen'
                          ? 'Замороженные'
                          : _frozenFilter == 'active'
                              ? 'Активные'
                              : 'Любой статус',
                      onTap: _cycleFrozenFilter,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip:
                          _order == 'desc' ? 'По убыванию' : 'По возрастанию',
                      icon: Icon(_order == 'desc'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded),
                      iconSize: 20,
                      onPressed: () {
                        setState(() => _order = _order == 'desc' ? 'asc' : 'desc');
                        _applyQuery();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentStart,
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ошибка загрузки: ${formatUserError(e, fallback: "попробуйте позже")}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            data: (state) {
              if (state.users.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Пользователи не найдены',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: state.users.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= state.users.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentStart,
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _UserCard(
                      user: state.users[i],
                      currentUserId: currentUserId,
                      repo: repo,
                      onChanged: _applyQuery,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _sortLabel() {
    switch (_sort) {
      case 'last_seen':
        return 'По последнему визиту';
      case 'email':
        return 'По email';
      default:
        return 'По дате рег.';
    }
  }

  IconData _sortIcon() {
    switch (_sort) {
      case 'last_seen':
        return Icons.access_time_rounded;
      case 'email':
        return Icons.alternate_email_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, this.icon, required this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppColors.accentStart),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentStart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Карточка пользователя + действия.
// ──────────────────────────────────────────────────────────────────────────
class _UserCard extends ConsumerWidget {
  const _UserCard({
    required this.user,
    required this.currentUserId,
    required this.repo,
    required this.onChanged,
  });

  final AdminUserItem user;
  final String? currentUserId;
  final AdminRepository repo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : user.email;

    return GradientCard(
      animate: false,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => _showActions(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (user.isAdmin)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.shield_rounded,
                                  size: 15, color: AppColors.accentStart),
                            ),
                          if (user.isFrozen)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.ac_unit_rounded,
                                  size: 15, color: Colors.blueGrey),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${user.balanceBronze} бр.',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (user.lastSeenAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _lastSeenShort(user.lastSeenAt!),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onPressed: () => _showActions(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AdminUserItem u) {
    if (u.avatarKind == 'file' &&
        u.avatarValue != null &&
        u.avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(u.avatarValue!);
      if (img != null) {
        return CircleAvatar(radius: 18, backgroundImage: img);
      }
    }
    final displayName = u.displayName?.trim() ?? '';
    final letter = displayName.isEmpty
        ? u.email.isNotEmpty
            ? u.email[0].toUpperCase()
            : '?'
        : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.accentSoft,
      child: Text(letter, style: const TextStyle(color: AppColors.accentStart)),
    );
  }

  String _lastSeenShort(String iso) {
    try {
      final t = DateTime.parse(iso);
      final diff = DateTime.now().toUtc().difference(t);
      if (diff.inMinutes < 1) return 'только что';
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
      if (diff.inHours < 24) return '${diff.inHours} ч назад';
      return '${diff.inDays} дн назад';
    } catch (_) {
      return '';
    }
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final isSelf = user.id == currentUserId;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.shield_rounded,
                    color: AppColors.accentStart),
                title: Text(user.isAdmin ? 'Убрать админа' : 'Сделать админом'),
                enabled: !(isSelf && user.isAdmin),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _doAction(
                    context,
                    () => repo.setAdmin(user.id, !user.isAdmin),
                    success:
                        user.isAdmin ? 'Права админа сняты' : 'Права админа выданы',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.monetization_on_outlined,
                    color: AppColors.accentStart),
                title: const Text('Начислить монеты'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGrantCoinsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded,
                    color: AppColors.accentStart),
                title: const Text('Написать от поддержки'),
                onTap: () {
                  Navigator.pop(ctx);
                  final name = user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!.trim()
                      : user.email;
                  ref.read(adminOpenSupportChatProvider.notifier).state =
                      AdminOpenSupportChat(
                    userId: user.id,
                    peerName: name,
                    avatarKind: user.avatarKind,
                    avatarValue: user.avatarValue,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  user.isFrozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded,
                  color: user.isFrozen ? Colors.green : Colors.blueGrey,
                ),
                title: Text(user.isFrozen ? 'Разморозить' : 'Заморозить'),
                enabled: !isSelf,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _doAction(
                    context,
                    () => repo.freezeUser(user.id, !user.isFrozen),
                    success: user.isFrozen ? 'Разморожен' : 'Заморожен',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.accentStart),
                title: const Text('Сбросить пароль'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showResetPasswordDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _doAction(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      onChanged();
      if (!context.mounted) return;
      showAppSnackBar(context, message: success, kind: AppSnackKind.success);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: formatUserError(e, fallback: 'Ошибка'),
        kind: AppSnackKind.error,
      );
    }
  }

  void _showGrantCoinsDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начислить монеты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Количество (отрицательное = списание)',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(hintText: 'Причина (необязательно)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text.trim());
              if (amount == null || amount == 0) return;
              Navigator.pop(ctx);
              await _doAction(
                context,
                () => repo.grantCoins(user.id, amount,
                    reason: reasonCtrl.text.trim()),
                success: amount > 0
                    ? 'Карточка отправлена в чат поддержки'
                    : 'Списано ${amount.abs()} бронзовых',
              );
            },
            child: const Text('Начислить'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить пароль'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Новый пароль (мин. 6)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.length < 6) return;
              Navigator.pop(ctx);
              await _doAction(
                context,
                () => repo.resetPassword(user.id, ctrl.text),
                success: 'Пароль сброшен',
              );
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Таб «Поддержка»: список диалогов + переписка.
// ──────────────────────────────────────────────────────────────────────────
class _SupportTab extends ConsumerStatefulWidget {
  const _SupportTab();

  @override
  ConsumerState<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends ConsumerState<_SupportTab> {
  String? _selectedUserId;
  String? _selectedPeerName;
  String? _selectedChatId;
  String? _selectedAvatarKind;
  String? _selectedAvatarValue;

  @override
  Widget build(BuildContext context) {
    ref.watch(supportInboxRealtimeProvider);
    final localRead = ref.watch(locallyReadSupportChatIdsProvider);
    ref.listen<AdminOpenSupportChat?>(adminOpenSupportChatProvider, (_, next) {
      if (next == null) return;
      setState(() {
        _selectedUserId = next.userId;
        _selectedPeerName = next.peerName;
        _selectedChatId = next.chatId;
        _selectedAvatarKind = next.avatarKind;
        _selectedAvatarValue = next.avatarValue;
      });
      // Сбрасываем запрос, чтобы повторное открытие того же юзера сработало.
      ref.read(adminOpenSupportChatProvider.notifier).state = null;
    });
    if (_selectedUserId != null) {
      return _SupportConversation(
        userId: _selectedUserId!,
        peerName: _selectedPeerName,
        chatId: _selectedChatId,
        avatarKind: _selectedAvatarKind,
        avatarValue: _selectedAvatarValue,
        onBack: () {
          ref.read(openSupportChatIdProvider.notifier).state = null;
          setState(() {
            _selectedUserId = null;
            _selectedPeerName = null;
            _selectedChatId = null;
            _selectedAvatarKind = null;
            _selectedAvatarValue = null;
          });
          ref.invalidate(supportChatsProvider);
        },
      );
    }
    final async = ref.watch(supportChatsProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accentStart,
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Ошибка: ${formatUserError(e, fallback: "попробуйте позже")}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Нет обращений в поддержку',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          itemBuilder: (context, i) {
            final c = chats[i];
            final unread =
                localRead.contains(c.chatId) ? 0 : c.unreadCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GradientCard(
                animate: false,
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: c.peerId.isEmpty
                        ? null
                        : () {
                            if (c.chatId.trim().isNotEmpty) {
                              markSupportChatReadInCache(ref, c.chatId);
                              ref.read(openSupportChatIdProvider.notifier).state =
                                  c.chatId;
                            }
                            setState(() {
                              _selectedUserId = c.peerId;
                              _selectedPeerName = c.peerName;
                              _selectedChatId =
                                  c.chatId.trim().isEmpty ? null : c.chatId;
                              _selectedAvatarKind = c.avatarKind;
                              _selectedAvatarValue = c.avatarValue;
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.accentSoft,
                            child: Icon(Icons.person_rounded,
                                size: 18, color: AppColors.accentStart),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (c.peerName != null &&
                                          c.peerName!.trim().isNotEmpty)
                                      ? c.peerName!.trim()
                                      : (c.peerId.isNotEmpty
                                          ? c.peerId
                                          : 'Пользователь'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                if (c.lastMessage != null &&
                                    c.lastMessage!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(c.lastMessage!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ],
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SupportConversation extends ConsumerStatefulWidget {
  const _SupportConversation({
    required this.userId,
    required this.onBack,
    this.peerName,
    this.chatId,
    this.avatarKind,
    this.avatarValue,
  });
  final String userId;
  final String? peerName;
  final String? chatId;
  final String? avatarKind;
  final String? avatarValue;
  final VoidCallback onBack;

  @override
  ConsumerState<_SupportConversation> createState() =>
      _SupportConversationState();
}

class _SupportConversationState extends ConsumerState<_SupportConversation> {
  SupportChatSession? _session;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final session = await repo.ensureSupportChat(widget.userId);
      if (!mounted) return;
      setState(() {
        final fallbackChat = widget.chatId?.trim() ?? '';
        _session = session.chatId.isNotEmpty
            ? session
            : SupportChatSession(
                chatId: fallbackChat,
                supportUserId: session.supportUserId,
                peerId: session.peerId,
              );
        _loading = false;
      });
      final chatId = _session?.chatId ?? '';
      if (chatId.isNotEmpty) {
        ref.read(openSupportChatIdProvider.notifier).state = chatId;
        markSupportChatReadInCache(ref, chatId);
      }
      ref.invalidate(supportChatsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatUserError(e, fallback: context.l10n.supportOpenFailed);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = (widget.peerName != null && widget.peerName!.trim().isNotEmpty)
        ? widget.peerName!.trim()
        : l10n.commonPlayer;
    if (_loading) {
      return Column(
        children: [
          _SupportChatHeader(title: title, onBack: widget.onBack),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentStart,
              ),
            ),
          ),
        ],
      );
    }
    if (_error != null || _session == null || _session!.chatId.isEmpty) {
      return Column(
        children: [
          _SupportChatHeader(title: title, onBack: widget.onBack),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error ?? l10n.supportOpenFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ChatRoomScreen(
      chatID: _session!.chatId,
      peerName: title,
      peerUser: ChatUserItem(
        id: widget.userId,
        displayName: title,
        avatarKind: widget.avatarKind ?? 'letter',
        avatarValue: widget.avatarValue,
      ),
      actingAsUserId: _session!.supportUserId,
      hidePeerActions: true,
      onLeave: widget.onBack,
      onMarkedRead: () => markSupportChatReadInCache(ref, _session!.chatId),
    );
  }
}

class _SupportChatHeader extends StatelessWidget {
  const _SupportChatHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: context.l10n.commonBack,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
