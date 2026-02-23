import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String? _error;
  bool _isOpeningStartChatDialog = false;
  bool _isOpeningBlockedUsersDialog = false;
  bool _isStartingChat = false;
  bool _isNavigatingToChat = false;
  bool _hasBlockedUsers = false;
  final Set<String> _chatActionInFlight = <String>{};
  Future<List<FriendItem>>? _friendsLoadInFlight;
  List<FriendItem> _cachedFriends = const [];
  DateTime? _friendsCachedAt;
  Timer? _navigationLockTimer;

  static const Duration _friendsCacheTTL = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    unawaited(_warmUpStartChatData());
    unawaited(_refreshBlockedUsersPresence());
  }

  @override
  void dispose() {
    _navigationLockTimer?.cancel();
    super.dispose();
  }

  bool get _hasFreshFriendsCache {
    final ts = _friendsCachedAt;
    if (ts == null) return false;
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

  Future<void> _refreshBlockedUsersPresence({bool silent = true}) async {
    try {
      final blocked = await ref.read(chatsRepositoryProvider).listBlockedUsers();
      if (!mounted) return;
      final hasBlocked = blocked.isNotEmpty;
      if (hasBlocked != _hasBlockedUsers) {
        setState(() => _hasBlockedUsers = hasBlocked);
      }
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!silent && mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _error = 'Не удалось загрузить список блокировок');
      }
    }
  }

  Future<List<FriendItem>> _loadFriendsForStartChat({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _hasFreshFriendsCache) {
      return _cachedFriends;
    }
    final inFlight = _friendsLoadInFlight;
    if (!forceRefresh && inFlight != null) {
      return inFlight;
    }

    late Future<List<FriendItem>> request;
    request = () async {
      try {
        if (!forceRefresh) {
          final snapshot = ref.read(friendsSnapshotProvider).valueOrNull;
          if (snapshot != null) {
            _cacheFriends(snapshot.friends);
            return snapshot.friends;
          }
        }
        final snapshot = await ref.read(friendsSnapshotProvider.future);
        _cacheFriends(snapshot.friends);
        return snapshot.friends;
      } catch (_) {
        // Если потоковый снимок недоступен, фолбэкаемся на прямой API-запрос.
        final snapshot = await ref.read(friendsRepositoryProvider).getFriends();
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

  Future<void> _loadChats() async {
    setState(() => _error = null);
    try {
      await refreshChatsList(ref, force: true);
      await _refreshBlockedUsersPresence();
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
      setState(() => _error = 'Не удалось загрузить чаты');
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
      Future<List<BlockedChatUserItem>> blockedFuture =
          ref.read(chatsRepositoryProvider).listBlockedUsers();

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final unblocking = <String>{};
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 10,
                  ),
                  child: GradientCard(
                    animate: false,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 420,
                      child: Column(
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
                          Expanded(
                            child: FutureBuilder<List<BlockedChatUserItem>>(
                              future: blockedFuture,
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
                                  final err = snapshot.error;
                                  final message = err is ChatException
                                      ? err.message
                                      : 'Не удалось загрузить список';
                                  return ListView(
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
                                            setSheetState(() {
                                              blockedFuture = ref
                                                  .read(chatsRepositoryProvider)
                                                  .listBlockedUsers();
                                            });
                                          },
                                          icon: const Icon(Icons.refresh_rounded),
                                          label: const Text('Повторить'),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final blocked = snapshot.data ?? const <BlockedChatUserItem>[];
                                final hasBlockedNow = blocked.isNotEmpty;
                                if (hasBlockedNow != _hasBlockedUsers) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(() => _hasBlockedUsers = hasBlockedNow);
                                  });
                                }
                                if (blocked.isEmpty) {
                                  return ListView(
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
                                }

                                return ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  itemCount: blocked.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
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
                                            color: Colors.black.withOpacity(0.08),
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
                                                        await ref
                                                            .read(chatsRepositoryProvider)
                                                            .unblockUser(user.id);
                                                        await refreshChatsList(ref, force: true);
                                                        await refreshFriendsSnapshot(ref);
                                                        if (!mounted) return;
                                                        setSheetState(() {
                                                          blockedFuture = ref
                                                              .read(chatsRepositoryProvider)
                                                              .listBlockedUsers();
                                                        });
                                                        unawaited(_refreshBlockedUsersPresence());
                                                      } on ChatException catch (e) {
                                                        if (e.statusCode == 401) {
                                                          await ref
                                                              .read(authStateProvider.notifier)
                                                              .logout();
                                                          if (mounted) context.go('/login');
                                                          return;
                                                        }
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(e.message)),
                                                        );
                                                      } finally {
                                                        if (mounted) {
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
                              },
                            ),
                          ),
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
    } finally {
      if (mounted) setState(() => _isOpeningBlockedUsersDialog = false);
    }
  }

  Future<void> _startChatWithUser(FriendUserItem pickedUser) async {
    if (_isStartingChat || _isNavigatingToChat) return;
    setState(() => _isStartingChat = true);
    try {
      final chatID = await ref.read(chatsRepositoryProvider).startChat(pickedUser.id);
      if (!mounted || chatID.isEmpty) return;
      unawaited(refreshChatsList(ref));
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
    unawaited(
      context.push('/chats/$chatID?name=$name').whenComplete(() {
        _navigationLockTimer?.cancel();
        if (mounted) {
          setState(() => _isNavigatingToChat = false);
        }
      }),
    );
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

    setState(() => _chatActionInFlight.add(item.chatID));
    try {
      await ref.read(chatsRepositoryProvider).clearChat(item.chatID);
      await refreshChatsList(ref, force: true);
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _chatActionInFlight.remove(item.chatID));
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

    setState(() => _chatActionInFlight.add(item.chatID));
    try {
      await ref.read(chatsRepositoryProvider).blockUser(userID);
      await refreshChatsList(ref, force: true);
      await refreshFriendsSnapshot(ref);
      await _refreshBlockedUsersPresence();
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _chatActionInFlight.remove(item.chatID));
    }
  }

  String _friendLoadErrorText(Object? error) {
    if (error is FriendsException) return error.message;
    return 'Не удалось загрузить друзей';
  }

  Future<FriendUserItem?> _pickFriendDialog() async {
    final queryController = TextEditingController();
    Future<List<FriendItem>> friendsFuture = _loadFriendsForStartChat();
    try {
      return await showModalBottomSheet<FriendUserItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          var query = '';

          List<FriendItem> filtered(List<FriendItem> source) {
            final q = query.trim().toLowerCase();
            if (q.isEmpty) return source;
            return source.where((item) {
              final name = _friendTitle(item.user).toLowerCase();
              return name.contains(q);
            }).toList();
          }

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 10,
                  ),
                  child: GradientCard(
                    animate: false,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 420,
                      child: Column(
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
                            decoration: const InputDecoration(
                              hintText: 'Найти друга по нику',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (value) {
                              setSheetState(() => query = value);
                            },
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: FutureBuilder<List<FriendItem>>(
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
                                            setSheetState(() {
                                              friendsFuture = _loadFriendsForStartChat(
                                                forceRefresh: true,
                                              );
                                            });
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

                                return ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
                                    final friend = list[index].user;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => Navigator.of(sheetContext).pop(friend),
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
                            ),
                          ),
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
    } finally {
      queryController.dispose();
    }
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

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsListProvider);
    final chats = chatsAsync.valueOrNull ?? const <ChatPreviewItem>[];
    final providerError = chatsAsync.whenOrNull(
      error: (err, _) => err is ChatException ? err.message : 'Не удалось загрузить чаты',
    );
    final errorText = _error ?? providerError;
    final loading = chatsAsync.isLoading && chats.isEmpty && errorText == null;
    final actionBusy = _isOpeningStartChatDialog ||
        _isOpeningBlockedUsersDialog ||
        _isStartingChat ||
        _isNavigatingToChat;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadChats,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Row(
                children: [
                  Text(
                    'Чаты',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (_hasBlockedUsers)
                    IconButton(
                      onPressed: actionBusy ? null : _openBlockedUsersDialog,
                      tooltip: 'Заблокированные пользователи',
                      icon: const Icon(Icons.block_rounded),
                    ),
                  IconButton(
                    onPressed: actionBusy ? null : _openStartChatDialog,
                    tooltip: 'Новый чат',
                    icon: const Icon(Icons.add_comment_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                )
              else if (chats.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы выбрать друга и начать диалог.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ...chats.map(
                  (item) {
                    final lastMessage = item.lastMessage;
                    final unread = item.unreadCount;
                    final subtitle = (lastMessage?.body ?? '').trim();
                    final itemBusy = _chatActionInFlight.contains(item.chatID);
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Slidable(
                        key: ValueKey('chat_${item.chatID}'),
                        enabled: !itemBusy,
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.24,
                          children: [
                            SlidableAction(
                              onPressed: (_) => unawaited(_clearChatFromList(item)),
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              icon: Icons.delete_sweep_rounded,
                              label: 'Очистить',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.24,
                          children: [
                            SlidableAction(
                              onPressed: (_) => unawaited(_blockChatUserFromList(item)),
                              backgroundColor: const Color(0xFFD32F2F),
                              foregroundColor: Colors.white,
                              icon: Icons.block_rounded,
                              label: 'Блок',
                            ),
                          ],
                        ),
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
                                        peerName: _peerTitle(item.user),
                                      ),
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              child: Row(
                                children: [
                                  _AvatarDot(user: item.user),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _peerTitle(item.user),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle.isEmpty ? 'Нет сообщений' : subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (lastMessage != null)
                                        Text(
                                          _formatDateTime(lastMessage.createdAt),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (unread > 0) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentStart,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            unread > 99 ? '99+' : '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({required this.user});

  final ChatUserItem user;

  @override
  Widget build(BuildContext context) {
    if (user.avatarKind == 'preset') {
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
        return CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentSoft,
          child: Icon(icons[idx], color: AppColors.accentStart),
        );
      }
    }

    final raw = user.displayName?.trim();
    final letter = (raw != null && raw.isNotEmpty) ? raw.substring(0, 1).toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.accentStart,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
