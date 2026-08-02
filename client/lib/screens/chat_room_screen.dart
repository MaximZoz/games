import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/chats/chat_image_pick.dart';
import 'package:multigames_client/chats/chat_image_widgets.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/chats/coins_credit_message.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/message_status_ticks.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatID,
    this.peerName,
    this.fromFriends = false,
    this.fromGames = false,
    this.gameReturnPath,
    this.inSplitView = false,
  });

  final String chatID;
  final String? peerName;
  final bool fromFriends;
  final bool fromGames;
  final String? gameReturnPath;
  final bool inSplitView;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

enum _RoomAction {
  clearChat,
  blockUser,
  sendFriendRequest,
  acceptFriendRequest,
  removeFriend,
}

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
  static const int _messagesInitialLoad = 15;
  static const double _loadOlderThreshold = 120;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  final Set<String> _messageIDs = <String>{};

  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  bool _initialScrollDone = false;
  bool _leavingToChats = false;
  bool _showScrollToBottomButton = false;
  bool _roomActionInFlight = false;
  bool _emojiOnly = false;
  String? _composerAlert;
  String? _error;
  List<ChatMessageItem> _messages = const [];
  ChatMessageItem? _replyTo;
  ChatMessageItem? _editingMessage;
  final List<_PendingImageEntry> _pendingImages = [];
  static const int _maxPendingImages = 3;
  int _pendingImageSeq = 0;
  static const Color _composerIconPurple = Color(0xFF8B5CF6);
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
  String? _highlightedMessageID;
  bool _jumpingToMessage = false;

  /// Всплывашка «Вставить» для скопированной invite-ссылки.
  String? _pasteInviteUrl;
  bool _pasteSuggestionVisible = false;
  bool _applyingPaste = false;

  /// Статусы, пришедшие по WS раньше, чем сообщение попало в ленту.
  final Set<String> _pendingDeliveredIDs = <String>{};
  final Set<String> _pendingReadIDs = <String>{};
  final Map<String, String> _pendingDeliveredAtByID = <String, String>{};
  final Map<String, String> _pendingReadAtByID = <String, String>{};

  /// Автоперевод входящих сообщений (локальный переключатель на чат).
  bool _autoTranslate = false;
  final Map<String, String> _translations = <String, String>{};
  bool _translateInFlight = false;
  String? _peerLanguageHint;

  String get _autoTranslatePrefsKey => 'chat_auto_translate_${widget.chatID}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _composerFocusNode.addListener(_onComposerFocusChanged);
    _textController.addListener(_onComposerTextChanged);
    _scrollController.addListener(_onMessagesScroll);
    unawaited(_restoreAutoTranslatePref());
    _loadMessages(initial: true);
    unawaited(_loadCapabilities());
    // Сразу гасим бейдж таба при входе в чат (не ждём ответ markRead).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      markChatReadInChatsCache(ref, widget.chatID);
      unawaited(_maybeShowPasteSuggestion());
    });
  }

  @override
  void didUpdateWidget(covariant ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatID != widget.chatID) {
      _messages = const [];
      _loading = true;
      _loadingOlder = false;
      _hasMoreOlder = true;
      _initialScrollDone = false;
      _emojiOnly = false;
      _composerAlert = null;
      _highlightedMessageID = null;
      _pasteInviteUrl = null;
      _pasteSuggestionVisible = false;
      _messageKeys.clear();
      _messageIDs.clear();
      _translations.clear();
      _autoTranslate = false;
      _peerLanguageHint = null;
      unawaited(_restoreAutoTranslatePref());
      _loadMessages(initial: true);
      unawaited(_loadCapabilities());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_maybeShowPasteSuggestion());
      });
    }
  }

  Future<void> _restoreAutoTranslatePref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoTranslatePrefsKey) ?? false;
    if (!mounted) return;
    setState(() => _autoTranslate = enabled);
    if (enabled) unawaited(_ensureTranslations());
  }

  Future<void> _setAutoTranslate(bool enabled) async {
    setState(() {
      _autoTranslate = enabled;
      if (!enabled) _translations.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTranslatePrefsKey, enabled);
    if (enabled) unawaited(_ensureTranslations());
  }

  bool _isTranslatableBody(String body) {
    final t = body.trim();
    if (t.isEmpty) return false;
    if (isAnimatedEmojiMessage(t) ||
        isGiftCollectionMessage(t) ||
        isCoinsCreditMessage(t) ||
        isInviteLobbyMessage(t)) {
      return false;
    }
    return true;
  }

  String _displayBodyFor(ChatMessageItem message, {required bool mine}) {
    if (!_autoTranslate || mine) return message.body;
    return _translations[message.id] ?? message.body;
  }

  Future<void> _ensureTranslations({String? onlyMessageID}) async {
    if (!_autoTranslate || _translateInFlight || !mounted) return;
    final meID = ref.read(authStateProvider).valueOrNull?.id;
    if (meID == null || meID.isEmpty) return;
    final targetLang =
        effectiveAppLocale(ref.read(appLocaleProvider)).languageCode;
    final items = <({String id, String text})>[];
    for (final m in _messages) {
      if (m.senderUserID == meID) continue;
      if (onlyMessageID != null && m.id != onlyMessageID) continue;
      if (_translations.containsKey(m.id)) continue;
      if (!_isTranslatableBody(m.body)) continue;
      items.add((id: m.id, text: m.body));
    }
    if (items.isEmpty) return;
    _translateInFlight = true;
    try {
      final mapped = await ref.read(chatsRepositoryProvider).translateMessages(
            items: items,
            targetLang: targetLang,
            sourceLang: _peerLanguageHint,
            chatID: widget.chatID,
          );
      if (!mounted || !_autoTranslate) return;
      if (mapped.isEmpty) return;
      setState(() => _translations.addAll(mapped));
    } catch (_) {
      // оставляем оригинал
    } finally {
      _translateInFlight = false;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!_composerFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    final notifier = ref.read(mobileToolbarLeadingProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.state = null;
    });
    WidgetsBinding.instance.removeObserver(this);
    _composerFocusNode.removeListener(_onComposerFocusChanged);
    _textController.removeListener(_onComposerTextChanged);
    _scrollController.removeListener(_onMessagesScroll);
    _composerFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onComposerTextChanged() {
    if (_applyingPaste) return;
    if (!_pasteSuggestionVisible && _composerAlert == null) return;
    setState(() {
      _pasteSuggestionVisible = false;
      _composerAlert = null;
    });
  }

  Future<void> _maybeShowPasteSuggestion() async {
    if (!mounted || _textController.text.trim().isNotEmpty) return;

    String? url = ref.read(pendingInvitePasteProvider)?.trim();
    if (url == null || url.isEmpty || parseInviteLobbyShareUrl(url) == null) {
      url = null;
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text?.trim();
        if (text != null &&
            text.isNotEmpty &&
            parseInviteLobbyShareUrl(text) != null) {
          url = text;
        }
      } catch (_) {
        // Safari/PWA часто блокирует чтение буфера без жеста.
      }
    }
    if (!mounted || url == null) return;
    if (_textController.text.trim().isNotEmpty) return;
    setState(() {
      _pasteInviteUrl = url;
      _pasteSuggestionVisible = true;
    });
  }

  void _dismissPasteSuggestion() {
    if (!_pasteSuggestionVisible && _pasteInviteUrl == null) return;
    setState(() {
      _pasteSuggestionVisible = false;
    });
  }

  void _applyPasteSuggestion() {
    final url = _pasteInviteUrl?.trim();
    if (url == null || url.isEmpty) return;
    _applyingPaste = true;
    _textController.text = url;
    _textController.selection = TextSelection.collapsed(offset: url.length);
    ref.read(pendingInvitePasteProvider.notifier).state = null;
    setState(() {
      _pasteSuggestionVisible = false;
      _pasteInviteUrl = null;
      _composerAlert = null;
    });
    _applyingPaste = false;
    _composerFocusNode.requestFocus();
  }

  /// Диалог видим в shell (не фоновая вкладка и не уходим назад).
  /// Для markRead по WS — иначе сообщения помечаются прочитанными «в фоне».
  bool _isChatRoomVisibleInShell() {
    if (_leavingToChats || !mounted) return false;
    return ref.read(currentRoutePathProvider) == '/chats/${widget.chatID}';
  }

  void _onComposerFocusChanged() {
    if (!_composerFocusNode.hasFocus) return;
    unawaited(_loadCapabilities());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadCapabilities());
    }
  }

  void _goBackToChats() {
    if (_leavingToChats) return;
    _leavingToChats = true;

    final chatId = widget.chatID;
    // Локально сразу сбрасываем unread — список чатов без мигания.
    markChatReadInChatsCache(ref, chatId);

    if (widget.fromGames && widget.gameReturnPath != null) {
      context.go(widget.gameReturnPath!);
    } else if (widget.fromFriends) {
      context.go('/friends');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats');
    }

    // markRead на сервере — в фоне, не блокирует «Назад».
    unawaited(
      ref.read(chatsRepositoryProvider).markRead(chatId).then<void>(
            (_) {},
            onError: (_, __) {},
          ),
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
              child: Text(context.l10n.commonCancel),
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
    String? incomingRequestId,
  }) async {
    if (_roomActionInFlight) return;

    if (action == _RoomAction.sendFriendRequest ||
        action == _RoomAction.acceptFriendRequest) {
      final id = (peerUserID ?? '').trim();
      if (id.isEmpty) return;
      final chats =
          ref.read(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
      for (final c in chats) {
        if (c.chatID == widget.chatID &&
            (c.user.isSupport ||
                c.user.displayName?.trim() == 'Поддержка')) {
          return;
        }
      }
      setState(() => _roomActionInFlight = true);
      try {
        final repo = ref.read(friendsRepositoryProvider);
        if (action == _RoomAction.acceptFriendRequest) {
          final requestId = (incomingRequestId ?? '').trim();
          if (requestId.isEmpty) return;
          await repo.acceptRequest(requestId);
        } else {
          await repo.sendRequest(id);
        }
        await refreshFriendsSnapshot(ref);
        unawaited(_loadCapabilities());
        if (!mounted) return;
        showAppSnackBar(
          context,
          message: action == _RoomAction.acceptFriendRequest
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
          message: e.toString(),
          kind: AppSnackKind.error,
        );
      } finally {
        if (mounted) setState(() => _roomActionInFlight = false);
      }
      return;
    }

    if (action == _RoomAction.removeFriend) {
      final id = (peerUserID ?? '').trim();
      if (id.isEmpty) return;
      final chats =
          ref.read(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
      String peerName = LocaleService.l10n.chatThisUser;
      for (final item in chats) {
        if (item.chatID == widget.chatID) {
          final n = (item.user.displayName ?? '').trim();
          if (n.isNotEmpty) peerName = n;
          break;
        }
      }
      if (peerName == LocaleService.l10n.chatThisUser) {
        final routeName = (widget.peerName ?? '').trim();
        if (routeName.isNotEmpty) peerName = routeName;
      }
      final confirmed = await _confirmAction(
        title: context.l10n.friendsRemoveTitle,
        description: LocaleService.l10n.friendsRemoveConfirm(peerName),
        confirmText: LocaleService.l10n.friendsRemoveConfirmAction,
        destructive: true,
      );
      if (!confirmed) return;

      setState(() => _roomActionInFlight = true);
      try {
        await ref.read(friendsRepositoryProvider).removeFriend(id);
        await refreshFriendsSnapshot(ref);
        unawaited(_loadCapabilities());
        if (!mounted) return;
        showAppSnackBar(
          context,
          message: LocaleService.l10n.friendsRemoved,
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
          message: e.toString(),
          kind: AppSnackKind.error,
        );
      } finally {
        if (mounted) setState(() => _roomActionInFlight = false);
      }
      return;
    }

    if (action == _RoomAction.blockUser) {
      final id = (peerUserID ?? '').trim();
      if (id.isEmpty) return;
      final chats =
          ref.read(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
      for (final c in chats) {
        if (c.chatID == widget.chatID && c.user.isSupport) return;
      }
      final confirmed = await _confirmAction(
        title: context.l10n.chatsBlockTitle,
        description: context.l10n.chatsBlockDesc,
        confirmText: context.l10n.chatsBlockConfirm,
        destructive: true,
      );
      if (!confirmed) return;

      setState(() => _roomActionInFlight = true);
      try {
        final chatId = widget.chatID;
        await ref.read(chatsRepositoryProvider).blockUser(id);
        // Сразу убираем из сайдбара (десктоп split-view) и уходим из комнаты.
        removeChatFromChatsCache(ref, chatId);
        if (!mounted) return;
        context.go('/chats');
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
        if (mounted) setState(() => _roomActionInFlight = false);
      }
      return;
    }

    final confirmed = await _confirmAction(
      title: context.l10n.chatsClearTitle,
      description: context.l10n.chatsClearDesc,
      confirmText: context.l10n.chatsClearConfirm,
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _roomActionInFlight = true);
    try {
      final chatId = widget.chatID;
      await ref.read(chatsRepositoryProvider).clearChat(chatId);
      // Сайдбар на десктопе живёт в отдельном State — refreshChatsList его
      // не трогает. Удаляем локально и сразу закрываем комнату.
      removeChatFromChatsCache(ref, chatId);
      if (!mounted) return;
      context.go('/chats');
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
      if (mounted) setState(() => _roomActionInFlight = false);
    }
  }

  Future<void> _loadCapabilities() async {
    try {
      final caps =
          await ref.read(chatsRepositoryProvider).getCapabilities(widget.chatID);
      if (!mounted) return;
      if (_emojiOnly != caps.emojiOnly ||
          (!caps.emojiOnly && _composerAlert == _friendsOnlyAlert)) {
        setState(() {
          _emojiOnly = caps.emojiOnly;
          if (!caps.emojiOnly && _composerAlert == _friendsOnlyAlert) {
            _composerAlert = null;
          }
        });
      }
    } catch (_) {
      // Не блокируем чат при ошибке capabilities.
    }
  }

  static String get _friendsOnlyAlert => LocaleService.l10n.chatFriendsOnly;

  bool _isFriendsOnlySendError(ChatException e) {
    if (e.statusCode != 403) return false;
    final m = e.message.toLowerCase();
    return m.contains('only friends') ||
        m.contains('только друзья') ||
        m.contains('текст только для друзей') ||
        m.contains('только смайлик') ||
        m.contains('friends can send');
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (_sending) return;
    _dismissPasteSuggestion();
    if (_editingMessage != null) {
      if (text.isEmpty && !_editingMessage!.hasImage) return;
      setState(() {
        _sending = true;
        _composerAlert = null;
      });
      try {
        final edited = await ref
            .read(chatsRepositoryProvider)
            .editMessage(_editingMessage!.id, text);
        if (!mounted) return;
        _upsertMessage(edited);
        _textController.clear();
        setState(() {
          _sending = false;
          _editingMessage = null;
          _composerAlert = null;
        });
      } on ChatException catch (e) {
        if (e.statusCode == 401) {
          await ref.read(authStateProvider.notifier).logout();
          if (mounted) context.go('/login');
          return;
        }
        if (!mounted) return;
        setState(() {
          _sending = false;
          _composerAlert = e.message;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _composerAlert = LocaleService.l10n.chatEditFailed;
        });
      }
      return;
    }

    if (_pendingImages.any((e) => e.isLoading)) return;
    final readyImages = [
      for (final e in _pendingImages)
        if (e.image != null) e.image!,
    ];
    if (text.isEmpty && readyImages.isEmpty) return;

    setState(() {
      _sending = true;
      _composerAlert = null;
    });
    try {
      final images = readyImages;
      final replyID = _replyTo?.id;
      if (images.isEmpty) {
        final sent = await ref.read(chatsRepositoryProvider).sendMessage(
              widget.chatID,
              text,
              replyToMessageID: replyID,
            );
        if (!mounted) return;
        _upsertMessage(sent);
      } else {
        final sent = await ref.read(chatsRepositoryProvider).sendMessage(
              widget.chatID,
              text,
              replyToMessageID: replyID,
              images: [
                for (final img in images) (base64: img.base64, mime: img.mime),
              ],
            );
        if (!mounted) return;
        _upsertMessage(sent);
      }
      if (!mounted) return;
      _textController.clear();
      setState(() {
        _sending = false;
        _emojiOnly = false;
        _composerAlert = null;
        _replyTo = null;
        _pendingImages.clear();
      });
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      final friendsOnly = _isFriendsOnlySendError(e);
      setState(() {
        _sending = false;
        if (friendsOnly) _emojiOnly = true;
        _composerAlert = friendsOnly ? _friendsOnlyAlert : e.message;
      });
      if (!friendsOnly) {
        unawaited(_loadCapabilities());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _composerAlert = LocaleService.l10n.chatSendFailed;
      });
      unawaited(_loadCapabilities());
    }
  }

  void _startReply(ChatMessageItem message) {
    setState(() {
      _replyTo = message;
      _editingMessage = null;
      _composerAlert = null;
      _pasteSuggestionVisible = false;
    });
    _composerFocusNode.requestFocus();
  }

  void _startEdit(ChatMessageItem message) {
    _applyingPaste = true;
    setState(() {
      _editingMessage = message;
      _replyTo = null;
      _pendingImages.clear();
      _composerAlert = null;
      _pasteSuggestionVisible = false;
      _textController.text = message.body;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    });
    _applyingPaste = false;
    _composerFocusNode.requestFocus();
  }

  void _cancelComposerContext() {
    final wasEditing = _editingMessage != null;
    setState(() {
      _replyTo = null;
      _editingMessage = null;
      _pasteSuggestionVisible = false;
      if (wasEditing) {
        _textController.clear();
      }
    });
  }

  Future<void> _pickPhoto() async {
    if (_sending ||
        _editingMessage != null ||
        _emojiOnly ||
        _pendingImages.length >= _maxPendingImages) {
      return;
    }
    _dismissPasteSuggestion();
    // Сначала выбор файла; превью с лоадером — сразу после выбора, до сжатия.
    final raw = await pickChatImageRawBytes(ImageSource.gallery);
    if (!mounted || raw == null) return;
    if (_pendingImages.length >= _maxPendingImages) return;

    final entryId = 'pending_${_pendingImageSeq++}';
    setState(() {
      _pendingImages.add(_PendingImageEntry.loading(entryId));
      _composerAlert = null;
    });
    // Дать кадру отрисовать плейсхолдер с лоадером до тяжёлого сжатия.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;

    PickedChatImage? picked;
    try {
      picked = await compressRawChatImageAsync(raw);
    } catch (_) {
      picked = null;
    }
    if (!mounted) return;
    setState(() {
      final index = _pendingImages.indexWhere((e) => e.id == entryId);
      if (index < 0) return;
      if (picked == null) {
        _pendingImages.removeAt(index);
        _composerAlert = LocaleService.l10n.commonGenericError;
      } else {
        _pendingImages[index] = _PendingImageEntry.ready(entryId, picked);
      }
    });
  }

  void _removePendingImage(int index) {
    if (index < 0 || index >= _pendingImages.length) return;
    setState(() => _pendingImages.removeAt(index));
  }

  void _previewPendingImage(PickedChatImage image) {
    ChatImageFullscreenViewer.open(context, image.bytes);
  }

  Future<void> _showMessageActions(ChatMessageItem message) async {
    final meID = ref.read(authStateProvider).valueOrNull?.id;
    final mine = meID != null && message.senderUserID == meID;
    final canEdit = mine &&
        (message.body.trim().isNotEmpty || message.hasImage) &&
        !isAnimatedEmojiMessage(message.body) &&
        !isGiftCollectionMessage(message.body) &&
        !isCoinsCreditMessage(message.body) &&
        !isInviteLobbyMessage(message.body);

    final media = MediaQuery.of(context);
    final screen = media.size;
    final pad = media.padding;
    const menuWidth = 180.0;
    const menuMaxHeight = 168.0;
    const gap = 6.0;

    double? left;
    double? right;
    var top = screen.height * 0.35;

    final box =
        _keyForMessage(message.id).currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.attached) {
      final origin = box.localToGlobal(Offset.zero);
      final bubble = box.size;
      final spaceBelow = screen.height - pad.bottom - (origin.dy + bubble.height);
      if (spaceBelow >= menuMaxHeight + gap) {
        top = origin.dy + bubble.height + gap;
      } else {
        top = (origin.dy - menuMaxHeight - gap)
            .clamp(pad.top + 8.0, screen.height - pad.bottom - menuMaxHeight);
      }
      if (mine) {
        right = (screen.width - origin.dx - bubble.width)
            .clamp(8.0, screen.width - menuWidth - 8.0);
      } else {
        left = origin.dx.clamp(8.0, screen.width - menuWidth - 8.0);
      }
    } else if (mine) {
      right = 16;
    } else {
      left = 16;
    }

    final action = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: left,
              right: right,
              top: top,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 148,
                      maxWidth: menuWidth,
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _messageActionTile(
                            ctx,
                            value: 'reply',
                            label: context.l10n.commonReply,
                          ),
                          if (canEdit)
                            _messageActionTile(
                              ctx,
                              value: 'edit',
                              label: context.l10n.commonEdit,
                            ),
                          if (mine)
                            _messageActionTile(
                              ctx,
                              value: 'delete',
                              label: context.l10n.commonDelete,
                              danger: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'reply':
        _startReply(message);
      case 'edit':
        _startEdit(message);
      case 'delete':
        unawaited(_deleteMessage(message));
    }
  }

  Widget _messageActionTile(
    BuildContext ctx, {
    required String value,
    required String label,
    bool danger = false,
  }) {
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            color: danger ? Colors.red.shade700 : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessageItem message) async {
    try {
      await ref.read(chatsRepositoryProvider).deleteMessage(message.id);
      if (!mounted) return;
      _removeMessageLocally(message.id);
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _composerAlert = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _composerAlert = LocaleService.l10n.chatDeleteFailed);
    }
  }

  void _removeMessageLocally(String messageID) {
    if (!mounted) return;
    setState(() {
      _messages = _messages.where((m) => m.id != messageID).toList();
      _messageIDs.remove(messageID);
      if (_replyTo?.id == messageID) _replyTo = null;
      if (_editingMessage?.id == messageID) {
        _editingMessage = null;
        _textController.clear();
      }
    });
  }

  Widget _wrapSwipeReply({
    required ChatMessageItem message,
    required AlignmentGeometry alignment,
    required Widget child,
  }) {
    final highlighted = _highlightedMessageID == message.id;
    return KeyedSubtree(
      key: _keyForMessage(message.id),
      child: Dismissible(
        key: ValueKey('swipe_${message.id}'),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.15,
        },
        movementDuration: const Duration(milliseconds: 180),
        confirmDismiss: (_) async {
          _startReply(message);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          child: const Icon(
            Icons.reply_rounded,
            color: AppColors.accentStart,
            size: 26,
          ),
        ),
        child: Align(
          alignment: alignment,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: highlighted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentStart.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: GestureDetector(
              onLongPress: () => unawaited(_showMessageActions(message)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendAnimatedEmoji(InventoryItem item) async {
    final name = item.animatedName;
    if (name == null || name.isEmpty || _sending) return;
    if (item.quantity <= 0) return;

    setState(() {
      _sending = true;
    });
    try {
      await ref.read(shopRepositoryProvider).consumeEmoji(item.code);
      ref.invalidate(inventoryListProvider);
      final body = encodeAnimatedEmojiMessage(name);
      final sent =
          await ref.read(chatsRepositoryProvider).sendMessage(widget.chatID, body);
      if (!mounted) return;
      _upsertMessage(sent);
      setState(() {
        _sending = false;
        _composerAlert = null;
      });
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() {
        _sending = false;
        _composerAlert = e.message;
      });
      ref.invalidate(inventoryListProvider);
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _composerAlert =
            _isFriendsOnlySendError(e) ? _friendsOnlyAlert : e.message;
      });
      ref.invalidate(inventoryListProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _composerAlert = LocaleService.l10n.chatEmojiSendFailed;
      });
      ref.invalidate(inventoryListProvider);
    }
  }

  Future<void> _loadMessages({bool initial = false, bool surfaceErrors = true}) async {
    try {
      final list = await ref.read(chatsRepositoryProvider).listMessages(
            widget.chatID,
            limit: initial ? _messagesInitialLoad : _messagesPageSize,
          );
      if (!mounted) return;

      final previousLastID = _messages.isEmpty ? null : _messages.last.id;
      final nextLastID = list.isEmpty ? null : list.last.id;
      final hasNewTail = previousLastID != nextLastID;
      final changed = !_areMessagesEqual(_messages, list);

      final limitUsed = initial ? _messagesInitialLoad : _messagesPageSize;
      if (_loading || _error != null || changed) {
        setState(() {
          _messages = list;
          _messageIDs
            ..clear()
            ..addAll(list.map((e) => e.id));
          _error = null;
          _loading = false;
          _loadingOlder = false;
          _hasMoreOlder = list.length >= limitUsed;
        });
      } else if (_loadingOlder || _hasMoreOlder != (list.length >= limitUsed)) {
        setState(() {
          _loadingOlder = false;
          _hasMoreOlder = list.length >= limitUsed;
        });
      }

      if (hasNewTail || initial) {
        // ListView.builder строит элементы лениво. Длинные сообщения требуют нескольких
        // layout-проходов — повторяем скролл до низа, пока позиция не стабилизируется.
        _scheduleScrollToBottom(retriesLeft: 8);
      }
      // Подарки коллекций: бейдж на Главной/Предметах, даже если подарок
      // пришёл офлайн и пользователь сразу открыл чат (до sync списка).
      // Только ещё не прочитанные — чтобы старые подарки не поднимали бейдж снова.
      final me = ref.read(authStateProvider).valueOrNull?.id;
      // В группе read_at на сообщениях больше не ставится — не поднимаем подарки
      // повторно после локального markRead.
      final groupAlreadyRead =
          ref.read(locallyReadChatIdsProvider).contains(widget.chatID);
      if (me != null && me.isNotEmpty && !groupAlreadyRead) {
        final giftCodes = <String>{};
        for (final m in list) {
          if (m.senderUserID == me) continue;
          if (m.readAt != null && m.readAt!.trim().isNotEmpty) continue;
          final code = giftCollectionCodeFromBody(m.body);
          if (code != null) giftCodes.add(code);
        }
        if (giftCodes.isNotEmpty) {
          unawaited(
            ref
                .read(unreadGiftedCollectionsProvider.notifier)
                .addCodes(giftCodes),
          );
          ref.invalidate(inventoryListProvider);
          ref.invalidate(collectionIncomeProvider);
        }
      }
      // При открытии комнаты всегда отмечаем прочитанным (экран только что создан).
      // Повторные фоновые вызовы _loadMessages при уходе — нет (_leavingToChats).
      if (!_leavingToChats) {
        unawaited(() async {
          try {
            await ref.read(chatsRepositoryProvider).markRead(widget.chatID);
            if (!mounted) return;
            // Сразу гасим бейдж таба, не дожидаясь reload списка.
            markChatReadInChatsCache(ref, widget.chatID);
          } catch (_) {
            // Ошибку чтения не показываем пользователю в фоне.
          }
        }());
      }
      if (_autoTranslate) {
        unawaited(_ensureTranslations());
      }
    } on ChatException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
        return;
      }
      // Удалённый групповой чат / нет доступа — на список, не «Доступ запрещён».
      if (e.statusCode == 403 || e.statusCode == 404) {
        removeChatFromChatsCache(ref, widget.chatID);
        if (mounted) context.go('/chats');
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
        _error = LocaleService.l10n.chatLoadFailed;
        _loading = false;
      });
    }
  }

  static const double _scrollToBottomThreshold = 80;

  void _onMessagesScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final nearBottom = pos.pixels <= _scrollToBottomThreshold;
    if (_showScrollToBottomButton != !nearBottom) {
      setState(() => _showScrollToBottomButton = !nearBottom);
    }
    if (!_initialScrollDone || _loading || _loadingOlder || !_hasMoreOlder || _messages.isEmpty) return;
    if (pos.pixels >= pos.maxScrollExtent - _loadOlderThreshold) {
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

      final deduplicated =
          older.where((m) => !_messageIDs.contains(m.id)).toList();
      // reverse: true сам удерживает якорь у низа — jumpTo(offset+delta)
      // сдвигал ленту вверх при подгрузке истории.
      setState(() {
        if (deduplicated.isNotEmpty) {
          _messages = [...deduplicated, ..._messages];
          _messageIDs.addAll(deduplicated.map((m) => m.id));
        }
        _loadingOlder = false;
        _hasMoreOlder = older.length >= _messagesPageSize;
      });
      if (_autoTranslate && deduplicated.isNotEmpty) {
        unawaited(_ensureTranslations());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
    }
  }

  void _handleRealtimeEvent(Map<String, dynamic> payload) {
    if (!mounted) return;
    final type = payload['type']?.toString() ?? '';
    final chatID = payload['chat_id']?.toString() ?? '';
    if (type == 'chat_message') {
      if (chatID != widget.chatID) return;
      final messageRaw = payload['message'];
      if (messageRaw is! Map) return;
      final item = ChatMessageItem.fromJson(Map<String, dynamic>.from(messageRaw));
      _upsertMessage(item);
      if (!mounted) return;
      final meID = ref.read(authStateProvider).valueOrNull?.id;
      if (item.senderUserID != meID && _isChatRoomVisibleInShell()) {
        // Доставку отмечает chatsListProvider глобально; здесь только прочтение.
        unawaited(() async {
          try {
            await ref.read(chatsRepositoryProvider).markRead(widget.chatID);
            if (!mounted) return;
            markChatReadInChatsCache(ref, widget.chatID);
          } catch (_) {}
        }());
      }
      return;
    }
    if (type == 'chat_message_updated') {
      if (chatID != widget.chatID) return;
      final messageRaw = payload['message'];
      if (messageRaw is! Map) return;
      final item = ChatMessageItem.fromJson(Map<String, dynamic>.from(messageRaw));
      _upsertMessage(item);
      return;
    }
    if (type == 'chat_message_deleted') {
      if (chatID != widget.chatID) return;
      final messageID = payload['message_id']?.toString() ?? '';
      if (messageID.isEmpty) return;
      _removeMessageLocally(messageID);
      return;
    }
    if (type == 'chat_delivered') {
      if (chatID != widget.chatID) return;
      final meID = ref.read(authStateProvider).valueOrNull?.id;
      final delivererID = payload['deliverer_user_id']?.toString();
      if (meID == null || delivererID == null || delivererID == meID) return;
      final at = payload['delivered_at']?.toString() ??
          DateTime.now().toUtc().toIso8601String();
      _markOwnMessagesDelivered(
        meID,
        at,
        _parseMessageIDs(payload['message_ids']),
      );
      return;
    }
    if (type == 'chat_read') {
      if (chatID != widget.chatID) return;
      final meID = ref.read(authStateProvider).valueOrNull?.id;
      final readerID = payload['reader_user_id']?.toString();
      if (meID == null || readerID == null || readerID == meID) return;
      final at = payload['read_at']?.toString() ??
          DateTime.now().toUtc().toIso8601String();
      _markOwnMessagesRead(
        meID,
        at,
        _parseMessageIDs(payload['message_ids']),
      );
      return;
    }
  }

  Set<String> _parseMessageIDs(dynamic raw) {
    if (raw is! List) return const <String>{};
    return raw
        .map((e) => e?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  String? _preferStatusTs(String? incoming, String? existing) {
    if (existing != null && existing.isNotEmpty) return existing;
    if (incoming != null && incoming.isNotEmpty) return incoming;
    return null;
  }

  bool _messageMatchesStatusEvent(
    ChatMessageItem message,
    Set<String> messageIDs,
    String eventAt,
  ) {
    if (messageIDs.isNotEmpty) return messageIDs.contains(message.id);
    // Fallback без message_ids: не трогаем сообщения новее события.
    final at = DateTime.tryParse(eventAt)?.toUtc();
    final created = DateTime.tryParse(message.createdAt)?.toUtc();
    if (at == null || created == null) return true;
    return !created.isAfter(at);
  }

  void _markOwnMessagesDelivered(
    String meID,
    String deliveredAt,
    Set<String> messageIDs,
  ) {
    if (!mounted) return;
    if (messageIDs.isNotEmpty) {
      _pendingDeliveredIDs.addAll(messageIDs);
      for (final id in messageIDs) {
        _pendingDeliveredAtByID[id] = deliveredAt;
      }
    }
    var changed = false;
    final updated = _messages.map((m) {
      if (m.senderUserID != meID) return m;
      if (!_messageMatchesStatusEvent(m, messageIDs, deliveredAt)) return m;
      if (m.deliveredAt != null && m.deliveredAt!.isNotEmpty) return m;
      changed = true;
      return m.copyWith(deliveredAt: deliveredAt);
    }).toList(growable: false);
    if (!changed) return;
    setState(() => _messages = updated);
  }

  void _markOwnMessagesRead(
    String meID,
    String readAt,
    Set<String> messageIDs,
  ) {
    if (!mounted) return;
    if (messageIDs.isNotEmpty) {
      _pendingReadIDs.addAll(messageIDs);
      _pendingDeliveredIDs.addAll(messageIDs);
      for (final id in messageIDs) {
        _pendingReadAtByID[id] = readAt;
        _pendingDeliveredAtByID.putIfAbsent(id, () => readAt);
      }
    }
    var changed = false;
    final updated = _messages.map((m) {
      if (m.senderUserID != meID) return m;
      if (!_messageMatchesStatusEvent(m, messageIDs, readAt)) return m;
      final needDelivered = m.deliveredAt == null || m.deliveredAt!.isEmpty;
      final needRead = m.readAt == null || m.readAt!.isEmpty;
      if (!needDelivered && !needRead) return m;
      changed = true;
      return m.copyWith(
        deliveredAt: needDelivered ? readAt : m.deliveredAt,
        readAt: needRead ? readAt : m.readAt,
      );
    }).toList(growable: false);
    if (!changed) return;
    setState(() => _messages = updated);
  }

  ChatMessageItem _applyPendingStatus(ChatMessageItem item) {
    var deliveredAt = item.deliveredAt;
    var readAt = item.readAt;
    final pendingDelivered = _pendingDeliveredAtByID[item.id];
    final pendingRead = _pendingReadAtByID[item.id];
    if (pendingDelivered != null) {
      deliveredAt = _preferStatusTs(deliveredAt, pendingDelivered);
    }
    if (pendingRead != null) {
      readAt = _preferStatusTs(readAt, pendingRead);
      deliveredAt = _preferStatusTs(deliveredAt, pendingRead);
    }
    if (deliveredAt == item.deliveredAt && readAt == item.readAt) return item;
    return item.copyWith(deliveredAt: deliveredAt, readAt: readAt);
  }

  void _upsertMessage(ChatMessageItem item) {
    if (!mounted) return;

    final withPending = _applyPendingStatus(item);
    final existingIndex = _messages.indexWhere((m) => m.id == withPending.id);
    if (existingIndex >= 0) {
      final existing = _messages[existingIndex];
      // WS-эхо нового сообщения приходит без delivered/read — не затираем статусы.
      final merged = withPending.copyWith(
        body: withPending.body,
        editedAt: withPending.editedAt ?? existing.editedAt,
        hasImage: withPending.hasImage,
        imageCount: withPending.imageCount > 0
            ? withPending.imageCount
            : existing.imageCount,
        replyToMessageID: withPending.replyToMessageID ?? existing.replyToMessageID,
        replyToBody: withPending.replyToBody ?? existing.replyToBody,
        replyToHasImage: withPending.replyToHasImage,
        replyToSenderID: withPending.replyToSenderID ?? existing.replyToSenderID,
        deliveredAt:
            _preferStatusTs(withPending.deliveredAt, existing.deliveredAt),
        readAt: _preferStatusTs(withPending.readAt, existing.readAt),
      );
      final updated = List<ChatMessageItem>.of(_messages);
      updated[existingIndex] = merged;
      setState(() {
        _messages = updated;
        _messageIDs.add(withPending.id);
        // Текст мог измениться — сбросить кэш перевода.
        if (existing.body != merged.body) {
          _translations.remove(merged.id);
        }
      });
      if (_autoTranslate) {
        unawaited(_ensureTranslations(onlyMessageID: merged.id));
      }
      return;
    }

    setState(() {
      _messages = [..._messages, withPending];
      _messageIDs.add(withPending.id);
    });
    if (_autoTranslate) {
      unawaited(_ensureTranslations(onlyMessageID: withPending.id));
    }
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
          left.deliveredAt != right.deliveredAt ||
          left.readAt != right.readAt ||
          left.editedAt != right.editedAt ||
          left.hasImage != right.hasImage ||
          left.imageCount != right.imageCount ||
          left.replyToMessageID != right.replyToMessageID) {
        return false;
      }
    }
    return true;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    const target = 0.0;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  GlobalKey _keyForMessage(String messageID) {
    return _messageKeys.putIfAbsent(messageID, GlobalKey.new);
  }

  Future<void> _jumpToMessage(String messageID) async {
    final targetID = messageID.trim();
    if (targetID.isEmpty || _jumpingToMessage) return;
    _jumpingToMessage = true;
    try {
      var found = _messages.any((m) => m.id == targetID);
      var guard = 0;
      while (!found && mounted && guard < 50) {
        guard++;
        if (_loadingOlder) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          found = _messages.any((m) => m.id == targetID);
          continue;
        }
        if (!_hasMoreOlder) break;
        final beforeCount = _messages.length;
        await _loadOlderMessages();
        if (!mounted) return;
        found = _messages.any((m) => m.id == targetID);
        if (!found && _messages.length == beforeCount) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          if (_messages.length == beforeCount && !_loadingOlder) break;
        }
      }
      if (!mounted) return;
      if (!found) {
        setState(() => _composerAlert = context.l10n.chatReplySourceMissing);
        return;
      }

      setState(() {
        _highlightedMessageID = targetID;
        _composerAlert = null;
      });

      // С reverse-списком сначала прыгаем ближе по оценке, затем ensureVisible.
      if (_scrollController.hasClients) {
        final timeline = _buildTimelineEntries();
        final ti = timeline.indexWhere((e) => e.message?.id == targetID);
        if (ti >= 0) {
          var itemsFromEnd = 0;
          for (var i = timeline.length - 1; i > ti; i--) {
            itemsFromEnd++;
          }
          final estimated = (itemsFromEnd * 96.0)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.jumpTo(estimated);
        }
      }

      for (var attempt = 0; attempt < 12; attempt++) {
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
        final ctx = _keyForMessage(targetID).currentContext;
        if (ctx != null && ctx.mounted) {
          await Scrollable.ensureVisible(
            ctx,
            duration: attempt == 0
                ? Duration.zero
                : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.28,
          );
          break;
        }
        if (_scrollController.hasClients) {
          final next = (_scrollController.offset + 220)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.jumpTo(next);
        }
      }

      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      if (_highlightedMessageID == targetID) {
        setState(() => _highlightedMessageID = null);
      }
    } finally {
      _jumpingToMessage = false;
    }
  }

  void _scheduleScrollToBottom({int retriesLeft = 12}) {
    if (!mounted || retriesLeft <= 0) {
      if (mounted) setState(() => _initialScrollDone = true);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || !mounted) return;
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients || !mounted) return;
        final pos = _scrollController.position;
        const threshold = 24.0;
        if (pos.pixels > threshold) {
          _scheduleScrollToBottom(retriesLeft: retriesLeft - 1);
        } else {
          setState(() {
            _initialScrollDone = true;
            _showScrollToBottomButton = pos.pixels > _scrollToBottomThreshold;
          });
        }
      });
    });
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
    if (dateKey == todayKey) return context.l10n.chatToday;
    if (dateKey == yesterdayKey) return context.l10n.chatYesterday;
    final dd = localDate.day.toString().padLeft(2, '0');
    final mo = localDate.month.toString().padLeft(2, '0');
    final yyyy = localDate.year.toString();
    return '$dd.$mo.$yyyy';
  }

  String _peerTitle(ChatUserItem user) {
    final value = user.displayName?.trim();
    if (user.isSupport || value == 'Поддержка') {
      return context.l10n.supportTitle;
    }
    if (value == null || value.isEmpty) return context.l10n.commonUser;
    return value;
  }

  String _chatTitle(ChatPreviewItem? item, String fallback) {
    if (item?.isGroup == true) {
      final title = item?.title?.trim();
      if (title != null && title.isNotEmpty) return title;
      return 'Групповой чат';
    }
    final user = item?.user;
    return user == null ? fallback : _peerTitle(user);
  }

  /// Имя отправителя для группового чата (внутри пузыря, как в Telegram).
  String? _groupSenderName({
    required ChatPreviewItem? chat,
    required bool mine,
    required String senderUserID,
  }) {
    if (chat?.isGroup != true || mine) return null;
    final senderUser = _chatMember(chat, senderUserID);
    return senderUser == null ? context.l10n.commonUser : _peerTitle(senderUser);
  }

  /// Аватар слева для чужих сообщений в групповом чате (логин — внутри пузыря).
  Widget _wrapGroupSender({
    required ChatPreviewItem? chat,
    required bool mine,
    required String senderUserID,
    required Widget child,
  }) {
    final show = chat?.isGroup == true && !mine;
    if (!show) return child;
    final senderUser = _chatMember(chat, senderUserID);
    final senderName =
        senderUser == null ? context.l10n.commonUser : _peerTitle(senderUser);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPeerAvatar(
            user: senderUser,
            fallbackTitle: senderName,
            radius: 14,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: child),
      ],
    );
  }

  ChatUserItem? _chatMember(ChatPreviewItem? item, String userId) {
    if (item == null || userId.isEmpty) return null;
    for (final member in item.members) {
      if (member.id == userId) return member;
    }
    return null;
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
    bool? isOnline,
  }) {
    Widget avatar;
    if (user != null &&
        (user.isSupport || user.displayName?.trim() == 'Поддержка')) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.accentSoft,
        child: Icon(
          Icons.support_agent_rounded,
          color: AppColors.accentStart,
          size: radius * 1.15,
        ),
      );
    } else if (user != null &&
        user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.trim().isNotEmpty) {
      final memoryImage = AvatarMemoryCache.fromAvatarValue(user.avatarValue);
      if (memoryImage != null) {
        avatar = CircleAvatar(
          radius: radius,
          backgroundImage: memoryImage,
        );
      } else {
        avatar = _buildLetterAvatar(raw: user.displayName?.trim() ?? fallbackTitle.trim(), radius: radius);
      }
    } else if (user != null && user.avatarKind == 'preset') {
      final iconIndex = int.tryParse(user.avatarValue ?? '');
      if (iconIndex != null) {
        final idx = iconIndex % _chatAvatarIcons.length;
        avatar = CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(
            _chatAvatarIcons[idx],
            color: AppColors.accentStart,
            size: radius,
          ),
        );
      } else {
        avatar = _buildLetterAvatar(raw: user.displayName?.trim() ?? fallbackTitle.trim(), radius: radius);
      }
    } else {
      final raw = user?.displayName?.trim() ?? fallbackTitle.trim();
      avatar = _buildLetterAvatar(raw: raw, radius: radius);
    }
    avatar = FramedAvatar(
      size: radius * 2,
      borderWidth: radius < 18 ? 2.2 : 2.8,
      frameCode: user?.frameCode,
      frameColor: user?.frameColor,
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

  Widget _buildGroupAvatarStack(ChatPreviewItem? chat, {double radius = 18}) {
    final members = chat?.members.take(3).toList(growable: false) ??
        const <ChatUserItem>[];
    final size = radius * 2;
    return SizedBox(
      width: size + 18,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.accentSoft,
            child: Icon(
              Icons.grid_3x3_rounded,
              color: AppColors.accentStart,
              size: radius * 1.15,
            ),
          ),
          for (var i = 0; i < members.length; i++)
            Positioned(
              left: radius * 0.9 + i * (radius * 0.48),
              bottom: i.isEven ? -1 : radius * 0.28,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceCard, width: 1),
                ),
                child: _buildPeerAvatar(
                  user: members[i],
                  fallbackTitle: members[i].displayName ?? '?',
                  radius: radius * 0.38,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLetterAvatar({required String raw, required double radius}) {
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
            : (presence.online ? context.l10n.commonOnlineCap : formatLastSeen(presence.lastSeenAt));
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
                    _buildPeerAvatar(
                      user: user,
                      fallbackTitle: name,
                      radius: 22,
                      isOnline: presence?.online,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                      tooltip: context.l10n.commonClose,
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
                          text: context.l10n.profileAgeYears(user.age!),
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
                  Text(
                    context.l10n.commonAboutMe,
                    style: const TextStyle(
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
                HeadToHeadSection(
                  opponentId: user.id,
                  opponentName: user.displayName,
                ),
                PeerCollectionsSection(userId: user.id),
              ],
            ),
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

  /// Сумма бейджей нижнего меню, пока открыт этот чат:
  /// другие диалоги + игры (инвайты/ход) + друзья + главная.
  int _shellNotificationCount() {
    final chats =
        ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
    final localRead = ref.watch(locallyReadChatIdsProvider);
    var otherChats = 0;
    for (final item in chats) {
      if (item.chatID == widget.chatID) continue;
      if (localRead.contains(item.chatID)) continue;
      otherChats += item.unreadCount;
    }
    final incomingFriends = ref.watch(friendsIncomingCountProvider);
    final gamesMyTurn = ref.watch(gamesMyTurnCountProvider);
    final gameInvites = ref.watch(gameInvitesCountProvider);
    final dailyReward =
        ref.watch(dailyRewardAvailableProvider).valueOrNull == true ? 1 : 0;
    final achievements =
        ref.watch(achievementsUnclaimedCountProvider).valueOrNull ?? 0;
    final collectionIncome =
        ref.watch(collectionIncomeAvailableProvider) ? 1 : 0;
    final gifted = ref.watch(unreadGiftedCollectionsCountProvider);
    return otherChats +
        incomingFriends +
        gamesMyTurn +
        gameInvites +
        dailyReward +
        achievements +
        collectionIncome +
        gifted;
  }

  Widget _buildChatToolbar({
    required ChatUserItem? peerUser,
    required ChatPreviewItem? chat,
    required String title,
    PresenceEntry? presence,
  }) {
    final infoUser = peerUser;
    final isGroup = chat?.isGroup == true;
    final statusText = isGroup || presence == null
        ? null
        : (presence.online ? context.l10n.commonOnlineCap : formatLastSeen(presence.lastSeenAt));
    final notifyCount = _shellNotificationCount();
    final notifyLabel = notifyCount > 99 ? '99+' : '$notifyCount';
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.inSplitView && !widget.fromFriends && !widget.fromGames)
            const SizedBox(width: 8)
          else
            Tooltip(
              message: widget.fromGames
                  ? context.l10n.chatBackToGame
                  : context.l10n.chatBackToChats,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _leavingToChats ? null : _goBackToChats,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      10,
                      notifyCount > 0 ? 6 : 8,
                      10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          color: _leavingToChats
                              ? AppColors.textSecondary.withValues(alpha: 0.4)
                              : null,
                        ),
                        if (notifyCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            '($notifyLabel)',
                            style: TextStyle(
                              color: _leavingToChats
                                  ? AppColors.accentStart.withValues(alpha: 0.4)
                                  : AppColors.accentStart,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          isGroup
              ? _buildGroupAvatarStack(chat, radius: 18)
              : Tooltip(
                  message: context.l10n.userInfoTitle,
                  child: MouseRegion(
                    cursor: infoUser == null
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: infoUser == null
                          ? null
                          : () {
                              final user = infoUser;
                              unawaited(
                                _showUserInfoDialog(user, presence: presence),
                              );
                            },
                      behavior: HitTestBehavior.opaque,
                      child: _buildPeerAvatar(
                        user: peerUser,
                        fallbackTitle: title,
                        radius: 18,
                        isOnline: presence?.online,
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (statusText != null && statusText.isNotEmpty)
                  Text(
                    statusText,
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
          PopupMenuButton<_RoomAction>(
            enabled: !_roomActionInFlight,
            tooltip: context.l10n.chatActions,
            onSelected: (action) {
              if (isGroup && action == _RoomAction.sendFriendRequest) {
                unawaited(_showGroupMembersFriendSheet(chat));
                return;
              }
              final snapshot = ref.read(friendsSnapshotProvider).valueOrNull;
              final peerId = (peerUser?.id ?? '').trim();
              String? incomingRequestId;
              if (snapshot != null && peerId.isNotEmpty) {
                for (final r in snapshot.incoming) {
                  if (r.user.id == peerId) {
                    incomingRequestId = r.requestId;
                    break;
                  }
                }
              }
              unawaited(_runRoomAction(
                action,
                peerUserID: peerUser?.id,
                incomingRequestId: incomingRequestId,
              ));
            },
            itemBuilder: (context) {
              final peerId = (peerUser?.id ?? '').trim();
              final isSupport = peerUser?.isSupport == true ||
                  peerUser?.displayName?.trim() == 'Поддержка';
              if (isGroup) {
                return <PopupMenuEntry<_RoomAction>>[
                  PopupMenuItem<_RoomAction>(
                    value: _RoomAction.sendFriendRequest,
                    child: Text(context.l10n.friendsAdd),
                  ),
                ];
              }
              final snapshot = ref.read(friendsSnapshotProvider).valueOrNull;
              final isFriend = peerId.isNotEmpty &&
                  snapshot?.friends.any((f) => f.user.id == peerId) == true;
              final hasOutgoing = peerId.isNotEmpty &&
                  snapshot?.outgoing.any((r) => r.user.id == peerId) == true;
              final hasIncoming = peerId.isNotEmpty &&
                  snapshot?.incoming.any((r) => r.user.id == peerId) == true;

              return <PopupMenuEntry<_RoomAction>>[
                if (!isSupport && isFriend)
                  PopupMenuItem<_RoomAction>(
                    value: _RoomAction.removeFriend,
                    child: Text(context.l10n.friendsRemove),
                  )
                else if (!isSupport && peerId.isNotEmpty && snapshot != null)
                  if (hasIncoming)
                    PopupMenuItem<_RoomAction>(
                      value: _RoomAction.acceptFriendRequest,
                      child: Text(context.l10n.friendsAcceptRequest),
                    )
                  else if (hasOutgoing)
                    PopupMenuItem<_RoomAction>(
                      enabled: false,
                      value: _RoomAction.sendFriendRequest,
                      child: Text(context.l10n.friendsRequestAlreadySent),
                    )
                  else
                    PopupMenuItem<_RoomAction>(
                      value: _RoomAction.sendFriendRequest,
                      child: Text(context.l10n.friendsSendRequest),
                    ),
                PopupMenuItem<_RoomAction>(
                  value: _RoomAction.clearChat,
                  child: Text(context.l10n.chatsClearConfirm),
                ),
                if (!isSupport)
                  PopupMenuItem<_RoomAction>(
                    value: _RoomAction.blockUser,
                    enabled: peerId.isNotEmpty,
                    child: Text(context.l10n.chatsBlockConfirm),
                  ),
              ];
            },
            icon: const Icon(Icons.more_vert_rounded),
          ),
          if (_shouldShowAutoTranslate(peerUser))
            Tooltip(
              message: context.l10n.chatAutoTranslate,
              child: IconButton(
                onPressed: () => unawaited(_setAutoTranslate(!_autoTranslate)),
                icon: Icon(
                  Icons.translate_rounded,
                  color: _autoTranslate
                      ? AppColors.accentStart
                      : AppColors.textPrimary,
                  shadows: _autoTranslate
                      ? const [
                          Shadow(
                            color: Color(0x996366F1),
                            blurRadius: 10,
                          ),
                          Shadow(
                            color: Color(0x668B5CF6),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowAutoTranslate(ChatUserItem? peerUser) {
    final peerLang = (peerUser?.preferredLanguage ?? _peerLanguageHint ?? '')
        .trim()
        .toLowerCase();
    if (peerLang.isEmpty) return false;
    final myLang =
        effectiveAppLocale(ref.read(appLocaleProvider)).languageCode;
    return peerLang != myLang;
  }

  Future<void> _showGroupMembersFriendSheet(ChatPreviewItem? chat) async {
    if (chat == null || !chat.isGroup) return;
    final meId = ref.read(authStateProvider).valueOrNull?.id;
    final members = chat.members
        .where((m) => m.id.isNotEmpty && m.id != meId)
        .toList(growable: false);
    if (members.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GradientCard(
                  animate: false,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.friendsAdd,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      for (final member in members)
                        Builder(
                          builder: (context) {
                            final isFriend = snapshot?.friends
                                    .any((f) => f.user.id == member.id) ==
                                true;
                            final hasOutgoing = snapshot?.outgoing
                                    .any((r) => r.user.id == member.id) ==
                                true;
                            final title = _peerTitle(member);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: _buildPeerAvatar(
                                  user: member,
                                  fallbackTitle: title,
                                  radius: 20,
                                ),
                                title: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(
                                  isFriend
                                      ? Icons.check_rounded
                                      : Icons.person_add_alt_1_rounded,
                                  color: isFriend || hasOutgoing
                                      ? AppColors.textSecondary
                                      : AppColors.accentStart,
                                ),
                                onTap: isFriend || hasOutgoing
                                    ? null
                                    : () {
                                        Navigator.of(sheetContext).pop();
                                        unawaited(_runRoomAction(
                                          _RoomAction.sendFriendRequest,
                                          peerUserID: member.id,
                                        ));
                                      },
                              ),
                            );
                          },
                        ),
                    ],
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
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      realtimeEventsProvider,
      (_, next) {
        final event = next.valueOrNull;
        if (event == null) return;
        _handleRealtimeEvent(event);
      },
    );

    // Вернулись на вкладку с открытым диалогом — дочитываем накопившееся.
    ref.listen<String>(currentRoutePathProvider, (prev, next) {
      if (_leavingToChats) return;
      final roomPath = '/chats/${widget.chatID}';
      if (next != roomPath || prev == roomPath) return;
      unawaited(() async {
        try {
          await ref.read(chatsRepositoryProvider).markRead(widget.chatID);
        } catch (_) {}
      }());
    });

    // Дружба изменилась — пересчитать «только смайлики».
    ref.listen(friendsSnapshotProvider, (prev, next) {
      if (prev?.valueOrNull == next.valueOrNull) return;
      unawaited(_loadCapabilities());
    });

    final meID = ref.watch(authStateProvider).valueOrNull?.id;
    // Нужен watch: пункты меню «заявка» / «убрать из друзей» зависят от снимка.
    ref.watch(friendsSnapshotProvider);
    ref.watch(appLocaleProvider);
    final media = MediaQuery.of(context);
    final narrowLandscape =
        isNarrow(context) && media.size.width > media.size.height;
    final routeTitle = (widget.peerName ?? '').trim().isEmpty ? context.l10n.chatDialog : widget.peerName!.trim();
    final chats = ref.watch(chatsListProvider).valueOrNull ?? const <ChatPreviewItem>[];
    final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
    ChatPreviewItem? currentChat;
    ChatUserItem? peerUser;
    for (final item in chats) {
      if (item.chatID == widget.chatID) {
        currentChat = item;
        peerUser = item.user;
        break;
      }
    }
    final peerLang = (peerUser?.preferredLanguage ?? '').trim();
    if (peerLang.isNotEmpty && peerLang != _peerLanguageHint) {
      _peerLanguageHint = peerLang;
    }
    final title = _chatTitle(currentChat, routeTitle);
    final peerPresence =
        currentChat?.isGroup == true || peerUser == null ? null : presence[peerUser.id];

    if (narrowLandscape) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(mobileToolbarLeadingProvider.notifier).state =
            _buildChatToolbar(
          peerUser: peerUser,
          chat: currentChat,
          title: title,
          presence: peerPresence,
        );
      });
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
      final listView = _messages.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    context.l10n.chatEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              reverse: true,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              cacheExtent: 1200,
              itemCount: timeline.length + ((_loadingOlder || _hasMoreOlder) ? 1 : 0),
              itemBuilder: (context, index) {
                  final topLoaderVisible = _loadingOlder || _hasMoreOlder;
                  final itemCount = timeline.length + (topLoaderVisible ? 1 : 0);
                  if (topLoaderVisible && index == itemCount - 1) {
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

                  final timelineIndex = timeline.length - 1 - index;
                  final entry = timeline[timelineIndex];
                  final itemKey = entry.message?.id ?? 'h-${entry.headerLabel ?? index}';
                  if (entry.headerLabel != null) {
                    return Padding(
                      key: ValueKey(itemKey),
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                  final isEmoji = isAnimatedEmojiMessage(message.body);
                  final isGift = isGiftCollectionMessage(message.body);
                  final isCoinsCredit = isCoinsCreditMessage(message.body);
                  final inviteLink = parseInviteLobbyShareUrl(message.body);
                  if (inviteLink != null) {
                    return _wrapSwipeReply(
                      message: message,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14, top: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ChatInviteCard(
                              link: inviteLink,
                              messageId: message.id,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatBubbleDateTime(message.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                if (mine) ...[
                                  const SizedBox(width: 4),
                                  MessageStatusTicks(
                                    deliveredAt: message.deliveredAt,
                                    readAt: message.readAt,
                                    size: 14,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (isGift) {
                    return _wrapSwipeReply(
                      message: message,
                      alignment: mine
                          ? Alignment.centerRight
                          : (currentChat?.isGroup == true
                              ? Alignment.centerLeft
                              : Alignment.center),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14, top: 6),
                        child: _wrapGroupSender(
                          chat: currentChat,
                          mine: mine,
                          senderUserID: message.senderUserID,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_groupSenderName(
                                    chat: currentChat,
                                    mine: mine,
                                    senderUserID: message.senderUserID,
                                  ) !=
                                  null) ...[
                                Text(
                                  _groupSenderName(
                                    chat: currentChat,
                                    mine: mine,
                                    senderUserID: message.senderUserID,
                                  )!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              _ChatGiftCard(body: message.body),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatBubbleDateTime(message.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (mine) ...[
                                    const SizedBox(width: 4),
                                    MessageStatusTicks(
                                      deliveredAt: message.deliveredAt,
                                      readAt: message.readAt,
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (isCoinsCredit) {
                    return _wrapSwipeReply(
                      message: message,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14, top: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ChatCoinsCreditCard(
                              messageId: message.id,
                              body: message.body,
                            ),
                            const SizedBox(height: 6),
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
                    );
                  }
                  if (isEmoji) {
                    return _wrapSwipeReply(
                      message: message,
                      alignment: mine
                          ? Alignment.centerRight
                          : (currentChat?.isGroup == true
                              ? Alignment.centerLeft
                              : Alignment.center),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: _wrapGroupSender(
                          chat: currentChat,
                          mine: mine,
                          senderUserID: message.senderUserID,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_groupSenderName(
                                    chat: currentChat,
                                    mine: mine,
                                    senderUserID: message.senderUserID,
                                  ) !=
                                  null) ...[
                                Text(
                                  _groupSenderName(
                                    chat: currentChat,
                                    mine: mine,
                                    senderUserID: message.senderUserID,
                                  )!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              _ChatMessageBody(
                                body: message.body,
                                largeCentered: true,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatBubbleDateTime(message.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (mine) ...[
                                    const SizedBox(width: 4),
                                    MessageStatusTicks(
                                      deliveredAt: message.deliveredAt,
                                      readAt: message.readAt,
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return _wrapSwipeReply(
                    message: message,
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: _wrapGroupSender(
                      chat: currentChat,
                      mine: mine,
                      senderUserID: message.senderUserID,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppColors.accentSoft
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: mine
                                  ? AppColors.accentStart
                                      .withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                if (_groupSenderName(
                                      chat: currentChat,
                                      mine: mine,
                                      senderUserID: message.senderUserID,
                                    ) !=
                                    null) ...[
                                  Text(
                                    _groupSenderName(
                                      chat: currentChat,
                                      mine: mine,
                                      senderUserID: message.senderUserID,
                                    )!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                if (message.replyToMessageID != null) ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => unawaited(
                                        _jumpToMessage(message.replyToMessageID!),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.fromLTRB(
                                            8, 6, 8, 6),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: const Border(
                                            left: BorderSide(
                                              color: AppColors.accentStart,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          message.replyToHasImage
                                              ? (message.replyToBody
                                                          ?.trim()
                                                          .isNotEmpty ==
                                                      true
                                                  ? context.l10n.photoWithText(
                                                      formatChatMessagePreview(
                                                        message.replyToBody!,
                                                      ),
                                                    )
                                                  : context.l10n.photo)
                                              : (message.replyToBody
                                                          ?.trim()
                                                          .isNotEmpty ==
                                                      true
                                                  ? formatChatMessagePreview(
                                                      message.replyToBody!)
                                                  : context.l10n.chatMessageHint),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (message.hasImage) ...[
                                  Builder(
                                    builder: (context) {
                                      final count = message.imageCount > 0
                                          ? message.imageCount.clamp(1, 3)
                                          : 1;
                                      final side = count == 1
                                          ? 168.0
                                          : (count == 2 ? 128.0 : 88.0);
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (var i = 0; i < count; i++) ...[
                                            if (i > 0) const SizedBox(width: 4),
                                            ChatMessageImageThumb(
                                              messageID: message.id,
                                              imageIndex: i,
                                              width: side,
                                              height: side,
                                              borderRadius: 10,
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  if (message.body.trim().isNotEmpty)
                                    const SizedBox(height: 6),
                                ],
                                if (message.body.trim().isNotEmpty)
                                  _ChatMessageBody(
                                    body: _displayBodyFor(message, mine: mine),
                                  ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (message.editedAt != null &&
                                          message.editedAt!.isNotEmpty) ...[
                                        Text(
                                          context.l10n.messageEdited,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        _formatBubbleDateTime(message.createdAt),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (mine) ...[
                                        const SizedBox(width: 4),
                                        MessageStatusTicks(
                                          deliveredAt: message.deliveredAt,
                                          readAt: message.readAt,
                                          size: 14,
                                        ),
                                      ],
                                    ],
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
      // Без RefreshIndicator: у reverse-списка он цепляется за визуальный верх
      // и сбрасывает пагинацию при подгрузке старых сообщений.
      messagesWidget = listView;
    }

    final canSwipeBack = !(widget.inSplitView &&
            !widget.fromFriends &&
            !widget.fromGames) &&
        !_leavingToChats;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SwipeBackScope(
          enabled: canSwipeBack,
          onBack: _goBackToChats,
          // Композер слева (смайлик) не должен перекрываться edge-зоной свайпа.
          bottomInset: 72,
          child: Column(
            children: [
              if (!narrowLandscape)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: _buildChatToolbar(
                    peerUser: peerUser,
                    chat: currentChat,
                    title: title,
                    presence: peerPresence,
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    messagesWidget,
                    if (_showScrollToBottomButton && _messages.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Tooltip(
                            message: context.l10n.chatScrollToEnd,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _scrollToBottom,
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.borderAt(0.22),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_double_arrow_down_rounded,
                                      color: AppColors.accentStart,
                                      size: 28,
                                    ),
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
              if (_composerAlert != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    _composerAlert!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (_pasteSuggestionVisible && _pasteInviteUrl != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 12, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _applyPasteSuggestion,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderCycle.first,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.content_paste_rounded,
                                size: 18,
                                color: AppColors.accentStart,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.chatPaste,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_pendingImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _pendingImages.length; i++)
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _pendingImages[i].image == null
                                          ? null
                                          : () => _previewPendingImage(
                                                _pendingImages[i].image!,
                                              ),
                                      borderRadius: BorderRadius.circular(10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _pendingImages[i].image == null
                                            ? ColoredBox(
                                                color: const Color(0xFFE9E4F8),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color:
                                                          _composerIconPurple,
                                                      backgroundColor: Colors
                                                          .white
                                                          .withValues(
                                                        alpha: 0.85,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Image.memory(
                                                _pendingImages[i].image!.bytes,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _removePendingImage(i),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: _composerIconPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: (_sending ||
                              _editingMessage != null ||
                              _emojiOnly ||
                              _pendingImages.length >= _maxPendingImages)
                          ? null
                          : _pickPhoto,
                      tooltip: context.l10n.photo,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.image_outlined,
                        color: (_sending ||
                                _editingMessage != null ||
                                _emojiOnly ||
                                _pendingImages.length >= _maxPendingImages)
                            ? _composerIconPurple.withValues(alpha: 0.35)
                            : _composerIconPurple,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_replyTo != null || _editingMessage != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 8, 4, 0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: _composerIconPurple,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _editingMessage != null
                                                ? context.l10n.chatEditing
                                                : context.l10n.chatReplyingTo(_replyAuthorLabel(_replyTo!)),
                                            style: const TextStyle(
                                              color: _composerIconPurple,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            (_editingMessage ?? _replyTo)!
                                                .previewText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color:
                                                  AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _cancelComposerContext,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: _composerIconPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextField(
                              controller: _textController,
                              focusNode: _composerFocusNode,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              // Тема приложения рисует OutlineInputBorder —
                              // явно гасим все границы и заливку.
                              decoration: InputDecoration(
                                hintText: context.l10n.chatMessageHint,
                                filled: false,
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  4,
                                  12,
                                ),
                                suffixIcon: IconButton(
                                  onPressed:
                                      _sending ? null : _openEmojiPicker,
                                  tooltip: context.l10n.chatEmoji,
                                  splashRadius: 20,
                                  icon: const Icon(
                                    Icons.emoji_emotions_outlined,
                                    color: _composerIconPurple,
                                    size: 24,
                                  ),
                                ),
                                suffixIconConstraints:
                                    const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                              textInputAction: TextInputAction.send,
                              onTap: _scrollToBottom,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: (_sending ||
                              _pendingImages.any((e) => e.isLoading))
                          ? null
                          : _sendMessage,
                      tooltip: _editingMessage != null
                          ? context.l10n.commonSave
                          : context.l10n.commonSend,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _composerIconPurple,
                              ),
                            )
                          : Icon(
                              _editingMessage != null
                                  ? Icons.check_rounded
                                  : Icons.send_rounded,
                              color: _composerIconPurple,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _replyAuthorLabel(ChatMessageItem message) {
    final meID = ref.read(authStateProvider).valueOrNull?.id;
    if (meID != null && message.senderUserID == meID) {
      return context.l10n.chatReplySelf;
    }
    final name = (widget.peerName ?? '').trim();
    if (name.isNotEmpty) return name;
    return context.l10n.chatReplyPeer;
  }

  Future<void> _openEmojiPicker() async {
    _dismissPasteSuggestion();
    _composerFocusNode.unfocus();
    // Не invalidate: иначе на мобиле valueOrNull=null и панель «пустая».
    final cached = ref.read(inventoryListProvider).valueOrNull;
    if (cached == null) {
      unawaited(ref.read(inventoryListProvider.future).then((_) {}, onError: (_, __) {}));
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final items =
                ref.watch(inventoryListProvider).valueOrNull ?? cached ?? const [];
            final emojis = items
                .where((e) => e.kind == 'emoji' && e.quantity > 0)
                .toList();
            return _ChatEmojiPickerSheet(
              emojis: emojis,
              onPick: (it) {
                Navigator.of(sheetContext).pop();
                unawaited(_sendAnimatedEmoji(it));
              },
            );
          },
        );
      },
    );
  }
}

class _ChatEmojiPickerSheet extends StatefulWidget {
  const _ChatEmojiPickerSheet({
    required this.emojis,
    required this.onPick,
  });

  final List<InventoryItem> emojis;
  final ValueChanged<InventoryItem> onPick;

  @override
  State<_ChatEmojiPickerSheet> createState() => _ChatEmojiPickerSheetState();
}

class _ChatEmojiPickerSheetState extends State<_ChatEmojiPickerSheet> {
  static const _collapsedSize = 0.14;
  static const _expandedThreshold = 0.26;

  bool _expanded = false;

  Map<String, String> get _groupTitles {
    final l10n = LocaleService.l10n;
    return {
      'emotions': l10n.emojiGroupEmotions,
      'game': l10n.emojiGroupGame,
      'flags': l10n.emojiGroupFlags,
      'animals': l10n.emojiGroupAnimals,
      'food': l10n.emojiGroupFood,
      'travel': l10n.emojiGroupTravel,
      'party': l10n.emojiGroupParty,
      'objects': l10n.emojiGroupObjects,
    };
  }

  Widget _emojiTile(
    InventoryItem it, {
    required double emojiSize,
    required double qtySize,
  }) {
    return InkWell(
      onTap: () => widget.onPick(it),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShopAnimatedEmoji(
              animatedName: it.animatedName ?? 'smile',
              size: emojiSize,
              fallback: it.emoji,
            ),
            Text(
              '${it.quantity}',
              style: TextStyle(
                fontSize: qtySize,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final preferredFlagIso =
        preferredFlagIsoForLocale(LocaleService.locale);
    final emojis = List<InventoryItem>.from(widget.emojis);
    preferFlagIsoFirstInMixedList<InventoryItem>(
      emojis,
      preferredIso: preferredFlagIso,
      isFlag: (e) => (e.group ?? '') == 'flags',
      codeOf: (e) => e.code,
      animatedNameOf: (e) => e.animatedName,
    );
    final grouped = <String, List<InventoryItem>>{};
    for (final e in emojis) {
      grouped.putIfAbsent(e.group ?? 'other', () => []).add(e);
    }
    const known = [
      'emotions',
      'game',
      'flags',
      'animals',
      'food',
      'travel',
      'party',
      'objects',
    ];
    final groupOrder = [
      ...known.where(grouped.containsKey),
      ...grouped.keys.where((k) => !known.contains(k)),
    ];

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        final next = n.extent >= _expandedThreshold;
        if (next != _expanded) {
          setState(() => _expanded = next);
        }
        return false;
      },
      child: DraggableScrollableSheet(
        expand: false,
        snap: true,
        snapSizes: const [_collapsedSize, 0.55],
        initialChildSize: _collapsedSize,
        minChildSize: _collapsedSize,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                if (widget.emojis.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.chatBuyEmojiHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (!_expanded)
                  // Одна горизонтальная полоса, без названий групп.
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: emojis.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 2),
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 58,
                              child: _emojiTile(
                                emojis[index],
                                emojiSize: 42,
                                qtySize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 12 + bottom),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final key = groupOrder[index];
                          final items = grouped[key]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                                  child: Text(
                                    _groupTitles[key] ?? context.l10n.chatEmoji,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cols = (constraints.maxWidth / 68)
                                        .floor()
                                        .clamp(4, 8);
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: items.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 2,
                                        childAspectRatio: 0.82,
                                      ),
                                      itemBuilder: (context, i) {
                                        return _emojiTile(
                                          items[i],
                                          emojiSize: 48,
                                          qtySize: 12,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: groupOrder.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatInviteCard extends ConsumerWidget {
  const _ChatInviteCard({
    required this.link,
    required this.messageId,
  });

  final InviteLobbyLink link;
  final String messageId;

  Future<void> _acceptAndGo(BuildContext context, WidgetRef ref) async {
    final lobbyId = link.lobbyId.trim();
    if (lobbyId.isEmpty) {
      context.go(link.appPathFromMessage(messageId));
      return;
    }
    try {
      final result =
          await ref.read(gamesRepositoryProvider).joinLobby(lobbyId);
      if (!context.mounted) return;
      ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
      if (result.joined && result.waitingMore) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        return;
      }
      if (result.joined && result.gameId != null) {
        context.go('/games/tictactoe/game/${result.gameId}');
        return;
      }
      context.go(link.appPathFromMessage(messageId));
    } catch (_) {
      if (context.mounted) {
        context.go(link.appPathFromMessage(messageId));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // Сразу join + редирект в лобби (не оставляем «Войти в игру» вручную).
          onTap: () => unawaited(_acceptAndGo(context, ref)),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentStart.withValues(alpha: 0.35),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceCard,
                  AppColors.accentSoft.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accentStart, AppColors.accentEnd],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.grid_3x3_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.lobbyInviteTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.gamesTicTacToe,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentStart.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 20,
                        color: AppColors.accentStart,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.lobbyEnterGame,
                        style: const TextStyle(
                          color: AppColors.accentStart,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatCoinsCreditCard extends ConsumerStatefulWidget {
  const _ChatCoinsCreditCard({
    required this.messageId,
    required this.body,
  });

  final String messageId;
  final String body;

  @override
  ConsumerState<_ChatCoinsCreditCard> createState() =>
      _ChatCoinsCreditCardState();
}

class _ChatCoinsCreditCardState extends ConsumerState<_ChatCoinsCreditCard> {
  final GlobalKey _claimKey = GlobalKey();
  bool _claiming = false;
  bool? _claimedOverride;

  @override
  void didUpdateWidget(covariant _ChatCoinsCreditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      _claimedOverride = null;
    }
  }

  Future<void> _claim(CoinsCreditPayload credit) async {
    if (_claiming || credit.claimed || (_claimedOverride ?? false)) return;
    setState(() => _claiming = true);
    try {
      final fromBalance =
          ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
      final result =
          await ref.read(authRepositoryProvider).claimAdminGrant(credit.grantId);
      if (!mounted) return;
      setState(() => _claimedOverride = true);
      if (result.rewardBronze > 0) {
        await playBalanceGain(
          ref: ref,
          context: context,
          newBalanceBronze: result.balanceBronze,
          fromBronze: fromBalance,
          rewardBronze: result.rewardBronze,
          sourceKey: _claimKey,
        );
      } else {
        await ref
            .read(authStateProvider.notifier)
            .applyBalance(result.balanceBronze);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: formatUserError(e, fallback: context.l10n.commonGenericError),
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = parseCoinsCreditMessage(widget.body);
    if (credit == null) {
      return _ChatMessageBody(body: widget.body, largeCentered: true);
    }
    final claimed = _claimedOverride ?? credit.claimed;
    final l10n = context.l10n;
    final reason = credit.reason.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentStart.withValues(alpha: 0.35),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceCard,
                AppColors.accentSoft.withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentStart, AppColors.accentEnd],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.coinsCreditCardTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reason,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (claimed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentStart.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.accentStart.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.coinsAlreadyClaimed,
                        style: TextStyle(
                          color: AppColors.accentStart.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                FilledButton(
                  key: _claimKey,
                  onPressed: _claiming ? null : () => _claim(credit),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _claiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.coinsClaim,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: BalanceDisplay(
                                bronze: credit.amountBronze,
                                coinSize: 18,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                spacing: 5,
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatGiftCard extends StatelessWidget {
  const _ChatGiftCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final gift = parseGiftCollectionMessage(body);
    if (gift == null) {
      return _ChatMessageBody(body: body, largeCentered: true);
    }
    final title = catalogTitle(
      gift.code,
      fallback: gift.title.isNotEmpty
          ? gift.title
          : LocaleService.l10n.chatCollection,
    );
    final name =
        gift.animatedName.isNotEmpty ? gift.animatedName : 'sparkles';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showCollectionFullscreen(
            context,
            title: title,
            animatedName: name,
            fallback: gift.emoji.isNotEmpty ? gift.emoji : null,
            subtitle: LocaleService.l10n.chatGiftCollection,
          ),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentStart.withValues(alpha: 0.35),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceCard,
                  AppColors.accentSoft.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        size: 15,
                        color: AppColors.accentStart,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LocaleService.l10n.chatGift,
                        style: const TextStyle(
                          color: AppColors.accentStart,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentStart.withValues(alpha: 0.12),
                    ),
                  ),
                  child: ShopAnimatedEmoji(
                    animatedName: name,
                    size: 112,
                    fallback: gift.emoji.isNotEmpty ? gift.emoji : null,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleService.l10n.inventoryTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBody extends StatelessWidget {
  const _ChatMessageBody({
    required this.body,
    this.largeCentered = false,
  });

  final String body;
  final bool largeCentered;

  @override
  Widget build(BuildContext context) {
    final gift = parseGiftCollectionMessage(body);
    if (gift != null) {
      // Запасной путь — основная отрисовка через [_ChatGiftCard].
      return _ChatGiftCard(body: body);
    }
    if (isCoinsCreditMessage(body)) {
      return _ChatCoinsCreditCard(messageId: '', body: body);
    }
    final name = parseAnimatedEmojiName(body);
    if (name != null) {
      return ShopAnimatedEmoji(
        animatedName: name,
        size: largeCentered ? 168 : 56,
        fallback: formatChatMessagePreview(body),
        animate: true,
      );
    }
    if (!animatedEmojiTokenAnywhereRe.hasMatch(body)) {
      return Text(
        body,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      );
    }
    // В тексте есть `[ae:…]` — рисуем смайлики inline, не сырой код.
    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in animatedEmojiTokenAnywhereRe.allMatches(body)) {
      if (m.start > start) {
        spans.add(TextSpan(text: body.substring(start, m.start)));
      }
      final tokenName = m.group(1) ?? '';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: ShopAnimatedEmoji(
              animatedName: tokenName,
              size: 22,
              fallback: unicodeEmojiFromAnimatedName(tokenName) ?? '🙂',
              animate: true,
            ),
          ),
        ),
      );
      start = m.end;
    }
    if (start < body.length) {
      spans.add(TextSpan(text: body.substring(start)));
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        children: spans,
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

/// Слот превью вложения: сначала лоадер, затем готовое фото.
class _PendingImageEntry {
  const _PendingImageEntry.loading(this.id) : image = null;
  const _PendingImageEntry.ready(this.id, this.image);

  final String id;
  final PickedChatImage? image;

  bool get isLoading => image == null;
}
