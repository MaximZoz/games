import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

class BattleshipLobbyScreen extends ConsumerStatefulWidget {
  const BattleshipLobbyScreen({
    super.key,
    required this.lobbyId,
    this.initialMode,
  });

  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<BattleshipLobbyScreen> createState() =>
      _BattleshipLobbyScreenState();
}

class _BattleshipLobbyScreenState extends ConsumerState<BattleshipLobbyScreen> {
  final Set<String> _invited = {};
  final Set<String> _declined = {};
  final Set<String> _inviting = {};
  final Set<String> _cancelling = {};
  bool _leaving = false;
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
          .read(battleshipRepositoryProvider)
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
      final repo = ref.read(battleshipRepositoryProvider);
      var lobbyId = widget.lobbyId;
      try {
        await repo.inviteFriend(lobbyId, friendId);
      } on GamesException catch (e) {
        if (e.statusCode != 404) rethrow;
        final lobby =
            ref.read(battleshipLobbyProvider(widget.lobbyId)).valueOrNull;
        final created = await repo.createLobby(
          mode: 'invite',
          turnTimeSec: lobby?.turnTimeSec ?? 0,
          stakeBronze: lobby?.stakeBronze ?? 2,
          firstMoveRestriction: lobby?.firstMoveRestriction ?? false,
        );
        lobbyId = created.lobbyId;
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'battleship',
              ),
            );
        await repo.inviteFriend(lobbyId, friendId);
        if (!mounted) return;
        context.go('/games/battleship/lobby/$lobbyId?mode=invite');
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
          .read(battleshipRepositoryProvider)
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
      baseUri: Uri.base,
      gameType: 'battleship',
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
    final lobbyAsync = ref.watch(battleshipLobbyProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final narrow = isNarrow(context);

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

    ref.listen(battleshipLobbyProvider(widget.lobbyId), (_, next) {
      final lobby = next.valueOrNull;
      if (lobby?.gameId != null && lobby!.gameId!.isNotEmpty) {
        context.go('/games/battleship/game/${lobby.gameId}');
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
              Icon(
                Icons.directions_boat_filled_rounded,
                size: narrow ? 20 : 22,
                color: AppColors.accentStart,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.gamesBattleship,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                  title: context.l10n.rulesBattleshipTitle,
                  content: Text(context.l10n.rulesBattleshipBody),
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
              data: (lobby) {
                if (lobby.gameId != null && lobby.gameId!.isNotEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentStart,
                    ),
                  );
                }
                return _buildBody(lobby, friendsAsync, isMatchmake);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentStart,
                ),
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
    BattleshipLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
    bool isMatchmake,
  ) {
    final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
    final friendsCount = friendsAsync.valueOrNull?.friends
            .where((f) => !memberIds.contains(f.user.id))
            .length ??
        0;
    final pad = isNarrow(context) ? 16.0 : 24.0;

    return GameLobbyWaitingLayout(
      maxPlayers: 2,
      stakeBronze: lobby.stakeBronze,
      stakeLabel: context.l10n.shopStakes,
      friendsCount: friendsCount,
      padding: EdgeInsets.all(pad),
      searchBanner: isMatchmake
          ? LobbySearchBanner(label: context.l10n.lobbySearchingOpponent)
          : null,
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

  Widget _buildFriendsCard(
    BattleshipLobbyView lobby,
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
          final presence =
              ref.watch(presenceMapProvider).valueOrNull ?? const {};
          final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
          final list = snapshot.friends
              .where((f) => !memberIds.contains(f.user.id))
              .toList();
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
            key: const PageStorageKey('battleship-lobby-friends'),
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
                                : context.l10n.commonPlayer,
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
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            formatUserError(e, fallback: context.l10n.friendsLoadFailed),
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
          child: Text(
            letter,
            style: const TextStyle(
              color: AppColors.accentStart,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    } else {
      avatar = CircleAvatar(
        radius: 20,
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
}
