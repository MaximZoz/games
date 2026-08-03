import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/lobby_game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
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

/// Оценка высоты карточки друзей (паддинг + строки ~56px).
double _estimateFriendsCardHeight(int friendCount) {
  if (friendCount <= 0) return 88;
  return 24 + friendCount * 56.0;
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
  final Set<String> _friendRequestInFlight = {};
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
            // Иконка правил — в AppBar, на одной высоте со стрелкой «Назад».
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
              // Планшет / phone landscape / низкий экран: страница скроллится,
              // иначе карточка приглашения обрезается.
              final shortViewport = isPhoneLandscape(context) ||
                  isTablet(context) ||
                  MediaQuery.sizeOf(context).height < 640;
              final useScrollFriends = shortViewport &&
                  (showOpenFindWaiting ||
                      (showPrivateInviteWaiting && isCreator));
              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 480 : double.infinity,
                    ),
                    child: useScrollFriends
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final friendCount =
                                  friendsAsync.valueOrNull?.friends.length ?? 0;
                              final estimated =
                                  _estimateFriendsCardHeight(friendCount);
                              final maxFriendsH = (constraints.maxHeight * 0.55)
                                  .clamp(180.0, 360.0);
                              final expandFriends = estimated > maxFriendsH;
                              return SingleChildScrollView(
                                padding: EdgeInsets.all(pad),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: ClampingScrollPhysics(),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (showOpenFindWaiting) ...[
                                      _buildSearchLoaderBanner(context),
                                      const SizedBox(height: 12),
                                    ] else if (lobby.stakeBronze > 0) ...[
                                      _LobbyStakeChip(
                                        stakeBronze: lobby.stakeBronze,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (showMultiLobby) ...[
                                      _buildMultiLobbyCard(
                                        context,
                                        lobby,
                                        currentUser?.id,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    _buildShareInviteLinkCard(context),
                                    const SizedBox(height: 12),
                                    if (expandFriends)
                                      SizedBox(
                                        height: maxFriendsH,
                                        child: _buildFriendsCard(
                                          context,
                                          friendsAsync,
                                          expand: true,
                                        ),
                                      )
                                    else
                                      _buildFriendsCard(
                                        context,
                                        friendsAsync,
                                        expand: false,
                                      ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Padding(
                            padding: EdgeInsets.all(pad),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showOpenFindWaiting) ...[
                                  _buildSearchLoaderBanner(context),
                                  const SizedBox(height: 12),
                                  if (showMultiLobby) ...[
                                    _buildMultiLobbyCard(
                                      context,
                                      lobby,
                                      currentUser?.id,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (showMultiLobby) ...[
                                    _buildShareInviteLinkCard(context),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final friendCount = friendsAsync
                                                  .valueOrNull
                                                  ?.friends
                                                  .length ??
                                              0;
                                          final estimated =
                                              _estimateFriendsCardHeight(
                                                  friendCount);
                                          final expand = estimated >=
                                              constraints.maxHeight;
                                          final card = _buildFriendsCard(
                                            context,
                                            friendsAsync,
                                            expand: expand,
                                          );
                                          if (expand) return card;
                                          return Align(
                                            alignment: Alignment.topCenter,
                                            child: card,
                                          );
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: GradientCard(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context
                                                  .l10n.lobbySearchingOpponent,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            _buildMatchmakeInfoCard(
                                              context,
                                              lobby,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ] else if (showPrivateInviteWaiting &&
                                    isCreator) ...[
                                  if (showMultiLobby) ...[
                                    _buildMultiLobbyCard(
                                      context,
                                      lobby,
                                      currentUser?.id,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  // Ссылка — максимально высоко (заголовок уже в AppBar).
                                  _buildShareInviteLinkCard(context),
                                  const SizedBox(height: 12),
                                  // Мало друзей — карточка по контенту; много — растягиваем.
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final friendCount = friendsAsync
                                                .valueOrNull?.friends.length ??
                                            0;
                                        final estimated =
                                            _estimateFriendsCardHeight(
                                                friendCount);
                                        final expand =
                                            estimated >= constraints.maxHeight;
                                        final card = _buildFriendsCard(
                                          context,
                                          friendsAsync,
                                          expand: expand,
                                        );
                                        if (expand) return card;
                                        return Align(
                                          alignment: Alignment.topCenter,
                                          child: card,
                                        );
                                      },
                                    ),
                                  ),
                                ] else if (showPrivateInviteWaiting &&
                                    !isCreator) ...[
                                  // Приглашённый в «Свою игру»: игроки + ссылка + правила.
                                  if (showMultiLobby) ...[
                                    _buildMultiLobbyCard(
                                      context,
                                      lobby,
                                      currentUser?.id,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  _buildShareInviteLinkCard(context),
                                  const SizedBox(height: 16),
                                  _buildMatchmakeInfoCard(context, lobby),
                                ] else if (showInviteAccept) ...[
                                  if (showMultiLobby) ...[
                                    _buildMultiLobbyCard(
                                      context,
                                      lobby,
                                      currentUser?.id,
                                    ),
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
                                                ? context.l10n
                                                    .lobbyCreatorInvites(
                                                        lobby.creatorName)
                                                : context
                                                    .l10n.lobbyInvitedToPlay,
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
                                              backgroundColor:
                                                  AppColors.accentStart,
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                            ),
                                            child: _isJoining
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(context
                                                    .l10n.lobbyEnterGame),
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

  /// Общая всплывашка с правилами (как в экране игры).
  void _showRules(BuildContext context, LobbyItem lobby) {
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    child: buildTictactoeRulesTextWidget(
                      variant: lobby.variant,
                      gridSize: lobby.gridSize,
                      turnTimeSec: lobby.turnTimeSec,
                      swapRule: lobby.swapRule,
                      firstMoveRestriction: lobby.firstMoveRestriction,
                      // В «Своя игра» ставок нет — не показываем строку ставки.
                      stakeBronze: 0,
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

  /// Карточка друзей.
  ///
  /// [expand]=true — занимает родителя и скроллит список внутри.
  /// [expand]=false — высота по контенту (мало друзей).
  Widget _buildFriendsCard(
    BuildContext context,
    AsyncValue<FriendsSnapshot> friendsAsync, {
    bool expand = true,
  }) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: friendsAsync.when(
        data: (snapshot) {
          final friends = snapshot.friends;
          final presence =
              ref.watch(presenceMapProvider).valueOrNull ?? const {};
          final visibleFriends = List.of(friends);
          sortByPresenceOnlineFirst(
            visibleFriends,
            (f) => f.user.id,
            presence,
          );
          if (visibleFriends.isEmpty) {
            final empty = Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.friendsEmpty,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            );
            return expand ? Center(child: empty) : empty;
          }
          final list = ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            shrinkWrap: !expand,
            physics: expand
                ? const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            itemCount: visibleFriends.length,
            itemBuilder: (context, i) {
              final f = visibleFriends[i];
              final friendId = f.user.id;
              final friendPresence = presence[friendId];
              final statusText = formatPresenceStatus(friendPresence);
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
                          child: _buildFriendAvatar(
                            f.user,
                            20,
                            isOnline: friendPresence?.online == true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.user.displayName?.trim().isNotEmpty == true
                                ? f.user.displayName!
                                : context.l10n.commonUser,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (statusText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: isInviting || isInvited
                          ? null
                          : () => _inviteFriend(context, friendId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentStart,
                        side: BorderSide(
                          color: AppColors.accentStart.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: isInviting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentStart,
                              ),
                            )
                          : Text(
                              isInvited
                                  ? context.l10n.lobbyInviteSentShort
                                  : context.l10n.lobbyInvite,
                            ),
                    ),
                  ],
                ),
              );
            },
          );
          return list;
        },
        loading: () {
          const spinner = Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          );
          return expand ? spinner : const SizedBox(height: 72, child: spinner);
        },
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${context.l10n.friendsLoadFailed}. ${formatUserError(e, fallback: context.l10n.commonTryLater)}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Блок под «Поиск соперника»: только правила, высота по контенту.
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

  Widget _buildSearchLoaderBanner(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.lobbySearchingOpponent,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLobbyCard(
    BuildContext context,
    LobbyItem lobby,
    String? currentUserId,
  ) {
    final players = lobby.players;
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Игроки ${lobby.playersCount}/${lobby.maxPlayers}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final player in players)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showLobbyPlayerProfile(context, player),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _LobbyPlayerAvatar(player: player),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 96),
                                  child: Text(
                                    player.displayName.trim().isNotEmpty
                                        ? player.displayName
                                        : context.l10n.commonUser,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.accentStart,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.accentStart,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    for (var i = players.length;
                        i < lobby.maxPlayers && i < 4;
                        i++)
                      const _LobbyEmptySeatAvatar(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
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
              return IconButton(
                tooltip: 'Чат группы',
                // Чат только для уже вступивших — иначе «Доступ запрещён».
                onPressed: canOpen ? () => _openGroupChat(context, lobby) : null,
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.forum_rounded),
                ),
                color: AppColors.accentStart,
              );
            },
          ),
          Builder(
            builder: (context) {
              final snapshot =
                  ref.watch(friendsSnapshotProvider).valueOrNull;
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
              if (!canAdd) return const SizedBox.shrink();
              return IconButton(
                tooltip: context.l10n.friendsAdd,
                onPressed: () => _showLobbyPlayersFriendSheet(
                  context,
                  lobby,
                  currentUserId,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                color: AppColors.accentStart,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openGroupChat(BuildContext context, LobbyItem lobby) async {
    // GetLobby синхронизирует chat_members — иначе после реванша бывает «Доступ запрещён».
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
          message: 'Чат лобби ещё не создан',
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
        'name': 'Лобби ${variantLabel(fresh.variant)}',
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
    // Уже в друзьях / исходящая заявка — не показываем в «Добавить в друзья».
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
                        leading: _LobbyPlayerAvatar(player: player),
                        title: Text(
                          player.displayName.trim().isNotEmpty
                              ? player.displayName
                              : context.l10n.commonUser,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            _friendRequestInFlight.contains(player.id)
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
        title: Text(l10n.lobbyLeaveTitle),
        content: Text(l10n.lobbyLeaveConfirm),
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
            child: Text(l10n.lobbyLeave),
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

  Widget _buildFriendAvatar(
    FriendUserItem user,
    double radius, {
    bool isOnline = false,
  }) {
    Widget avatar;
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(user.avatarValue!);
      if (img != null) {
        avatar = CircleAvatar(radius: radius, backgroundImage: img);
      } else {
        avatar = _friendLetterAvatar(user, radius);
      }
    } else if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final idx = int.tryParse(user.avatarValue!);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        avatar = CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      } else {
        avatar = _friendLetterAvatar(user, radius);
      }
    } else {
      avatar = _friendLetterAvatar(user, radius);
    }
    if (!isOnline) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 8,
            height: 8,
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

  Widget _friendLetterAvatar(FriendUserItem user, double radius) {
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
        messageReturnPath: '/games/tictactoe/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

}

class _LobbyPlayerAvatar extends StatelessWidget {
  const _LobbyPlayerAvatar({required this.player});

  final LobbyPlayer player;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    const radius = size / 2;
    Widget avatar;
    if (player.avatarKind == 'file' &&
        player.avatarValue != null &&
        player.avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(player.avatarValue!);
      avatar = img == null
          ? _letterAvatar(radius)
          : CircleAvatar(radius: radius, backgroundImage: img);
    } else if (player.avatarKind == 'preset' && player.avatarValue != null) {
      final idx = int.tryParse(player.avatarValue!);
      avatar = idx != null && idx >= 0 && idx < _presetAvatarIcons.length
          ? CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.accentSoft,
              child: Icon(
                _presetAvatarIcons[idx],
                color: AppColors.accentStart,
                size: radius,
              ),
            )
          : _letterAvatar(radius);
    } else {
      avatar = _letterAvatar(radius);
    }
    return FramedAvatar(
      size: size,
      borderWidth: 2.6,
      frameCode: player.frameCode,
      frameColor: player.frameColor,
      animate: false,
      child: avatar,
    );
  }

  Widget _letterAvatar(double radius) {
    final name = player.displayName.trim();
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
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

class _LobbyEmptySeatAvatar extends StatelessWidget {
  const _LobbyEmptySeatAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceCard,
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.9),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.textSecondary,
        size: 20,
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
