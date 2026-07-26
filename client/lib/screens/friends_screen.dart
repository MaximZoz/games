import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

enum _FriendsTabKind { friends, incoming, outgoing, findFriend }

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 10;
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
  late TabController _tabController;
  final Set<String> _actionsInProgress = <String>{};
  Timer? _searchDebounce;
  int _searchRevision = 0;

  List<FriendSearchItem> _searchResults = const [];
  bool _isSearching = false;
  bool _isSearchLoadingMore = false;
  bool _searchHasMore = false;
  bool _isSearchExpanded = false;
  int _friendsVisibleCount = _pageSize;
  int _incomingVisibleCount = _pageSize;
  int _outgoingVisibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_isFindFriendTab && _searchController.text.trim().isNotEmpty) {
      _scheduleSearch(immediate: true);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final notifier = ref.read(mobileToolbarLeadingProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.state = null;
    });
    _searchDebounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isFindFriendTab =>
      _tabController.index == 3; // findFriend всегда последний

  void _showMessage(String? error, String? success) {}

  String _displayName(FriendUserItem user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Пользователь';
  }

  bool _matchesSearch(FriendUserItem user, String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase();
    final name = _displayName(user).toLowerCase();
    return name.contains(q);
  }

  List<FriendItem> _sortedAndFilteredFriends(
    List<FriendItem> friends,
    Map<String, PresenceEntry> presence,
    String searchQuery,
  ) {
    var list =
        friends.where((f) => _matchesSearch(f.user, searchQuery)).toList();
    list.sort((a, b) {
      final pa = presence[a.user.id];
      final pb = presence[b.user.id];
      final aOnline = pa?.online ?? false;
      final bOnline = pb?.online ?? false;
      if (aOnline != bOnline) return bOnline ? 1 : -1;
      if (aOnline) return 0;
      final aTime = pa?.lastSeenAt;
      final bTime = pb?.lastSeenAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final da = DateTime.tryParse(aTime);
      final db = DateTime.tryParse(bTime);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return list;
  }

  List<FriendRequestItem> _filteredRequests(
    List<FriendRequestItem> items,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return items;
    return items.where((r) => _matchesSearch(r.user, searchQuery)).toList();
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
    PresenceEntry? presence,
  }) async {
    final name = _displayName(user);
    final about = user.about?.trim();
    final genderIcon = _genderIcon(user.gender);
    final female = _isFemaleGender(user.gender);
    final statusText = presence == null
        ? null
        : (presence.online ? 'Онлайн' : formatLastSeen(presence.lastSeenAt));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 380;
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
            ),
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
                      _buildAvatar(user, isOnline: presence?.online),
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
                            if (statusText != null && statusText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
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
                  if ((user.age != null && user.age! > 0) ||
                      genderIcon != null) ...[
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
                            backgroundColor: female
                                ? const Color(0xFFFCE7F3)
                                : AppColors.accentSoft,
                            foregroundColor: female
                                ? const Color(0xFFBE185D)
                                : AppColors.textPrimary,
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
          ),
        );
      },
    );
  }

  Widget _buildAvatar(FriendUserItem user, {bool? isOnline}) {
    Widget avatar;
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.isNotEmpty) {
      final memoryImage = AvatarMemoryCache.fromAvatarValue(user.avatarValue);
      if (memoryImage != null) {
        avatar = CircleAvatar(
          radius: 20,
          backgroundImage: memoryImage,
        );
      } else {
        avatar = _buildLetterAvatar(user);
      }
    } else if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final index = int.tryParse(user.avatarValue!);
      if (index != null && index >= 0 && index < _presetAvatarIcons.length) {
        avatar = CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[index], color: AppColors.accentStart),
        );
      } else {
        avatar = _buildLetterAvatar(user);
      }
    } else {
      avatar = _buildLetterAvatar(user);
    }
    if (isOnline == true) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceCard, width: 1),
              ),
            ),
          ),
        ],
      );
    }
    return avatar;
  }

  Widget _buildLetterAvatar(FriendUserItem user) {
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
      context.push('/chats/$chatID?name=$name&from=friends');
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
        _isSearchLoadingMore = false;
        _searchHasMore = false;
      }
    });

    if (_isSearchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
      if (_searchController.text.trim().isNotEmpty) {
        _scheduleSearch(immediate: true, forceRun: true);
      }
    } else {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _refreshSnapshot({bool refreshSearch = false}) async {
    try {
      ref.invalidate(friendsSnapshotProvider);
      // Онлайн/last seen — иначе статус друга не меняется без перезагрузки.
      refreshPresence(ref);
      await Future.wait([
        ref.read(friendsSnapshotProvider.future),
        ref.read(presenceMapProvider.future),
      ]);
      if (mounted) {
        setState(() {
          _friendsVisibleCount = _pageSize;
          _incomingVisibleCount = _pageSize;
          _outgoingVisibleCount = _pageSize;
        });
      }
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

  void _scheduleSearch({bool immediate = false, bool forceRun = false}) {
    if (!forceRun && !_isFindFriendTab) return;
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchRevision++;
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _isSearchLoadingMore = false;
        _searchHasMore = false;
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
        _isSearchLoadingMore = false;
        _searchHasMore = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _isSearchLoadingMore = false;
      _searchHasMore = false;
    });
    final repo = ref.read(friendsRepositoryProvider);
    try {
      final page = await repo.searchUsersPage(
        q,
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted || currentRequestID != _searchRevision) return;
      setState(() {
        _searchResults = page.users;
        _searchHasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted || currentRequestID != _searchRevision) return;
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
      if (mounted && currentRequestID == _searchRevision) {
        setState(() => _searchHasMore = false);
      }
    } finally {
      if (mounted && currentRequestID == _searchRevision) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isSearching || _isSearchLoadingMore || !_searchHasMore) return;
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final requestID = _searchRevision;
    if (!mounted) return;
    setState(() => _isSearchLoadingMore = true);

    final repo = ref.read(friendsRepositoryProvider);
    try {
      final page = await repo.searchUsersPage(
        q,
        limit: _pageSize,
        offset: _searchResults.length,
      );
      if (!mounted || requestID != _searchRevision) return;
      setState(() {
        _searchResults = [..._searchResults, ...page.users];
        _searchHasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted || requestID != _searchRevision) return;
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
      if (mounted && requestID == _searchRevision) {
        setState(() => _searchHasMore = false);
      }
    } finally {
      if (mounted && requestID == _searchRevision) {
        setState(() => _isSearchLoadingMore = false);
      }
    }
  }

  void _updateSearchRelation(
    String userID, {
    required String relationStatus,
    String? requestID,
  }) {
    if (!mounted) return;
    setState(() {
      _searchResults = _searchResults.map((entry) {
        if (entry.user.id != userID) return entry;
        return FriendSearchItem(
          user: entry.user,
          relationStatus: relationStatus,
          requestId: requestID,
        );
      }).toList();
    });
  }

  Future<void> _runSearchAction({
    required String key,
    required Future<void> Function(FriendsRepository repo) call,
    required String success,
    required String userID,
    required String nextRelationStatus,
    String? nextRequestID,
  }) async {
    if (_actionsInProgress.contains(key)) return;
    setState(() => _actionsInProgress.add(key));

    final repo = ref.read(friendsRepositoryProvider);
    try {
      await call(repo);
      _showMessage(null, success);
      _updateSearchRelation(
        userID,
        relationStatus: nextRelationStatus,
        requestID: nextRequestID,
      );
      await _refreshSnapshot(refreshSearch: false);
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
    required BuildContext context,
    required FriendUserItem user,
    required String subtitle,
    required List<Widget> actions,
    Widget? trailing,
    bool alignActionsRight = false,
    PresenceEntry? presence,
  }) {
    final compactDesktopCard = isWide(context);
    final statusText = presence == null
        ? null
        : (presence.online ? 'Онлайн' : formatLastSeen(presence.lastSeenAt));
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(compactDesktopCard ? 10 : 14),
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAvatar(user, isOnline: presence?.online),
              SizedBox(width: compactDesktopCard ? 8 : 10),
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
                    if (statusText != null && statusText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
          SizedBox(height: compactDesktopCard ? 6 : 10),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compactDesktopCard ? 11 : 12,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: alignActionsRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: actions),
            ),
          ],
        ],
      ),
    );
  }

  void _expandVisibleForTab(_FriendsTabKind tab, int totalCount) {
    if (!mounted) return;
    int current;
    switch (tab) {
      case _FriendsTabKind.friends:
        current = _friendsVisibleCount;
        break;
      case _FriendsTabKind.incoming:
        current = _incomingVisibleCount;
        break;
      case _FriendsTabKind.outgoing:
        current = _outgoingVisibleCount;
        break;
      case _FriendsTabKind.findFriend:
        return; // не используется для поиска
    }
    if (current >= totalCount) return;
    final next = current + _pageSize;
    final nextCount = next > totalCount ? totalCount : next;
    setState(() {
      switch (tab) {
        case _FriendsTabKind.friends:
          _friendsVisibleCount = nextCount;
          break;
        case _FriendsTabKind.incoming:
          _incomingVisibleCount = nextCount;
          break;
        case _FriendsTabKind.outgoing:
          _outgoingVisibleCount = nextCount;
          break;
        case _FriendsTabKind.findFriend:
          break;
      }
    });
  }

  Widget _buildAdaptiveList<T>({
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    required String emptyText,
    required _FriendsTabKind tab,
  }) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
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

    final configuredVisibleCount = switch (tab) {
      _FriendsTabKind.friends => _friendsVisibleCount,
      _FriendsTabKind.incoming => _incomingVisibleCount,
      _FriendsTabKind.outgoing => _outgoingVisibleCount,
      _FriendsTabKind.findFriend => items.length,
    };
    final visibleCount = configuredVisibleCount > items.length
        ? items.length
        : configuredVisibleCount;
    final hasMore = visibleCount < items.length;
    final totalCount = visibleCount + (hasMore ? 1 : 0);

    final useGrid = isWide(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (useGrid) {
          const gap = 12.0;
          const maxCellWidth = 320.0;
          final availableWidth = constraints.maxWidth - 32;
          final crossAxisCount =
              (availableWidth / (maxCellWidth + gap)).floor().clamp(1, 4);
          final itemWidth =
              (availableWidth - gap * (crossAxisCount - 1)) / crossAxisCount;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics()),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < visibleCount; i++)
                      SizedBox(
                        width: itemWidth,
                        child: itemBuilder(items[i]),
                      ),
                  ],
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _expandVisibleForTab(tab, items.length),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics()),
          itemCount: totalCount,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= visibleCount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _expandVisibleForTab(tab, items.length);
              });
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.topCenter,
              child: itemBuilder(items[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsTab(
      FriendsSnapshot snapshot, Map<String, PresenceEntry> presence) {
    final searchQuery = _searchController.text.trim();
    final items =
        _sortedAndFilteredFriends(snapshot.friends, presence, searchQuery);
    return _buildAdaptiveList<FriendItem>(
      items: items,
      emptyText: 'У вас пока нет друзей',
      tab: _FriendsTabKind.friends,
      itemBuilder: (item) {
        final key = 'remove_${item.user.id}';
        final chatKey = 'chat_${item.user.id}';
        return _buildUserCard(
          context: context,
          user: item.user,
          presence: presence[item.user.id],
          subtitle: 'Дружите с: ${_formatDateTime(item.createdAt)}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Информация о пользователе',
                onPressed: () => _showRequestInfoDialog(
                    user: item.user, presence: presence[item.user.id]),
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

  Widget _buildIncomingTab(
      FriendsSnapshot snapshot, Map<String, PresenceEntry> presence) {
    final searchQuery = _searchController.text.trim();
    final items = _filteredRequests(snapshot.incoming, searchQuery);
    return _buildAdaptiveList<FriendRequestItem>(
      items: items,
      emptyText: 'Нет входящих заявок',
      tab: _FriendsTabKind.incoming,
      itemBuilder: (item) {
        final acceptKey = 'accept_${item.requestId}';
        final rejectKey = 'reject_${item.requestId}';
        final chatKey = 'chat_incoming_${item.user.id}';
        return _buildUserCard(
          context: context,
          user: item.user,
          presence: presence[item.user.id],
          subtitle: 'Входящая заявка: ${_formatDateTime(item.createdAt)}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Информация о пользователе',
                onPressed: () => _showRequestInfoDialog(
                    user: item.user, presence: presence[item.user.id]),
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

  Widget _buildOutgoingTab(
      FriendsSnapshot snapshot, Map<String, PresenceEntry> presence) {
    final searchQuery = _searchController.text.trim();
    final items = _filteredRequests(snapshot.outgoing, searchQuery);
    return _buildAdaptiveList<FriendRequestItem>(
      items: items,
      emptyText: 'Нет исходящих заявок',
      tab: _FriendsTabKind.outgoing,
      itemBuilder: (item) {
        final cancelKey = 'cancel_${item.requestId}';
        final chatKey = 'chat_outgoing_${item.user.id}';
        return _buildUserCard(
          context: context,
          user: item.user,
          presence: presence[item.user.id],
          subtitle: 'Исходящая заявка: ${_formatDateTime(item.createdAt)}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Информация о пользователе',
                onPressed: () => _showRequestInfoDialog(
                    user: item.user, presence: presence[item.user.id]),
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
    final borderColor = danger
        ? Colors.red.shade300
        : AppColors.accentStart.withValues(alpha: 0.55);
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
    final gradient =
        redFrame ? null : AppGradients.borderAt(_isSearchExpanded ? 0.68 : 0.2);
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

  Widget _buildSearchResultCard(BuildContext context, FriendSearchItem item,
      Map<String, PresenceEntry> presence) {
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
        onPressed: () => _showRequestInfoDialog(
            user: item.user, presence: presence[item.user.id]),
      ),
    ];
    if (relation == 'none') {
      final busy = _busy(sendKey);
      controls.add(
        _buildCompactIconButton(
          icon: Icons.person_add_alt_1_rounded,
          tooltip: 'Добавить в друзья',
          loading: busy,
          onPressed: busy
              ? null
              : () => _runSearchAction(
                    key: sendKey,
                    call: (repo) => repo.sendRequest(item.user.id),
                    success: 'Заявка отправлена',
                    userID: item.user.id,
                    nextRelationStatus: 'outgoing',
                    nextRequestID: item.requestId,
                  ),
        ),
      );
    } else if (relation == 'outgoing' && item.requestId != null) {
      final busy = _busy(cancelKey);
      controls.add(
        _buildCompactIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Отменить заявку',
          danger: true,
          loading: busy,
          onPressed: busy
              ? null
              : () => _runSearchAction(
                    key: cancelKey,
                    call: (repo) => repo.cancelRequest(item.requestId!),
                    success: 'Заявка отменена',
                    userID: item.user.id,
                    nextRelationStatus: 'none',
                  ),
        ),
      );
    } else if (relation == 'incoming' && item.requestId != null) {
      final acceptBusy = _busy(acceptKey);
      final rejectBusy = _busy(rejectKey);
      controls.addAll([
        _buildCompactIconButton(
          icon: Icons.check_rounded,
          tooltip: 'Принять заявку',
          loading: acceptBusy,
          onPressed: acceptBusy
              ? null
              : () => _runSearchAction(
                    key: acceptKey,
                    call: (repo) => repo.acceptRequest(item.requestId!),
                    success: 'Заявка принята',
                    userID: item.user.id,
                    nextRelationStatus: 'friend',
                  ),
        ),
        _buildCompactIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Отклонить заявку',
          danger: true,
          loading: rejectBusy,
          onPressed: rejectBusy
              ? null
              : () => _runSearchAction(
                    key: rejectKey,
                    call: (repo) => repo.rejectRequest(item.requestId!),
                    success: 'Заявка отклонена',
                    userID: item.user.id,
                    nextRelationStatus: 'none',
                  ),
        ),
      ]);
    } else if (relation == 'friend') {
      final removeBusy = _busy(removeKey);
      controls.addAll([
        _buildCompactIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: 'Написать сообщение',
          loading: _busy(chatKey),
          onPressed: _busy(chatKey)
              ? null
              : () => _openChatWithUser(item.user, actionKey: chatKey),
        ),
        _buildCompactIconButton(
          icon: Icons.person_remove_alt_1_rounded,
          tooltip: 'Удалить из друзей',
          danger: true,
          loading: removeBusy,
          onPressed: removeBusy
              ? null
              : () => _runSearchAction(
                    key: removeKey,
                    call: (repo) => repo.removeFriend(item.user.id),
                    success: 'Пользователь удалён из друзей',
                    userID: item.user.id,
                    nextRelationStatus: 'none',
                  ),
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

    final isDesktop = isWide(context);
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.all(10),
      animate: false,
      child: Row(
        children: [
          _buildAvatar(item.user, isOnline: presence[item.user.id]?.online),
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
                if (presence[item.user.id] != null) ...[
                  Text(
                    presence[item.user.id]!.online
                        ? 'Онлайн'
                        : formatLastSeen(presence[item.user.id]!.lastSeenAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
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
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.red.shade400, width: 1.8),
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
                                _isSearchLoadingMore = false;
                                _searchHasMore = false;
                              });
                              _searchFocusNode.requestFocus();
                            },
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.red),
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

  Widget _buildSearchResults(Map<String, PresenceEntry> presence) {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.only(top: 80),
        children: const [
          Center(
            child: Text(
              'Используйте поиск, чтобы найти новых друзей',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    if (_isSearching) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
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
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
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
    final showPagingLoader = _isSearchLoadingMore || _searchHasMore;
    final itemCount = _searchResults.length + (showPagingLoader ? 1 : 0);

    if (isWide(context)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          const maxCellWidth = 600.0;
          final availableWidth = constraints.maxWidth - 32;
          final crossAxisCount =
              (availableWidth / (maxCellWidth + gap)).floor().clamp(1, 4);
          final itemWidth =
              (availableWidth - gap * (crossAxisCount - 1)) / crossAxisCount;
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  _searchHasMore &&
                  !_isSearchLoadingMore) {
                final m = notification.metrics;
                if (m.pixels >= m.maxScrollExtent - 80) {
                  unawaited(_loadMoreSearchResults());
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (var i = 0; i < _searchResults.length; i++)
                        SizedBox(
                          width: itemWidth,
                          child: _buildSearchResultCard(
                              context, _searchResults[i], presence),
                        ),
                    ],
                  ),
                  if (showPagingLoader)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
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
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          if (_searchHasMore && !_isSearchLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_loadMoreSearchResults());
            });
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
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
        return Align(
          alignment: Alignment.topCenter,
          child:
              _buildSearchResultCard(context, _searchResults[index], presence),
        );
      },
    );
  }

  Widget _buildWideHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildInlineSearchField(),
        ),
      ),
    );
  }

  Widget _buildInlineSearchField() {
    return AnimatedBorderBox(
      animateBorder: true,
      borderWidth: 2,
      borderRadius: AppRadius.input,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Поиск по нику',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Очистить',
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchRevision++;
                    _searchController.clear();
                    setState(() {
                      _searchResults = const [];
                      _isSearching = false;
                      _isSearchLoadingMore = false;
                      _searchHasMore = false;
                    });
                    _searchFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: _onSearchTextChanged,
        onSubmitted: (_) => _scheduleSearch(immediate: true),
      ),
    );
  }

  List<_FriendsTabKind> _visibleTabs(FriendsSnapshot? snapshot) {
    return const [
      _FriendsTabKind.friends,
      _FriendsTabKind.incoming,
      _FriendsTabKind.outgoing,
      _FriendsTabKind.findFriend,
    ];
  }

  String _tabTitle(_FriendsTabKind tab) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return 'Друзья';
      case _FriendsTabKind.incoming:
        return 'Входящие';
      case _FriendsTabKind.outgoing:
        return 'Исходящие';
      case _FriendsTabKind.findFriend:
        return 'Найти друга';
    }
  }

  int? _tabCount(
    _FriendsTabKind tab,
    FriendsSnapshot? snapshot,
    int? totalUsersCount,
  ) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return snapshot?.friends.length;
      case _FriendsTabKind.incoming:
        return snapshot?.incoming.length;
      case _FriendsTabKind.outgoing:
        return snapshot?.outgoing.length;
      case _FriendsTabKind.findFriend:
        return totalUsersCount;
    }
  }

  Widget _buildTabLabel(
    _FriendsTabKind tab,
    FriendsSnapshot? snapshot,
    int? totalUsersCount,
  ) {
    final title = _tabTitle(tab);
    final count = _tabCount(tab, snapshot, totalUsersCount);
    final isIncoming = tab == _FriendsTabKind.incoming;
    final isFindFriend = tab == _FriendsTabKind.findFriend;
    final countColor = (isIncoming && (count ?? 0) > 0)
        ? Colors.red.shade600
        : isFindFriend
            ? Colors.green.shade700
            : AppColors.accentStart;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: countColor,
              ),
            ),
          )
        else
          const SizedBox(height: 22),
        if (count != null) const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _tabContent(_FriendsTabKind tab, FriendsSnapshot snapshot,
      Map<String, PresenceEntry> presence) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(),
          child: _buildFriendsTab(snapshot, presence),
        );
      case _FriendsTabKind.incoming:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(),
          child: _buildIncomingTab(snapshot, presence),
        );
      case _FriendsTabKind.outgoing:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(),
          child: _buildOutgoingTab(snapshot, presence),
        );
      case _FriendsTabKind.findFriend:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(refreshSearch: true),
          child: _buildSearchResults(presence),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final totalUsersCount = ref.watch(totalUsersCountProvider).valueOrNull;
    final tabs = _visibleTabs(friendsAsync.valueOrNull);
    final compact = MediaQuery.sizeOf(context).width < 430;
    final wide = isWide(context);
    final path = ref.watch(currentRoutePathProvider);
    if (!wide && path == '/friends') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(mobileToolbarLeadingProvider.notifier).state =
              _buildGradientHeaderIconButton(
            icon: _isSearchExpanded
                ? Icons.search_off_rounded
                : Icons.search_rounded,
            tooltip: _isSearchExpanded ? 'Свернуть поиск' : 'Показать поиск',
            onPressed: _toggleSearch,
            redFrame: _isSearchExpanded,
          );
        });
      });
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildWideHeader(),
              ),
            if (!wide)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedSwitcher(
                  duration: AppDurations.short,
                  child: _isSearchExpanded
                      ? _buildSearchPanel()
                      : const SizedBox(
                          key: ValueKey('friends-search-collapsed'),
                        ),
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Column(
                    key: const ValueKey('friends-tabs'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: false,
                          tabAlignment: TabAlignment.fill,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
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
                                child: _buildTabLabel(
                                  tab,
                                  friendsAsync.valueOrNull,
                                  totalUsersCount,
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
                              // Свайп между табами друзей нужен; bottom-nav
                              // от history защищён через Router.neglect.
                              physics: const PageScrollPhysics(),
                              children: [
                                for (final tab in tabs)
                                  _tabContent(tab, snapshot, presence),
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
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 46,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    err.toString(),
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Colors.red.shade700),
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
            ),
          ],
        ),
      ),
    );
  }
}
