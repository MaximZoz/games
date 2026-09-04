import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/lobby_game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
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
/// Открытый multi-поиск: status=waiting_invite + mode=matchmake → «Лобби».
String tictactoeLobbyAppBarTitle({
  String? status,
  String? initialMode,
  String? lobbyMode,
  bool fromInviteLink = false,
  bool isLobbyMember = false,
}) {
  final l10n = LocaleService.l10n;
  final mode = (lobbyMode != null && lobbyMode.trim().isNotEmpty)
      ? lobbyMode.trim()
      : (initialMode ?? '');
  if (status == 'waiting_matchmake') return l10n.lobbyMatchmake;
  if (status == 'waiting_invite') {
    // «Найти игру» (открытый поиск) — Лобби, не «Своя игра».
    if (mode == 'matchmake') return l10n.lobbyMatchmake;
    // Уже в составе — «Своя игра», а не «Войти в игру».
    if (isLobbyMember || !fromInviteLink) return l10n.lobbyPrivateGame;
    return l10n.lobbyEnterGame;
  }
  if (fromInviteLink && !isLobbyMember) return l10n.lobbyEnterGame;
  if (mode == 'matchmake') return l10n.lobbyMatchmake;
  if (mode == 'invite') return l10n.lobbyPrivateGame;
  return '';
}

/// Иконка крестиков-ноликов в AppBar лобби / своей игры.
const IconData tictactoeLobbyAppBarIcon = Icons.grid_3x3_rounded;

class _TicTacToeLobbyScreenState extends ConsumerState<TicTacToeLobbyScreen> {
  /// Приглашение отправлено — кнопка «Отмена».
  final Set<String> _invitedFriendIds = {};
  /// Друг отказался — кнопка «Отправлено» disabled.
  final Set<String> _declinedFriendIds = {};
  final Set<String> _invitingFriendIds = {};
  final Set<String> _cancellingFriendIds = {};
  final Set<String> _friendRequestInFlight = {};
  bool _isLeaving = false;
  bool _isJoining = false;
  bool _linkCopied = false;
  bool _missingLobbyHandled = false;
  bool _startingSearch = false;
  Timer? _chatsRefreshTimer;
  Timer? _linkCopiedTimer;

