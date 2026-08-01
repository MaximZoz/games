import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/lobby_game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';

class TicTacToeLobbyScreen extends ConsumerStatefulWidget {
  const TicTacToeLobbyScreen({
    super.key,
    required this.lobbyId,
    this.initialMode,
    this.fromMessageId,
  });

  final String lobbyId;
  final String? initialMode;

  /// Если открыли «Свою игру» из сообщения в чате — удалить его после входа.
  final String? fromMessageId;

  @override
  ConsumerState<TicTacToeLobbyScreen> createState() =>
      _TicTacToeLobbyScreenState();
}

/// Заголовок AppBar экрана лобби.
///
/// Пока деталь лобби не загружена, опираемся на [initialMode] из query
/// (`?mode=invite|matchmake`), чтобы не показывать «Лобби» для своей игры.
/// Ссылки из чата ([fromInviteLink]) — не «Своя игра»: это вход гостя.
String tictactoeLobbyAppBarTitle({
  String? status,
  String? initialMode,
  bool fromInviteLink = false,
}) {
  final l10n = LocaleService.l10n;
  if (status == 'waiting_matchmake') return l10n.lobbyMatchmake;
  if (status == 'waiting_invite') {
    return fromInviteLink ? l10n.lobbyEnterGame : l10n.lobbyPrivateGame;
  }
  if (fromInviteLink) return l10n.lobbyEnterGame;
  if (initialMode == 'matchmake') return l10n.lobbyMatchmake;
  if (initialMode == 'invite') return l10n.lobbyPrivateGame;
  return '';
}

const List<IconData> _presetAvatarIcons = [
  Icons.face_rounded,
  Icons.face_2_rounded,
  Icons.face_3_rounded,
  Icons.face_4_rounded,
  Icons.face_5_rounded,
  Icons.face_6_rounded,
  Icons.man_rounded,
  Icons.woman_rounded,
  Icons.person_rounded,
];

class _TicTacToeLobbyScreenState extends ConsumerState<TicTacToeLobbyScreen> {
  final Set<String> _invitedFriendIds = {};
  final Set<String> _invitingFriendIds = {};
  bool _isLeaving = false;
  bool _isJoining = false;
  bool _linkCopied = false;
  bool _missingLobbyHandled = false;
  Timer? _chatsRefreshTimer;
  Timer? _linkCopiedTimer;

