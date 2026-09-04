import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';
import 'package:multigames_client/ui/widgets/nardy_game_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

class NardyLobbyScreen extends ConsumerStatefulWidget {
  const NardyLobbyScreen({
    super.key,
    required this.lobbyId,
    this.initialMode,
  });

  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<NardyLobbyScreen> createState() => _NardyLobbyScreenState();
}

class _NardyLobbyScreenState extends ConsumerState<NardyLobbyScreen> {
  final Set<String> _invited = {};
  final Set<String> _declined = {};
  final Set<String> _inviting = {};
  final Set<String> _cancelling = {};
  bool _leaving = false;
  bool _linkCopied = false;
  bool _startingSearch = false;
  Timer? _linkTimer;

  /// Открыть свою игру для поиска: лобби становится публичным.
  Future<void> _startSearch() async {
    if (_startingSearch) return;
    setState(() => _startingSearch = true);
    try {
      await ref.read(nardyRepositoryProvider).startMatchmake(widget.lobbyId);
      if (!mounted) return;
      ref.invalidate(nardyLobbyProvider(widget.lobbyId));
      ref.invalidate(openLobbiesProvider);
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _startingSearch = false);
    }
  }

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
          .read(nardyRepositoryProvider)
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
      final repo = ref.read(nardyRepositoryProvider);
      try {
        await repo.inviteFriend(widget.lobbyId, friendId);
      } on GamesException catch (e) {
        if (e.statusCode != 404) rethrow;
        final lobby = ref.read(nardyLobbyProvider(widget.lobbyId)).valueOrNull;
        final created = await repo.createLobby(
          mode: 'invite',
          gameMode: lobby?.gameMode ?? nardyModeShort,
          turnTimeSec: lobby?.turnTimeSec ?? 0,
          stakeBronze: lobby?.stakeBronze ?? 2,
        );
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: created.lobbyId,
                gameType: 'nardy',
              ),
            );
        await repo.inviteFriend(created.lobbyId, friendId);
        if (!mounted) return;
        context.go('/games/nardy/lobby/${created.lobbyId}?mode=invite');
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
          .read(nardyRepositoryProvider)
          .cancelInvite(widget.lobbyId, friendId);
      if (!mounted) return;
      setState(() {
        _invited.remove(friendId);
        _cancelling.remove(friendId);
      });
    } on GamesException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling.remove(friendId));
      if (e.statusCode == 404 || e.statusCode == 400) {
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
      gameType: 'nardy',
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
    final lobbyAsync = ref.watch(nardyLobbyProvider(widget.lobbyId));
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

    ref.listen(nardyLobbyProvider(widget.lobbyId), (_, next) {
      final lobby = next.valueOrNull;
      final gameId = lobby?.gameId ?? '';
      if (gameId.isNotEmpty) context.go('/games/nardy/game/$gameId');
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
              NardyGameIcon(
                size: narrow ? 20 : 22,
                color: AppColors.accentStart,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.gamesNardy,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                  content: rulesTextLines(nardyRuleLines(
                    gameMode: lobby.gameMode,
                    turnTimeSec: lobby.turnTimeSec,
                    stakeBronze: lobby.stakeBronze,
                    l10n: context.l10n,
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
              data: (lobby) {
                if ((lobby.gameId ?? '').isNotEmpty) {
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
    NardyLobbyView lobby,
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
        listStorageKey: 'nardy-lobby-friends',
        expand: expand,
        onInvite: (id) => unawaited(_invite(id)),
        onCancel: (id) => unawaited(_cancelInvite(id)),
        profileReturnPath: '/games/nardy/lobby/${widget.lobbyId}?mode=invite',
      ),
    );
  }
}
