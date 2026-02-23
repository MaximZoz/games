import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

enum _FriendsTabKind { friends, incoming, outgoing }

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
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
  Timer? _searchDebounce;
  int _searchRevision = 0;

  List<FriendSearchItem> _searchResults = const [];
  bool _isSearching = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String? error, String? success) {}

  String _displayName(FriendUserItem user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Пользователь';
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  IconData? _genderIcon(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    switch (normalized) {
      case 'male':
      case 'm':
      case 'man':
      case 'м':
      case 'муж':
      case 'мужской':
        return Icons.male_rounded;
      case 'female':
      case 'f':
      case 'woman':
      case 'ж':
      case 'жен':
      case 'женский':
        return Icons.female_rounded;
      default:
        return null;
    }
  }

  bool _isFemaleGender(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'female' ||
        normalized == 'f' ||
        normalized == 'woman' ||
        normalized == 'ж' ||
        normalized == 'жен' ||
        normalized == 'женский';
  }

  Widget _buildInfoPill({
    String? text,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? minWidth,
  }) {
    final bg = backgroundColor ?? AppColors.accentSoft;
    final fg = foregroundColor ?? AppColors.textPrimary;
    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            if (text != null && text.isNotEmpty) const SizedBox(width: 4),
          ],
          if (text != null && text.isNotEmpty)
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRequestInfoDialog({
    required FriendUserItem user,
  }) async {
    final name = _displayName(user);
    final about = user.about?.trim();
    final genderIcon = _genderIcon(user.gender);
    final female = _isFemaleGender(user.gender);
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
                if ((user.age != null && user.age! > 0) || genderIcon != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (user.age != null && user.age! > 0)
                        _buildInfoPill(
                          text: '${user.age} лет',
                          minWidth: 72,
                        ),
                      if (genderIcon != null)
                        _buildInfoPill(
                          icon: genderIcon,
                          minWidth: 46,
                          backgroundColor: female ? const Color(0xFFFCE7F3) : AppColors.accentSoft,
                          foregroundColor: female ? const Color(0xFFBE185D) : AppColors.textPrimary,
                        ),
                    ],
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

  Future<void> _handleChatException(ChatException e) async {
    if (e.statusCode == 401) {
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _openChatWithUser(
    FriendUserItem user, {
    String? actionKey,
  }) async {
    final key = actionKey ?? 'chat_${user.id}';
    if (_actionsInProgress.contains(key)) return;
    setState(() => _actionsInProgress.add(key));

    try {
      final chatID = await ref.read(chatsRepositoryProvider).startChat(user.id);
      if (!mounted) return;
      if (chatID.isEmpty) return;
      final name = Uri.encodeQueryComponent(_displayName(user));
      context.push('/chats/$chatID?name=$name');
    } catch (e) {
      if (e is ChatException) {
        await _handleChatException(e);
      }
    } finally {
      if (mounted) {
        setState(() => _actionsInProgress.remove(key));
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchDebounce?.cancel();
        _searchRevision++;
        _searchController.clear();
        _searchResults = const [];
        _isSearching = false;
      }
    });

    if (_isSearchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
      _scheduleSearch(immediate: true);
    } else {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _refreshSnapshot({bool refreshSearch = false}) async {
    try {
      await refreshFriendsSnapshot(ref);
      if (refreshSearch && _searchController.text.trim().isNotEmpty) {
        await _performSearch(query: _searchController.text.trim());
      }
    } catch (e) {
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    }
  }

  void _onSearchTextChanged(String _) {
    setState(() {});
    _scheduleSearch();
  }

  void _scheduleSearch({bool immediate = false}) {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchRevision++;
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    final requestID = ++_searchRevision;
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 220);
    _searchDebounce = Timer(delay, () {
      unawaited(_performSearch(query: query, requestID: requestID));
    });
  }

  Future<void> _performSearch({String? query, int? requestID}) async {
    final q = (query ?? _searchController.text).trim();
    final currentRequestID = requestID ?? ++_searchRevision;
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSearching = true);
    final repo = ref.read(friendsRepositoryProvider);
    try {
      final result = await repo.searchUsers(q, limit: 30);
      if (!mounted || currentRequestID != _searchRevision) return;
      setState(() {
        _searchResults = result;
      });
    } catch (e) {
      if (!mounted || currentRequestID != _searchRevision) return;
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    } finally {
      if (mounted && currentRequestID == _searchRevision) {
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
    bool alignActionsRight = false,
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
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: alignActionsRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: actions),
            ),
          ],
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.only(top: 80),
        children: [
          Center(
            child: Text(
              emptyText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
        final chatKey = 'chat_${item.user.id}';
        return _buildUserCard(
          user: item.user,
          subtitle: 'Дружите с: ${_formatDateTime(item.createdAt)}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Информация о пользователе',
                onPressed: () => _showRequestInfoDialog(user: item.user),
              ),
              const SizedBox(width: 4),
              _buildCompactIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Написать сообщение',
                loading: _busy(chatKey),
                onPressed: _busy(chatKey)
                    ? null
                    : () => _openChatWithUser(item.user, actionKey: chatKey),
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                key: key,
                icon: Icons.person_remove_alt_1_rounded,
                tooltip: 'Удалить из друзей',
                call: (repo) => repo.removeFriend(item.user.id),
                success: 'Пользователь удалён из друзей',
                danger: true,
              ),
            ],
          ),
          actions: const [],
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
        final chatKey = 'chat_incoming_${item.user.id}';
        return _buildUserCard(
          user: item.user,
          subtitle: 'Входящая заявка: ${_formatDateTime(item.createdAt)}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Информация о пользователе',
                onPressed: () => _showRequestInfoDialog(user: item.user),
              ),
              const SizedBox(width: 4),
              _buildCompactIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Написать сообщение',
                loading: _busy(chatKey),
                onPressed: _busy(chatKey)
                    ? null
                    : () => _openChatWithUser(item.user, actionKey: chatKey),
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                key: acceptKey,
                icon: Icons.check_rounded,
                tooltip: 'Принять заявку',
                call: (repo) => repo.acceptRequest(item.requestId),
                success: 'Заявка принята',
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                key: rejectKey,
                icon: Icons.close_rounded,
                tooltip: 'Отклонить заявку',
                call: (repo) => repo.rejectRequest(item.requestId),
                success: 'Заявка отклонена',
                danger: true,
              ),
            ],
          ),
          actions: const [],
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
        final chatKey = 'chat_outgoing_${item.user.id}';
        return _buildUserCard(
          user: item.user,
          subtitle: 'Исходящая заявка: ${_formatDateTime(item.createdAt)}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Информация о пользователе',
                onPressed: () => _showRequestInfoDialog(user: item.user),
              ),
              const SizedBox(width: 4),
              _buildCompactIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Написать сообщение',
                loading: _busy(chatKey),
                onPressed: _busy(chatKey)
                    ? null
                    : () => _openChatWithUser(item.user, actionKey: chatKey),
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                key: cancelKey,
                icon: Icons.close_rounded,
                tooltip: 'Отменить заявку',
                call: (repo) => repo.cancelRequest(item.requestId),
                success: 'Заявка отменена',
                danger: true,
              ),
            ],
          ),
          actions: const [],
        );
      },
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool danger = false,
    bool loading = false,
  }) {
    final enabled = onPressed != null && !loading;
    final borderColor = danger ? Colors.red.shade300 : AppColors.accentStart.withOpacity(0.55);
    final iconColor = danger ? Colors.red.shade700 : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Icon(icon, size: 18, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required String key,
    required IconData icon,
    required String tooltip,
    required Future<void> Function(FriendsRepository repo) call,
    required String success,
    bool danger = false,
  }) {
    final busy = _busy(key);
    return _buildCompactIconButton(
      icon: icon,
      tooltip: tooltip,
      danger: danger,
      loading: busy,
      onPressed: busy
          ? null
          : () => _runAction(
                key: key,
                call: call,
                success: success,
              ),
    );
  }

  Widget _buildGradientHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool redFrame = false,
  }) {
    final gradient = redFrame ? null : AppGradients.borderAt(_isSearchExpanded ? 0.68 : 0.2);
    final redBorderColor = Colors.red.shade400;
    final iconColor = redFrame ? Colors.red.shade700 : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: gradient,
          border: redFrame ? Border.all(color: redBorderColor, width: 2) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(FriendSearchItem item) {
    final relation = item.relationStatus;
    final sendKey = 'send_${item.user.id}';
    final cancelKey = 'cancel_search_${item.requestId ?? item.user.id}';
    final acceptKey = 'accept_search_${item.requestId ?? item.user.id}';
    final rejectKey = 'reject_search_${item.requestId ?? item.user.id}';
    final removeKey = 'remove_search_${item.user.id}';
    final chatKey = 'chat_search_${item.user.id}';

    final controls = <Widget>[
      _buildCompactIconButton(
        icon: Icons.info_outline_rounded,
        tooltip: 'Информация о пользователе',
        onPressed: () => _showRequestInfoDialog(user: item.user),
      ),
    ];
    if (relation == 'none') {
      controls.add(
        _buildActionIcon(
          key: sendKey,
          icon: Icons.person_add_alt_1_rounded,
          tooltip: 'Добавить в друзья',
          call: (repo) => repo.sendRequest(item.user.id),
          success: 'Заявка отправлена',
        ),
      );
    } else if (relation == 'outgoing' && item.requestId != null) {
      controls.add(
        _buildActionIcon(
          key: cancelKey,
          icon: Icons.close_rounded,
          tooltip: 'Отменить заявку',
          call: (repo) => repo.cancelRequest(item.requestId!),
          success: 'Заявка отменена',
          danger: true,
        ),
      );
    } else if (relation == 'incoming' && item.requestId != null) {
      controls.addAll([
        _buildActionIcon(
          key: acceptKey,
          icon: Icons.check_rounded,
          tooltip: 'Принять заявку',
          call: (repo) => repo.acceptRequest(item.requestId!),
          success: 'Заявка принята',
        ),
        _buildActionIcon(
          key: rejectKey,
          icon: Icons.close_rounded,
          tooltip: 'Отклонить заявку',
          call: (repo) => repo.rejectRequest(item.requestId!),
          success: 'Заявка отклонена',
          danger: true,
        ),
      ]);
    } else if (relation == 'friend') {
      controls.addAll([
        _buildCompactIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: 'Написать сообщение',
          loading: _busy(chatKey),
          onPressed: _busy(chatKey)
              ? null
              : () => _openChatWithUser(item.user, actionKey: chatKey),
        ),
        _buildActionIcon(
          key: removeKey,
          icon: Icons.person_remove_alt_1_rounded,
          tooltip: 'Удалить из друзей',
          call: (repo) => repo.removeFriend(item.user.id),
          success: 'Пользователь удалён из друзей',
          danger: true,
        ),
      ]);
    }

    final relationLabel = switch (relation) {
      'friend' => 'Уже в друзьях',
      'incoming' => 'Входящая заявка',
      'outgoing' => 'Исходящая заявка',
      _ => 'Не в друзьях',
    };

    final controlRow = <Widget>[];
    for (var i = 0; i < controls.length; i++) {
      if (i > 0) {
        controlRow.add(const SizedBox(width: 4));
      }
      controlRow.add(controls[i]);
    }

    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(10),
      animate: false,
      child: Row(
        children: [
          _buildAvatar(item.user),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(item.user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: controlRow),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GradientCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(10),
        animate: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Поиск по нику',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : Container(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade400, width: 1.8),
                          ),
                          child: IconButton(
                            tooltip: 'Очистить поиск',
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchRevision++;
                              _searchController.clear();
                              setState(() {
                                _searchResults = const [];
                                _isSearching = false;
                              });
                              _searchFocusNode.requestFocus();
                            },
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                          ),
                        ),
                ),
                onChanged: _onSearchTextChanged,
                onSubmitted: (_) => _scheduleSearch(immediate: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.only(top: 80),
        children: const [
          Center(
            child: Text(
              'Введите запрос для поиска',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    if (_isSearching) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.only(top: 80),
        children: const [
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentStart,
              ),
            ),
          ),
        ],
      );
    }
    if (_searchResults.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.only(top: 80),
        children: const [
          Center(
            child: Text(
              'Ничего не найдено',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildSearchResultCard(_searchResults[index]),
    );
  }

  List<_FriendsTabKind> _visibleTabs(FriendsSnapshot? snapshot) {
    if (snapshot == null) {
      return const [
        _FriendsTabKind.friends,
        _FriendsTabKind.incoming,
        _FriendsTabKind.outgoing,
      ];
    }

    final result = <_FriendsTabKind>[_FriendsTabKind.friends];
    if (snapshot.incoming.isNotEmpty) result.add(_FriendsTabKind.incoming);
    if (snapshot.outgoing.isNotEmpty) result.add(_FriendsTabKind.outgoing);
    return result;
  }

  String _tabTitle(_FriendsTabKind tab, FriendsSnapshot? snapshot) {
    switch (tab) {
      case _FriendsTabKind.friends:
        if (snapshot == null) return 'Друзья';
        return 'Друзья (${snapshot.friends.length})';
      case _FriendsTabKind.incoming:
        if (snapshot == null) return 'Входящие';
        return 'Входящие (${snapshot.incoming.length})';
      case _FriendsTabKind.outgoing:
        if (snapshot == null) return 'Исходящие';
        return 'Исходящие (${snapshot.outgoing.length})';
    }
  }

  Widget _buildTabLabel(_FriendsTabKind tab, FriendsSnapshot? snapshot) {
    final title = _tabTitle(tab, snapshot);
    final incomingCount = snapshot?.incoming.length ?? 0;
    final isIncoming = tab == _FriendsTabKind.incoming;
    if (!isIncoming || incomingCount <= 0) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Входящие'),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$incomingCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabContent(_FriendsTabKind tab, FriendsSnapshot snapshot) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return _buildFriendsTab(snapshot);
      case _FriendsTabKind.incoming:
        return _buildIncomingTab(snapshot);
      case _FriendsTabKind.outgoing:
        return _buildOutgoingTab(snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final tabs = _visibleTabs(friendsAsync.valueOrNull);
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
                  const Spacer(),
                  _buildGradientHeaderIconButton(
                    icon: _isSearchExpanded ? Icons.search_off_rounded : Icons.search_rounded,
                    tooltip: _isSearchExpanded ? 'Свернуть поиск' : 'Показать поиск',
                    onPressed: _toggleSearch,
                    redFrame: _isSearchExpanded,
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
            if (_isSearchExpanded)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refreshSnapshot(refreshSearch: true),
                  child: _buildSearchResults(),
                ),
              )
            else ...[
              Expanded(
                child: DefaultTabController(
                  key: ValueKey('friends-tabs-${tabs.map((e) => e.name).join("_")}'),
                  length: tabs.length,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: TabBar(
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
                            for (final tab in tabs)
                              Tab(
                                child: _buildTabLabel(tab, friendsAsync.valueOrNull),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: friendsAsync.when(
                          data: (snapshot) {
                            return RefreshIndicator(
                              onRefresh: () => _refreshSnapshot(refreshSearch: false),
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (final tab in tabs) _tabContent(tab, snapshot),
                                ],
                              ),
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
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 46,
                                    color: Colors.red.shade700,
                                  ),
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
