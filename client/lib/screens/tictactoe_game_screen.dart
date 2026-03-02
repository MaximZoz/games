import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/router.dart';

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

class TicTacToeGameScreen extends ConsumerStatefulWidget {
  const TicTacToeGameScreen({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  ConsumerState<TicTacToeGameScreen> createState() =>
      _TicTacToeGameScreenState();
}

class _TicTacToeGameScreenState extends ConsumerState<TicTacToeGameScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  bool _isMakingMove = false;
  bool _isRematching = false;
  bool _isAcceptingRematch = false;
  String? _rematchLobbyId;
  bool _rematchDeclined = false;
  bool _iDeclinedRematch = false;
  bool _isFindingGame = false;
  Timer? _rematchPollTimer;
  Timer? _syncStateTimer;
  Timer? _chatsRefreshTimer;
  late AnimationController _pulseController;
  String? _prevGameStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      chatsRouteObserver.unsubscribe(this);
      chatsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (mounted) refreshChatsList(ref, force: true);
  }

  @override
  void didUpdateWidget(covariant TicTacToeGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _rematchPollTimer?.cancel();
      _prevGameStatus = null;
      ref.invalidate(gameStateProvider(widget.gameId));
      setState(() {
        _rematchLobbyId = null;
        _rematchDeclined = false;
        _iDeclinedRematch = false;
        _isRematching = false;
        _isAcceptingRematch = false;
        _isFindingGame = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    ref.invalidate(gameStateProvider(widget.gameId));
    ref.invalidate(activeGameProvider);
    _syncStateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      ref.invalidate(gameStateProvider(widget.gameId));
      ref.invalidate(activeGameProvider);
    });
    Timer(const Duration(seconds: 8), () {
      _syncStateTimer?.cancel();
      _syncStateTimer = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
    _chatsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
    ref.listen(
      realtimeEventsProvider,
      (_, next) {
        final type = next.valueOrNull?['type']?.toString() ?? '';
        if (type == 'game_state' &&
            next.valueOrNull?['game_id'] == widget.gameId) {
          ref.invalidate(gameStateProvider(widget.gameId));
        }
        if (type == 'lobby_updated' && _rematchLobbyId != null) {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          final gameId = next.valueOrNull?['game_id']?.toString();
          if (lobbyId == _rematchLobbyId && gameId != null && mounted) {
            ref.invalidate(gameStateProvider(gameId));
            ref.invalidate(activeGameProvider);
            context.go('/games/tictactoe/game/$gameId');
          }
        }
        if (type == 'invite_declined') {
          final lobbyId = next.valueOrNull?['lobby_id']?.toString();
          if (lobbyId == _rematchLobbyId && mounted) {
            _rematchPollTimer?.cancel();
            setState(() {
              _rematchLobbyId = null;
              _rematchDeclined = true;
            });
          }
        }
        if (type == 'chat_message' || type == 'chat_list_changed') {
          if (mounted) refreshChatsList(ref, force: true);
        }
      },
    );
  }

  void _startRematchPoll() {
    _rematchPollTimer?.cancel();
    if (_rematchLobbyId == null) return;
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_rematchLobbyId == null || !mounted) return;
      ref.invalidate(activeGameProvider);
      try {
        final lobby =
            await ref.read(gamesRepositoryProvider).getLobby(_rematchLobbyId!);
        if (!mounted) return;
        if (lobby.gameId != null && lobby.gameId!.isNotEmpty) {
          _rematchPollTimer?.cancel();
          final gameId = lobby.gameId!;
          ref.invalidate(gameStateProvider(gameId));
          context.go('/games/tictactoe/game/$gameId');
        }
      } on GamesException catch (e) {
        if (e.statusCode == 404 && mounted) {
          _rematchPollTimer?.cancel();
          setState(() => _rematchLobbyId = null);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    chatsRouteObserver.unsubscribe(this);
    _rematchPollTimer?.cancel();
    _syncStateTimer?.cancel();
    _chatsRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameStateProvider(widget.gameId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final activeGame = ref.watch(activeGameProvider).valueOrNull;

    ref.listen(gameStateProvider(widget.gameId), (_, next) {
      next.whenOrNull(
        error: (_, __) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/games');
        }),
      );
    });
    ref.listen(activeGameProvider, (_, next) {
      final active = next.valueOrNull;
      if (active == null || active.type != 'game' || active.gameId == null)
        return;
      if (active.gameId != widget.gameId) {
        if (_rematchLobbyId == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(gameStateProvider(active.gameId!));
            context.go('/games/tictactoe/game/${active.gameId}');
          }
        });
        return;
      }
      final game = ref.read(gameStateProvider(widget.gameId)).valueOrNull;
      if (game == null || game.status != 'active') return;
      final isMyTurnFromGame =
          (game.turn == 'x' && game.xUserId == currentUser?.id) ||
              (game.turn == 'o' && game.oUserId == currentUser?.id);
      if (active.isMyTurn != isMyTurnFromGame) {
        ref.invalidate(gameStateProvider(widget.gameId));
      }
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => _handleClose(gameAsync.valueOrNull),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Крестики-нолики'),
      ),
      body: gameAsync.when(
        data: (game) {
          final isOver = game.status != 'active';
          final opponentId =
              game.xUserId == currentUser?.id ? game.oUserId : game.xUserId;
          if (isOver &&
              (_prevGameStatus == 'active' || _prevGameStatus == null)) {
            _rematchPollTimer?.cancel();
            _prevGameStatus = game.status;
            if (currentUser != null) {
              ref
                  .read(gameInvitesProvider.notifier)
                  .removeByCreatorId(opponentId);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _rematchLobbyId = null;
                  _rematchDeclined = false;
                  _iDeclinedRematch = false;
                  _isRematching = false;
                  _isFindingGame = false;
                });
              }
            });
          } else {
            _prevGameStatus = game.status;
          }
          final isMyTurnFromGame =
              (game.turn == 'x' && game.xUserId == currentUser?.id) ||
                  (game.turn == 'o' && game.oUserId == currentUser?.id);
          final isMyTurn = (activeGame != null &&
                  activeGame.type == 'game' &&
                  activeGame.gameId == widget.gameId)
              ? activeGame.isMyTurn
              : isMyTurnFromGame;
          final opponentName = game.xUserId == currentUser?.id
              ? (game.oDisplayName ?? 'Соперник')
              : (game.xDisplayName ?? 'Соперник');
          final opponentAvatarKind = game.xUserId == currentUser?.id
              ? game.oAvatarKind
              : game.xAvatarKind;
          final opponentAvatarValue = game.xUserId == currentUser?.id
              ? game.oAvatarValue
              : game.xAvatarValue;

