import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException, LobbyPlayer;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/uno_game_icon.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

class UnoLobbyScreen extends ConsumerStatefulWidget {
  const UnoLobbyScreen({
    super.key,
    required this.lobbyId,
    this.initialMode,
  });

  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<UnoLobbyScreen> createState() => _UnoLobbyScreenState();
}

class _UnoLobbyScreenState extends ConsumerState<UnoLobbyScreen> {
  final Set<String> _invited = {};
  final Set<String> _inviting = {};
  final Set<String> _cancelling = {};
  final Set<String> _friendRequestInFlight = {};
  bool _leaving = false;
  bool _linkCopied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
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
          .read(unoRepositoryProvider)
          .leaveLobby(widget.lobbyId)
          .catchError((_) {}),
    );
  }

  Future<void> _copyLink() async {
    final link = buildInviteLobbyShareUrl(
      lobbyId: widget.lobbyId,
      baseUri: Uri.base,
      gameType: 'uno',
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
          .read(unoRepositoryProvider)
          .inviteFriend(widget.lobbyId, userId);
      if (!mounted) return;
      setState(() {
        _inviting.remove(userId);
        _invited.add(userId);
      });
    } on GamesException catch (error) {
      if (!mounted) return;
      setState(() => _inviting.remove(userId));
      showAppSnackBar(
        context,
        message: formatUserError(error),
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _cancelInvite(String userId) async {
    if (_cancelling.contains(userId)) return;
    setState(() => _cancelling.add(userId));
    try {
      await ref
          .read(unoRepositoryProvider)
          .cancelInvite(widget.lobbyId, userId);
      if (!mounted) return;
      setState(() {
        _cancelling.remove(userId);
        _invited.remove(userId);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cancelling.remove(userId);
          _invited.remove(userId);
        });
      }
    }
  }

  void _showRules(UnoLobbyView lobby) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: rulesTextLines(unoRuleLines(
        players: lobby.maxPlayers,
        turnTimeSec: lobby.turnTimeSec,
        stakeBronze: lobby.stakeBronze,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(unoLobbyProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    ref.listen(unoLobbyProvider(widget.lobbyId), (_, next) {
      final gameId = next.valueOrNull?.gameId?.trim() ?? '';
      if (gameId.isEmpty || !mounted) return;
      ref.read(activeGameProvider.notifier).setLocal(
            ActiveGameItem(
              type: 'game',
              gameId: gameId,
              lobbyId: widget.lobbyId,
              gameType: 'uno',
            ),
          );
      context.go('/games/uno/game/$gameId');
    });

    final lobby = lobbyAsync.valueOrNull;
    final matchmaking = (lobby?.mode ?? widget.initialMode) == 'matchmake';
    return SwipeBackScope(
      enabled: !_leaving,
      onBack: _confirmLeave,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            onPressed: _leaving ? null : _confirmLeave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const UnoGameIcon(size: 22),
              const SizedBox(width: 8),
              Text(
                matchmaking
                    ? context.l10n.gamesLobbyTab
                    : context.l10n.lobbyPrivateGame,
              ),
            ],
          ),
          centerTitle: true,
          actions: [
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
    UnoLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
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
      searchBanner: lobby.mode == 'matchmake'
          ? LobbySearchBanner(label: context.l10n.lobbySearchingOpponent)
          : null,
      multiPlayersCard: _buildMultiPlayersCard(lobby),
      shareLinkCard: LobbyShareLinkCard(
        title: context.l10n.lobbyCopyLink,
        hint: _linkCopied
            ? context.l10n.lobbyLinkCopiedHint
            : context.l10n.lobbyCopyLinkHint,
        copied: _linkCopied,
        onTap: _copyLink,
      ),
      friendsCardBuilder: (expand) => LobbyFriendsInviteCard(
        friendsAsync: friendsAsync,
        excludeUserIds: memberIds,
        invitedIds: _invited,
        invitingIds: _inviting,
        cancellingIds: _cancelling,
        listStorageKey: 'uno-lobby-friends',
        expand: expand,
        onInvite: _invite,
        onCancel: _cancelInvite,
        onFriendTap: (friend) => _showFriendProfile(friend.user),
        profileReturnPath: '/games/uno/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

  Widget _buildMultiPlayersCard(UnoLobbyView lobby) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final players = lobby.players;
    final chatId = (lobby.chatId ?? '').trim();
    final isMember = currentUserId != null &&
        (lobby.playerIds.contains(currentUserId) ||
            players.any((player) => player.id == currentUserId) ||
            lobby.creatorId == currentUserId);
    final canOpen = chatId.isNotEmpty && isMember;
    final unread = !canOpen
        ? 0
        : ref.watch(chatsListProvider.select((async) {
            final list = async.valueOrNull;
            if (list == null) return 0;
            for (final chat in list) {
              if (chat.chatID == chatId) return chat.unreadCount;
            }
            return 0;
          }));
    final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
    final alreadyFriendIds = <String>{
      for (final friend in snapshot?.friends ?? const [])
        if (friend.user.id.isNotEmpty) friend.user.id,
    };
    final outgoingIds = <String>{
      for (final request in snapshot?.outgoing ?? const [])
        if (request.user.id.isNotEmpty) request.user.id,
    };
    final canAdd = players.any(
      (player) =>
          player.id.isNotEmpty &&
          player.id != currentUserId &&
          !alreadyFriendIds.contains(player.id) &&
          !outgoingIds.contains(player.id),
    );
    return LobbyMultiPlayersCard(
      players: players,
      maxPlayers: lobby.maxPlayers,
      playersCount: lobby.playerIds.length,
      currentUserId: currentUserId,
      chatUnread: unread,
      canOpenChat: canOpen,
      canAddFriend: canAdd,
      onOpenChat: () => _openGroupChat(lobby),
      onAddFriend: () => _showLobbyPlayersFriendSheet(lobby, currentUserId),
      onPlayerTap: (player) => _showLobbyPlayerProfile(player),
    );
  }

  Future<void> _openGroupChat(UnoLobbyView lobby) async {
    ref.invalidate(unoLobbyProvider(lobby.id));
    UnoLobbyView fresh = lobby;
    try {
      fresh = await ref.read(unoLobbyProvider(lobby.id).future);
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
      path: '/games/uno/lobby/${lobby.id}',
      queryParameters: widget.initialMode == null
          ? null
          : {'mode': widget.initialMode!},
    ).toString();
    final route = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': returnPath,
        'name': context.l10n.lobbyNamed(context.l10n.gamesUno),
      },
    ).toString();
    context.push(route);
  }

  Future<void> _showLobbyPlayersFriendSheet(
    UnoLobbyView lobby,
    String? currentUserId,
  ) async {
    final snapshot = ref.read(friendsSnapshotProvider).valueOrNull;
    final alreadyFriendIds = <String>{
      for (final friend in snapshot?.friends ?? const [])
        if (friend.user.id.isNotEmpty) friend.user.id,
    };
    final outgoingIds = <String>{
      for (final request in snapshot?.outgoing ?? const [])
        if (request.user.id.isNotEmpty) request.user.id,
    };
    final players = lobby.players
        .where(
          (player) =>
              player.id.isNotEmpty &&
              player.id != currentUserId &&
              !alreadyFriendIds.contains(player.id) &&
              !outgoingIds.contains(player.id),
        )
        .toList(growable: false);
    if (players.isEmpty) {
      if (mounted) {
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
    } on FriendsException catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: error.message,
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _friendRequestInFlight.remove(userId));
    }
  }

  void _showLobbyPlayerProfile(LobbyPlayer player) {
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
        messageReturnPath: '/games/uno/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

  void _showFriendProfile(FriendUserItem user) {
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
        messageReturnPath: '/games/uno/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }
}
