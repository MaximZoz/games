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
import 'package:multigames_client/ui/avatar_memory_cache.dart';
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

const List<IconData> _chatAvatarIcons = [
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

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with WidgetsBindingObserver {
  static const int _messagesPageSize = 20;
  static const double _loadOlderThreshold = 120;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  final Set<String> _messageIDs = <String>{};

  RealtimeSocket? _socket;
  StreamSubscription<String>? _socketSubscription;
  Timer? _reconnectTimer;

  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  bool _leavingToChats = false;
  bool _roomActionInFlight = false;
  String? _error;
  List<ChatMessageItem> _messages = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _composerFocusNode.addListener(_onComposerFocusChanged);
    _scrollController.addListener(_onMessagesScroll);
    _loadMessages(initial: true);
    unawaited(_connectRealtime());
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!_composerFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composerFocusNode.removeListener(_onComposerFocusChanged);
    _scrollController.removeListener(_onMessagesScroll);
    _reconnectTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    _socket?.close();
    _composerFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onComposerFocusChanged() {
    if (!_composerFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _goBackToChats() async {
    if (_leavingToChats) return;
    setState(() => _leavingToChats = true);
    if (!mounted) return;
    context.go('/chats');
    unawaited(
      refreshChatsList(ref, force: true).catchError((_) {
        // Фоновая синхронизация после перехода назад.
      }),
    );
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
      final list = await ref.read(chatsRepositoryProvider).listMessages(
            widget.chatID,
            limit: _messagesPageSize,
          );
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
          _loadingOlder = false;
          _hasMoreOlder = list.length >= _messagesPageSize;
        });
      } else if (_loadingOlder || _hasMoreOlder != (list.length >= _messagesPageSize)) {
        setState(() {
          _loadingOlder = false;
          _hasMoreOlder = list.length >= _messagesPageSize;
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

  void _onMessagesScroll() {
    if (!_scrollController.hasClients) return;
    if (_loading || _loadingOlder || !_hasMoreOlder || _messages.isEmpty) return;
    if (_scrollController.position.pixels <= _loadOlderThreshold) {
      unawaited(_loadOlderMessages());
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loading || _loadingOlder || !_hasMoreOlder || _messages.isEmpty) return;
    final before = DateTime.tryParse(_messages.first.createdAt);
    if (before == null) {
      if (mounted) {
        setState(() => _hasMoreOlder = false);
      }
      return;
    }

    final previousMaxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    if (mounted) {
      setState(() => _loadingOlder = true);
    }

    try {
      final older = await ref.read(chatsRepositoryProvider).listMessages(
            widget.chatID,
            limit: _messagesPageSize,
            before: before.toUtc(),
          );
      if (!mounted) return;

      if (older.isEmpty) {
        setState(() {
          _loadingOlder = false;
          _hasMoreOlder = false;
        });
        return;
      }

      final deduplicated = older.where((m) => !_messageIDs.contains(m.id)).toList();
      setState(() {
        if (deduplicated.isNotEmpty) {
          _messages = [...deduplicated, ..._messages];
          _messageIDs.addAll(deduplicated.map((m) => m.id));
        }
        _loadingOlder = false;
        _hasMoreOlder = older.length >= _messagesPageSize;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
        final delta = newMaxScrollExtent - previousMaxScrollExtent;
        final targetOffset = _scrollController.offset + (delta > 0 ? delta : 0);
        _scrollController.jumpTo(targetOffset);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
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

  String _peerTitle(ChatUserItem user) {
    final value = user.displayName?.trim();
    if (value == null || value.isEmpty) return 'Пользователь';
    return value;
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

  Widget _buildPeerAvatar({
    required ChatUserItem? user,
    required String fallbackTitle,
    double radius = 18,
  }) {
    if (user != null &&
        user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.trim().isNotEmpty) {
      final memoryImage = AvatarMemoryCache.fromAvatarValue(user.avatarValue);
      if (memoryImage != null) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: memoryImage,
        );
      }
    }

    if (user != null && user.avatarKind == 'preset') {
      final iconIndex = int.tryParse(user.avatarValue ?? '');
      if (iconIndex != null) {
        final idx = iconIndex % _chatAvatarIcons.length;
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(
            _chatAvatarIcons[idx],
            color: AppColors.accentStart,
            size: radius,
          ),
        );
      }
    }

    final raw = user?.displayName?.trim() ?? fallbackTitle.trim();
    final letter = raw.isEmpty ? '?' : raw.substring(0, 1).toUpperCase();
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

  Future<void> _showUserInfoDialog(ChatUserItem user) async {
    final name = _peerTitle(user);
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
                    _buildPeerAvatar(
                      user: user,
                      fallbackTitle: name,
                      radius: 22,
                    ),
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
    final routeTitle = (widget.peerName ?? '').trim().isEmpty ? 'Диалог' : widget.peerName!.trim();
    final chats = ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
    ChatUserItem? peerUser;
    for (final item in chats) {
      if (item.chatID == widget.chatID) {
        peerUser = item.user;
        break;
      }
    }
    final title = peerUser == null ? routeTitle : _peerTitle(peerUser);
    final infoUser = peerUser;

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
                itemCount: timeline.length + ((_loadingOlder || _hasMoreOlder) ? 1 : 0),
                itemBuilder: (context, index) {
                  final topLoaderVisible = _loadingOlder || _hasMoreOlder;
                  if (topLoaderVisible && index == 0) {
                    if (_loadingOlder) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 8);
                  }

                  final timelineIndex = topLoaderVisible ? index - 1 : index;
                  final entry = timeline[timelineIndex];
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
                  _buildPeerAvatar(
                    user: peerUser,
                    fallbackTitle: title,
                    radius: 18,
                  ),
                  const SizedBox(width: 8),
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
                  IconButton(
                    onPressed: infoUser == null
                        ? null
                        : () {
                            final user = infoUser;
                            unawaited(_showUserInfoDialog(user));
                          },
                    tooltip: 'Информация о пользователе',
                    icon: const Icon(Icons.info_outline_rounded),
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
                        focusNode: _composerFocusNode,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onTap: _scrollToBottom,
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
