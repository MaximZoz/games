import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException, LobbyPlayer;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/shared_lobby.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/utils/user_error.dart';

class DurakLobbyScreen extends ConsumerStatefulWidget {
  const DurakLobbyScreen({super.key, required this.lobbyId, this.initialMode});
  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<DurakLobbyScreen> createState() => _DurakLobbyScreenState();
}

class _DurakLobbyScreenState extends ConsumerState<DurakLobbyScreen> {
  /// Приглашение отправлено — кнопка «Отмена».
  final Set<String> _invited = {};
  /// Друг отказался — «Отправлено» disabled.
  final Set<String> _declined = {};
  final Set<String> _inviting = {};
  final Set<String> _cancelling = {};
  final Set<String> _friendRequestInFlight = {};
  bool _leaving = false;
  bool _linkCopied = false;
  Timer? _linkTimer;

  @override
  void dispose() {
    _linkTimer?.cancel();
    super.dispose();
  }

  /// Кнопка «Назад» и свайп: сначала подтверждение — как в крестиках-ноликах.
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
    // Как в крестиках-ноликах: сразу уходим и сбрасываем активную сессию,
    // иначе список игр редиректит обратно в уже удалённое лобби
    // («Лобби не найдено»).
    ref.read(activeGameProvider.notifier).clearLocal();
    ref.read(openLobbiesProvider.notifier).removeLocal(widget.lobbyId);
    ref.invalidate(openLobbiesProvider);
    context.go('/games');
    unawaited(
      ref
          .read(durakRepositoryProvider)
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
      final repo = ref.read(durakRepositoryProvider);
      var lobbyId = widget.lobbyId;
      try {
        await repo.inviteFriend(lobbyId, friendId);
      } on GamesException catch (e) {
        // Лобби закрыли после отказа другого — пересоздаём и зовём снова.
        if (e.statusCode != 404) rethrow;
        final lobby = ref.read(durakLobbyProvider(widget.lobbyId)).valueOrNull;
        final created = await repo.createLobby(
          mode: 'invite',
          maxPlayers: lobby?.maxPlayers ?? 2,
          deckSize: lobby?.deckSize ?? 36,
          gameMode: lobby?.gameMode ?? 'podkidnoi',
          turnTimeSec: lobby?.turnTimeSec ?? 0,
          stakeBronze: lobby?.stakeBronze ?? 1,
        );
        lobbyId = created.lobbyId;
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        await repo.inviteFriend(lobbyId, friendId);
        if (!mounted) return;
        context.go(
          '${LobbyGameKind.lobbyPath(lobbyId, gameType: LobbyGameKind.durak)}'
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
          .read(durakRepositoryProvider)
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
    final link = buildInviteLink(lobbyId, gameType: 'durak');
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    setState(() => _linkCopied = true);
    _linkTimer?.cancel();
    _linkTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(durakLobbyProvider(widget.lobbyId));
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

    // Автоматический переход в партию когда сервер стартовал игру.
    ref.listen(durakLobbyProvider(widget.lobbyId), (_, next) {
      final lobby = next.valueOrNull;
      if (lobby?.gameId != null && lobby!.gameId!.isNotEmpty) {
        context.go('/games/durak/game/${lobby.gameId}');
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
              const Icon(Icons.style_rounded,
                  size: 22, color: AppColors.accentStart),
              const SizedBox(width: 8),
              Text(isMatchmake
                  ? context.l10n.gamesLobbyTab
                  : context.l10n.lobbyPrivateGame),
            ],
          ),
          centerTitle: true,
          actions: [
            if (lobby != null)
              IconButton(
                tooltip: context.l10n.gamesRulesTitle,
                icon: const Icon(Icons.rule_rounded),
                onPressed: () => showGameRulesDialog(
                  context: context,
                  title: context.l10n.gamesRulesTitle,
                  content: rulesTextLines(durakRuleLines(
                    mode: lobby.gameMode,
                    players: lobby.maxPlayers,
                    deckSize: lobby.deckSize,
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
    DurakLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
    final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
    final friendsCount = friendsAsync.valueOrNull?.friends
            .where((f) => !memberIds.contains(f.user.id))
            .length ??
        0;
    final isMatchmake = lobby.mode == 'matchmake';
    // Тот же скелет, что и в крестиках-ноликах: 2 игрока → чип ставки,
    // 3–4 → карточка «Игроки N/M», друзья — по контенту.
    return GameLobbyWaitingLayout(
      maxPlayers: lobby.maxPlayers,
      stakeBronze: lobby.stakeBronze,
      stakeLabel: context.l10n.shopStakes,
      friendsCount: friendsCount,
      searchBanner: isMatchmake
          ? LobbySearchBanner(label: context.l10n.lobbySearchingOpponent)
          : null,
      multiPlayersCard: _buildMultiPlayersCard(lobby),
      shareLinkCard: LobbyShareLinkCard(
        title: context.l10n.lobbyCopyLink,
        hint: _linkCopied
            ? context.l10n.lobbyLinkCopiedHint
            : context.l10n.lobbyCopyLinkHint,
        copied: _linkCopied,
        onTap: () => _copyLink(lobby.id),
      ),
      friendsCardBuilder: (expand) =>
          _buildFriendsCard(lobby, friendsAsync, expand: expand),
    );
  }

  /// Карточка состава для 3–4 — общий [LobbyMultiPlayersCard] (как в крестиках).
  Widget _buildMultiPlayersCard(DurakLobbyView lobby) {
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

  Future<void> _openGroupChat(DurakLobbyView lobby) async {
    ref.invalidate(durakLobbyProvider(lobby.id));
    DurakLobbyView fresh = lobby;
    try {
      fresh = await ref.read(durakLobbyProvider(lobby.id).future);
    } catch (_) {}
    final chatId = (fresh.chatId ?? lobby.chatId ?? '').trim();
    if (chatId.isEmpty) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Чат лобби ещё не создан',
          kind: AppSnackKind.error,
        );
      }
      return;
    }
    unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
    if (!mounted) return;
    final returnPath = Uri(
      path: '/games/durak/lobby/${lobby.id}',
      queryParameters: widget.initialMode == null
          ? null
          : {'mode': widget.initialMode!},
    ).toString();
    final route = Uri(
      path: '/chats/$chatId',
      queryParameters: {
        'from': 'games',
        'game': returnPath,
        'name': 'Лобби ${durakModeLabel(fresh.gameMode)}',
      },
    ).toString();
    context.push(route);
  }

  Future<void> _showLobbyPlayersFriendSheet(
    DurakLobbyView lobby,
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
        messageReturnPath: '/games/durak/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }

  Widget _buildFriendsCard(
    DurakLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync, {
    bool expand = true,
  }) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: friendsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (snapshot) {
          final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
          final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
          final list =
              snapshot.friends.where((f) => !memberIds.contains(f.user.id)).toList();
          sortByPresenceOnlineFirst(list, (f) => f.user.id, presence);
          if (list.isEmpty) {
            final empty = Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.friendsEmpty,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
            return expand ? Center(child: empty) : empty;
          }
          return ListView.builder(
            key: const PageStorageKey('durak-lobby-friends'),
            padding: const EdgeInsets.only(bottom: 8),
            shrinkWrap: !expand,
            physics: expand
                ? const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];
              final id = f.user.id;
              final invited = _invited.contains(id);
              final declined = _declined.contains(id);
              final cancelling = _cancelling.contains(id);
              final inviting = _inviting.contains(id);
              final p = presence[id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _avatarSmall(f.user, isOnline: p?.online == true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (f.user.displayName?.trim().isNotEmpty ?? false)
                                ? f.user.displayName!
                                : 'Игрок',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            formatPresenceStatus(p),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: inviting || cancelling || declined
                          ? null
                          : invited
                              ? () => unawaited(_cancelInvite(id))
                              : () => unawaited(_invite(id)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentStart,
                        side: BorderSide(
                            color: AppColors.accentStart.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: (inviting || cancelling)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentStart,
                              ),
                            )
                          : Text(
                              declined
                                  ? context.l10n.lobbyInviteSentShort
                                  : invited
                                      ? context.l10n.commonCancel
                                      : context.l10n.lobbyInvite,
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
              strokeWidth: 2, color: AppColors.accentStart),
        ),
        error: (e, _) => Center(
          child: Text(
            formatUserError(e, fallback: 'Не удалось загрузить друзей'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _avatarSmall(FriendUserItem u, {required bool isOnline}) {
    Widget avatar;
    final displayName = u.displayName?.trim() ?? '';
    final letter = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    if (u.avatarKind == 'file' &&
        u.avatarValue != null &&
        u.avatarValue!.isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(u.avatarValue!);
      if (img != null) {
        avatar = CircleAvatar(radius: 20, backgroundImage: img);
      } else {
        avatar = CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentSoft,
          child: Text(letter,
              style: const TextStyle(
                color: AppColors.accentStart,
                fontWeight: FontWeight.bold,
              )),
        );
      }
    } else {
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.accentSoft,
        child: Text(letter,
            style: const TextStyle(
              color: AppColors.accentStart,
              fontWeight: FontWeight.bold,
            )),
      );
    }
    if (!isOnline) return avatar;
    return Stack(clipBehavior: Clip.none, children: [
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
    ]);
  }

}