          String statusText = '';
          if (isOver) {
            if (game.status == 'x_won') {
              final iWon = game.xUserId == currentUser?.id;
              statusText = iWon
                  ? (game.forfeit
                      ? 'Вы победили, соперник вышел'
                      : 'Вы победили!')
                  : 'Победил $opponentName';
            } else if (game.status == 'o_won') {
              final iWon = game.oUserId == currentUser?.id;
              statusText = iWon
                  ? (game.forfeit
                      ? 'Вы победили, соперник вышел'
                      : 'Вы победили!')
                  : 'Победил $opponentName';
            } else if (game.status == 'draw') {
              statusText = 'Ничья';
            }
          } else {
            statusText = isMyTurn ? 'Ваш ход' : 'Ход соперника';
          }

          final isDesktop = isWide(context);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isDesktop
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _OpponentCard(
                          opponentId: opponentId,
                          displayName: opponentName,
                          avatarKind: opponentAvatarKind,
                          avatarValue: opponentAvatarValue,
                          friendsSnapshot:
                              ref.watch(friendsSnapshotProvider).valueOrNull,
                          chatsList: ref.watch(chatsListProvider).valueOrNull ??
                              const [],
                          onInfoTap: () => _showOpponentInfo(
                            context,
                            opponentId: opponentId,
                            displayName: opponentName,
                            avatarKind: opponentAvatarKind,
                            avatarValue: opponentAvatarValue,
                          ),
                          onMessageTap: () =>
                              _openChat(context, opponentId, opponentName),
                          onAddFriendTap: (requestId) => _addFriend(
                              context, opponentId, opponentName,
                              requestId: requestId),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          statusText,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        if (isOver) ...[
                          const SizedBox(height: 16),
                          _RematchSection(
                            rematchLobbyId: _rematchLobbyId,
                            rematchDeclined: _rematchDeclined,
                            iDeclinedRematch: _iDeclinedRematch,
                            isRematching: _isRematching,
                            isAcceptingRematch: _isAcceptingRematch,
                            isFindingGame: _isFindingGame,
                            opponentId: opponentId,
                            invites: ref.watch(gameInvitesProvider),
                            onRematch: () => _rematch(context),
                            onAccept: _acceptRematch,
                            onDecline: _declineRematch,
                            onCancelWait: _cancelRematchWait,
                            onFindGame: () => _findGame(context),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Expanded(
                          child: Center(
                            child: _GameBoard(
                              game: game,
                              isMyTurn: isMyTurn,
                              isOver: isOver,
                              isMakingMove: _isMakingMove,
                              onMove: _makeMove,
                              pulseController: _pulseController,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OpponentCard(
                            opponentId: opponentId,
                            displayName: opponentName,
                            avatarKind: opponentAvatarKind,
                            avatarValue: opponentAvatarValue,
                            friendsSnapshot:
                                ref.watch(friendsSnapshotProvider).valueOrNull,
                            chatsList:
                                ref.watch(chatsListProvider).valueOrNull ??
                                    const [],
                            onInfoTap: () => _showOpponentInfo(
                              context,
                              opponentId: opponentId,
                              displayName: opponentName,
                              avatarKind: opponentAvatarKind,
                              avatarValue: opponentAvatarValue,
                            ),
                            onMessageTap: () =>
                                _openChat(context, opponentId, opponentName),
                            onAddFriendTap: (requestId) => _addFriend(
                                context, opponentId, opponentName,
                                requestId: requestId),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            statusText,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          if (isOver) ...[
                            const SizedBox(height: 16),
                            _RematchSection(
                              rematchLobbyId: _rematchLobbyId,
                              rematchDeclined: _rematchDeclined,
                              iDeclinedRematch: _iDeclinedRematch,
                              isRematching: _isRematching,
                              isAcceptingRematch: _isAcceptingRematch,
                              isFindingGame: _isFindingGame,
                              opponentId: opponentId,
                              invites: ref.watch(gameInvitesProvider),
                              onRematch: () => _rematch(context),
                              onAccept: _acceptRematch,
                              onDecline: _declineRematch,
                              onCancelWait: _cancelRematchWait,
                              onFindGame: () => _findGame(context),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _GameBoard(
                            game: game,
                            isMyTurn: isMyTurn,
                            isOver: isOver,
                            isMakingMove: _isMakingMove,
                            onMove: _makeMove,
                            pulseController: _pulseController,
                          ),
                        ],
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
        error: (_, __) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
      ),
    );
  }

  Future<void> _rematch(BuildContext context) async {
    setState(() => _isRematching = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.rematch(widget.gameId);
      if (!mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.matched &&
          result.gameId != null &&
          result.gameId!.isNotEmpty) {
        setState(() => _isRematching = false);
        final gameId = result.gameId!;
        ref.invalidate(gameStateProvider(gameId));
        if (!mounted) return;
        context.go('/games/tictactoe/game/$gameId');
      } else {
        setState(() {
          _rematchLobbyId = result.lobbyId;
          _rematchDeclined = false;
          _iDeclinedRematch = false;
          _isRematching = false;
        });
        _startRematchPoll();
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
      if (mounted) setState(() => _isRematching = false);
    }
  }

  Future<void> _acceptRematch(String lobbyId) async {
    if (_isAcceptingRematch) return;
    setState(() => _isAcceptingRematch = true);
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      final result = await ref.read(gamesRepositoryProvider).joinLobby(lobbyId);
      if (!mounted) return;
      if (result.joined && result.gameId != null) {
        final gameId = result.gameId!;
        ref.invalidate(gameStateProvider(gameId));
        if (!mounted) return;
        context.go('/games/tictactoe/game/$gameId');
      }
    } on GamesException catch (e) {
      // 409 = одновременный реванш: соперник уже принял наше приглашение, игра создана
      if (e.statusCode == 409 && mounted) {
        ref.invalidate(activeGameProvider);
        ref.read(activeGameProvider.future).then((active) {
          if (active?.type == 'game' && active?.gameId != null && mounted) {
            context.go('/games/tictactoe/game/${active!.gameId}');
          } else if (mounted) {
            _redirectToGamesOnError();
          }
        });
      } else if (mounted) {
        _redirectToGamesOnError();
      }
    } catch (_) {
      if (mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isAcceptingRematch = false);
    }
  }

  Future<void> _declineRematch(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      await ref.read(gamesRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {}
    if (mounted) setState(() => _iDeclinedRematch = true);
  }

  Future<void> _cancelRematchWait() async {
    if (_rematchLobbyId == null) return;
    _rematchPollTimer?.cancel();
    final lobbyId = _rematchLobbyId!;
    setState(() => _rematchLobbyId = null);
    try {
      await ref.read(gamesRepositoryProvider).leaveLobby(lobbyId);
    } catch (_) {}
  }

  Future<void> _findGame(BuildContext context) async {
    setState(() => _isFindingGame = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.createLobby(mode: 'matchmake');
      if (!mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.matched && result.gameId != null) {
        context.go('/games/tictactoe/game/${result.gameId}');
      } else {
        context.go('/games/tictactoe/lobby/${result.lobbyId}');
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isFindingGame = false);
    }
  }

  void _redirectToGamesOnError() {
    if (mounted) context.go('/games');
  }

  void _handleClose(GameStateItem? game) async {
    final isOver = game?.status != 'active';
    if (isOver) {
      if (_rematchLobbyId != null) {
        try {
          await ref.read(gamesRepositoryProvider).leaveLobby(_rematchLobbyId!);
        } catch (_) {}
      }
      if (mounted) context.go('/games');
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выход из игры'),
        content: const Text(
          'Если вы выйдете, то вы проиграете. Выйти?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    ).then((exit) async {
      if (exit != true || !mounted) return;
      try {
        await ref.read(gamesRepositoryProvider).forfeitGame(widget.gameId);
        if (mounted) {
          ref.invalidate(gameStateProvider(widget.gameId));
          ref.invalidate(activeGameProvider);
          context.go('/games');
        }
      } catch (e) {
        if (mounted) _redirectToGamesOnError();
      }
    });
  }

  void _showOpponentInfo(
    BuildContext context, {
    required String opponentId,
    required String displayName,
    required String avatarKind,
    required String? avatarValue,
  }) {
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
                final friendsSnapshot =
                    ref.watch(friendsSnapshotProvider).valueOrNull;
                final presence =
                    ref.watch(presenceMapProvider).valueOrNull ?? const {};
                FriendItem? friendItem;
                for (final f in friendsSnapshot?.friends ?? []) {
                  if (f.user.id == opponentId) {
                    friendItem = f;
                    break;
                  }
                }
                final friendUser = friendItem?.user;
                final presenceEntry = presence[opponentId];
                final statusText = presenceEntry == null
                    ? null
                    : (presenceEntry.online
                        ? 'Онлайн'
                        : formatLastSeen(presenceEntry.lastSeenAt));
                final about = friendUser?.about?.trim();
                final genderIcon = _genderIcon(friendUser?.gender);
                final female = _isFemaleGender(friendUser?.gender);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOpponentAvatar(
                          friendUser?.avatarKind ?? avatarKind,
                          friendUser?.avatarValue ?? avatarValue,
                          friendUser?.displayName ?? displayName,
                          22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                friendUser?.displayName?.trim().isNotEmpty ==
                                        true
                                    ? friendUser!.displayName!
                                    : displayName,
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
                          tooltip: 'Закрыть',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    if ((friendUser?.age != null && friendUser!.age! > 0) ||
                        genderIcon != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (friendUser?.age != null && friendUser!.age! > 0)
                            _buildInfoPill(
                              text: '${friendUser.age} лет',
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
                      const Text(
                        'О себе',
                        style: TextStyle(
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addFriend(
    BuildContext ctx,
    String userId,
    String displayName, {
    String? requestId,
    void Function()? onSuccess,
  }) async {
    try {
      if (requestId != null && requestId.isNotEmpty) {
        await ref.read(friendsRepositoryProvider).acceptRequest(requestId);
        if (!mounted) return;
        onSuccess?.call();
        ref.invalidate(friendsSnapshotProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Заявка принята')),
          );
        }
      } else {
        await ref.read(friendsRepositoryProvider).sendRequest(userId);
        if (!mounted) return;
        onSuccess?.call();
        ref.invalidate(friendsSnapshotProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Запрос отправлен')),
          );
        }
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    }
  }

  Future<void> _openChat(
    BuildContext ctx,
    String userId,
    String displayName, {
    void Function()? onSuccess,
  }) async {
    try {
      final chatId = await ref.read(chatsRepositoryProvider).startChat(userId);
      if (!mounted) return;
      onSuccess?.call();
      if (mounted && chatId.isNotEmpty) {
        final uri = Uri(
          path: '/chats/$chatId',
          queryParameters: {
            'name': displayName,
            'from': 'games',
            'game': '/games/tictactoe/game/${widget.gameId}',
          },
        );
        context.push(uri.toString());
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    }
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

  Widget _buildOpponentAvatar(
    String avatarKind,
    String? avatarValue,
    String displayName,
    double radius,
  ) {
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      if (img != null) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: img,
        );
      }
    }
    if (avatarKind == 'preset' && avatarValue != null) {
      final idx = int.tryParse(avatarValue);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      }
    }
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
    );
  }

  Future<void> _makeMove(int cell) async {
    setState(() => _isMakingMove = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      await repo.makeMove(widget.gameId, cell);
      if (mounted) {
        ref.invalidate(gameStateProvider(widget.gameId));
        ref.invalidate(activeGameProvider);
      }
    } catch (e) {
      if (mounted) _redirectToGamesOnError();
    } finally {
      if (mounted) setState(() => _isMakingMove = false);
    }
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final btn = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accentStart,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(size, size),
        fixedSize: const Size(size, size),
      ),
    );
    if (badge <= 0) return SizedBox(width: size, height: size, child: btn);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          btn,
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RematchSection extends StatelessWidget {
  const _RematchSection({
    required this.rematchLobbyId,
    required this.rematchDeclined,
    required this.iDeclinedRematch,
    required this.isRematching,
    required this.isAcceptingRematch,
    required this.isFindingGame,
    required this.opponentId,
    required this.invites,
    required this.onRematch,
    required this.onAccept,
    required this.onDecline,
    required this.onCancelWait,
    required this.onFindGame,
  });

  final String? rematchLobbyId;
  final bool rematchDeclined;
  final bool iDeclinedRematch;
  final bool isRematching;
  final bool isAcceptingRematch;
  final bool isFindingGame;
  final String opponentId;
  final List<GameInvite> invites;
  final VoidCallback onRematch;
  final void Function(String lobbyId) onAccept;
  final void Function(String lobbyId) onDecline;
  final VoidCallback? onCancelWait;
  final VoidCallback onFindGame;

  @override
  Widget build(BuildContext context) {
    final rematchOffer =
        invites.where((i) => i.creatorId == opponentId).firstOrNull;

    // После нажатия «Принять» показываем часики до перехода в игру
    if (isAcceptingRematch) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 20, color: AppColors.accentStart),
          const SizedBox(width: 8),
          Text(
            'Подключение к игре...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    // Приглашение соперника показываем всегда, даже если ранее отклоняли — новое предложение.
    if (rematchOffer != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Соперник предлагает реванш',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => onDecline(rematchOffer.lobbyId),
                child: const Text('Отклонить'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => onAccept(rematchOffer.lobbyId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentStart,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Принять'),
              ),
            ],
          ),
        ],
      );
    }
    if (iDeclinedRematch) {
      return _buildRematchButtons(
        isRematching: isRematching,
        isFindingGame: isFindingGame,
        onRematch: onRematch,
        onFindGame: onFindGame,
      );
    }
    if (rematchDeclined) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Соперник отклонил предложение поиграть',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildRematchButtons(
            isRematching: isRematching,
            isFindingGame: isFindingGame,
            onRematch: onRematch,
            onFindGame: onFindGame,
          ),
        ],
      );
    }
    if (rematchLobbyId != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: 20, color: AppColors.accentStart),
              const SizedBox(width: 8),
              Text(
                'Ожидание соперника',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (onCancelWait != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onCancelWait,
              child: const Text('Отмена'),
            ),
          ],
        ],
      );
    }
    return _buildRematchButtons(
      isRematching: isRematching,
      isFindingGame: isFindingGame,
      onRematch: onRematch,
      onFindGame: onFindGame,
    );
  }

  Widget _buildRematchButtons({
    required bool isRematching,
    required bool isFindingGame,
    required VoidCallback onRematch,
    required VoidCallback onFindGame,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: isRematching ? null : onRematch,
          icon: isRematching
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.replay_rounded, size: 20),
          label: Text(isRematching ? 'Создание...' : 'Сыграть ещё раз'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isFindingGame ? null : onFindGame,
          icon: isFindingGame
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search_rounded, size: 20),
          label: Text(isFindingGame ? 'Поиск...' : 'Найти другую игру'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentStart,
            side: BorderSide(color: AppColors.accentStart),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponentId,
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
    required this.friendsSnapshot,
    required this.chatsList,
    required this.onInfoTap,
    required this.onMessageTap,
    required this.onAddFriendTap,
  });

  final String opponentId;
  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final FriendsSnapshot? friendsSnapshot;
  final List<ChatPreviewItem> chatsList;
  final VoidCallback onInfoTap;
  final VoidCallback onMessageTap;
  final void Function(String? requestId) onAddFriendTap;

  @override
  Widget build(BuildContext context) {
    final isFriend =
        friendsSnapshot?.friends.any((f) => f.user.id == opponentId) == true;
    final outgoing = friendsSnapshot?.outgoing
            .where((r) => r.user.id == opponentId)
            .toList() ??
        [];
    final incoming = friendsSnapshot?.incoming
            .where((r) => r.user.id == opponentId)
            .toList() ??
        [];
    final hasOutgoing = outgoing.isNotEmpty;
    final hasIncoming = incoming.isNotEmpty;
    final incomingRequestId = hasIncoming ? incoming.first.requestId : null;
    final addFriendEnabled = !hasOutgoing;
    final messageBadge = chatsList
        .where((c) => c.user.id == opponentId)
        .map((c) => c.unreadCount)
        .fold<int>(0, (a, b) => a + b);

    final card = GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.zero,
      animate: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _OpponentAvatar(
            displayName: displayName,
            avatarKind: avatarKind,
            avatarValue: avatarValue,
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _IconWithBadge(
            icon: Icons.chat_bubble_outline_rounded,
            badge: messageBadge,
            tooltip: 'Написать сообщение',
            onPressed: onMessageTap,
          ),
          if (!isFriend)
            _IconWithBadge(
              icon: Icons.person_add_alt_1_rounded,
              badge: hasIncoming ? 1 : 0,
              tooltip: hasIncoming
                  ? 'Принять заявку'
                  : (addFriendEnabled
                      ? 'Добавить в друзья'
                      : 'Заявка отправлена'),
              onPressed: addFriendEnabled
                  ? () => onAddFriendTap(hasIncoming ? incomingRequestId : null)
                  : null,
            ),
          _IconWithBadge(
            icon: Icons.info_outline_rounded,
            tooltip: 'Информация о пользователе',
            onPressed: onInfoTap,
          ),
        ],
      ),
    );
    if (isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: card,
        ),
      );
    }
    return card;
  }
}

