import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
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

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _actionsInProgress = <String>{};
  late final TabController _tabController;

  List<FriendSearchItem> _searchResults = const [];
  bool _isSearching = false;
  bool _isSearchExpanded = false;
  String? _error;
  String? _success;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(String? error, String? success) {
    _messageTimer?.cancel();
    setState(() {
      _error = error;
      _success = success;
    });
    if (error != null || success != null) {
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() {
          _error = null;
          _success = null;
        });
      });
    }
  }

  String _displayName(FriendUserItem user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email;
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String? _genderLabel(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    switch (normalized) {
      case 'male':
      case 'm':
      case 'man':
      case 'м':
      case 'муж':
      case 'мужской':
        return 'Мужской';
      case 'female':
      case 'f':
      case 'woman':
      case 'ж':
      case 'жен':
      case 'женский':
        return 'Женский';
      default:
        return value;
    }
  }

  Future<void> _showRequestInfoDialog({
    required FriendUserItem user,
  }) async {
    final name = _displayName(user);
    final about = user.about?.trim();
    final gender = _genderLabel(user.gender);
    final chips = <String>[
      if (user.age != null && user.age! > 0) '${user.age} лет',
      if (gender != null && gender.isNotEmpty) gender,
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 380;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          backgroundColor: Colors.transparent,
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(user),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips
                        .map(
                          (chip) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chip,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (about != null && about.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'О себе',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    about,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(FriendUserItem user) {
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.isNotEmpty) {
      var raw = user.avatarValue!;
      if (raw.startsWith('base64,')) raw = raw.substring(7);
      try {
        final bytes = base64Decode(raw);
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }

    if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final index = int.tryParse(user.avatarValue!);
      if (index != null && index >= 0 && index < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[index], color: AppColors.accentStart),
        );
      }
    }

    final first = _displayName(user).trim();
    final letter = first.isEmpty ? '?' : first.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _handleFriendsException(FriendsException e) async {
    if (e.statusCode == 401) {
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      _showMessage('Сессия истекла. Войдите заново.', null);
      context.go('/login');
      return;
    }
    _showMessage(e.message, null);
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchResults = const [];
      }
    });

    if (_isSearchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    } else {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _refreshSnapshot({bool refreshSearch = false}) async {
    try {
      ref.invalidate(friendsSnapshotProvider);
      ref.invalidate(friendsIncomingCountProvider);
      await ref.read(friendsSnapshotProvider.future);
      if (refreshSearch && _searchController.text.trim().isNotEmpty) {
        await _performSearch();
      }
    } catch (e) {
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final repo = ref.read(friendsRepositoryProvider);
    try {
      final result = await repo.searchUsers(query, limit: 30);
      if (!mounted) return;
      setState(() {
        _searchResults = result;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _runAction({
    required String key,
    required Future<void> Function(FriendsRepository repo) call,
    required String success,
    bool refreshSearch = true,
  }) async {
    if (_actionsInProgress.contains(key)) return;
    setState(() => _actionsInProgress.add(key));

    final repo = ref.read(friendsRepositoryProvider);
    try {
      await call(repo);
      _showMessage(null, success);
      await _refreshSnapshot(refreshSearch: refreshSearch);
    } catch (e) {
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    } finally {
      if (mounted) {
        setState(() => _actionsInProgress.remove(key));
      }
    }
  }

  bool _busy(String key) => _actionsInProgress.contains(key);

  Widget _buildUserCard({
    required FriendUserItem user,
    required String subtitle,
    required List<Widget> actions,
    Widget? trailing,
  }) {
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(user),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }

  Widget _buildAdaptiveList<T>({
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    required String emptyText,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 520,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.6,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(items[index]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }

  Widget _buildFriendsTab(FriendsSnapshot snapshot) {
    return _buildAdaptiveList<FriendItem>(
      items: snapshot.friends,
      emptyText: 'У вас пока нет друзей',
      itemBuilder: (item) {
        final key = 'remove_${item.user.id}';
        return _buildUserCard(
          user: item.user,
          subtitle: 'Дружите с: ${_formatDateTime(item.createdAt)}',
          actions: [
            AppButton(
              onPressed: _busy(key)
                  ? null
                  : () => _runAction(
                        key: key,
                        call: (repo) => repo.removeFriend(item.user.id),
                        success: 'Пользователь удалён из друзей',
                      ),
              label: 'Удалить из друзей',
              style: AppButtonStyle.danger,
              isLoading: _busy(key),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIncomingTab(FriendsSnapshot snapshot) {
    return _buildAdaptiveList<FriendRequestItem>(
      items: snapshot.incoming,
      emptyText: 'Нет входящих заявок',
      itemBuilder: (item) {
        final acceptKey = 'accept_${item.requestId}';
        final rejectKey = 'reject_${item.requestId}';
        return _buildUserCard(
          user: item.user,
          subtitle: 'Входящая заявка: ${_formatDateTime(item.createdAt)}',
          trailing: IconButton(
            tooltip: 'Информация о пользователе',
            onPressed: () => _showRequestInfoDialog(user: item.user),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          actions: [
            AppButton(
              onPressed: _busy(acceptKey)
                  ? null
                  : () => _runAction(
                        key: acceptKey,
                        call: (repo) => repo.acceptRequest(item.requestId),
                        success: 'Заявка принята',
                      ),
              label: 'Принять',
              isLoading: _busy(acceptKey),
            ),
            AppButton(
              onPressed: _busy(rejectKey)
                  ? null
                  : () => _runAction(
                        key: rejectKey,
                        call: (repo) => repo.rejectRequest(item.requestId),
                        success: 'Заявка отклонена',
                      ),
              label: 'Отклонить',
              style: AppButtonStyle.danger,
              isLoading: _busy(rejectKey),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutgoingTab(FriendsSnapshot snapshot) {
    return _buildAdaptiveList<FriendRequestItem>(
      items: snapshot.outgoing,
      emptyText: 'Нет исходящих заявок',
      itemBuilder: (item) {
        final cancelKey = 'cancel_${item.requestId}';
        return _buildUserCard(
          user: item.user,
          subtitle: 'Исходящая заявка: ${_formatDateTime(item.createdAt)}',
          trailing: IconButton(
            tooltip: 'Информация о пользователе',
            onPressed: () => _showRequestInfoDialog(user: item.user),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          actions: [
            AppButton(
              onPressed: _busy(cancelKey)
                  ? null
                  : () => _runAction(
                        key: cancelKey,
                        call: (repo) => repo.cancelRequest(item.requestId),
                        success: 'Заявка отменена',
                      ),
              label: 'Отменить заявку',
              style: AppButtonStyle.danger,
              isLoading: _busy(cancelKey),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GradientCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        animate: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final textField = TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Поиск по email или нику',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (_) => _performSearch(),
            );

            if (compact) {
              return Column(
                children: [
                  textField,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          onPressed: _isSearching ? null : _performSearch,
                          label: 'Найти',
                          isLoading: _isSearching,
                          expanded: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Закрыть поиск',
                        onPressed: _toggleSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: textField),
                const SizedBox(width: 10),
                AppButton(
                  onPressed: _isSearching ? null : _performSearch,
                  label: 'Найти',
                  isLoading: _isSearching,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Закрыть поиск',
                  onPressed: _toggleSearch,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Введите запрос и нажмите "Найти"',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GradientCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        animate: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Результаты поиска: "$query"',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_isSearching)
              const Expanded(
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentStart,
                    ),
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Ничего не найдено',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    final sendKey = 'send_${item.user.id}';
                    final cancelKey = 'cancel_search_${item.requestId ?? item.user.id}';
                    final acceptKey = 'accept_search_${item.requestId ?? item.user.id}';
                    final rejectKey = 'reject_search_${item.requestId ?? item.user.id}';
                    final removeKey = 'remove_search_${item.user.id}';

                    final relation = item.relationStatus;
                    final actions = <Widget>[];
                    if (relation == 'none') {
                      actions.add(
                        AppButton(
                          onPressed: _busy(sendKey)
                              ? null
                              : () => _runAction(
                                    key: sendKey,
                                    call: (repo) => repo.sendRequest(item.user.id),
                                    success: 'Заявка отправлена',
                                  ),
                          label: 'Добавить',
                          isLoading: _busy(sendKey),
                        ),
                      );
                    } else if (relation == 'outgoing' && item.requestId != null) {
                      actions.add(
                        AppButton(
                          onPressed: _busy(cancelKey)
                              ? null
                              : () => _runAction(
                                    key: cancelKey,
                                    call: (repo) => repo.cancelRequest(item.requestId!),
                                    success: 'Заявка отменена',
                                  ),
                          label: 'Отменить заявку',
                          style: AppButtonStyle.danger,
                          isLoading: _busy(cancelKey),
                        ),
                      );
                    } else if (relation == 'incoming' && item.requestId != null) {
                      actions.addAll([
                        AppButton(
                          onPressed: _busy(acceptKey)
                              ? null
                              : () => _runAction(
                                    key: acceptKey,
                                    call: (repo) => repo.acceptRequest(item.requestId!),
                                    success: 'Заявка принята',
                                  ),
                          label: 'Принять',
                          isLoading: _busy(acceptKey),
                        ),
                        AppButton(
                          onPressed: _busy(rejectKey)
                              ? null
                              : () => _runAction(
                                    key: rejectKey,
                                    call: (repo) => repo.rejectRequest(item.requestId!),
                                    success: 'Заявка отклонена',
                                  ),
                          label: 'Отклонить',
                          style: AppButtonStyle.danger,
                          isLoading: _busy(rejectKey),
                        ),
                      ]);
                    } else if (relation == 'friend') {
                      actions.add(
                        AppButton(
                          onPressed: _busy(removeKey)
                              ? null
                              : () => _runAction(
                                    key: removeKey,
                                    call: (repo) => repo.removeFriend(item.user.id),
                                    success: 'Пользователь удалён из друзей',
                                  ),
                          label: 'Удалить из друзей',
                          style: AppButtonStyle.danger,
                          isLoading: _busy(removeKey),
                        ),
                      );
                    }

                    final relationLabel = switch (relation) {
                      'friend' => 'Уже в друзьях',
                      'incoming' => 'Входящая заявка',
                      'outgoing' => 'Исходящая заявка',
                      _ => 'Не в друзьях',
                    };

                    return _buildUserCard(
                      user: item.user,
                      subtitle: relationLabel,
                      actions: actions,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final compact = MediaQuery.sizeOf(context).width < 430;
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
                  Text(
                    'Друзья',
                    style: (compact
                            ? Theme.of(context).textTheme.headlineMedium
                            : Theme.of(context).textTheme.headlineSmall)
                        ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: _toggleSearch,
                    tooltip: _isSearchExpanded ? 'Свернуть поиск' : 'Показать поиск',
                    icon: Icon(
                      _isSearchExpanded ? Icons.search_off_rounded : Icons.search_rounded,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _refreshSnapshot(refreshSearch: true),
                    tooltip: 'Обновить',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: AppDurations.short,
              child: _isSearchExpanded
                  ? _buildSearchPanel()
                  : const SizedBox(
                      key: ValueKey('friends-search-collapsed'),
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: MessageBanner(message: _error!, type: BannerType.error),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: MessageBanner(message: _success!, type: BannerType.success),
              ),
            if (_isSearchExpanded)
              Expanded(child: _buildSearchResults())
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: TextStyle(
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Text(
                        friendsAsync.valueOrNull == null
                            ? 'Друзья'
                            : 'Друзья (${friendsAsync.valueOrNull!.friends.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Tab(
                      child: Text(
                        friendsAsync.valueOrNull == null
                            ? 'Входящие'
                            : 'Входящие (${friendsAsync.valueOrNull!.incoming.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Tab(
                      child: Text(
                        friendsAsync.valueOrNull == null
                            ? 'Исходящие'
                            : 'Исходящие (${friendsAsync.valueOrNull!.outgoing.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: friendsAsync.when(
                  data: (snapshot) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFriendsTab(snapshot),
                        _buildIncomingTab(snapshot),
                        _buildOutgoingTab(snapshot),
                      ],
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
                          Icon(Icons.error_outline_rounded, size: 46, color: Colors.red.shade700),
                          const SizedBox(height: 12),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
