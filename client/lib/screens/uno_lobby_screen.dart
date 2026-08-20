import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show ActiveGameItem, GamesException;
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
      multiPlayersCard: LobbyMultiPlayersCard(
        players: lobby.players,
        playersCount: lobby.playerIds.length,
        maxPlayers: lobby.maxPlayers,
        currentUserId: ref.read(authStateProvider).valueOrNull?.id,
      ),
      shareLinkCard: LobbyShareLinkCard(
        title: context.l10n.lobbyCopyLink,
        hint: _linkCopied
            ? context.l10n.lobbyLinkCopiedHint
            : context.l10n.lobbyCopyLinkHint,
        copied: _linkCopied,
        onTap: _copyLink,
      ),
      friendsCardBuilder: (expand) =>
          _friendsCard(lobby, friendsAsync, expand: expand),
    );
  }

  Widget _friendsCard(
    UnoLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync, {
    required bool expand,
  }) {
    final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: friendsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (snapshot) {
          final friends = snapshot.friends
              .where((friend) => !memberIds.contains(friend.user.id))
              .toList();
          if (friends.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.friendsEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            key: const PageStorageKey('uno-lobby-friends'),
            shrinkWrap: !expand,
            physics: expand
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: friends.length,
            itemBuilder: (_, index) {
              final user = friends[index].user;
              final name = (user.displayName ?? '').trim();
              final invited = _invited.contains(user.id);
              final working =
                  _inviting.contains(user.id) || _cancelling.contains(user.id);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.accentStart),
                  ),
                ),
                title: Text(
                  name.isEmpty ? context.l10n.commonPlayer : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: working
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: invited
                            ? () => _cancelInvite(user.id)
                            : () => _invite(user.id),
                        child: Text(
                          invited
                              ? context.l10n.commonCancel
                              : context.l10n.lobbyInvite,
                        ),
                      ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (error, _) => Text(
          formatUserError(error),
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
