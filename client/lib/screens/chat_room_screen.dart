import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
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

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  static const _pollInterval = Duration(seconds: 3);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ChatMessageItem> _messages = const [];

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool initial = false}) async {
    try {
      final list = await ref.read(chatsRepositoryProvider).listMessages(widget.chatID, limit: 100);
      if (!mounted) return;

      final previousLastID = _messages.isEmpty ? null : _messages.last.id;
      final nextLastID = list.isEmpty ? null : list.last.id;
      final hasNewTail = previousLastID != nextLastID;

      setState(() {
        _messages = list;
        _error = null;
        _loading = false;
      });

      if (hasNewTail || initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      // Отмечаем как прочитанные в фоне.
      unawaited(ref.read(chatsRepositoryProvider).markRead(widget.chatID));
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить сообщения';
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final sent = await ref.read(chatsRepositoryProvider).sendMessage(widget.chatID, text);
      if (!mounted) return;
      _textController.clear();
      setState(() {
        _messages = [..._messages, sent];
        _sending = false;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } on ChatException catch (e) {
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

  String _formatBubbleTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final meID = ref.watch(authStateProvider).valueOrNull?.id;
    final title = (widget.peerName ?? '').trim().isEmpty ? 'Диалог' : widget.peerName!.trim();

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
                    onPressed: () => context.go('/chats'),
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
                  IconButton(
                    onPressed: _loadMessages,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Обновить',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        )
                      : _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Сообщений пока нет.\nНапишите первое сообщение.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
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
                                            _formatBubbleTime(message.createdAt),
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
            ),
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
