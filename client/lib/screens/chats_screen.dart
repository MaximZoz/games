import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/message_status_ticks.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

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
        _error = e.message;
        _isLoadingChats = false;
        _isLoadingMoreChats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить чаты';
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
      final message = formatUserError(err, fallback: 'Не удалось загрузить список');
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
              label: const Text('Повторить'),
            ),
          ),
        ],
      );
    } else if (blocked.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'Список пуст',
              style: TextStyle(color: AppColors.textSecondary),
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
                          'Заблокирован: ${_formatDateTime(entry.blockedAt)}',
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
                              if (e.statusCode == 401) {
                                await modalRef
                                    .read(authStateProvider.notifier)
                                    .logout();
                                if (!context.mounted) return;
                                // ignore: use_build_context_synchronously
                                context.go('/login');
                                return;
                              }
                              // ignore: use_build_context_synchronously
                              showAppSnackBar(
                                context,
                                message: e.message,
                                kind: AppSnackKind.error,
                              );
                            } finally {
                              if (context.mounted) {
                                setSheetState(() => unblocking.remove(user.id));
                              }
                            }
                          },
                    child: const Text('Разблокировать'),
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
              const Text(
                'Заблокированные пользователи',
                style: TextStyle(
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
      setState(() => _error = 'Не удалось создать чат');
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
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
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _clearChatFromList(ChatPreviewItem item) async {
    final confirmed = await _confirmChatAction(
      title: 'Очистить переписку?',
      description: 'Диалог будет удалён без возможности восстановления.',
      confirmText: 'Очистить',
      destructive: true,
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
    final userID = item.user.id.trim();
    if (userID.isEmpty) return;
    final confirmed = await _confirmChatAction(
      title: 'Заблокировать пользователя?',
      description: 'Вы больше не сможете писать друг другу. Диалог и дружба будут удалены.',
      confirmText: 'Заблокировать',
      destructive: true,
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
    return 'Не удалось загрузить друзей';
  }

  Future<FriendUserItem?> _pickFriendDialog() async {
    final queryController = TextEditingController();
    Future<List<FriendItem>> friendsFuture = _loadFriendsForStartChat();
    final wide = isWide(context);
    try {
      if (wide) {
        return await _showNewChatDialogCentered(
          queryController: queryController,
          friendsFuture: friendsFuture,
        );
      }
      return await _showNewChatBottomSheet(
        queryController: queryController,
        friendsFuture: friendsFuture,
      );
    } finally {
      queryController.dispose();
    }
  }

  Future<FriendUserItem?> _showNewChatDialogCentered({
    required TextEditingController queryController,
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
                return _buildNewChatContent(
                  modalContext: dialogContext,
                  setSheetState: setSheetState,
                  queryController: queryController,
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
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 10,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return _buildNewChatContent(
                  modalContext: sheetContext,
                  setSheetState: setSheetState,
                  queryController: queryController,
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
    required Future<List<FriendItem>> friendsFuture,
    required String query,
    required int visibleCount,
    required void Function(String) onQueryChanged,
    required void Function(int) onVisibleCountChanged,
    required void Function() onRefreshFriends,
    required bool wrapInSheet,
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
              height: 420,
              child: _newChatColumn(
                queryController: queryController,
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
                                      const SizedBox(height: 70),
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
                                          label: const Text('Повторить'),
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
                                    children: const [
                                      SizedBox(height: 80),
                                      Center(
                                        child: Text(
                                          'Сначала добавьте друзей, потом можно открыть чат.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final list = filtered(friends);
                                if (list.isEmpty) {
                                  return ListView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    children: const [
                                      SizedBox(height: 80),
                                      Center(
                                        child: Text(
                                          'Друзья не найдены',
                                          style: TextStyle(color: AppColors.textSecondary),
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
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => Navigator.of(modalContext).pop(friend),
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
                                                isOnline: presence[friend.id]?.online,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _friendTitle(friend),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                            ],
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
    return Column(
      mainAxisSize: maxListHeight != null ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Новый чат',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: queryController,
          autofillHints: null,
          enableSuggestions: false,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Найти друга по нику',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) {
            setSheetState(() {
              onQueryChanged(value);
              onVisibleCountChanged(_modalPageSize);
            });
          },
        ),
        const SizedBox(height: 10),
        listPart,
      ],
    );
  }

  String _friendTitle(FriendUserItem user) {
    final value = user.displayName?.trim();
    if (value == null || value.isEmpty) return 'Пользователь';
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
    if (value == null || value.isEmpty) return 'Пользователь';
    return value;
  }

  String _chatSubtitleWithPresence(String subtitle, PresenceEntry? presence) {
    final preview = formatChatMessagePreview(subtitle);
    if (presence == null) {
      return preview.isEmpty ? 'Нет сообщений' : preview;
    }
    final statusText = presence.online ? 'Онлайн' : formatLastSeen(presence.lastSeenAt);
    if (statusText.isEmpty) {
      return preview.isEmpty ? 'Нет сообщений' : preview;
    }
    return preview.isEmpty ? statusText : '$statusText · $preview';
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

  Future<void> _showUserInfoDialog(ChatUserItem user, {PresenceEntry? presence}) async {
    final name = _peerTitle(user);
    final about = user.about?.trim();
    final genderIcon = _genderIcon(user.gender);
    final female = _isFemaleGender(user.gender);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 380;
        final statusText = presence == null
            ? null
            : (presence.online ? 'Онлайн' : formatLastSeen(presence.lastSeenAt));
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
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
                    _AvatarDot(user: user, radius: 22, isOnline: presence?.online),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                if (statusText != null && statusText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
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
                PeerCollectionsSection(userId: user.id),
              ],
            ),
          ),
        ),
        );
      },
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
          child: _buildHeaderFrameIconButton(
            icon: Icons.add_comment_rounded,
            tooltip: 'Новый чат',
            onPressed: actionBusy ? null : _openStartChatDialog,
          ),
        ),
        if (hasBlockedUsers)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildHeaderFrameIconButton(
              icon: Icons.block_rounded,
              tooltip: 'Заблокированные пользователи',
              onPressed: actionBusy ? null : _openBlockedUsersDialog,
            ),
          ),
      ],
    );
  }

  /// Рамка как у лупы поиска друзей: скруглённый квадрат, фиолетовый бордер.
  Widget _buildHeaderFrameIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? iconColor,
  }) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentStart, width: 2),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.accentStart,
              ),
            ),
          ),
        ),
      ),
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
        message: 'Заявка уже отправлена',
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
            ? 'Заявка принята'
            : 'Заявка отправлена',
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
    final loading = _isLoadingChats && chats.isEmpty && errorText == null;
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
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Center(
                  child: IconButton(
                    onPressed: actionBusy ? null : _openStartChatDialog,
                    tooltip: 'Новый чат',
                    icon: const Icon(Icons.add_comment_rounded),
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
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isNavigatingToChat
                                            ? null
                                            : () => _openChatRoute(
                                                  chatID: item.chatID,
                                                  peerName: _peerTitle(item.user),
                                                ),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            _AvatarDot(
                                              user: item.user,
                                              radius: 24,
                                              isOnline: presence[item.user.id]?.online,
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
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Text(
                            'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы выбрать друга и начать диалог.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = chats[index];
                              final lastMessage = item.lastMessage;
                              final unread = item.unreadCount;
                              final subtitle =
                                  (lastMessage?.body ?? '').trim();
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
                              final showAddFriend =
                                  peerId.isNotEmpty && !isFriend;
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 10,
                                ),
                                child: Slidable(
                                  key: ValueKey('chat_${item.chatID}'),
                                  enabled: !itemBusy,
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.40,
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
                                        child: _buildSlidableActionContent(
                                          icon: Icons.delete_sweep_rounded,
                                          iconColor: const Color(0xFF1E88E5),
                                          phaseShift: 0.0,
                                          busy: clearBusy,
                                        ),
                                      ),
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
                                        child: _buildSlidableActionContent(
                                          icon: Icons.block_rounded,
                                          iconColor: const Color(0xFFD32F2F),
                                          phaseShift: 0.5,
                                          busy: blockBusy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Opacity(
                                    opacity: itemBusy ? 0.65 : 1,
                                    child: GradientCard(
                                      margin: EdgeInsets.zero,
                                      animate: false,
                                      child: InkWell(
                                        onTap: _isNavigatingToChat || itemBusy
                                            ? null
                                            : () => _openChatRoute(
                                                  chatID: item.chatID,
                                                  peerName: _peerTitle(item.user),
                                                ),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.card),
                                        child: Row(
                                          children: [
                                            Tooltip(
                                              message:
                                                  'Информация о пользователе',
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: itemBusy
                                                      ? null
                                                      : () {
                                                          unawaited(
                                                            _showUserInfoDialog(
                                                              item.user,
                                                              presence: presence[
                                                                  item.user.id],
                                                            ),
                                                          );
                                                        },
                                                  behavior:
                                                      HitTestBehavior.opaque,
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
                                                  Text(
                                                    _peerTitle(item.user),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _chatSubtitleWithPresence(
                                                      subtitle,
                                                      presence[item.user.id],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
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
                                      if (showAddFriend)
                                        Positioned(
                                          top: -7,
                                          right: -7,
                                          child: Tooltip(
                                            message: hasIncoming
                                                ? 'Принять заявку в друзья'
                                                : (hasOutgoing
                                                    ? 'Заявка уже отправлена'
                                                    : 'Отправить заявку в друзья'),
                                            child: Material(
                                              color: AppColors.surfaceCard,
                                              elevation: 0,
                                              shape: const CircleBorder(
                                                side: BorderSide(
                                                  color: AppColors.accentSoft,
                                                  width: 1,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: InkWell(
                                                customBorder:
                                                    const CircleBorder(),
                                                onTap: itemBusy ||
                                                        friendBusy ||
                                                        hasOutgoing
                                                    ? null
                                                    : () => unawaited(
                                                          _sendOrAcceptFriendFromChat(
                                                            item,
                                                          ),
                                                        ),
                                                child: SizedBox(
                                                  width: 26,
                                                  height: 26,
                                                  child: Center(
                                                    child: friendBusy
                                                        ? const SizedBox(
                                                            width: 12,
                                                            height: 12,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 1.5,
                                                              color: AppColors
                                                                  .accentStart,
                                                            ),
                                                          )
                                                        : Icon(
                                                            hasIncoming
                                                                ? Icons
                                                                    .person_add_alt_1_rounded
                                                                : Icons
                                                                    .person_add_alt_1_rounded,
                                                            size: 15,
                                                            color: hasOutgoing
                                                                ? AppColors
                                                                    .accentStart
                                                                    .withValues(
                                                                      alpha:
                                                                          0.35,
                                                                    )
                                                                : AppColors
                                                                    .accentStart,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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
          ],
        ),
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
    if (user.avatarKind == 'file' &&
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