  @override
  void initState() {
    super.initState();
    // Не инвалидируем lobbyDetail здесь: invalidate → loading без данных →
    // мигание всего экрана при каждом remount (таб «Игры», query без mode).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Deep-link / push: пользователь уже открыл лобби — убрать карточку
      // «Вас пригласили» и бейдж в табе «Игры».
      ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
      ref.invalidate(openLobbiesProvider);
      refreshChatsList(ref, force: true).catchError((_) {});
    });
    _chatsRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
  }

  @override
  void dispose() {
    _chatsRefreshTimer?.cancel();
    _linkCopiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(lobbyDetailProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return LobbyGameNavigationWatcher(
      lobbyId: widget.lobbyId,
      onRealtimeEvent: (event) {
        final type = event['type']?.toString();
        if (type == 'chat_message' || type == 'chat_list_changed') {
          refreshChatsList(ref, force: true).catchError((_) {});
        }
      },
      child: SwipeBackScope(
        enabled: !_isLeaving,
        onBack: () => _confirmLeaveLobby(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              tooltip: context.l10n.commonBack,
              onPressed: _isLeaving ? null : () => _confirmLeaveLobby(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              tictactoeLobbyAppBarTitle(
                status: lobbyAsync.valueOrNull?.status,
                initialMode: widget.initialMode,
                fromInviteLink: widget.fromMessageId?.trim().isNotEmpty ==
                        true ||
                    (lobbyAsync.valueOrNull != null &&
                        currentUser != null &&
                        lobbyAsync.valueOrNull!.creatorId != currentUser.id),
              ),
            ),
            // Иконка правил — в AppBar, на одной высоте со стрелкой «Назад».
            actions: [
              if (() {
                    final lobby = lobbyAsync.valueOrNull;
                    return lobby != null &&
                        lobby.status == 'waiting_invite' &&
                        currentUser?.id == lobby.creatorId;
                  }())
                IconButton(
                  tooltip: context.l10n.gamesRulesTitle,
                  icon: const Icon(Icons.rule_rounded),
                  onPressed: () {
                    final lobby = lobbyAsync.valueOrNull;
                    if (lobby != null) _showRules(context, lobby);
                  },
                ),
            ],
          ),
          body: lobbyAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (lobby) {
            final isCreator = currentUser?.id == lobby.creatorId;
            final isInviteMode = lobby.status == 'waiting_invite';
            final isMatchmakeMode = lobby.status == 'waiting_matchmake';
            if (lobby.gameId != null) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentStart,
                ),
              );
            }

            final isDesktop = isWide(context);
            final pad = isDesktop ? 32.0 : 24.0;
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 480 : double.infinity,
                  ),
                  // Весь экран НЕ листается: помещается в размер экрана.
                  // Скроллится только список друзей внутри карточки (Expanded).
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lobby.stakeBronze > 0 && !isInviteMode) ...[
                          _LobbyStakeChip(stakeBronze: lobby.stakeBronze),
                          const SizedBox(height: 16),
                        ],
                        if (isInviteMode && isCreator) ...[
                          // Заголовок «Своя игра» + иконка правил справа.
                          _buildInviteHeaderRow(context),
                          const SizedBox(height: 12),
                          // Ссылка — максимально высоко.
                          _buildShareInviteLinkCard(context),
                          const SizedBox(height: 12),
                          // Друзья — растягиваются на оставшееся место.
                          Expanded(
                            child: _buildFriendsCard(context, friendsAsync),
                          ),
                        ] else ...[
                          // Не invite-режим creator'а: матчмейкинг или гость.
                          Expanded(
                            child: GradientCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  if (isMatchmakeMode) ...[
                                    const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accentStart,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.l10n.lobbySearchingOpponent,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.l10n.lobbyWaitingJoin,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ] else if (isInviteMode && !isCreator) ...[
                                    Text(
                                      context.l10n.lobbyInviteTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      lobby.creatorName.trim().isNotEmpty
                                          ? context.l10n
                                              .lobbyCreatorInvites(lobby.creatorName)
                                          : context.l10n.lobbyInvitedToPlay,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      buildTictactoeRulesText(
                                        gridSize: lobby.gridSize,
                                        turnTimeSec: lobby.turnTimeSec,
                                        swapRule: lobby.swapRule,
                                        firstMoveRestriction:
                                            lobby.firstMoveRestriction,
                                        stakeBronze: lobby.stakeBronze,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: _isJoining
                                          ? null
                                          : () => _joinViaLink(context),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.accentStart,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(48),
                                      ),
                                      child: _isJoining
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(context.l10n.lobbyEnterGame),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
          error: (error, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleLobbyMissing(error);
            });
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentStart,
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  /// Ссылка на лобби устарела / лобби закрыто — уведомление, без «Своя игра».
  void _handleLobbyMissing(Object error) {
    if (!mounted || _missingLobbyHandled || _isLeaving) return;
    _missingLobbyHandled = true;
    final fromChat = widget.fromMessageId?.trim().isNotEmpty == true;
    final isGone = error is GamesException &&
        (error.statusCode == 404 ||
            error.statusCode == 409 ||
            error.statusCode == 400);
    final message = isGone
        ? context.l10n.lobbyGone
        : formatUserError(error, fallback: context.l10n.lobbyGone);
    showAppSnackBar(
      context,
      message: message,
      kind: AppSnackKind.error,
    );
    if (isGone) {
      unawaited(_deleteGoneInviteMessage());
    }
    // Не clearLocal/leaveLobby: у пользователя может быть своё другое лобби.
    context.go(fromChat ? '/chats' : '/games');
  }

  /// Убрать карточку «Войти в игру», если сервер сказал, что лобби уже нет.
  Future<void> _deleteGoneInviteMessage() async {
    final messageId = widget.fromMessageId?.trim();
    if (messageId != null && messageId.isNotEmpty) {
      try {
        await ref.read(chatsRepositoryProvider).deleteMessage(messageId);
      } catch (_) {}
    }
    await refreshChatsList(ref, force: true).catchError((_) {});
  }

  /// Заголовок «Своя игра» (иконка правил — в AppBar, на уровне крестика).
  Widget _buildInviteHeaderRow(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Своя игра',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Общая всплывашка с правилами (как в экране игры).
  void _showRules(BuildContext context, LobbyItem lobby) {
    final rulesText = buildTictactoeRulesText(
      gridSize: lobby.gridSize,
      turnTimeSec: lobby.turnTimeSec,
      swapRule: lobby.swapRule,
      firstMoveRestriction: lobby.firstMoveRestriction,
      // В «Своя игра» ставок нет — не показываем строку ставки в правилах.
      stakeBronze: 0,
    );
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 14,
          vertical: isDesktop ? 40 : 20,
        ),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 380 : double.infinity,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.gamesRulesTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.commonClose,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      rulesText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
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
  }

  /// Карточка друзей: список листается ВНУТРИ неё (Expanded в родителе),
  /// сама карточка занимает всё оставшееся место.
  Widget _buildFriendsCard(
    BuildContext context,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: friendsAsync.when(
        data: (snapshot) {
          final friends = snapshot.friends;
          final presence =
              ref.watch(presenceMapProvider).valueOrNull ?? const {};
          final visibleFriends = List.of(friends)
            ..sort((a, b) {
              final aOnline = presence[a.user.id]?.online ?? false;
              final bOnline = presence[b.user.id]?.online ?? false;
              if (aOnline == bOnline) return 0;
              return aOnline ? -1 : 1;
            });
          if (visibleFriends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.friendsEmpty,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            shrinkWrap: true,
            itemCount: visibleFriends.length,
            itemBuilder: (context, i) {
              final f = visibleFriends[i];
              final friendId = f.user.id;
              final isInvited = _invitedFriendIds.contains(friendId);
              final isInviting = _invitingFriendIds.contains(friendId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Tooltip(
                      message: context.l10n.userInfoTitle,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showFriendInfo(context, f),
                          behavior: HitTestBehavior.opaque,
                          child: _buildFriendAvatar(f.user, 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.user.displayName?.trim().isNotEmpty == true
                            ? f.user.displayName!
                            : context.l10n.commonUser,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isInviting || isInvited
                          ? null
                          : () => _inviteFriend(context, friendId),
                      icon: isInviting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentStart,
                              ),
                            )
                          : Icon(
                              isInvited
                                  ? Icons.check_rounded
                                  : Icons.person_add_alt_rounded,
                              size: 18,
                            ),
                      label: Text(
                        isInvited
                            ? context.l10n.lobbyInviteSentShort
                            : context.l10n.lobbyInvite,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentStart,
                        side: BorderSide(
                          color: AppColors.accentStart.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${context.l10n.friendsLoadFailed}. ${formatUserError(e, fallback: context.l10n.commonTryLater)}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareInviteLinkCard(BuildContext context) {
    return GradientCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copyInviteLink,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Левая «скрепка»/link — всегда без изменений.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: AppColors.accentStart,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _linkCopied
                            ? context.l10n.lobbyLinkCopied
                            : context.l10n.lobbyCopyLink,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _linkCopied
                            ? context.l10n.lobbyLinkCopiedHint
                            : context.l10n.lobbyCopyLinkHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _linkCopied ? Icons.check_rounded : Icons.copy_rounded,
                  color: AppColors.accentStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyInviteLink() async {
    final url = buildInviteLobbyShareUrl(
      lobbyId: widget.lobbyId,
      baseUri: Uri.base,
    );
    await Clipboard.setData(ClipboardData(text: url));
    // Чтобы в чате сразу показать «Вставить» без чтения буфера (Safari).
    ref.read(pendingInvitePasteProvider.notifier).state = url;
    if (!mounted) return;
    setState(() => _linkCopied = true);
    _linkCopiedTimer?.cancel();
    _linkCopiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  Future<void> _joinViaLink(BuildContext context) async {
    setState(() => _isJoining = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(widget.lobbyId);
      if (!context.mounted) return;
      if (result.joined && result.gameId != null) {
        ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
        ref.invalidate(lobbyDetailProvider(widget.lobbyId));
        ref.invalidate(activeGameProvider);

        final messageId = widget.fromMessageId?.trim();
        if (messageId != null && messageId.isNotEmpty) {
          try {
            await ref.read(chatsRepositoryProvider).deleteMessage(messageId);
            await refreshChatsList(ref, force: true);
          } catch (_) {
            // Вход в игру важнее удаления сообщения.
          }
        }

        if (!context.mounted) return;
        // Закрыть «Свою игру» и сразу открыть матч (go затирает лобби в истории).
        context.go('/games/tictactoe/game/${result.gameId}');
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      final gone = e is GamesException &&
          (e.statusCode == 404 || e.statusCode == 409 || e.statusCode == 400);
      showAppSnackBar(
        context,
        message: gone
            ? context.l10n.lobbyGone
            : formatUserError(e, fallback: context.l10n.lobbyGone),
        kind: AppSnackKind.error,
      );
      if (gone) {
        await _deleteGoneInviteMessage();
        if (!context.mounted) return;
        final fromChat = widget.fromMessageId?.trim().isNotEmpty == true;
        context.go(fromChat ? '/chats' : '/games');
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _inviteFriend(BuildContext context, String friendUserId) async {
    setState(() => _invitingFriendIds.add(friendUserId));
    try {
      final repo = ref.read(gamesRepositoryProvider);
      await repo.inviteToLobby(widget.lobbyId, friendUserId);
      if (context.mounted) {
        // Без всплывашки: визуальный отклик — кнопка превращается в «Отправлено»
        // с галочкой (через _invitedFriendIds).
        setState(() {
          _invitedFriendIds.add(friendUserId);
          _invitingFriendIds.remove(friendUserId);
        });
      }
    } catch (e) {
      if (context.mounted) context.go('/games');
    } finally {
      if (mounted) {
        setState(() => _invitingFriendIds.remove(friendUserId));
      }
    }
  }

  Future<void> _confirmLeaveLobby(BuildContext context) async {
    if (_isLeaving) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Покинуть лобби?'),
        content: const Text(
          'Лобби будет удалено после выхода. Приглашённые друзья получат отказ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      _leaveLobby(context);
    }
  }

  void _leaveLobby(BuildContext context) {
    if (_isLeaving) return;
    _isLeaving = true;

    final lobbyId = widget.lobbyId;
    final repo = ref.read(gamesRepositoryProvider);
    final fromChat = widget.fromMessageId?.trim().isNotEmpty == true;

    // Сразу уходим с экрана — не ждём сеть и не трогаем lobbyDetail
    // (invalidate после leave давал AsyncError → спиннер → мигание карточек).
    ref.read(activeGameProvider.notifier).clearLocal();
    ref.invalidate(openLobbiesProvider);
    // Из сообщения чата — обратно к списку чатов, иначе к играм.
    context.go(fromChat ? '/chats' : '/games');

    unawaited(() async {
      try {
        await repo.leaveLobby(lobbyId);
      } catch (_) {
        // Лобби могли уже закрыть — сервер всё равно чистит invite-сообщения.
      }
      await refreshChatsList(ref, force: true).catchError((_) {});
    }());
  }

  Widget _buildFriendAvatar(FriendUserItem user, double radius) {
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(user.avatarValue!);
      if (img != null) {
        return CircleAvatar(radius: radius, backgroundImage: img);
      }
    }
    if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final idx = int.tryParse(user.avatarValue!);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      }
    }
    final displayName = user.displayName?.trim() ?? '';
    final letter = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.accentStart,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFriendInfo(BuildContext context, FriendItem friend) {
    final user = friend.user;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Consumer(
              builder: (context, ref, _) {
                final presence =
                    ref.watch(presenceMapProvider).valueOrNull ?? const {};
                final presenceEntry = presence[user.id];
                final statusText = presenceEntry == null
                    ? null
                    : (presenceEntry.online
                        ? context.l10n.commonOnlineCap
                        : formatLastSeen(presenceEntry.lastSeenAt));
                final about = user.about?.trim();
                final genderIcon = _genderIcon(user.gender);
                final female = _isFemaleGender(user.gender);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFriendAvatar(user, 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.displayName?.trim().isNotEmpty == true
                                      ? user.displayName!
                                      : context.l10n.commonUser,
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
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      if ((user.age != null && user.age! > 0) ||
                          genderIcon != null) ...[
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
                                backgroundColor: female
                                    ? const Color(0xFFFCE7F3)
                                    : AppColors.accentSoft,
                                foregroundColor: female
                                    ? const Color(0xFFBE185D)
                                    : AppColors.textPrimary,
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
                );
              },
            ),
          ),
        ),
      ),
    );
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
      child: icon != null
          ? Icon(icon, size: 16, color: fg)
          : Text(
              text ?? '',
              style: TextStyle(fontSize: 13, color: fg),
            ),
    );
  }
}

/// Ставка лобби: сумма + иконка монеты (как на карточке игры).
class _LobbyStakeChip extends StatelessWidget {
  const _LobbyStakeChip({required this.stakeBronze});

  final int stakeBronze;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.accentSoft.withValues(alpha: 0.9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.shopStakes,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatStakeAmount(stakeBronze),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            CoinIcon(
              coinType: stakeCoinType(stakeBronze),
              size: 22,
              showBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}
