import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/domino/domino_rules.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException, LobbyPlayer;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/lobby_guest.dart';
import 'package:multigames_client/games/shared_lobby.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

class DominoLobbyScreen extends ConsumerStatefulWidget {
  const DominoLobbyScreen({
    super.key,
    required this.lobbyId,
    this.initialMode,
  });

  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<DominoLobbyScreen> createState() => _DominoLobbyScreenState();
}

class _DominoLobbyScreenState extends ConsumerState<DominoLobbyScreen> {
  final Set<String> _invited = {};
  final Set<String> _inviting = {};
  final Set<String> _cancelling = {};
  bool _leaving = false;
  bool _joining = false;
  bool _startingSearch = false;
  bool _linkCopied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSearch() async {
    if (_startingSearch) return;
    setState(() => _startingSearch = true);
    try {
      await ref.read(dominoRepositoryProvider).startMatchmake(widget.lobbyId);
      if (!mounted) return;
      ref.invalidate(dominoLobbyProvider(widget.lobbyId));
      ref.invalidate(openLobbiesProvider);
    } on GamesException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, message: error.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _startingSearch = false);
    }
  }

  Future<void> _confirmLeave() async {
    if (_leaving) return;
    final leave = await confirmLeaveLobbyDialog(
      context: context,
      title: context.l10n.lobbyLeaveTitle,
      message: context.l10n.lobbyLeaveConfirm,
      cancelLabel: context.l10n.commonCancel,
      leaveLabel: context.l10n.lobbyLeave,
    );
    if (!leave || !mounted) return;
    setState(() => _leaving = true);
    ref.read(activeGameProvider.notifier).clearLocal();
    ref.read(openLobbiesProvider.notifier).removeLocal(widget.lobbyId);
    context.go('/games');
    unawaited(
      ref
          .read(dominoRepositoryProvider)
          .leaveLobby(widget.lobbyId)
          .catchError((_) {}),
    );
  }

  Future<void> _join() {
    return runLobbyJoin(
      context: context,
      ref: ref,
      lobbyId: widget.lobbyId,
      gameType: 'domino',
      setJoining: (joining) {
        if (mounted) setState(() => _joining = joining);
      },
      invalidateLobby: () => ref.invalidate(dominoLobbyProvider(widget.lobbyId)),
      join: () async {
        final result =
            await ref.read(dominoRepositoryProvider).joinLobby(widget.lobbyId);
        return LobbyJoinOutcome(
          joined: result.joined,
          gameId: result.gameId,
          waitingMore: result.waitingMore,
        );
      },
    );
  }

  Future<void> _copyLink() async {
    final link = buildInviteLobbyShareUrl(
      lobbyId: widget.lobbyId,
      baseUri: shareLinkBaseUri,
      gameType: 'domino',
    );
    await Clipboard.setData(ClipboardData(text: link));
    ref.read(pendingInvitePasteProvider.notifier).state = link;
    if (!mounted) return;
    setState(() => _linkCopied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  Future<void> _invite(String userId) async {
    if (_inviting.contains(userId) || _invited.contains(userId)) return;
    setState(() => _inviting.add(userId));
    try {
      await ref
          .read(dominoRepositoryProvider)
          .inviteFriend(widget.lobbyId, userId);
      if (!mounted) return;
      setState(() => _invited.add(userId));
      ref.invalidate(dominoLobbyProvider(widget.lobbyId));
    } on GamesException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, message: error.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _inviting.remove(userId));
    }
  }

  Future<void> _cancelInvite(String userId) async {
    if (_cancelling.contains(userId)) return;
    setState(() => _cancelling.add(userId));
    try {
      await ref
          .read(dominoRepositoryProvider)
          .cancelInvite(widget.lobbyId, userId);
      if (!mounted) return;
      setState(() => _invited.remove(userId));
      ref.invalidate(dominoLobbyProvider(widget.lobbyId));
    } on GamesException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, message: error.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _cancelling.remove(userId));
    }
  }

  void _showRules(DominoLobbyView lobby) {
    showGameRulesDialog(
      context: context,
      content: rulesTextLines(dominoRuleLines(
        players: lobby.maxPlayers,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        mode: lobby.gameMode,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(dominoLobbyProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    ref.listen(dominoLobbyProvider(widget.lobbyId), (_, next) {
      final gameId = next.valueOrNull?.gameId?.trim() ?? '';
      if (gameId.isEmpty || !mounted) return;
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'game',
              gameId: gameId,
              lobbyId: widget.lobbyId,
              gameType: 'domino',
            ),
          );
      context.go('/games/domino/game/$gameId');
    });
    final lobby = lobbyAsync.valueOrNull;
    final guest = lobby != null &&
        !lobbyUserIsMember(
          userId: ref.watch(authStateProvider).valueOrNull?.id,
          creatorId: lobby.creatorId,
          playerIds: lobby.playerIds,
          players: lobby.players,
        );
    final matchmaking = (lobby?.mode ?? widget.initialMode) == 'matchmake';
    return SwipeBackScope(
      enabled: !_leaving,
      onBack: guest ? () => exitLobbyGuest(context) : _confirmLeave,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            onPressed: _leaving
                ? null
                : guest
                    ? () => exitLobbyGuest(context)
                    : _confirmLeave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 8,
          title: GameLobbyAppBarTitle(
            gameType: 'domino',
            title: lobbyAppBarTitle(
              status: lobby?.status,
              initialMode: widget.initialMode,
              lobbyMode: lobby?.mode,
              fromInviteLink: guest && lobby.mode != 'matchmake',
              isLobbyMember: lobby != null && !guest,
            ),
          ),
          centerTitle: false,
          actions: [
            if (lobby != null && !guest)
              LobbySearchAction(
                searching: matchmaking,
                busy: _startingSearch,
                onStart: () => unawaited(_startSearch()),
              ),
            if (lobby != null)
              IconButton(
                tooltip: context.l10n.gamesRulesTitle,
                onPressed: () => _showRules(lobby),
                icon: const Icon(Icons.rule_rounded),
              ),
          ],
        ),
        body: GradientBackground(
          child: lobbyAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            data: (value) => _buildBody(value, friendsAsync),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentStart),
            ),
            error: (error, _) => Center(
              child: Text(
                formatUserError(error, fallback: context.l10n.lobbyGone),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    DominoLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
    final uid = ref.watch(authStateProvider).valueOrNull?.id;
    final guest = !lobbyUserIsMember(
      userId: uid,
      creatorId: lobby.creatorId,
      playerIds: lobby.playerIds,
      players: lobby.players,
    );
    if (guest) {
      return LobbyInviteAcceptView(
        gameType: 'domino',
        creatorName: lobbyCreatorDisplayName(
          creatorId: lobby.creatorId,
          players: lobby.players,
        ),
        joining: _joining,
        onJoin: () => unawaited(_join()),
        stakeBronze: lobby.maxPlayers > 2 ? 0 : lobby.stakeBronze,
        padding: EdgeInsets.all(isNarrow(context) ? 16 : 24),
        top: lobby.maxPlayers > 2 ? _playersCard(lobby) : null,
        rules: rulesTextLines(dominoRuleLines(
          players: lobby.maxPlayers,
          turnTimeSec: lobby.turnTimeSec,
          stakeBronze: lobby.stakeBronze,
          mode: lobby.gameMode,
          l10n: context.l10n,
        )),
      );
    }
    final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
    final friendsCount = friendsAsync.valueOrNull?.friends
            .where((friend) => !memberIds.contains(friend.user.id))
            .length ??
        0;
    return GameLobbyWaitingLayout(
      maxPlayers: lobby.maxPlayers,
      stakeBronze: lobby.stakeBronze,
      stakeLabel: context.l10n.shopStakes,
      friendsCount: friendsCount,
      maxWidth: isNarrow(context) ? 480 : 560,
      padding: EdgeInsets.all(isNarrow(context) ? 16 : 24),
      multiPlayersCard: lobby.maxPlayers > 2 ? _playersCard(lobby) : null,
      shareLinkCard: LobbyShareLinkCard(
        title: context.l10n.lobbyCopyLink,
        hint: _linkCopied
            ? context.l10n.lobbyLinkCopiedHint
            : context.l10n.lobbyCopyLinkHint,
        copied: _linkCopied,
        onTap: _copyLink,
      ),
      friendsCardBuilder: (expand) => LobbyFriendsInviteCard(
        pendingInvites: lobby.invited,
        friendsAsync: friendsAsync,
        excludeUserIds: memberIds,
        invitedIds: {
          ..._invited,
          for (final guest in lobby.invited) guest.id,
        },
        invitingIds: _inviting,
        cancellingIds: _cancelling,
        listStorageKey: 'domino-lobby-friends',
        expand: expand,
        onInvite: _invite,
        onCancel: _cancelInvite,
        onFriendTap: (friend) => _showFriendProfile(friend.user),
        profileReturnPath: '/games/domino/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

  Widget _playersCard(DominoLobbyView lobby) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final chatId = (lobby.chatId ?? '').trim();
    final isMember = currentUserId != null &&
        (lobby.playerIds.contains(currentUserId) ||
            lobby.creatorId == currentUserId);
    final unread = chatId.isEmpty || !isMember
        ? 0
        : ref.watch(chatsListProvider.select((async) {
            final list = async.valueOrNull;
            if (list == null) return 0;
            for (final chat in list) {
              if (chat.chatID == chatId) return chat.unreadCount;
            }
            return 0;
          }));
    return LobbyMultiPlayersCard(
      players: lobby.players,
      maxPlayers: lobby.maxPlayers,
      playersCount: lobby.playerIds.length,
      currentUserId: currentUserId,
      chatUnread: unread,
      canOpenChat: chatId.isNotEmpty && isMember,
      canAddFriend: false,
      onOpenChat: () => _openGroupChat(lobby),
      onAddFriend: () {},
      onPlayerTap: _showPlayer,
    );
  }

  Future<void> _openGroupChat(DominoLobbyView lobby) async {
    ref.invalidate(dominoLobbyProvider(lobby.id));
    var fresh = lobby;
    try {
      fresh = await ref.read(dominoLobbyProvider(lobby.id).future);
    } catch (_) {}
    final chatId = (fresh.chatId ?? lobby.chatId ?? '').trim();
    if (chatId.isEmpty) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: context.l10n.lobbyChatNotReady,
          kind: AppSnackKind.error,
        );
      }
      return;
    }
    unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
    if (!mounted) return;
    final returnPath = Uri(
      path: '/games/domino/lobby/${lobby.id}',
      queryParameters: widget.initialMode == null
          ? null
          : {'mode': widget.initialMode},
    ).toString();
    context.push(Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': returnPath,
        'name': context.l10n.lobbyNamed(context.l10n.gamesDomino),
      },
    ).toString());
  }

  void _showPlayer(LobbyPlayer player) {
    unawaited(showUserProfileDialog(
      context: context,
      ref: ref,
      userId: player.id,
      displayName: player.displayName,
      avatarKind: player.avatarKind,
      avatarValue: player.avatarValue,
      frameCode: player.frameCode,
      frameColor: player.frameColor,
      messageFrom: 'games',
      messageReturnPath: '/games/domino/lobby/${widget.lobbyId}?mode=invite',
    ));
  }

  void _showFriendProfile(FriendUserItem user) {
    unawaited(showUserProfileDialog(
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
      messageReturnPath: '/games/domino/lobby/${widget.lobbyId}?mode=invite',
    ));
  }
}