class _OpponentAvatar extends StatelessWidget {
  const _OpponentAvatar({
    required this.displayName,
    required this.avatarKind,
    required this.avatarValue,
  });

  final String displayName;
  final String avatarKind;
  final String? avatarValue;

  @override
  Widget build(BuildContext context) {
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      if (img != null) {
        return CircleAvatar(
          radius: 22,
          backgroundImage: img,
        );
      }
    }
    if (avatarKind == 'preset' && avatarValue != null) {
      final idx = int.tryParse(avatarValue!);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      }
    }
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({
    required this.game,
    required this.isMyTurn,
    required this.isOver,
    required this.isMakingMove,
    required this.onMove,
    required this.pulseController,
  });

  final GameStateItem game;
  final bool isMyTurn;
  final bool isOver;
  final bool isMakingMove;
  final ValueChanged<int> onMove;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStart.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: Offset.zero,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset.zero,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _GridPainter(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellW = constraints.maxWidth / 3;
                    final cellH = constraints.maxHeight / 3;
                    return Stack(
                      children: List.generate(9, (i) {
                        final row = i ~/ 3;
                        final col = i % 3;
                        final cell = game.board[i];
                        return Positioned(
                          left: col * cellW + 4,
                          top: row * cellH + 4,
                          width: cellW - 8,
                          height: cellH - 8,
                          child: _AnimatedGameCell(
                            symbol: cell,
                            isMyTurn: isMyTurn && !isOver && !isMakingMove,
                            canTap: cell.isEmpty,
                            onTap: () => (cell.isEmpty &&
                                    isMyTurn &&
                                    !isOver &&
                                    !isMakingMove)
                                ? onMove(i)
                                : null,
                            pulse: isMyTurn && cell.isEmpty
                                ? pulseController
                                : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentSoft.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final thirdW = w / 3;
    final thirdH = h / 3;

    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(thirdW * i, 0),
        Offset(thirdW * i, h),
        paint,
      );
      canvas.drawLine(
        Offset(0, thirdH * i),
        Offset(w, thirdH * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedGameCell extends StatelessWidget {
  const _AnimatedGameCell({
    required this.symbol,
    required this.isMyTurn,
    required this.canTap,
    this.onTap,
    this.pulse,
  });

  final String symbol;
  final bool isMyTurn;
  final bool canTap;
  final VoidCallback? onTap;
  final AnimationController? pulse;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.short,
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Transform.scale(
          scale: symbol.isNotEmpty ? t : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: canTap && isMyTurn
                      ? AppColors.accentSoft.withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
                child: pulse != null && canTap && isMyTurn
                    ? AnimatedBuilder(
                        animation: pulse!,
                        builder: (context, _) {
                          final alpha = 0.2 +
                              0.12 * (0.5 + 0.5 * (pulse!.value * 2 - 1).abs());
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: AppColors.accentStart
                                  .withValues(alpha: alpha),
                            ),
                            child: Center(
                              child: _SymbolWidget(symbol: symbol),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: _SymbolWidget(symbol: symbol),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SymbolWidget extends StatelessWidget {
  const _SymbolWidget({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (symbol.isEmpty) return const SizedBox.shrink();
    final isX = symbol == 'x';
    final color = isX ? AppColors.accentStart : AppColors.accentEnd;
    return AnimatedSwitcher(
      duration: AppDurations.short,
      child: CustomPaint(
        key: ValueKey(symbol),
        size: const Size.square(42),
        painter: _SymbolPainter(isX: isX, color: color),
      ),
    );
  }
}

/// Рисует X и O через Canvas — без шрифтов, чтобы не было placeholder при загрузке.
class _SymbolPainter extends CustomPainter {
  _SymbolPainter({required this.isX, required this.color});

  final bool isX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isX) {
      final padding = size.width * 0.15;
      canvas.drawLine(
        Offset(padding, padding),
        Offset(size.width - padding, size.height - padding),
        paint,
      );
      canvas.drawLine(
        Offset(size.width - padding, padding),
        Offset(padding, size.height - padding),
        paint,
      );
    } else {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - strokeWidth) / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter old) =>
      old.isX != isX || old.color != color;
}
