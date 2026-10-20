import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/chats/chats_gamepad.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_auth.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_highlight.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/message_status_ticks.dart';
import 'package:multigames_client/ui/widgets/screen_load_error.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/admin/admin_provider.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';

/// В альбоме шапка «Новый чат» + поле 28pt не влезают над клавиатурой.
@visibleForTesting
bool chatsNewChatUseCompactStrip({required bool phoneLandscape}) =>
    phoneLandscape;

/// Высота шита поиска друга: в альбоме — щель над клавиатурой, не 420.
@visibleForTesting
double chatsNewChatSheetHeight({
  required bool phoneLandscape,
  required double viewHeight,
  required double keyboardInset,
}) {
  if (!phoneLandscape) return 420;
  final available = viewHeight - keyboardInset - 8;
  return available.clamp(72.0, viewHeight);
}

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({
    super.key,
    this.inSplitView = false,
    this.sidebarCompact = false,
  });

  /// В split-view на десктопе используем go вместо push при выборе чата.
  final bool inSplitView;
  /// Компактный режим: только круглые аватары (для свёрнутой панели).
  final bool sidebarCompact;

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

enum _ChatSwipeAction { clear, block }

class _ChatsScreenState extends ConsumerState<ChatsScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  static const int _chatsPageSize = 10;
  static const int _modalPageSize = 10;

  String? _error;
  Object? _chatsLoadError;
  bool _isOpeningStartChatDialog = false;
  bool _isOpeningBlockedUsersDialog = false;
  bool _isStartingChat = false;
  bool _isNavigatingToChat = false;
  bool _isLoadingChats = true;
  bool _isLoadingMoreChats = false;
  bool _hasMoreChats = true;
  bool _isChatsRequestInFlight = false;
  final Set<String> _chatActionInFlight = <String>{};
  final ScrollController _chatsScrollController = ScrollController();
  late final AnimationController _borderAnimationController;
  Future<List<FriendItem>>? _friendsLoadInFlight;
  List<FriendItem> _cachedFriends = const [];
  List<ChatPreviewItem> _chats = const [];
  int _gamepadChatIndex = 0;
  int? _gamepadActionIndex;
  final Map<String, SlidableController> _slidableControllers = {};
  final Map<String, GlobalKey> _gamepadChatKeys = {};
  DateTime? _friendsCachedAt;
  Timer? _navigationLockTimer;

  static const Duration _friendsCacheTTL = Duration(minutes: 2);

  /// Сортировка чатов по времени последнего сообщения / обновления (новые сверху).
  static List<ChatPreviewItem> _sortChats(List<ChatPreviewItem> list) {
    final sorted = List<ChatPreviewItem>.from(list);
    sorted.sort((a, b) {
      final ta = a.lastMessage?.createdAt ?? a.updatedAt;
      final tb = b.lastMessage?.createdAt ?? b.updatedAt;
      final da = DateTime.tryParse(ta);
      final db = DateTime.tryParse(tb);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return sorted;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      chatsRouteObserver.unsubscribe(this);
      chatsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Возврат из комнаты чата: список уже в стеке — только подтянуть кэш
    // (unread уже сброшен в markChatReadInChatsCache), без полного reload.
    final cache = ref.read(chatsListCacheProvider);
    if (cache == null || cache.chats.isEmpty || !mounted) return;
    setState(() {
      _chats = _sortChats(cache.chats);
      _hasMoreChats = cache.chats.length >= _chatsPageSize;
      _isLoadingChats = false;
      _error = null;
      _chatsLoadError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _chatsScrollController.addListener(_onChatsScroll);
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    unawaited(_loadChatsOrUseCache());
    unawaited(_warmUpStartChatData());
    unawaited(
      ref.read(blockedUsersProvider.future).then((_) {}, onError: (_, __) {}),
    );
  }

  @override
  void dispose() {
    final notifier = ref.read(mobileToolbarLeadingProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.state = null;
    });
    chatsRouteObserver.unsubscribe(this);
    _borderAnimationController.dispose();
    for (final controller in _slidableControllers.values) {
      controller.dispose();
    }
    _chatsScrollController.removeListener(_onChatsScroll);
    _chatsScrollController.dispose();
    _navigationLockTimer?.cancel();
    super.dispose();
  }

  bool get _hasFreshFriendsCache {
    final ts = _friendsCachedAt;
    if (ts == null) return false;
    if (_cachedFriends.isEmpty) return false;
    return DateTime.now().difference(ts) <= _friendsCacheTTL;
  }

  void _cacheFriends(List<FriendItem> friends) {
    _cachedFriends = List<FriendItem>.unmodifiable(friends);
    _friendsCachedAt = DateTime.now();
  }

  Future<void> _warmUpStartChatData() async {
    try {
      await _loadFriendsForStartChat();
    } catch (_) {
      // Тихий прогрев: ошибки покажем только если пользователь откроет диалог.
    }
  }

  Future<List<FriendItem>> _loadFriendsForStartChat({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final liveSnapshot = ref.read(friendsSnapshotProvider).valueOrNull;
      if (liveSnapshot != null && liveSnapshot.friends.isNotEmpty) {
        _cacheFriends(liveSnapshot.friends);
        return liveSnapshot.friends;
      }
      if (_hasFreshFriendsCache) {
        return _cachedFriends;
      }
    }
    final inFlight = _friendsLoadInFlight;
    if (!forceRefresh && inFlight != null) {
      return inFlight;
    }

    late Future<List<FriendItem>> request;
    request = () async {
      try {
        // Для модалки "Новый чат" берём свежие данные напрямую, чтобы не
        // застревать на пустом снимке stream-провайдера.
        final snapshot = await ref.read(friendsRepositoryProvider).getFriends();
        _cacheFriends(snapshot.friends);
        return snapshot.friends;
      } catch (_) {
        // Если прямой запрос недоступен, пробуем потоковый снимок.
        final snapshot = await ref.read(friendsSnapshotProvider.future);
        _cacheFriends(snapshot.friends);
        return snapshot.friends;
      }
    }();

    _friendsLoadInFlight = request;
    try {
      return await request;
    } on FriendsException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
      rethrow;
    } finally {
      if (identical(_friendsLoadInFlight, request)) {
        _friendsLoadInFlight = null;
      }
    }
  }

  static const _chatsCacheTTL = Duration(seconds: 60);

  Future<void> _loadChatsOrUseCache() async {
    final cache = ref.read(chatsListCacheProvider);
    if (cache != null &&
        DateTime.now().difference(cache.at) <= _chatsCacheTTL &&
        cache.chats.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _chats = _sortChats(cache.chats);
        _hasMoreChats = cache.chats.length >= _chatsPageSize;
        _isLoadingChats = false;
        _error = null;
        _chatsLoadError = null;
      });
      return;
    }
    return unawaited(_loadChats(refreshOnline: true));
  }

  Future<void> _loadChats({
    bool showLoading = true,
    bool refreshOnline = false,
  }) async {
    if (!mounted || _isChatsRequestInFlight) return;
    _isChatsRequestInFlight = true;
    setState(() {
      _error = null;
      _chatsLoadError = null;
      // Не мигаем спиннером, если список уже на экране.
      if (showLoading && _chats.isEmpty) {
        _isLoadingChats = true;
      }
      _isLoadingMoreChats = false;
    });
    try {
      final raw = await ref
          .read(chatsRepositoryProvider)
          .listChats(limit: _chatsPageSize, offset: 0);
      if (!mounted) return;
      final chats = _sortChats(raw);
      ref.read(chatsListCacheProvider.notifier).state =
          (chats: chats, at: DateTime.now());
      setState(() {
        _chats = chats;
        _hasMoreChats = raw.length >= _chatsPageSize;
        _isLoadingChats = false;
        _isLoadingMoreChats = false;
        _error = null;
        _chatsLoadError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chatsScrollController.hasClients) return;
        final position = _chatsScrollController.position;
        if (position.maxScrollExtent <= 0 &&
            _hasMoreChats &&
            !_isLoadingMoreChats) {
          unawaited(_loadMoreChats());
        }
      });
      unawaited(refreshBlockedUsers(ref, force: true).catchError((_) {}));
      // Онлайн — только по явному pull-to-refresh / первому загрузу.
      if (refreshOnline) {
        try {
          refreshPresence(ref);
          await ref.read(presenceMapProvider.future);
        } catch (_) {}
      }
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _chatsLoadError = e;
        _isLoadingChats = false;
        _isLoadingMoreChats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatsLoadError = e;
        _isLoadingChats = false;
        _isLoadingMoreChats = false;
      });
    } finally {
      _isChatsRequestInFlight = false;
    }
  }

  Future<void> _loadMoreChats() async {
    if (_isLoadingChats || _isLoadingMoreChats || !_hasMoreChats) return;
    setState(() => _isLoadingMoreChats = true);
    try {
      final next = await ref.read(chatsRepositoryProvider).listChats(
            limit: _chatsPageSize,
            offset: _chats.length,
          );
      if (!mounted) return;
      final existingIDs = _chats.map((e) => e.chatID).toSet();
      final uniqueNext = next.where((item) => !existingIDs.contains(item.chatID));
      final merged = _sortChats([..._chats, ...uniqueNext]);
      setState(() {
        _chats = merged;
        _hasMoreChats = uniqueNext.isNotEmpty && next.length >= _chatsPageSize;
        _isLoadingMoreChats = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chatsScrollController.hasClients) return;
        final position = _chatsScrollController.position;
        if (position.maxScrollExtent <= 0 &&
            _hasMoreChats &&
            !_isLoadingMoreChats) {
          unawaited(_loadMoreChats());
        }
      });
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoadingMoreChats = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMoreChats = false);
    }
  }

  void _onChatsScroll() {
    if (!_chatsScrollController.hasClients) return;
    final position = _chatsScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      unawaited(_loadMoreChats());
    }
  }

  Future<void> _openStartChatDialog() async {
    if (_isOpeningStartChatDialog || _isStartingChat || _isNavigatingToChat) {
      return;
    }
    setState(() {
      _isOpeningStartChatDialog = true;
      _error = null;
    });

    FriendUserItem? pickedUser;
    try {
      pickedUser = await _pickFriendDialog();
    } finally {
      if (mounted) {
        setState(() => _isOpeningStartChatDialog = false);
      }
    }

    if (!mounted) return;
    if (pickedUser == null) return;

    await _startChatWithUser(pickedUser);
  }

  Future<void> _openBlockedUsersDialog() async {
    if (_isOpeningBlockedUsersDialog || _isOpeningStartChatDialog || _isNavigatingToChat) {
      return;
    }
    setState(() => _isOpeningBlockedUsersDialog = true);
    try {
      final wide = isWide(context);
      if (wide) {
        await _showBlockedUsersDialogCentered();
      } else {
        await _showBlockedUsersBottomSheet();
      }
    } finally {
      if (mounted) setState(() => _isOpeningBlockedUsersDialog = false);
    }
  }

  Future<void> _showBlockedUsersDialogCentered() async {
    final unblocking = <String>{};
    final locallyHiddenUserIDs = <String>{};
    var visibleBlockedCount = _modalPageSize;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.center,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Consumer(
                  builder: (context, modalRef, _) {
                    return _buildBlockedUsersContent(
                      modalRef: modalRef,
                      setSheetState: setSheetState,
                      unblocking: unblocking,
                      locallyHiddenUserIDs: locallyHiddenUserIDs,
                      visibleBlockedCount: visibleBlockedCount,
                      onVisibleCountChanged: (v) => visibleBlockedCount = v,
                      wrapInSheet: false,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBlockedUsersBottomSheet() async {
    final unblocking = <String>{};
    final locallyHiddenUserIDs = <String>{};
    var visibleBlockedCount = _modalPageSize;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 10,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Consumer(
                  builder: (context, modalRef, _) {
                    return _buildBlockedUsersContent(
                      modalRef: modalRef,
                      setSheetState: setSheetState,
                      unblocking: unblocking,
                      locallyHiddenUserIDs: locallyHiddenUserIDs,
                      visibleBlockedCount: visibleBlockedCount,
                      onVisibleCountChanged: (v) => visibleBlockedCount = v,
                      wrapInSheet: true,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedUsersContent({
    required WidgetRef modalRef,
    required void Function(void Function()) setSheetState,
    required Set<String> unblocking,
    required Set<String> locallyHiddenUserIDs,
    required int visibleBlockedCount,
    required void Function(int) onVisibleCountChanged,
    required bool wrapInSheet,
  }) {
    final blockedAsync = modalRef.watch(blockedUsersProvider);
    final blockedRaw = blockedAsync.valueOrNull ?? const <BlockedChatUserItem>[];
    var currentVisible = visibleBlockedCount;
    final blocked = blockedRaw
        .where((entry) => !locallyHiddenUserIDs.contains(entry.user.id))
        .toList(growable: false);
    if (currentVisible > blocked.length) {
      currentVisible = blocked.length;
      onVisibleCountChanged(currentVisible);
    }

    Widget content;
    if (blockedAsync.isLoading && blockedRaw.isEmpty) {
      content = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (blockedAsync.hasError && blockedRaw.isEmpty) {
      final err = blockedAsync.error;
      final message = formatUserError(err, fallback: LocaleService.l10n.chatsLoadListFailed);
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setSheetState(() => onVisibleCountChanged(_modalPageSize));
                unawaited(refreshBlockedUsers(modalRef, force: true));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
            ),
          ),
        ],
      );
    } else if (blocked.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              context.l10n.chatsBlockedEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    } else {
      final visible = currentVisible > blocked.length ? blocked.length : currentVisible;
      final hasMore = visible < blocked.length;
      final itemCount = visible + (hasMore ? 1 : 0);
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index >= visible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setSheetState(() {
                final next = currentVisible + _modalPageSize;
                onVisibleCountChanged(next > blocked.length ? blocked.length : next);
              });
            });
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final entry = blocked[index];
          final user = entry.user;
          final busy = unblocking.contains(user.id);
          return Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  _AvatarDot(user: user),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _peerTitle(user),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.chatsBlockedAt(_formatDateTime(entry.blockedAt)),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setSheetState(() => unblocking.add(user.id));
                            try {
                              await modalRef
                                  .read(chatsRepositoryProvider)
                                  .unblockUser(user.id);
                              if (!context.mounted) return;
                              setSheetState(
                                () => locallyHiddenUserIDs.add(user.id),
                              );
                            } on ChatException catch (e) {
                              if (!context.mounted) return;
                              final sheetContext = context;
                              if (e.statusCode == 401) {
                                await modalRef
                                    .read(authStateProvider.notifier)
                                    .logout();
                                if (!sheetContext.mounted) return;
                                sheetContext.go('/login');
                                return;
                              }
                              showAppSnackBar(
                                sheetContext,
                                message: e.message,
                                kind: AppSnackKind.error,
                              );
                            } finally {
                              if (context.mounted) {
                                setSheetState(() => unblocking.remove(user.id));
                              }
                            }
                          },
                    child: Text(context.l10n.chatsUnblock),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    const headerReserved = 80.0;
    final cardContent = GradientCard(
      animate: false,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final safeListHeight = (availableHeight - headerReserved).clamp(120.0, double.infinity);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.chatsBlockedUsers,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (wrapInSheet)
                SizedBox(
                  height: (screenHeight * 0.5).clamp(200.0, 400.0),
                  child: content,
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: availableHeight.isFinite ? safeListHeight : screenHeight * 0.5),
                  child: content,
                ),
            ],
          );
        },
      ),
    );
    return cardContent;
  }

  Future<void> _startChatWithUser(FriendUserItem pickedUser) async {
    if (_isStartingChat || _isNavigatingToChat) return;
    setState(() => _isStartingChat = true);
    try {
      final chatID = await ref.read(chatsRepositoryProvider).startChat(pickedUser.id);
      if (!mounted || chatID.isEmpty) return;
      unawaited(_loadChats());
      _openChatRoute(
        chatID: chatID,
        peerName: _friendTitle(pickedUser),
      );
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = LocaleService.l10n.chatsCreateFailed);
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
    }
  }

  /// Открывает чат с поддержкой: определяет support-юзера, создаёт чат, открывает.
  Future<void> _openSupport() async {
    if (_isStartingChat || _isNavigatingToChat) return;
    setState(() => _isStartingChat = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final support = await repo.getSupportUser();
      if (!mounted) return;
      if (support == null) {
        setState(() => _error = context.l10n.supportUnavailable);
        return;
      }
      final chatID = await ref.read(chatsRepositoryProvider).startChat(support.id);
      if (!mounted || chatID.isEmpty) return;
      unawaited(_loadChats());
      _openChatRoute(chatID: chatID, peerName: context.l10n.supportTitle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.supportOpenFailed);
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  void _openChatRoute({
    required String chatID,
    required String peerName,
  }) {
    if (_isNavigatingToChat) return;
    setState(() => _isNavigatingToChat = true);
    _navigationLockTimer?.cancel();
    _navigationLockTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isNavigatingToChat = false);
      }
    });
    final name = Uri.encodeQueryComponent(peerName);
    // Сохраняем превью, чтобы при pop не делать полный reload списка.
    if (_chats.isNotEmpty) {
      ref.read(chatsListCacheProvider.notifier).state =
          (chats: _chats, at: DateTime.now());
    }
    if (widget.inSplitView) {
      context.go('/chats/$chatID?name=$name');
      _navigationLockTimer?.cancel();
      if (mounted) setState(() => _isNavigatingToChat = false);
    } else {
      unawaited(
        context.push('/chats/$chatID?name=$name').whenComplete(() {
          _navigationLockTimer?.cancel();
          if (mounted) {
            setState(() => _isNavigatingToChat = false);
          }
        }),
      );
    }
  }

  Future<bool> _confirmChatAction({
    required String title,
    required String description,
    required String confirmText,
  }) async {
    return showGamepadChoiceDialog(
      context: context,
      title: title,
      message: description,
      confirmLabel: confirmText,
    );
  }

  Future<void> _clearChatFromList(ChatPreviewItem item) async {
    final confirmed = await _confirmChatAction(
      title: context.l10n.chatsClearTitle,
      description: context.l10n.chatsClearDesc,
      confirmText: context.l10n.chatsClearConfirm,
    );
    if (!confirmed) return;

    final actionKey = 'clear_${item.chatID}';
    setState(() => _chatActionInFlight.add(actionKey));
    try {
      final chatId = item.chatID;
      await ref.read(chatsRepositoryProvider).clearChat(chatId);
      removeChatFromChatsCache(ref, chatId);
      if (mounted) {
        setState(() {
          _chats =
              _chats.where((c) => c.chatID != chatId).toList(growable: false);
        });
      }
      unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.message,
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _chatActionInFlight.remove(actionKey));
    }
  }

  Future<void> _blockChatUserFromList(ChatPreviewItem item) async {
    if (item.isGroup) return;
    if (item.user.isSupport ||
        item.user.displayName?.trim() == 'Поддержка') {
      return;
    }
    final userID = item.user.id.trim();
    if (userID.isEmpty) return;
    final confirmed = await _confirmChatAction(
      title: context.l10n.chatsBlockTitle,
      description: context.l10n.chatsBlockDesc,
      confirmText: context.l10n.chatsBlockConfirm,
    );
    if (!confirmed) return;

    final actionKey = 'block_${item.user.id}';
    setState(() => _chatActionInFlight.add(actionKey));
    try {
      final chatId = item.chatID;
      await ref.read(chatsRepositoryProvider).blockUser(userID);
      removeChatFromChatsCache(ref, chatId);
      if (mounted) {
        setState(() {
          _chats =
              _chats.where((c) => c.chatID != chatId).toList(growable: false);
        });
      }
      unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
      unawaited(refreshFriendsSnapshot(ref).catchError((_) {}));
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.message,
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _chatActionInFlight.remove(actionKey));
    }
  }

  Widget _buildSlidableActionContent({
    required IconData icon,
    required Color iconColor,
    required double phaseShift,
    required bool busy,
  }) {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, _) {
        final phase = (_borderAnimationController.value + phaseShift) % 1.0;
        return Opacity(
          opacity: busy ? 0.6 : 1,
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppGradients.borderAt(phase),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSlidableActionPressed(
    BuildContext actionContext,
    ChatPreviewItem item,
    _ChatSwipeAction action,
  ) async {
    final clearKey = 'clear_${item.chatID}';
    final blockKey = 'block_${item.user.id}';
    final busy = _chatActionInFlight.contains(clearKey) || _chatActionInFlight.contains(blockKey);
    if (busy) return;

    try {
      if (action == _ChatSwipeAction.clear) {
        await _clearChatFromList(item);
      } else {
        await _blockChatUserFromList(item);
      }
    } finally {
      if (actionContext.mounted) {
        Slidable.of(actionContext)?.close();
      }
    }
  }

  String _friendLoadErrorText(Object? error) {
    if (error is FriendsException) return error.message;
    return LocaleService.l10n.friendsLoadFailed;
  }

  Future<FriendUserItem?> _pickFriendDialog() async {
    final queryController = TextEditingController();
    final searchFocus = FocusNode();
    Future<List<FriendItem>> friendsFuture = _loadFriendsForStartChat();
    final wide = isWide(context);
    try {
      if (wide) {
        return await _showNewChatDialogCentered(
          queryController: queryController,
          searchFocus: searchFocus,
          friendsFuture: friendsFuture,
        );
      }
      return await _showNewChatBottomSheet(
        queryController: queryController,
        searchFocus: searchFocus,
        friendsFuture: friendsFuture,
      );
    } finally {
      dismissGamepadKeyboard();
      searchFocus.dispose();
      queryController.dispose();
    }
  }

  Widget _wrapNewChatGamepad({
    required BuildContext modalContext,
    required Widget child,
  }) {
    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action == GamepadAction.cancel) {
          dismissGamepadKeyboard();
          final nav = Navigator.of(modalContext);
          if (nav.canPop()) nav.pop();
          return true;
        }
        if (action == GamepadAction.confirm || action.isDirection) {
          return handleGamepadUiAction(modalContext, action);
        }
        return true;
      },
      child: GamepadNavGroup(
        name: 'new-chat-popup',
        exclusive: true,
        child: child,
      ),
    );
  }

  Future<FriendUserItem?> _showNewChatDialogCentered({
    required TextEditingController queryController,
    required FocusNode searchFocus,
    required Future<List<FriendItem>> friendsFuture,
  }) async {
    var query = '';
    var visibleCount = _modalPageSize;
    var currentFriendsFuture = friendsFuture;


    return showDialog<FriendUserItem>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.center,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return _wrapNewChatGamepad(
                  modalContext: dialogContext,
                  child: _buildNewChatContent(
                  modalContext: dialogContext,
                  setSheetState: setSheetState,
                  queryController: queryController,
                  searchFocus: searchFocus,
                  friendsFuture: currentFriendsFuture,
                  query: query,
                  visibleCount: visibleCount,
                  onQueryChanged: (v) => query = v,
                  onVisibleCountChanged: (v) => visibleCount = v,
                  onRefreshFriends: () {
                    currentFriendsFuture = _loadFriendsForStartChat(forceRefresh: true);
                    setSheetState(() {});
                  },
                  wrapInSheet: false,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<FriendUserItem?> _showNewChatBottomSheet({
    required TextEditingController queryController,
    required FocusNode searchFocus,
    required Future<List<FriendItem>> friendsFuture,
  }) async {
    var query = '';
    var visibleCount = _modalPageSize;
    var currentFriendsFuture = friendsFuture;


    return showModalBottomSheet<FriendUserItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final phoneLand = isPhoneLandscape(sheetContext);
        final sheetHeight = chatsNewChatSheetHeight(
          phoneLandscape: phoneLand,
          viewHeight: media.size.height,
          keyboardInset: media.viewInsets.bottom,
        );
        return SafeArea(
          top: !phoneLand,
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: phoneLand ? 4 : media.viewInsets.bottom + 10,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return _wrapNewChatGamepad(
                  modalContext: sheetContext,
                  child: _buildNewChatContent(
                  modalContext: sheetContext,
                  setSheetState: setSheetState,
                  queryController: queryController,
                  searchFocus: searchFocus,
                  friendsFuture: currentFriendsFuture,
                  query: query,
                  visibleCount: visibleCount,
                  onQueryChanged: (v) => query = v,
                  onVisibleCountChanged: (v) => visibleCount = v,
                  onRefreshFriends: () {
                    currentFriendsFuture = _loadFriendsForStartChat(forceRefresh: true);
                    setSheetState(() {});
                  },
                  wrapInSheet: true,
                  sheetHeight: sheetHeight,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewChatContent({
    required BuildContext modalContext,
    required void Function(void Function()) setSheetState,
    required TextEditingController queryController,
    required FocusNode searchFocus,
    required Future<List<FriendItem>> friendsFuture,
    required String query,
    required int visibleCount,
    required void Function(String) onQueryChanged,
    required void Function(int) onVisibleCountChanged,
    required void Function() onRefreshFriends,
    required bool wrapInSheet,
    double? sheetHeight,
  }) {
    List<FriendItem> filtered(List<FriendItem> source) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return source;
      return source.where((item) {
        final name = _friendTitle(item.user).toLowerCase();
        return name.contains(q);
      }).toList();
    }

    final maxListHeight = !wrapInSheet ? MediaQuery.of(modalContext).size.height * 0.65 : null;
    final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
    return GradientCard(
      animate: false,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: wrapInSheet
          ? SizedBox(
              height: sheetHeight ?? 420,
              child: _newChatColumn(
                queryController: queryController,
                searchFocus: searchFocus,
                friendsFuture: friendsFuture,
                modalContext: modalContext,
                setSheetState: setSheetState,
                filtered: filtered,
                visibleCount: visibleCount,
                onQueryChanged: onQueryChanged,
                onVisibleCountChanged: onVisibleCountChanged,
                onRefreshFriends: onRefreshFriends,
                maxListHeight: null,
                presence: presence,
              ),
            )
          : _newChatColumn(
              queryController: queryController,
              searchFocus: searchFocus,
              friendsFuture: friendsFuture,
              modalContext: modalContext,
              setSheetState: setSheetState,
              filtered: filtered,
              visibleCount: visibleCount,
              onQueryChanged: onQueryChanged,
              onVisibleCountChanged: onVisibleCountChanged,
              onRefreshFriends: onRefreshFriends,
              maxListHeight: maxListHeight,
              presence: presence,
            ),
    );
  }

  Widget _newChatColumn({
    required TextEditingController queryController,
    required FocusNode searchFocus,
    required Future<List<FriendItem>> friendsFuture,
    required BuildContext modalContext,
    required void Function(void Function()) setSheetState,
    required List<FriendItem> Function(List<FriendItem>) filtered,
    required int visibleCount,
    required void Function(String) onQueryChanged,
    required void Function(int) onVisibleCountChanged,
    required void Function() onRefreshFriends,
    double? maxListHeight,
    Map<String, PresenceEntry> presence = const {},
  }) {
    final compactStrip = chatsNewChatUseCompactStrip(
      phoneLandscape: isPhoneLandscape(modalContext),
    );
    final listChild = FutureBuilder<List<FriendItem>>(
      future: friendsFuture,
      builder: (context, snapshot) {
                                if (snapshot.connectionState != ConnectionState.done) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return ListView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    children: [
                                      SizedBox(height: compactStrip ? 8 : 70),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            _friendLoadErrorText(snapshot.error),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.red.shade700),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            onVisibleCountChanged(_modalPageSize);
                                            onRefreshFriends();
                                          },
                                          icon: const Icon(Icons.refresh_rounded),
                                          label: Text(context.l10n.commonRetry),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final friends = snapshot.data ?? const <FriendItem>[];
                                if (friends.isEmpty) {
                                  return ListView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    children: [
                                      SizedBox(height: compactStrip ? 8 : 80),
                                      Center(
                                        child: Text(
                                          context.l10n.chatsNeedFriendsFirst,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final list = filtered(friends);
                                sortByPresenceOnlineFirst(
                                  list,
                                  (f) => f.user.id,
                                  presence,
                                );
                                if (list.isEmpty) {
                                  return ListView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    children: [
                                      SizedBox(height: compactStrip ? 8 : 80),
                                      Center(
                                        child: Text(
                                          context.l10n.chatsFriendsNotFound,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final visible = visibleCount > list.length
                                    ? list.length
                                    : visibleCount;
                                final hasMore = visible < list.length;
                                final itemCount = visible + (hasMore ? 1 : 0);
                                return ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  itemCount: itemCount,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
                                    if (index >= visible) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        setSheetState(() {
                                          final next = visibleCount + _modalPageSize;
                                          onVisibleCountChanged(next > list.length ? list.length : next);
                                        });
                                      });
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4),
                                        child: Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    }
                                    final friend = list[index].user;
                                    final friendPresence = presence[friend.id];
                                    final statusText =
                                        formatPresenceStatus(friendPresence);
                                    return GamepadFocusBlock(
                                      radius: 12,
                                      onActivate: () {
                                        dismissGamepadKeyboard();
                                        Navigator.of(modalContext).pop(friend);
                                      },
                                      child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          dismissGamepadKeyboard();
                                          Navigator.of(modalContext).pop(friend);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              _AvatarDot(
                                                user: ChatUserItem(
                                                  id: friend.id,
                                                  displayName: friend.displayName,
                                                  avatarKind: friend.avatarKind,
                                                  avatarValue: friend.avatarValue,
                                                  age: friend.age,
                                                  gender: friend.gender,
                                                  about: friend.about,
                                                ),
                                                isOnline: friendPresence?.online,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _friendTitle(friend),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (statusText.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 2),
                                                        child: Text(
                                                          statusText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    );
                                  },
                                );
                              },
    );
    final listPart = maxListHeight != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: listChild,
          )
        : Expanded(child: listChild);
    final searchField = GamepadFieldBlock(
      inputFocus: searchFocus,
      child: TextField(
      controller: queryController,
      focusNode: searchFocus,
      readOnly: gamepadConnected(),
      showCursor: true,
      autofillHints: null,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      textInputAction: TextInputAction.search,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: context.l10n.chatsFindFriendHint,
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: compactStrip,
        contentPadding: compactStrip
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : null,
      ),
      onChanged: (value) {
        setSheetState(() {
          onQueryChanged(value);
          onVisibleCountChanged(_modalPageSize);
        });
      },
      ),
    );
    void openSupport() {
      dismissGamepadKeyboard();
      Navigator.of(modalContext).maybePop();
      _openSupport();
    }

    final supportButton = GamepadFocusBlock(
      shape: GamepadHighlightShape.circle,
      radius: 22,
      onActivate: openSupport,
      child: IconButton(
      tooltip: context.l10n.supportTitle,
      onPressed: openSupport,
      icon: const Icon(
        Icons.support_agent_rounded,
        color: AppColors.accentStart,
      ),
      ),
    );
    final closeButton = GamepadFocusBlock(
      shape: GamepadHighlightShape.circle,
      radius: 22,
      onActivate: () {
        dismissGamepadKeyboard();
        Navigator.of(modalContext).maybePop();
      },
      child: IconButton(
        tooltip: context.l10n.commonClose,
        onPressed: () {
          dismissGamepadKeyboard();
          Navigator.of(modalContext).maybePop();
        },
        icon: const Icon(Icons.close_rounded),
      ),
    );
    return Column(
      mainAxisSize: maxListHeight != null ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compactStrip)
          Row(
            children: [
              Expanded(child: searchField),
              supportButton,
              closeButton,
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.chatsNewChat,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              supportButton,
            ],
          ),
          const SizedBox(height: 10),
          searchField,
        ],
        SizedBox(height: compactStrip ? 6 : 10),
        listPart,
      ],
    );
  }

  String _friendTitle(FriendUserItem user) {
    final value = user.displayName?.trim();
    if (value == null || value.isEmpty) return context.l10n.commonUser;
    return value;
  }

  String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$dd.$mo.$yyyy $hh:$mm';
  }

  String _peerTitle(ChatUserItem user) {
    final value = user.displayName?.trim();
    // is_support с API; «Поддержка» — имя в БД до/без флага.
    if (user.isSupport || value == 'Поддержка') {
      return context.l10n.supportTitle;
    }
    if (value == null || value.isEmpty) return context.l10n.commonUser;
    return value;
  }

  String _chatTitle(ChatPreviewItem item) {
    if (item.isGroup) {
      final title = item.title?.trim();
      if (title != null && title.isNotEmpty) {
        return localizeChatTitle(title, context.l10n);
      }
      return context.l10n.chatsGroupChat;
    }
    return _peerTitle(item.user);
  }

  String _chatSubtitle(ChatPreviewItem item, String subtitle, PresenceEntry? presence) {
    if (item.isGroup) {
      final preview = formatChatMessagePreview(subtitle);
      return preview.isEmpty ? context.l10n.chatsNoMessages : preview;
    }
    return _chatSubtitleWithPresence(subtitle, presence);
  }

  String _chatSubtitleWithPresence(String subtitle, PresenceEntry? presence) {
    final preview = formatChatMessagePreview(subtitle);
    if (presence == null) {
      return preview.isEmpty ? context.l10n.chatsNoMessages : preview;
    }
    final statusText = formatPresenceStatus(presence);
    if (statusText.isEmpty) {
      return preview.isEmpty ? context.l10n.chatsNoMessages : preview;
    }
    return preview.isEmpty ? statusText : '$statusText · $preview';
  }

  Future<void> _showUserInfoDialog(ChatUserItem user, {PresenceEntry? presence}) async {
    await showUserProfileDialog(
      context: context,
      ref: ref,
      userId: user.id,
      displayName: _peerTitle(user),
      isSupport: user.isSupport || isSupportDisplayName(user.displayName),
      avatarKind: user.avatarKind,
      avatarValue: user.avatarValue,
      frameCode: user.frameCode,
      frameColor: user.frameColor,
      age: user.age,
      gender: user.gender,
      about: user.about,
      messageFrom: 'chats',
    );
  }

  Widget _buildChatsToolbarActions({
    required bool hasBlockedUsers,
    required bool actionBusy,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ChatsGamepadLtHint(
            child: _buildHeaderFrameIconButton(
            icon: Icons.add_comment_rounded,
            tooltip: context.l10n.chatsNewChat,
            onPressed: actionBusy ? null : _openStartChatDialog,
            ),
          ),
        ),
        if (hasBlockedUsers)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildHeaderFrameIconButton(
              icon: Icons.block_rounded,
              tooltip: context.l10n.chatsBlockedUsers,
              onPressed: actionBusy ? null : _openBlockedUsersDialog,
            ),
          ),
      ],
    );
  }

  /// Мягкая лавандовая рамка как у свайп-действий и поиска друзей.
  Widget _buildHeaderFrameIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? iconColor,
  }) {
    return FramedIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      iconColor: iconColor ?? AppColors.accentStart,
    );
  }

  Widget _buildChatsHeaderRow({
    required bool hasBlockedUsers,
    required bool actionBusy,
  }) {
    return Row(
      children: [
        const Spacer(),
        _buildChatsToolbarActions(
          hasBlockedUsers: hasBlockedUsers,
          actionBusy: actionBusy,
        ),
      ],
    );
  }

  Future<void> _sendOrAcceptFriendFromChat(ChatPreviewItem item) async {
    final userId = item.user.id.trim();
    if (userId.isEmpty) return;
    final actionKey = 'friend_$userId';
    if (_chatActionInFlight.contains(actionKey)) return;

    final snapshot = ref.read(friendsSnapshotProvider).valueOrNull;
    if (snapshot?.friends.any((f) => f.user.id == userId) == true) return;

    String? incomingRequestId;
    for (final r in snapshot?.incoming ?? const []) {
      if (r.user.id == userId) {
        incomingRequestId = r.requestId;
        break;
      }
    }
    final hasOutgoing =
        snapshot?.outgoing.any((r) => r.user.id == userId) == true;
    if (hasOutgoing &&
        (incomingRequestId == null || incomingRequestId.isEmpty)) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: context.l10n.friendsRequestAlreadySent,
        kind: AppSnackKind.info,
      );
      return;
    }

    setState(() => _chatActionInFlight.add(actionKey));
    try {
      final repo = ref.read(friendsRepositoryProvider);
      if (incomingRequestId != null && incomingRequestId.isNotEmpty) {
        await repo.acceptRequest(incomingRequestId);
      } else {
        await repo.sendRequest(userId);
      }
      await refreshFriendsSnapshot(ref);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: incomingRequestId != null && incomingRequestId.isNotEmpty
            ? context.l10n.friendsRequestAccepted
            : context.l10n.friendsRequestSent,
        kind: AppSnackKind.success,
      );
    } on FriendsException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.message,
        kind: AppSnackKind.error,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: formatUserError(e),
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _chatActionInFlight.remove(actionKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Очистка/блок из комнаты (десктоп split-view): комната не владеет _chats.
    ref.listen<String?>(chatRemovedIdProvider, (_, chatId) {
      if (chatId == null || chatId.isEmpty || !mounted) return;
      if (!_chats.any((c) => c.chatID == chatId)) return;
      setState(() {
        _chats =
            _chats.where((c) => c.chatID != chatId).toList(growable: false);
      });
    });
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      realtimeEventsProvider,
      (_, next) {
        final type = next.valueOrNull?['type']?.toString() ?? '';
        if (type == 'chat_message' ||
            type == 'chat_list_changed' ||
            type == 'chat_read' ||
            type == 'chat_delivered' ||
            type == 'realtime_connected') {
          // Фоновый sync без спиннера и без presence-запроса.
          unawaited(_loadChats(showLoading: false));
        }
      },
    );

    final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
    final blockedUsers = ref.watch(blockedUsersProvider).valueOrNull ?? const <BlockedChatUserItem>[];
    final friendsSnapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
    final meID = ref.watch(authStateProvider).valueOrNull?.id;
    final chats = _chats;
    final hasBlockedUsers = blockedUsers.isNotEmpty;
    final errorText = _error;
    final loadError = _chatsLoadError;
    final loading = _isLoadingChats &&
        chats.isEmpty &&
        errorText == null &&
        loadError == null;
    final actionBusy = _isOpeningStartChatDialog ||
        _isOpeningBlockedUsersDialog ||
        _isStartingChat ||
        _isNavigatingToChat;

    final headerRow = _buildChatsHeaderRow(
      hasBlockedUsers: hasBlockedUsers,
      actionBusy: actionBusy,
    );
    final narrow = !isWide(context) && !widget.inSplitView;
    final path = ref.watch(currentRoutePathProvider);
    if (narrow && path == '/chats') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(mobileToolbarLeadingProvider.notifier).state =
              _buildChatsToolbarActions(
                hasBlockedUsers: hasBlockedUsers,
                actionBusy: actionBusy,
              );
        });
      });
    }

    const double headerHeight = 56;
    final compact = widget.sidebarCompact && widget.inSplitView;

    if (compact) {
      return GamepadScope(
        onAction: _onGamepad,
        child: Scaffold(
        backgroundColor: Colors.transparent,
        // Клавиатуру уже вычел AppShell — второй раз нельзя.
        resizeToAvoidBottomInset: !KeyboardInsetScope.handledOf(context),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Center(
                  child: ChatsGamepadLtHint(
                    child: IconButton(
                    onPressed: actionBusy ? null : _openStartChatDialog,
                    tooltip: context.l10n.chatsNewChat,
                    icon: const Icon(Icons.add_comment_rounded),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : RefreshIndicator(
                            onRefresh: () => _loadChats(refreshOnline: true),
                            child: chats.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    children: const [
                                      SizedBox(height: 120),
                                      Center(
                                        child: Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 32,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                              controller: _chatsScrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: chats.length,
                              itemBuilder: (context, index) {
                                final item = chats[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Center(
                                    child: wrapGamepadCursor(
                                      highlighted: _isGamepadChat(item) &&
                                          _gamepadActionIndex == null,
                                      radius: 24,
                                      child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isNavigatingToChat
                                            ? null
                                            : () {
                                                FocusManager.instance.primaryFocus
                                                    ?.unfocus();
                                                _openChatRoute(
                                                  chatID: item.chatID,
                                                  peerName: _chatTitle(item),
                                                );
                                              },
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            item.isGroup
                                                ? _GroupChatLeading(
                                                    members: item.members,
                                                    radius: 24,
                                                  )
                                                : _AvatarDot(
                                                    user: item.user,
                                                    radius: 24,
                                                    isOnline:
                                                        presence[item.user.id]
                                                            ?.online,
                                                  ),
                                            if (item.unreadCount > 0)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accentStart,
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    item.unreadCount > 99
                                                        ? '99+'
                                                        : '${item.unreadCount}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
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
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      );
    }

    return GamepadScope(
      onAction: _onGamepad,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      // Клавиатуру уже вычел AppShell — второй раз нельзя.
      resizeToAvoidBottomInset: !KeyboardInsetScope.handledOf(context),
      body: SafeArea(
        child: Column(
          children: [
            if (!narrow)
              SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: headerRow,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadChats(refreshOnline: true),
                // Один открытый свайп: при открытии второго предыдущий закрывается.
                child: SlidableAutoCloseBehavior(
                  child: CustomScrollView(
                  controller: _chatsScrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    if (loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (loadError != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ScreenLoadError(
                          title: context.l10n.chatsLoadFailed,
                          error: loadError,
                          onRetry: () => _loadChats(refreshOnline: true),
                        ),
                      )
                    else if (errorText != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            errorText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else if (chats.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            context.l10n.chatsEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        // Сверху запас под фиолетовую тень GradientCard —
                        // иначе CustomScrollView обрезает её о хедер (линия среза).
                        padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = chats[index];
                              final lastMessage = item.lastMessage;
                              final unread = item.unreadCount;
                              final subtitle =
                                  lastMessage?.previewText.trim() ?? '';
                              final clearKey = 'clear_${item.chatID}';
                              final blockKey = 'block_${item.user.id}';
                              final clearBusy =
                                  _chatActionInFlight.contains(clearKey);
                              final blockBusy =
                                  _chatActionInFlight.contains(blockKey);
                              final itemBusy = clearBusy || blockBusy;
                              final peerId = item.user.id.trim();
                              final isFriend = peerId.isNotEmpty &&
                                  friendsSnapshot?.friends
                                          .any((f) => f.user.id == peerId) ==
                                      true;
                              final hasOutgoing = peerId.isNotEmpty &&
                                  friendsSnapshot?.outgoing
                                          .any((r) => r.user.id == peerId) ==
                                      true;
                              final hasIncoming = peerId.isNotEmpty &&
                                  friendsSnapshot?.incoming
                                          .any((r) => r.user.id == peerId) ==
                                      true;
                              final friendBusy = _chatActionInFlight
                                  .contains('friend_$peerId');
                              final isSupportPeer = item.user.isSupport ||
                                  item.user.displayName?.trim() == 'Поддержка';
                              final blockDisabled =
                                  isSupportPeer || item.isGroup;
                              final showAddFriend = peerId.isNotEmpty &&
                                  !isFriend &&
                                  !isSupportPeer &&
                                  !item.isGroup;
                              return Padding(
                                key: _gamepadKeyForChat(item.chatID),
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 10,
                                ),
                                child: Slidable(
                                  key: ValueKey('chat_${item.chatID}'),
                                  controller: _slidableFor(item.chatID),
                                  groupTag: 'chats_list',
                                  enabled: !itemBusy,
                                  closeOnScroll: _gamepadActionIndex == null,
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: blockDisabled ? 0.20 : 0.40,
                                    children: [
                                      CustomSlidableAction(
                                        onPressed: itemBusy
                                            ? null
                                            : (actionContext) {
                                                unawaited(
                                                  _onSlidableActionPressed(
                                                    actionContext,
                                                    item,
                                                    _ChatSwipeAction.clear,
                                                  ),
                                                );
                                              },
                                        backgroundColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        child: wrapGamepadCursor(
                                          highlighted: _isGamepadChatAction(
                                            item,
                                            0,
                                          ),
                                          radius: 12,
                                          child: _buildSlidableActionContent(
                                          icon: Icons.delete_sweep_rounded,
                                          iconColor: const Color(0xFF1E88E5),
                                          phaseShift: 0.0,
                                          busy: clearBusy,
                                          ),
                                        ),
                                      ),
                                      if (!blockDisabled)
                                        CustomSlidableAction(
                                          onPressed: itemBusy
                                              ? null
                                              : (actionContext) {
                                                  unawaited(
                                                    _onSlidableActionPressed(
                                                      actionContext,
                                                      item,
                                                      _ChatSwipeAction.block,
                                                    ),
                                                  );
                                                },
                                          backgroundColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 8,
                                          ),
                                          child: wrapGamepadCursor(
                                            highlighted: _isGamepadChatAction(
                                              item,
                                              1,
                                            ),
                                            radius: 12,
                                            child: _buildSlidableActionContent(
                                            icon: Icons.block_rounded,
                                            iconColor: const Color(0xFFD32F2F),
                                            phaseShift: 0.5,
                                            busy: blockBusy,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  child: wrapGamepadCursor(
                                    highlighted: _isGamepadChat(item) &&
                                        _gamepadActionIndex == null,
                                    radius: AppRadius.card,
                                    child: Opacity(
                                    opacity: itemBusy ? 0.65 : 1,
                                    child: GradientCard(
                                      margin: EdgeInsets.zero,
                                      animate: false,
                                      child: InkWell(
                                        onTap: _isNavigatingToChat || itemBusy
                                            ? null
                                            : () => _openChatRoute(
                                                  chatID: item.chatID,
                                                  peerName: _chatTitle(item),
                                                ),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.card),
                                        child: Row(
                                          children: [
                                            item.isGroup
                                                ? _GroupChatLeading(
                                                    members: item.members,
                                                  )
                                                : Tooltip(
                                                    message: context
                                                        .l10n.userInfoTitle,
                                                    child: MouseRegion(
                                                      cursor:
                                                          SystemMouseCursors
                                                              .click,
                                                      child: GestureDetector(
                                                        onTap: itemBusy
                                                            ? null
                                                            : () {
                                                                unawaited(
                                                                  _showUserInfoDialog(
                                                                    item.user,
                                                                    presence: presence[
                                                                        item.user
                                                                            .id],
                                                                  ),
                                                                );
                                                              },
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        child: _AvatarDot(
                                                          user: item.user,
                                                          isOnline: presence[
                                                                  item.user.id]
                                                              ?.online,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text.rich(
                                                    TextSpan(
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              _chatTitle(item),
                                                        ),
                                                        if (showAddFriend)
                                                          WidgetSpan(
                                                            alignment:
                                                                PlaceholderAlignment
                                                                    .middle,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                left: 4,
                                                              ),
                                                              child: Tooltip(
                                                                message: hasIncoming
                                                                    ? context.l10n.friendsAcceptRequest
                                                                    : (hasOutgoing
                                                                        ? context.l10n.friendsRequestAlreadySent
                                                                        : context.l10n.friendsSendRequest),
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child:
                                                                      InkWell(
                                                                    onTap: itemBusy ||
                                                                            friendBusy ||
                                                                            hasOutgoing
                                                                        ? null
                                                                        : () =>
                                                                            unawaited(
                                                                          _sendOrAcceptFriendFromChat(
                                                                            item,
                                                                          ),
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      999,
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                        2,
                                                                      ),
                                                                      child: friendBusy
                                                                          ? const SizedBox(
                                                                              width:
                                                                                  14,
                                                                              height:
                                                                                  14,
                                                                              child:
                                                                                  CircularProgressIndicator(
                                                                                strokeWidth:
                                                                                    1.5,
                                                                                color:
                                                                                    AppColors.accentStart,
                                                                              ),
                                                                            )
                                                                          : Icon(
                                                                              Icons.person_add_alt_1_rounded,
                                                                              size: 16,
                                                                              color: hasOutgoing
                                                                                  ? AppColors.accentStart.withValues(
                                                                                      alpha: 0.4,
                                                                                    )
                                                                                  : AppColors.accentStart,
                                                                            ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _chatSubtitle(
                                                      item,
                                                      subtitle,
                                                      presence[item.user.id],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (lastMessage != null)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (meID != null &&
                                                          lastMessage
                                                                  .senderUserID ==
                                                              meID) ...[
                                                        MessageStatusTicks(
                                                          deliveredAt:
                                                              lastMessage
                                                                  .deliveredAt,
                                                          readAt: lastMessage
                                                              .readAt,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 3),
                                                      ],
                                                      Text(
                                                        formatChatListDateTime(
                                                            lastMessage
                                                                .createdAt),
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                const SizedBox(height: 6),
                                                if (unread > 0)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 7,
                                                            vertical: 3),
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          AppColors.accentStart,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(999),
                                                    ),
                                                    child: Text(
                                                      unread > 99
                                                          ? '99+'
                                                          : '$unread',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ),
                              );
                            },
                            childCount: chats.length,
                          ),
                        ),
                      ),
                    if (_isLoadingMoreChats)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
    ),
    );
  }

  bool _onGamepad(GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (action == GamepadAction.triggerL) {
      unawaited(_openStartChatDialog());
      return true;
    }
    if (_chats.isEmpty) return false;
    _gamepadChatIndex = _gamepadChatIndex.clamp(0, _chats.length - 1);
    final item = _chats[_gamepadChatIndex];
    final actions = _swipeActionsFor(item);
    if (chatsGamepadIsHorizontal(action)) {
      if (widget.sidebarCompact) return true;
      setState(() {
        _gamepadActionIndex = chatsActionIndexAfterMove(
          current: _gamepadActionIndex,
          actionCount: actions.length,
          action: action,
        );
      });
      _syncOpenSlidable();
      return true;
    }
    if (chatsGamepadIsVertical(action)) {
      setState(() {
        _gamepadActionIndex = null;
        _gamepadChatIndex = chatsListIndexAfterMove(
          index: _gamepadChatIndex,
          count: _chats.length,
          action: action,
        );
      });
      _syncOpenSlidable();
      _ensureGamepadChatVisible();
      return true;
    }
    if (action == GamepadAction.confirm) {
      if (_isNavigatingToChat) return true;
      final actionIndex = _gamepadActionIndex;
      if (actionIndex != null &&
          actionIndex >= 0 &&
          actionIndex < actions.length) {
        unawaited(
          _runSwipeAction(item, actions[actionIndex]),
        );
        return true;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      _openChatRoute(chatID: item.chatID, peerName: _chatTitle(item));
      return true;
    }
    if (action == GamepadAction.cancel && _gamepadActionIndex != null) {
      setState(() => _gamepadActionIndex = null);
      _syncOpenSlidable();
      return true;
    }
    return false;
  }

  List<_ChatSwipeAction> _swipeActionsFor(ChatPreviewItem item) {
    final isSupport = item.user.isSupport ||
        item.user.displayName?.trim() == 'Поддержка';
    final canBlock = !isSupport && !item.isGroup;
    return [
      _ChatSwipeAction.clear,
      if (canBlock) _ChatSwipeAction.block,
    ];
  }

  SlidableController _slidableFor(String chatId) {
    return _slidableControllers.putIfAbsent(
      chatId,
      () => SlidableController(this),
    );
  }

  GlobalKey _gamepadKeyForChat(String chatId) {
    return _gamepadChatKeys.putIfAbsent(chatId, GlobalKey.new);
  }

  void _syncOpenSlidable() {
    if (widget.sidebarCompact || _chats.isEmpty) return;
    final id = _chats[_gamepadChatIndex.clamp(0, _chats.length - 1)].chatID;
    for (final entry in _slidableControllers.entries) {
      if (entry.key == id && _gamepadActionIndex != null) {
        unawaited(entry.value.openEndActionPane());
      } else if (entry.value.actionPaneType.value != ActionPaneType.none) {
        unawaited(entry.value.close());
      }
    }
  }

  void _ensureGamepadChatVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _chats.isEmpty) return;
      final id = _chats[_gamepadChatIndex.clamp(0, _chats.length - 1)].chatID;
      final ctx = _gamepadChatKeys[id]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: const Duration(milliseconds: 120),
      );
    });
  }

  Future<void> _runSwipeAction(
    ChatPreviewItem item,
    _ChatSwipeAction action,
  ) async {
    if (action == _ChatSwipeAction.clear) {
      await _clearChatFromList(item);
    } else {
      await _blockChatUserFromList(item);
    }
    if (!mounted) return;
    setState(() => _gamepadActionIndex = null);
    _syncOpenSlidable();
  }

  bool _isGamepadChat(ChatPreviewItem item) {
    if (_chats.isEmpty) return false;
    final i = _gamepadChatIndex.clamp(0, _chats.length - 1);
    return _chats[i].chatID == item.chatID;
  }

  bool _isGamepadChatAction(ChatPreviewItem item, int actionIndex) {
    return _isGamepadChat(item) && _gamepadActionIndex == actionIndex;
  }
}

class _GroupChatLeading extends StatelessWidget {
  const _GroupChatLeading({
    required this.members,
    this.radius = 22,
  });

  final List<ChatUserItem> members;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final shown = members.take(3).toList(growable: false);
    return SizedBox(
      width: size + 18,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentStart, AppColors.accentEnd],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.grid_3x3_rounded,
              color: Colors.white,
              size: radius,
            ),
          ),
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: radius * 0.95 + i * (radius * 0.48),
              bottom: i.isEven ? -1 : radius * 0.32,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceCard, width: 1.2),
                ),
                child: _AvatarDot(
                  user: shown[i],
                  radius: radius * 0.38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({
    required this.user,
    this.radius = 20,
    this.isOnline,
  });

  final ChatUserItem user;
  final double radius;
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (user.isSupport || user.displayName?.trim() == 'Поддержка') {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.accentSoft,
        child: Icon(
          Icons.support_agent_rounded,
          color: AppColors.accentStart,
          size: radius * 1.15,
        ),
      );
    } else if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.trim().isNotEmpty) {
      final memoryImage = AvatarMemoryCache.fromAvatarValue(user.avatarValue);
      if (memoryImage != null) {
        avatar = CircleAvatar(
          radius: radius,
          backgroundImage: memoryImage,
        );
      } else {
        avatar = _buildLetterAvatar();
      }
    } else if (user.avatarKind == 'preset') {
      final iconIndex = int.tryParse(user.avatarValue ?? '');
      if (iconIndex != null) {
        const icons = <IconData>[
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
        final idx = iconIndex % icons.length;
        avatar = CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(
            icons[idx],
            color: AppColors.accentStart,
            size: radius,
          ),
        );
      } else {
        avatar = _buildLetterAvatar();
      }
    } else {
      avatar = _buildLetterAvatar();
    }
    avatar = FramedAvatar(
      size: radius * 2,
      borderWidth: radius < 18 ? 2.2 : 2.8,
      frameCode: user.frameCode,
      frameColor: user.frameColor,
      child: avatar,
    );
    if (isOnline == true) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
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

  Widget _buildLetterAvatar() {
    final raw = user.displayName?.trim();
    final letter = (raw != null && raw.isNotEmpty) ? raw.substring(0, 1).toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.accentStart,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
