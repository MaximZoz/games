import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException, LobbyPlayer;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/shared_lobby.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/poker_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/utils/user_error.dart';

class PokerLobbyScreen extends ConsumerStatefulWidget {
  const PokerLobbyScreen({super.key, required this.lobbyId, this.initialMode});
  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<PokerLobbyScreen> createState() => _PokerLobbyScreenState();
}

class _PokerLobbyScreenState extends ConsumerState<PokerLobbyScreen> {
  final Set<String> _invited = {};
  final Set<String> _declined = {};
  final Set<String> _inviting = {};
  final Set<String> _cancelling = {};
  final Set<String> _friendRequestInFlight = {};
  bool _leaving = false;
  bool _startingSearch = false;

  /// Открыть свою игру для поиска: лобби становится публичным.
  Future<void> _startSearch() async {
    if (_startingSearch) return;
    setState(() => _startingSearch = true);
    try {
      await ref.read(pokerRepositoryProvider).startMatchmake(widget.lobbyId);
      if (!mounted) return;
      ref.invalidate(pokerLobbyProvider(widget.lobbyId));
      ref.invalidate(openLobbiesProvider);
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _startingSearch = false);
    }
  }
  bool _linkCopied = false;
  Timer? _linkTimer;

  @override
  void dispose() {
    _linkTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmLeave() async {
    if (_leaving) return;
    final l10n = context.l10n;
    final ok = await confirmLeaveLobbyDialog(
      context: context,
      title: l10n.lobbyLeaveTitle,
      message: l10n.lobbyLeaveConfirm,
      cancelLabel: l10n.commonCancel,
      leaveLabel: l10n.lobbyLeave,
    );
    if (!ok || !mounted) return;
    await _leave();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    ref.read(activeGameProvider.notifier).clearLocal();
    ref.read(openLobbiesProvider.notifier).removeLocal(widget.lobbyId);
    ref.invalidate(openLobbiesProvider);
    context.go('/games');
    unawaited(
      ref
          .read(pokerRepositoryProvider)
          .leaveLobby(widget.lobbyId)
          .catchError((_) {}),
    );
  }

  Future<void> _invite(String friendId) async {
    if (_inviting.contains(friendId) ||
        _invited.contains(friendId) ||
        _declined.contains(friendId)) {
      return;
    }
    setState(() => _inviting.add(friendId));
    try {
      final repo = ref.read(pokerRepositoryProvider);
      var lobbyId = widget.lobbyId;
      try {
        await repo.inviteFriend(lobbyId, friendId);
      } on GamesException catch (e) {
        if (e.statusCode != 404) rethrow;
        final lobby = ref.read(pokerLobbyProvider(widget.lobbyId)).valueOrNull;
        final created = await repo.createLobby(
          mode: 'invite',
          maxPlayers: lobby?.maxPlayers ?? 2,
          turnTimeSec: lobby?.turnTimeSec ?? 0,
          stakeBronze: lobby?.stakeBronze ?? 2,
        );
        lobbyId = created.lobbyId;
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        await repo.inviteFriend(lobbyId, friendId);
        if (!mounted) return;
        context.go(
          '${LobbyGameKind.lobbyPath(lobbyId, gameType: LobbyGameKind.poker)}'
          '?mode=invite',
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _invited.add(friendId);
        _inviting.remove(friendId);
      });
    } on GamesException catch (e) {
      if (!mounted) return;
      setState(() => _inviting.remove(friendId));
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    }
  }

  Future<void> _cancelInvite(String friendId) async {
    if (_cancelling.contains(friendId) || !_invited.contains(friendId)) return;
    setState(() => _cancelling.add(friendId));
    try {
      await ref
          .read(pokerRepositoryProvider)
          .cancelInvite(widget.lobbyId, friendId);
      if (!mounted) return;
      setState(() {
        _invited.remove(friendId);
        _cancelling.remove(friendId);
      });
    } on GamesException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling.remove(friendId));
      final gone = e.statusCode == 404 || e.statusCode == 400;
      if (gone) {
        setState(() => _invited.remove(friendId));
      } else {
        showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _copyLink(String lobbyId) async {
    final link = buildInviteLobbyShareUrl(
      lobbyId: lobbyId,
      baseUri: shareLinkBaseUri,
      gameType: 'poker',
    );
    await Clipboard.setData(ClipboardData(text: link));
    ref.read(pendingInvitePasteProvider.notifier).state = link;
    if (!mounted) return;
    setState(() => _linkCopied = true);
    _linkTimer?.cancel();
    _linkTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(pokerLobbyProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);

    ref.listen(realtimeEventsProvider, (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      if (data['type']?.toString() != 'invite_declined') return;
      final lobbyId = data['lobby_id']?.toString() ?? '';
      final userId = data['user_id']?.toString() ?? '';
      if (lobbyId != widget.lobbyId || userId.isEmpty) return;
      setState(() {
        _invited.remove(userId);
        _declined.add(userId);
      });
    });

    ref.listen(pokerLobbyProvider(widget.lobbyId), (_, next) {
      final lobby = next.valueOrNull;
      if (lobby?.gameId != null && lobby!.gameId!.isNotEmpty) {
        context.go('/games/poker/game/${lobby.gameId}');
      }
    });

    final lobby = lobbyAsync.valueOrNull;
    final isMatchmake = (lobby?.mode ?? widget.initialMode) == 'matchmake';
    return SwipeBackScope(
      enabled: !_leaving,
      onBack: _confirmLeave,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _leaving ? null : _confirmLeave,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PokerGameIcon(size: 22, color: AppColors.accentStart),
              const SizedBox(width: 8),
              Text(isMatchmake
                  ? context.l10n.gamesLobbyTab
                  : context.l10n.lobbyPrivateGame),
            ],
          ),
          centerTitle: false,
          actions: [
            if (lobby != null)
              LobbySearchAction(
                searching: isMatchmake,
                busy: _startingSearch,
                onStart: () => unawaited(_startSearch()),
              ),
            if (lobby != null)
              IconButton(
                tooltip: context.l10n.gamesRulesTitle,
                icon: const Icon(Icons.rule_rounded),
                onPressed: () => showGameRulesDialog(
                  context: context,
                  title: context.l10n.gamesRulesTitle,
                  content: rulesTextLines(pokerRuleLines(
                    players: lobby.maxPlayers,
                    turnTimeSec: lobby.turnTimeSec,
                    stakeBronze: lobby.stakeBronze,
                  )),
                  closeLabel: context.l10n.commonClose,
                ),
              ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
            child: lobbyAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (lobby) => _buildBody(lobby, friendsAsync),
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentStart),
              ),
              error: (e, _) => Center(
                child: Text(
                  formatUserError(e, fallback: context.l10n.lobbyGone),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    PokerLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
    final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
    final friendsCount = friendsAsync.valueOrNull?.friends
            .where((f) => !memberIds.contains(f.user.id))
            .length ??
        0;
    return GameLobbyWaitingLayout(
      maxPlayers: lobby.maxPlayers,
      stakeBronze: lobby.stakeBronze,
      stakeLabel: context.l10n.shopStakes,
      friendsCount: friendsCount,
      multiPlayersCard: _buildMultiPlayersCard(lobby),
      shareLinkCard: LobbyShareLinkCard(
        title: context.l10n.lobbyCopyLink,
        hint: _linkCopied
            ? context.l10n.lobbyLinkCopiedHint
            : context.l10n.lobbyCopyLinkHint,
        copied: _linkCopied,
        onTap: () => _copyLink(lobby.id),
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
        declinedIds: _declined,
        listStorageKey: 'poker-lobby-friends',
        expand: expand,
        onInvite: (id) => unawaited(_invite(id)),
        onCancel: (id) => unawaited(_cancelInvite(id)),
        profileReturnPath: '/games/poker/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

  Widget _buildMultiPlayersCard(PokerLobbyView lobby) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final players = lobby.players;
    final chatId = (lobby.chatId ?? '').trim();
    final isMember = currentUserId != null &&
        (lobby.playerIds.contains(currentUserId) ||
            players.any((p) => p.id == currentUserId));
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
      playersCount: lobby.playerIds.length,
      currentUserId: currentUserId,
      chatUnread: unread,
      canOpenChat: canOpen,
      canAddFriend: canAdd,
      onOpenChat: () => _openGroupChat(lobby),
      onAddFriend: () => _showLobbyPlayersFriendSheet(lobby, currentUserId),
      onPlayerTap: (p) => _showLobbyPlayerProfile(p),
    );
  }

  Future<void> _openGroupChat(PokerLobbyView lobby) async {
    ref.invalidate(pokerLobbyProvider(lobby.id));
    PokerLobbyView fresh = lobby;
    try {
      fresh = await ref.read(pokerLobbyProvider(lobby.id).future);
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
      path: '/games/poker/lobby/${lobby.id}',
      queryParameters: widget.initialMode == null
          ? null
          : {'mode': widget.initialMode!},
    ).toString();
    final route = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': returnPath,
        'name': context.l10n.lobbyNamed(context.l10n.gamesPoker),
      },
    ).toString();
    context.push(route);
  }

  Future<void> _showLobbyPlayersFriendSheet(
    PokerLobbyView lobby,
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
        messageReturnPath: '/games/poker/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }
}