  /// Открыть свою игру для поиска: лобби становится публичным.
  Future<void> _startSearch() async {
    if (_startingSearch) return;
    setState(() => _startingSearch = true);
    try {
      await ref
          .read(gamesRepositoryProvider)
          .startLobbyMatchmake(widget.lobbyId);
      if (!mounted) return;
      ref.invalidate(lobbyDetailProvider(widget.lobbyId));
      ref.invalidate(openLobbiesProvider);
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _startingSearch = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Не инвалидируем lobbyDetail здесь: invalidate → loading без данных →
    // мигание всего экрана при каждом remount (таб «Игры», query без mode).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Deep-link / чат: если уже в другой партии — всплывашка и назад.
      if (await blockJoinIfBusyAsync(
        context,
        ref,
        targetLobbyId: widget.lobbyId,
        redirectToActive: true,
      )) {
        return;
      }
      if (!mounted) return;
      // Deep-link / push: пользователь уже открыл лобби — убрать карточку
      // «Вас пригласили» и бейдж в табе «Игры».
      ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
      ref.invalidate(openLobbiesProvider);
      refreshChatsList(ref, force: true).catchError((_) {});
    });
    // Редко: основной апдейт — по WS (chat_message / lobby_updated).
    _chatsRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
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
        // lobby_updated меняет состав — чаты не трогаем (badge обновится по chat_*).
        if (type == 'chat_message' || type == 'chat_list_changed') {
          refreshChatsList(ref, force: true).catchError((_) {});
        }
        if (type == 'invite_declined') {
          final lobbyId = event['lobby_id']?.toString() ?? '';
          final userId = event['user_id']?.toString() ?? '';
          if (lobbyId == widget.lobbyId && userId.isNotEmpty && mounted) {
            setState(() {
              _invitedFriendIds.remove(userId);
              _declinedFriendIds.add(userId);
            });
          }
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
            title: Builder(
              builder: (context) {
                final lobby = lobbyAsync.valueOrNull;
                final uid = currentUser?.id;
                final member = lobby != null &&
                    uid != null &&
                    (uid == lobby.creatorId ||
                        lobby.playerIds.contains(uid) ||
                        lobby.players.any((p) => p.id == uid) ||
                        lobby.opponentId == uid);
                final title = tictactoeLobbyAppBarTitle(
                  status: lobby?.status,
                  initialMode: widget.initialMode,
                  lobbyMode: lobby?.mode,
                  fromInviteLink: widget.fromMessageId?.trim().isNotEmpty ==
                          true ||
                      (lobby != null &&
                          currentUser != null &&
                          lobby.creatorId != currentUser.id &&
                          lobby.mode != 'matchmake'),
                  isLobbyMember: member,
                );
                if (title.isEmpty) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tictactoeLobbyAppBarIcon,
                      size: 22,
                      color: AppColors.accentStart,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
            // Поиск и правила — в AppBar, на одной высоте со стрелкой «Назад».
            actions: [
              if (() {
                final lobby = lobbyAsync.valueOrNull;
                if (lobby == null) return false;
                final uid = currentUser?.id;
                if (uid == null) return false;
                final member = uid == lobby.creatorId ||
                    lobby.playerIds.contains(uid) ||
                    lobby.players.any((p) => p.id == uid);
                if (!member) return false;
                return lobby.status == 'waiting_invite' ||
                    lobby.status == 'waiting_matchmake';
              }())
                LobbySearchAction(
                  searching: () {
                    final lobby = lobbyAsync.valueOrNull;
                    if (lobby == null) return false;
                    return lobby.status == 'waiting_matchmake' ||
                        lobby.mode == 'matchmake';
                  }(),
                  busy: _startingSearch,
                  onStart: () => unawaited(_startSearch()),
                ),
              if (() {
                final lobby = lobbyAsync.valueOrNull;
                if (lobby == null) return false;
                final uid = currentUser?.id;
                if (uid == null) return false;
                final member = uid == lobby.creatorId ||
                    lobby.playerIds.contains(uid) ||
                    lobby.players.any((p) => p.id == uid);
                if (!member) return false;
                // Открытый поиск / своя игра — правила в AppBar у всех участников.
                return lobby.status == 'waiting_invite' ||
                    lobby.status == 'waiting_matchmake';
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
              final uid = currentUser?.id;
              final isCreator = uid != null && uid == lobby.creatorId;
              final isLobbyMember = uid != null &&
                  (isCreator ||
                      lobby.playerIds.contains(uid) ||
                      lobby.players.any((p) => p.id == uid) ||
                      lobby.opponentId == uid);
              final isInviteMode = lobby.status == 'waiting_invite';
              final isMatchmakeMode = lobby.status == 'waiting_matchmake';
              // Открытый поиск (1v1 matchmake или multi «Найти игру»).
              final isOpenFind = isMatchmakeMode ||
                  (isInviteMode && lobby.mode == 'matchmake');
              final showMultiLobby = lobby.maxPlayers > 2;
              // Уже вступили (реванш / повторный заход) — не показываем «Войти в игру».
              final showInviteAccept = !isLobbyMember &&
                  (isInviteMode || isMatchmakeMode);
              final showPrivateInviteWaiting =
                  isInviteMode && isLobbyMember && !isOpenFind;
              final showOpenFindWaiting = isOpenFind && isLobbyMember;
              final lobbyMemberIds = <String>{
                ...lobby.playerIds,
                ...lobby.players.map((p) => p.id),
                if (lobby.creatorId.trim().isNotEmpty) lobby.creatorId,
                if ((lobby.opponentId ?? '').trim().isNotEmpty)
                  lobby.opponentId!.trim(),
              };
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
              final friendCount = friendsAsync.valueOrNull?.friends
                      .where((f) => !lobbyMemberIds.contains(f.user.id))
                      .length ??
                  0;

              // Своя игра / multi-поиск — тот же скелет, что у Дурака.
              if (showPrivateInviteWaiting ||
                  (showOpenFindWaiting && showMultiLobby)) {
                return GameLobbyWaitingLayout(
                  maxPlayers: lobby.maxPlayers,
                  stakeBronze: lobby.stakeBronze,
                  stakeLabel: context.l10n.shopStakes,
                  friendsCount: friendCount,
                  padding: EdgeInsets.all(pad),
                  maxWidth: isDesktop ? 480 : 480,
                  multiPlayersCard: showMultiLobby
                      ? _buildMultiLobbyCard(lobby)
                      : null,
                  shareLinkCard: _buildShareInviteLinkCard(context),
                  friendsCardBuilder: (expand) => LobbyFriendsInviteCard(
                    pendingInvites: lobby.invited,
                    friendsAsync: friendsAsync,
                    excludeUserIds: lobbyMemberIds,
                    invitedIds: {
                      ..._invitedFriendIds,
                      for (final guest in lobby.invited) guest.id,
                    },
                    invitingIds: _invitingFriendIds,
                    cancellingIds: _cancellingFriendIds,
                    declinedIds: _declinedFriendIds,
                    listStorageKey: 'lobby-friends-invite',
                    expand: expand,
                    onInvite: (id) => _inviteFriend(context, id),
                    onCancel: (id) =>
                        unawaited(_cancelInviteFriend(context, id)),
                    onFriendTap: (friend) => _showFriendInfo(context, friend),
                    profileReturnPath:
                        '/games/tictactoe/lobby/${widget.lobbyId}?mode=invite',
                  ),
                );
              }

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 480 : double.infinity,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(pad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showOpenFindWaiting) ...[
                            LobbySearchBanner(
                              label: context.l10n.lobbySearchingOpponent,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: GradientCard(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      context.l10n.lobbySearchingOpponent,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildMatchmakeInfoCard(context, lobby),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (showInviteAccept) ...[
                            if (showMultiLobby) ...[
                              _buildMultiLobbyCard(lobby),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: GradientCard(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
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
                                          ? context.l10n.lobbyCreatorInvites(
                                              lobby.creatorName)
                                          : context.l10n.lobbyInvitedToPlay,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    buildTictactoeRulesTextWidget(
                                      variant: lobby.variant,
                                      gridSize: lobby.gridSize,
                                      turnTimeSec: lobby.turnTimeSec,
                                      swapRule: lobby.swapRule,
                                      firstMoveRestriction:
                                          lobby.firstMoveRestriction,
                                      stakeBronze: lobby.stakeBronze,
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

  /// Общий диалог правил — ставка из лобби, как на карточке создания.
  void _showRules(BuildContext context, LobbyItem lobby) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      closeLabel: context.l10n.commonClose,
      content: buildTictactoeRulesTextWidget(
        variant: lobby.variant,
        gridSize: lobby.gridSize,
        turnTimeSec: lobby.turnTimeSec,
        swapRule: lobby.swapRule,
        firstMoveRestriction: lobby.firstMoveRestriction,
        stakeBronze: lobby.stakeBronze,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildMatchmakeInfoCard(BuildContext context, LobbyItem lobby) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.gamesRulesTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          buildTictactoeRulesTextWidget(
            variant: lobby.variant,
            gridSize: lobby.gridSize,
            turnTimeSec: lobby.turnTimeSec,
            swapRule: lobby.swapRule,
            firstMoveRestriction: lobby.firstMoveRestriction,
            stakeBronze: lobby.stakeBronze,
          ),
        ],
      ),
    );
  }

  Widget _buildShareInviteLinkCard(BuildContext context) {
    // Общий виджет — тот же, что в лобби Дурака.
    return LobbyShareLinkCard(
      title: _linkCopied
          ? context.l10n.lobbyLinkCopied
          : context.l10n.lobbyCopyLink,
      hint: _linkCopied
          ? context.l10n.lobbyLinkCopiedHint
          : context.l10n.lobbyCopyLinkHint,
      copied: _linkCopied,
      onTap: _copyInviteLink,
    );
  }

  Widget _buildMultiLobbyCard(LobbyItem lobby) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final players = lobby.players;
    final chatId = (lobby.chatId ?? '').trim();
    final isMember = currentUserId != null &&
        players.any((p) => p.id == currentUserId);
    final canOpen = chatId.isNotEmpty && isMember;
    final unread = !canOpen
        ? 0
        : ref.watch(chatsListProvider.select((async) {
            final list = async.valueOrNull;
            if (list == null) return 0;
            for (final c in list) {
              if (c.chatID == chatId) return c.unreadCount;
            }
            return 0;
          }));
    final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
    final alreadyFriendIds = <String>{
      for (final f in snapshot?.friends ?? const [])
        if (f.user.id.isNotEmpty) f.user.id,
    };
    final outgoingIds = <String>{
      for (final r in snapshot?.outgoing ?? const [])
        if (r.user.id.isNotEmpty) r.user.id,
    };
    final canAdd = players.any(
      (p) =>
          p.id.isNotEmpty &&
          p.id != currentUserId &&
          !alreadyFriendIds.contains(p.id) &&
          !outgoingIds.contains(p.id),
    );
    return LobbyMultiPlayersCard(
      players: players,
      maxPlayers: lobby.maxPlayers,
      playersCount: lobby.playersCount,
      currentUserId: currentUserId,
      chatUnread: unread,
      canOpenChat: canOpen,
      canAddFriend: canAdd,
      onOpenChat: () => _openGroupChat(context, lobby),
      onAddFriend: () => _showLobbyPlayersFriendSheet(
        context,
        lobby,
        currentUserId,
      ),
      onPlayerTap: (p) => _showLobbyPlayerProfile(context, p),
    );
  }

  Future<void> _openGroupChat(BuildContext context, LobbyItem lobby) async {
    ref.invalidate(lobbyDetailProvider(lobby.id));
    LobbyItem fresh = lobby;
    try {
      fresh = await ref.read(lobbyDetailProvider(lobby.id).future);
    } catch (_) {}
    final chatId = (fresh.chatId ?? lobby.chatId ?? '').trim();
    if (chatId.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: context.l10n.lobbyChatNotReady,
          kind: AppSnackKind.error,
        );
      }
      return;
    }
    unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
    if (!context.mounted) return;
    final returnPath = Uri(
      path: '/games/tictactoe/lobby/${lobby.id}',
      queryParameters: widget.initialMode == null
          ? null
          : {'mode': widget.initialMode!},
    ).toString();
    final route = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': returnPath,
        'name': context.l10n.lobbyNamed(variantLabel(fresh.variant)),
      },
    ).toString();
    context.push(route);
  }

  Future<void> _showLobbyPlayersFriendSheet(
    BuildContext context,
    LobbyItem lobby,
    String? currentUserId,
  ) async {
    final snapshot = ref.read(friendsSnapshotProvider).valueOrNull;
    final alreadyFriendIds = <String>{
      for (final f in snapshot?.friends ?? const [])
        if (f.user.id.isNotEmpty) f.user.id,
    };
    final outgoingIds = <String>{
      for (final r in snapshot?.outgoing ?? const [])
        if (r.user.id.isNotEmpty) r.user.id,
    };
    final players = lobby.players
        .where(
          (p) =>
              p.id.isNotEmpty &&
              p.id != currentUserId &&
              !alreadyFriendIds.contains(p.id) &&
              !outgoingIds.contains(p.id),
        )
        .toList(growable: false);
    if (players.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: context.l10n.friendsAlreadyFriends,
          kind: AppSnackKind.info,
        );
      }
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
                  for (final player in players)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: LobbyPlayerAvatar(player: player),
                        title: Text(
                          player.displayName.trim().isNotEmpty
                              ? player.displayName
                              : context.l10n.commonUser,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _friendRequestInFlight.contains(player.id)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentStart,
                                ),
                              )
                            : const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.accentStart,
                              ),
                        onTap: _friendRequestInFlight.contains(player.id)
                            ? null
                            : () => _sendLobbyFriendRequest(
                                  sheetContext,
                                  player.id,
                                ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendLobbyFriendRequest(
    BuildContext sheetContext,
    String userId,
  ) async {
    setState(() => _friendRequestInFlight.add(userId));
    try {
      await ref.read(friendsRepositoryProvider).sendRequest(userId);
      await refreshFriendsSnapshot(ref);
      if (!mounted) return;
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      showAppSnackBar(
        context,
        message: context.l10n.friendsRequestSent,
        kind: AppSnackKind.success,
      );
    } on FriendsException catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.message,
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _friendRequestInFlight.remove(userId));
    }
  }

  void _showLobbyPlayerProfile(BuildContext context, LobbyPlayer player) {
    unawaited(
      showUserProfileDialog(
        context: context,
        ref: ref,
        userId: player.id,
        displayName: player.displayName,
        avatarKind: player.avatarKind,
        avatarValue: player.avatarValue,
        frameCode: player.frameCode,
        frameColor: player.frameColor,
        messageFrom: 'games',
        messageReturnPath:
            '/games/tictactoe/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

  Future<void> _copyInviteLink() async {
    final url = buildInviteLobbyShareUrl(
      lobbyId: widget.lobbyId,
      baseUri: shareLinkBaseUri,
      gameType: 'tictactoe',
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
    if (blockJoinIfBusy(
      context,
      ref,
      targetLobbyId: widget.lobbyId,
      redirectToActive: true,
    )) {
      return;
    }
    setState(() => _isJoining = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(widget.lobbyId);
      if (!context.mounted) return;
      if (result.joined && result.waitingMore) {
        ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
        ref.invalidate(openLobbiesProvider);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: widget.lobbyId),
            );
        // Дождаться свежего состава — сразу видно себя в «Игроки».
        ref.invalidate(lobbyDetailProvider(widget.lobbyId));
        try {
          await ref.read(lobbyDetailProvider(widget.lobbyId).future);
        } catch (_) {}
        await refreshChatsList(ref, force: true).catchError((_) {});
        return;
      }
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
      // Уже в составе лобби — остаёмся в ожидании, не уходим на список игр.
      final msg = e is GamesException ? e.message.toLowerCase() : '';
      final alreadyIn = e is GamesException &&
          e.statusCode == 400 &&
          (msg.contains('already in lobby') || msg.contains('уже в лобби'));
      if (alreadyIn) {
        ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: widget.lobbyId),
            );
        // Дождаться состава — иначе кратко «не вижу себя» в «Игроки».
        ref.invalidate(lobbyDetailProvider(widget.lobbyId));
        try {
          await ref.read(lobbyDetailProvider(widget.lobbyId).future);
        } catch (_) {}
        return;
      }
      if (isFinishCurrentGameError(e)) {
        final active = resolveActiveForGuard(ref, context);
        showAppSnackBar(
          context,
          message: finishCurrentGameMessage,
          kind: AppSnackKind.error,
        );
        if (active != null) {
          goToActiveSession(context, active);
        }
        return;
      }
      final gone = e is GamesException &&
          (e.statusCode == 404 || e.statusCode == 409);
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
    if (_invitingFriendIds.contains(friendUserId) ||
        _invitedFriendIds.contains(friendUserId) ||
        _declinedFriendIds.contains(friendUserId)) {
      return;
    }
    final fallbackError = context.l10n.commonTryLater;
    setState(() => _invitingFriendIds.add(friendUserId));
    try {
      final repo = ref.read(gamesRepositoryProvider);
      var lobbyId = widget.lobbyId;
      try {
        await repo.inviteToLobby(lobbyId, friendUserId);
      } on GamesException catch (e) {
        // Лобби успели закрыть после отказа другого друга — пересоздаём и
        // сразу зовём этого. Иначе «Лобби не найдено».
        if (e.statusCode != 404) rethrow;
        final lobby = ref.read(lobbyDetailProvider(widget.lobbyId)).valueOrNull;
        final created = await repo.createLobby(
          mode: 'invite',
          turnTimeSec: lobby?.turnTimeSec ?? 0,
          variant: lobby?.variant ?? 'classic',
          gridSize: lobby?.gridSize ?? 3,
          stakeBronze: lobby?.stakeBronze ?? 1,
        );
        lobbyId = created.lobbyId;
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        await repo.inviteToLobby(lobbyId, friendUserId);
        if (!mounted) return;
        if (!context.mounted) return;
        context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        return;
      }
      if (!mounted) return;
      // Кнопка → «Отмена»: можно отозвать и пригласить снова.
      setState(() {
        _invitedFriendIds.add(friendUserId);
        _invitingFriendIds.remove(friendUserId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _invitingFriendIds.remove(friendUserId));
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: formatUserError(e, fallback: fallbackError),
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _cancelInviteFriend(
    BuildContext context,
    String friendUserId,
  ) async {
    if (_cancellingFriendIds.contains(friendUserId) ||
        !_invitedFriendIds.contains(friendUserId)) {
      return;
    }
    final fallbackError = context.l10n.commonTryLater;
    setState(() => _cancellingFriendIds.add(friendUserId));
    try {
      await ref
          .read(gamesRepositoryProvider)
          .cancelLobbyInvite(widget.lobbyId, friendUserId);
      if (!mounted) return;
      setState(() {
        _invitedFriendIds.remove(friendUserId);
        _cancellingFriendIds.remove(friendUserId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancellingFriendIds.remove(friendUserId));
      // Лобби уже нет — приглашение всё равно снимаем локально.
      final gone = e is GamesException &&
          (e.statusCode == 404 || e.statusCode == 400);
      if (gone) {
        setState(() => _invitedFriendIds.remove(friendUserId));
      }
      if (!context.mounted) return;
      if (!gone) {
        showAppSnackBar(
          context,
          message: formatUserError(e, fallback: fallbackError),
          kind: AppSnackKind.error,
        );
      }
    }
  }

  Future<void> _confirmLeaveLobby(BuildContext context) async {
    if (_isLeaving) return;
    final l10n = context.l10n;
    final ok = await confirmLeaveLobbyDialog(
      context: context,
      title: l10n.lobbyLeaveTitle,
      message: l10n.lobbyLeaveConfirm,
      cancelLabel: l10n.commonCancel,
      leaveLabel: l10n.lobbyLeave,
    );
    if (ok && context.mounted) {
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
    ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
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

  void _showFriendInfo(BuildContext context, FriendItem friend) {
    final user = friend.user;
    unawaited(
      showUserProfileDialog(
        context: context,
        ref: ref,
        userId: user.id,
        displayName: user.displayName,
        avatarKind: user.avatarKind,
        avatarValue: user.avatarValue,
        frameCode: user.frameCode,
        frameColor: user.frameColor,
        age: user.age,
        gender: user.gender,
        about: user.about,
        messageFrom: 'games',
        messageReturnPath: '/games/tictactoe/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

}
