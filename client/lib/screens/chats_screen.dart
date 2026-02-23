import 'dart:async';

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

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

enum _ChatSwipeAction { clear, block }

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String? _error;
  final Set<String> _actionInFlight = <String>{};

  Future<void> _loadChats() async {
    setState(() => _error = null);
    try {
      await refreshChatsList(ref);
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
    List<FriendItem> friends;
    try {
      final snapshot = await ref.read(friendsRepositoryProvider).getFriends();
      friends = snapshot.friends;
    } on FriendsException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить друзей';
      });
      return;
    }

    if (friends.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала добавьте друзей, потом можно открыть чат')),
      );
      return;
    }

    final pickedUser = await _pickFriendDialog(friends);
    if (!mounted || pickedUser == null) return;

    try {
      final chatID = await ref.read(chatsRepositoryProvider).startChat(pickedUser.id);
      if (!mounted || chatID.isEmpty) return;
      unawaited(refreshChatsList(ref));
      final name = Uri.encodeQueryComponent(_friendTitle(pickedUser));
      context.push('/chats/$chatID?name=$name');
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
    }
  }

  Future<FriendUserItem?> _pickFriendDialog(List<FriendItem> friends) async {
    final queryController = TextEditingController();
    final result = await showModalBottomSheet<FriendUserItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var query = '';

        List<FriendItem> filtered() {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) return friends;
          return friends.where((item) {
            final name = _friendTitle(item.user).toLowerCase();
            return name.contains(q);
          }).toList();
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final list = filtered();
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
                          child: list.isEmpty
                              ? ListView(
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
                                )
                              : ListView.separated(
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

    queryController.dispose();
    return result;
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

  DateTime _chatSortDate(ChatPreviewItem item) {
    final updated = DateTime.tryParse(item.updatedAt);
    if (updated != null) return updated;
    final lastMessageAt = DateTime.tryParse(item.lastMessage?.createdAt ?? '');
    if (lastMessageAt != null) return lastMessageAt;
    return DateTime.tryParse(item.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<ChatPreviewItem> _sortedChats(List<ChatPreviewItem> input) {
    final list = List<ChatPreviewItem>.of(input);
    list.sort((left, right) {
      final leftUnread = left.unreadCount > 0;
      final rightUnread = right.unreadCount > 0;
      if (leftUnread != rightUnread) {
        return leftUnread ? -1 : 1;
      }
      final rightTime = _chatSortDate(right);
      final leftTime = _chatSortDate(left);
      final byTime = rightTime.compareTo(leftTime);
      if (byTime != 0) return byTime;
      return right.chatID.compareTo(left.chatID);
    });
    return list;
  }

  Future<bool> _confirmChatAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: danger
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _runChatAction({
    required String actionKey,
    required Future<void> Function() action,
    required String successMessage,
    required String fallbackErrorMessage,
  }) async {
    if (_actionInFlight.contains(actionKey)) return;
    setState(() {
      _error = null;
      _actionInFlight.add(actionKey);
    });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
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
      setState(() => _error = fallbackErrorMessage);
    } finally {
      if (mounted) {
        setState(() => _actionInFlight.remove(actionKey));
      }
    }
  }

  Future<void> _clearChat(ChatPreviewItem item) async {
    final confirmed = await _confirmChatAction(
      title: 'Очистить чат',
      message: 'Чат и вся переписка будут удалены для обеих сторон. Продолжить?',
      confirmLabel: 'Очистить',
      danger: true,
    );
    if (!confirmed) return;

    await _runChatAction(
      actionKey: 'clear_${item.chatID}',
      action: () async {
        await ref.read(chatsRepositoryProvider).clearChat(item.chatID);
        await refreshChatsList(ref);
      },
      successMessage: 'Чат удалён',
      fallbackErrorMessage: 'Не удалось очистить чат',
    );
  }

  Future<void> _blockUserFromChat(ChatPreviewItem item) async {
    final peerName = _peerTitle(item.user);
    final confirmed = await _confirmChatAction(
      title: 'Заблокировать пользователя',
      message: 'Пользователь "$peerName" будет заблокирован.\n'
          'Чат с перепиской удалится, и он не сможет писать вам и добавлять в друзья до разблокировки.',
      confirmLabel: 'Заблокировать',
      danger: true,
    );
    if (!confirmed) return;

    await _runChatAction(
      actionKey: 'block_${item.user.id}',
      action: () async {
        await ref.read(chatsRepositoryProvider).blockUser(item.user.id);
        await refreshChatsList(ref);
        await refreshFriendsSnapshot(ref);
      },
      successMessage: 'Пользователь заблокирован',
      fallbackErrorMessage: 'Не удалось заблокировать пользователя',
    );
  }

  Widget _buildSwipeActionsBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Row(
        children: [
          const Spacer(),
          Container(
            width: 110,
            color: const Color(0xFF1E88E5),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_sweep_rounded, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  'Очистить',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            width: 110,
            color: const Color(0xFFD32F2F),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  'Блок',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<_ChatSwipeAction?> _pickSwipeAction(ChatPreviewItem item) async {
    return showModalBottomSheet<_ChatSwipeAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: GradientCard(
              margin: EdgeInsets.zero,
              animate: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF1E88E5)),
                    title: const Text('Очистить чат'),
                    subtitle: const Text('Удалить чат и переписку'),
                    onTap: () => Navigator.of(sheetContext).pop(_ChatSwipeAction.clear),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.block_rounded, color: Color(0xFFD32F2F)),
                    title: const Text('Заблокировать'),
                    subtitle: const Text('Удалить чат и запретить писать/добавлять в друзья'),
                    onTap: () => Navigator.of(sheetContext).pop(_ChatSwipeAction.block),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBlockedUsersDialog() async {
    List<BlockedChatUserItem> blockedUsers;
    try {
      blockedUsers = await ref.read(chatsRepositoryProvider).listBlockedUsers();
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _error = e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось загрузить заблокированных пользователей');
      return;
    }

    if (!mounted) return;
    final busyIDs = <String>{};
    String? sheetError;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetInnerContext, setSheetState) {
            Future<void> unblock(BlockedChatUserItem item) async {
              final key = item.user.id;
              if (busyIDs.contains(key)) return;
              setSheetState(() {
                busyIDs.add(key);
                sheetError = null;
              });
              try {
                await ref.read(chatsRepositoryProvider).unblockUser(item.user.id);
                blockedUsers = blockedUsers.where((entry) => entry.user.id != item.user.id).toList();
                setSheetState(() {});
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пользователь разблокирован')),
                );
                unawaited(refreshChatsList(ref));
                unawaited(refreshFriendsSnapshot(ref));
              } on ChatException catch (e) {
                if (e.statusCode == 401) {
                  await ref.read(authStateProvider.notifier).logout();
                  if (!mounted) return;
                  Navigator.of(sheetContext).pop();
                  context.go('/login');
                  return;
                }
                setSheetState(() => sheetError = e.message);
              } catch (_) {
                setSheetState(() => sheetError = 'Не удалось разблокировать пользователя');
              } finally {
                if (mounted) {
                  setSheetState(() => busyIDs.remove(key));
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.viewInsetsOf(sheetInnerContext).bottom + 10,
                ),
                child: GradientCard(
                  animate: false,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 430,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Заблокированные',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (sheetError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            sheetError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Expanded(
                          child: blockedUsers.isEmpty
                              ? ListView(
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
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  itemCount: blockedUsers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
                                    final item = blockedUsers[index];
                                    final key = item.user.id;
                                    final busy = busyIDs.contains(key);
                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            _AvatarDot(user: item.user),
                                            const SizedBox(width: 10),
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
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Заблокирован: ${_formatDateTime(item.blockedAt)}',
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
                                            IconButton(
                                              onPressed: busy ? null : () => unblock(item),
                                              tooltip: 'Разблокировать',
                                              icon: busy
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                  : const Icon(Icons.lock_open_rounded),
                                            ),
                                          ],
                                        ),
                                      ),
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
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsListProvider);
    final chats = chatsAsync.valueOrNull ?? const <ChatPreviewItem>[];
    final sortedChats = _sortedChats(chats);
    final providerError = chatsAsync.whenOrNull(
      error: (err, _) => err is ChatException ? err.message : 'Не удалось загрузить чаты',
    );
    final errorText = _error ?? providerError;
    final loading = chatsAsync.isLoading && chats.isEmpty && errorText == null;
    final listPadding = const EdgeInsets.fromLTRB(16, 12, 16, 16);

    Widget buildStateList(List<Widget> children) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: listPadding,
        children: children,
      );
    }

    final listContent = loading
        ? buildStateList(const [
            SizedBox(height: 100),
            Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ])
        : errorText != null
            ? buildStateList([
                const SizedBox(height: 100),
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ])
            : sortedChats.isEmpty
                ? buildStateList(const [
                    SizedBox(height: 100),
                    Text(
                      'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы выбрать друга и начать диалог.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: listPadding,
                    itemCount: sortedChats.length,
                    itemBuilder: (context, index) {
                      final item = sortedChats[index];
                      final clearKey = 'clear_${item.chatID}';
                      final blockKey = 'block_${item.user.id}';
                      final busy = _actionInFlight.contains(clearKey) || _actionInFlight.contains(blockKey);
                      final lastMessage = item.lastMessage;
                      final unread = item.unreadCount;
                      final subtitle = (lastMessage?.body ?? '').trim();

                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                        child: Dismissible(
                          key: ValueKey('chat-${item.chatID}'),
                          direction: busy ? DismissDirection.none : DismissDirection.endToStart,
                          dismissThresholds: const {
                            DismissDirection.endToStart: 0.36,
                          },
                          background: const SizedBox.shrink(),
                          secondaryBackground: _buildSwipeActionsBackground(),
                          confirmDismiss: (_) async {
                            final picked = await _pickSwipeAction(item);
                            if (picked == _ChatSwipeAction.clear) {
                              await _clearChat(item);
                            } else if (picked == _ChatSwipeAction.block) {
                              await _blockUserFromChat(item);
                            }
                            return false;
                          },
                          child: Opacity(
                            opacity: busy ? 0.65 : 1,
                            child: GradientCard(
                              margin: EdgeInsets.zero,
                              animate: false,
                              child: InkWell(
                                onTap: () {
                                  final name = Uri.encodeQueryComponent(_peerTitle(item.user));
                                  context.push('/chats/${item.chatID}?name=$name');
                                },
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
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
                  );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(
                    'Чаты',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openBlockedUsersDialog,
                    tooltip: 'Заблокированные пользователи',
                    icon: const Icon(Icons.block_rounded),
                  ),
                  IconButton(
                    onPressed: _openStartChatDialog,
                    tooltip: 'Новый чат',
                    icon: const Icon(Icons.add_comment_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadChats,
                child: listContent,
              ),
            ),
          ],
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
