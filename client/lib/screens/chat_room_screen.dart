import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_ws.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatID,
    this.peerName,
  });

  final String chatID;
  final String? peerName;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

enum _RoomAction { clearChat, blockUser }

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _messageIDs = <String>{};

  RealtimeSocket? _socket;
  StreamSubscription<String>? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _backgroundSyncTimer;
  bool _syncInFlight = false;

  bool _loading = true;
  bool _sending = false;
  bool _leavingToChats = false;
  bool _roomActionInFlight = false;
  String? _error;
  List<ChatMessageItem> _messages = const [];

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    unawaited(_connectRealtime());
    _startBackgroundSync();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _reconnectTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    _socket?.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _goBackToChats() async {
    if (_leavingToChats) return;
    setState(() => _leavingToChats = true);
    try {
      await refreshChatsList(ref, force: true);
    } catch (_) {
      // Если синхронизация не удалась, всё равно даём вернуться в список.
    }
    if (!mounted) return;
    context.go('/chats');
  }

  Future<bool> _confirmAction({
    required String title,
    required String description,
    required String confirmText,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
        );
      },
    );
    return result == true;
  }

  Future<void> _runRoomAction(
    _RoomAction action, {
    required String? peerUserID,
  }) async {
    if (_roomActionInFlight) return;

    if (action == _RoomAction.blockUser) {
      final id = (peerUserID ?? '').trim();
      if (id.isEmpty) return;
      final confirmed = await _confirmAction(
        title: 'Заблокировать пользователя?',
        description:
            'Вы больше не сможете писать друг другу. Диалог и дружба будут удалены.',
        confirmText: 'Заблокировать',
        destructive: true,
      );
      if (!confirmed) return;

      setState(() => _roomActionInFlight = true);
      try {
        await ref.read(chatsRepositoryProvider).blockUser(id);
        await refreshChatsList(ref, force: true);
        await refreshFriendsSnapshot(ref);
        if (!mounted) return;
        context.go('/chats');
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
        if (mounted) setState(() => _roomActionInFlight = false);
      }
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Очистить переписку?',
      description: 'Диалог будет удалён без возможности восстановления.',
      confirmText: 'Очистить',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _roomActionInFlight = true);
    try {
      await ref.read(chatsRepositoryProvider).clearChat(widget.chatID);
      await refreshChatsList(ref, force: true);
      if (!mounted) return;
      context.go('/chats');
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
      if (mounted) setState(() => _roomActionInFlight = false);
    }
  }

  Future<void> _loadMessages({bool initial = false, bool surfaceErrors = true}) async {
    try {
      final list = await ref.read(chatsRepositoryProvider).listMessages(widget.chatID, limit: 100);
      if (!mounted) return;

      final previousLastID = _messages.isEmpty ? null : _messages.last.id;
      final nextLastID = list.isEmpty ? null : list.last.id;
      final hasNewTail = previousLastID != nextLastID;
      final changed = !_areMessagesEqual(_messages, list);

      if (_loading || _error != null || changed) {
        setState(() {
          _messages = list;
          _messageIDs
            ..clear()
            ..addAll(list.map((e) => e.id));
          _error = null;
          _loading = false;
        });
      }

      if (hasNewTail || initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      unawaited(() async {
        try {
          final updated = await ref.read(chatsRepositoryProvider).markRead(widget.chatID);
          if (updated > 0) {
            await refreshChatsList(ref);
          }
        } catch (_) {
          // Ошибку чтения не показываем пользователю в фоне.
        }
      }());
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!surfaceErrors) return;
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!surfaceErrors) return;
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить сообщения';
        _loading = false;
      });
    }
  }

  Future<void> _connectRealtime() async {
    await _socketSubscription?.cancel();
    _socket?.close();
    _socket = null;

    final token = await ref.read(authRepositoryProvider).getAccessToken();
    if (token == null || token.isEmpty) return;

    final uri = buildWebSocketUri(
      '/api/ws',
      queryParameters: {'access_token': token},
    );
    final socket = connectRealtimeSocket(uri);
    _socket = socket;
    _socketSubscription = socket.messages.listen(
      _handleRealtimeMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (!mounted || _reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      unawaited(_connectRealtime());
    });
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _syncInFlight || _loading) return;
      _syncInFlight = true;
      unawaited(
        _loadMessages(surfaceErrors: false).whenComplete(() {
          _syncInFlight = false;
        }),
      );
    });
  }

  void _handleRealtimeMessage(String raw) {
    try {
      final payload = jsonDecode(raw);
      if (payload is! Map) return;
      final type = payload['type']?.toString() ?? '';
      if (type == 'chat_message') {
        final chatID = payload['chat_id']?.toString() ?? '';
        if (chatID != widget.chatID) return;
        final messageRaw = payload['message'];
        if (messageRaw is! Map) return;
        final item = ChatMessageItem.fromJson(Map<String, dynamic>.from(messageRaw));
        _upsertMessage(item);
        unawaited(refreshChatsList(ref));
        final meID = ref.read(authStateProvider).valueOrNull?.id;
        if (item.senderUserID != meID) {
          unawaited(ref.read(chatsRepositoryProvider).markRead(widget.chatID));
        }
      } else if (type == 'chat_read') {
        final chatID = payload['chat_id']?.toString() ?? '';
        if (chatID == widget.chatID) {
          unawaited(_loadMessages());
        }
        unawaited(refreshChatsList(ref));
      } else if (type == 'chat_list_changed') {
        unawaited(refreshChatsList(ref));
      } else if (type == 'friends_updated') {
        unawaited(refreshFriendsSnapshot(ref));
      }
    } catch (_) {}
  }

  void _upsertMessage(ChatMessageItem item) {
    if (!mounted) return;

    final existingIndex = _messages.indexWhere((m) => m.id == item.id);
    if (existingIndex >= 0) {
      final updated = List<ChatMessageItem>.of(_messages);
      updated[existingIndex] = item;
      setState(() {
        _messages = updated;
        _messageIDs.add(item.id);
      });
      return;
    }

    setState(() {
      _messages = [..._messages, item];
      _messageIDs.add(item.id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  bool _areMessagesEqual(List<ChatMessageItem> a, List<ChatMessageItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.senderUserID != right.senderUserID ||
          left.body != right.body ||
          left.createdAt != right.createdAt ||
          left.readAt != right.readAt) {
        return false;
      }
    }
    return true;
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final sent = await ref.read(chatsRepositoryProvider).sendMessage(widget.chatID, text);
      if (!mounted) return;
      _textController.clear();
      _upsertMessage(sent);
      unawaited(refreshChatsList(ref));
      setState(() {
        _sending = false;
        _error = null;
      });
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось отправить сообщение';
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  String _formatBubbleDateTime(String raw) {
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

  String _formatDateGroupTitle(DateTime localDate) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterdayKey = todayKey.subtract(const Duration(days: 1));
    final dateKey = DateTime(localDate.year, localDate.month, localDate.day);
    if (dateKey == todayKey) return 'Сегодня';
    if (dateKey == yesterdayKey) return 'Вчера';
    final dd = localDate.day.toString().padLeft(2, '0');
    final mo = localDate.month.toString().padLeft(2, '0');
    final yyyy = localDate.year.toString();
    return '$dd.$mo.$yyyy';
  }

  List<_ChatTimelineEntry> _buildTimelineEntries() {
    final entries = <_ChatTimelineEntry>[];
    DateTime? previousDate;
    for (final message in _messages) {
      final parsed = DateTime.tryParse(message.createdAt)?.toLocal();
      if (parsed != null) {
        final currentDate = DateTime(parsed.year, parsed.month, parsed.day);
        if (previousDate == null || currentDate != previousDate) {
          entries.add(_ChatTimelineEntry.header(_formatDateGroupTitle(parsed)));
          previousDate = currentDate;
        }
      }
      entries.add(_ChatTimelineEntry.message(message));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final meID = ref.watch(authStateProvider).valueOrNull?.id;
    final title = (widget.peerName ?? '').trim().isEmpty ? 'Диалог' : widget.peerName!.trim();
    final chats = ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
    ChatUserItem? peerUser;
    for (final item in chats) {
      if (item.chatID == widget.chatID) {
        peerUser = item.user;
        break;
      }
    }

    Widget messagesWidget;
    if (_loading) {
      messagesWidget = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (_error != null) {
      messagesWidget = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      );
    } else {
      final timeline = _buildTimelineEntries();
      messagesWidget = RefreshIndicator(
        onRefresh: _loadMessages,
        child: _messages.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Сообщений пока нет.\nНапишите первое сообщение.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: timeline.length,
                itemBuilder: (context, index) {
                  final entry = timeline[index];
                  if (entry.headerLabel != null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black.withOpacity(0.08)),
                          ),
                          child: Text(
                            entry.headerLabel!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final message = entry.message!;
                  final mine = message.senderUserID == meID;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.accentSoft : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: mine
                                ? AppColors.accentStart.withOpacity(0.35)
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.body,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatBubbleDateTime(message.createdAt),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _leavingToChats ? null : _goBackToChats,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Назад к чатам',
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  PopupMenuButton<_RoomAction>(
                    enabled: !_roomActionInFlight,
                    tooltip: 'Действия с чатом',
                    onSelected: (action) {
                      unawaited(_runRoomAction(action, peerUserID: peerUser?.id));
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<_RoomAction>(
                        value: _RoomAction.clearChat,
                        child: Text('Очистить переписку'),
                      ),
                      PopupMenuItem<_RoomAction>(
                        value: _RoomAction.blockUser,
                        enabled: (peerUser?.id ?? '').trim().isNotEmpty,
                        child: const Text('Заблокировать пользователя'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
            ),
            Expanded(child: messagesWidget),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: GradientCard(
                animate: false,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _sendMessage,
                      tooltip: 'Отправить',
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
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

class _ChatTimelineEntry {
  const _ChatTimelineEntry.header(this.headerLabel) : message = null;
  const _ChatTimelineEntry.message(this.message) : headerLabel = null;

  final String? headerLabel;
  final ChatMessageItem? message;
}
