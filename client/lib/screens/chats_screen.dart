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

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsListProvider);
    final chats = chatsAsync.valueOrNull ?? const <ChatPreviewItem>[];
    final providerError = chatsAsync.whenOrNull(
      error: (err, _) => err is ChatException ? err.message : 'Не удалось загрузить чаты',
    );
    final errorText = _error ?? providerError;
    final loading = chatsAsync.isLoading && chats.isEmpty && errorText == null;

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
                  IconButton(
                    onPressed: _openStartChatDialog,
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
                    return GradientCard(
                      margin: const EdgeInsets.only(top: 10),
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
