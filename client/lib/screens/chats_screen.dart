import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  bool _loading = true;
  String? _error;
  List<ChatPreviewItem> _chats = const [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final items = await ref.read(chatsRepositoryProvider).listChats(limit: 100, offset: 0);
      if (!mounted) return;
      setState(() {
        _chats = items;
        _error = null;
        _loading = false;
      });
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить чаты';
        _loading = false;
      });
    }
  }

  Future<void> _openStartChatDialog() async {
    final controller = TextEditingController();
    String? localError;
    var submitting = false;

    final startedChatID = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final targetUserID = controller.text.trim();
              if (targetUserID.isEmpty) {
                setDialogState(() {
                  localError = 'Введите UUID пользователя';
                });
                return;
              }

              setDialogState(() {
                submitting = true;
                localError = null;
              });
              try {
                final chatID = await ref.read(chatsRepositoryProvider).startChat(targetUserID);
                if (!context.mounted) return;
                Navigator.of(context).pop(chatID);
              } on ChatException catch (e) {
                setDialogState(() {
                  localError = e.message;
                  submitting = false;
                });
              } catch (_) {
                setDialogState(() {
                  localError = 'Не удалось создать чат';
                  submitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Новый чат'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'UUID пользователя',
                      hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                AppButton(
                  onPressed: submitting ? null : submit,
                  label: submitting ? 'Создание...' : 'Создать',
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (startedChatID == null || startedChatID.isEmpty) return;

    await _loadChats();
    if (!mounted) return;
    context.push('/chats/$startedChatID');
  }

  String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _peerTitle(ChatUserItem user) {
    final value = user.displayName?.trim();
    if (value == null || value.isEmpty) {
      return 'Пользователь';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadChats,
          child: ListView(
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
                    onPressed: _loading ? null : _loadChats,
                    tooltip: 'Обновить',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    onPressed: _openStartChatDialog,
                    tooltip: 'Новый чат',
                    icon: const Icon(Icons.add_comment_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                )
              else if (_chats.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Пока нет чатов.\nНажмите на иконку справа сверху, чтобы начать диалог по UUID пользователя.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ..._chats.map(
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
