import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

enum _GamesTab { games, lobbies }

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _isCreating = false;
  bool _isFinding = false;
  _GamesTab _selectedTab = _GamesTab.games;
  int _selectedTurnTimeSec = 0; // 0=без лимита, 10, 30, 60, 600
  int _selectedGridSize = 3; // 3, 4, 5
  Timer? _lobbyRefreshTimer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopLobbyPoll();
    super.dispose();
  }

  void _startLobbyPoll() {
    _lobbyRefreshTimer?.cancel();
    _lobbyRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => ref.invalidate(openLobbiesProvider),
    );
  }

  void _stopLobbyPoll() {
    _lobbyRefreshTimer?.cancel();
    _lobbyRefreshTimer = null;
  }

  void _onTabChanged(_GamesTab tab) {
    setState(() => _selectedTab = tab);
    _pageController.animateToPage(
      tab == _GamesTab.games ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    if (tab == _GamesTab.lobbies) {
      ref.invalidate(openLobbiesProvider);
      _startLobbyPoll();
    } else {
      _stopLobbyPoll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobbiesAsync = ref.watch(openLobbiesProvider);
    final invites = ref.watch(gameInvitesProvider);
    final activeAsync = ref.watch(activeGameProvider);

    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final contentPadding = isMedium ? 20.0 : (isDesktop ? 32.0 : 24.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _GamesTabSwitcher(
                    selectedTab: _selectedTab,
                    onTabChanged: _onTabChanged,
                  ),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 28 : 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  final tab = index == 0 ? _GamesTab.games : _GamesTab.lobbies;
                  if (tab != _selectedTab) {
                    setState(() => _selectedTab = tab);
                    if (tab == _GamesTab.lobbies) {
                      ref.invalidate(openLobbiesProvider);
                      _startLobbyPoll();
                    } else {
                      _stopLobbyPoll();
                    }
                  }
                },
                children: [
                  _GamesPageContent(
                    isDesktop: isDesktop,
                    isCreating: _isCreating,
                    isFinding: _isFinding,
                    turnTimeSec: _selectedTurnTimeSec,
                    onTurnTimeChanged: (v) => setState(() => _selectedTurnTimeSec = v),
                    gridSize: _selectedGridSize,
                    onGridSizeChanged: (v) => setState(() => _selectedGridSize = v),
                    onCreateGame: () => _createGame(context, 'invite'),
                    onFindGame: () => _createGame(context, 'matchmake'),
                    invites: invites,
                    activeAsync: activeAsync,
                    onAcceptInvite: _acceptInvite,
                    onDeclineInvite: _declineInvite,
                    onShowCreatorInfo: _showCreatorInfo,
                    contentPadding: contentPadding,
                  ),
                  _LobbiesPageContent(
                    lobbiesAsync: lobbiesAsync,
                    isDesktop: isDesktop,
                    onJoinLobby: _joinLobby,
                    contentPadding: contentPadding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGame(BuildContext context, String mode) async {
    setState(() {
      if (mode == 'invite') {
        _isCreating = true;
      } else {
        _isFinding = true;
      }
    });
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.createLobby(
        mode: mode,
        turnTimeSec: _selectedTurnTimeSec,
        gridSize: _selectedGridSize,
      );
      if (!context.mounted) return;
      if (result.matched && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      } else {
        context.push('/games/tictactoe/lobby/${result.lobbyId}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserError(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _isFinding = false;
        });
      }
    }
  }

  Future<void> _acceptInvite(BuildContext context, String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      if (!context.mounted) return;
      if (result.joined && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserError(e))),
        );
      }
    }
  }

  void _showCreatorInfo(BuildContext context, GameInvite inv) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        backgroundColor: Colors.transparent,
        child: Consumer(
          builder: (context, ref, _) {
            final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
            final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
            FriendUserItem? user;
            for (final f in snapshot?.friends ?? []) {
              if (f.user.id == inv.creatorId) {
                user = f.user;
                break;
              }
            }
            if (user == null) {
              for (final r in snapshot?.incoming ?? []) {
                if (r.user.id == inv.creatorId) {
                  user = r.user;
                  break;
                }
              }
            }
            if (user == null) {
              for (final r in snapshot?.outgoing ?? []) {
                if (r.user.id == inv.creatorId) {
                  user = r.user;
                  break;
                }
              }
            }
            final p = presence[inv.creatorId];
            final statusText = p == null
                ? null
                : (p.online ? 'Онлайн' : formatLastSeen(p.lastSeenAt));
            final name = user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!
                : inv.creatorName;
            final about = user?.about?.trim();
            return GradientCard(
              animate: false,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.accentSoft,
                        child: Text(
                          (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accentStart,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
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
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _declineInvite(String lobbyId) {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
  }

  Future<void> _joinLobby(BuildContext context, String lobbyId) async {
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      if (!context.mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.joined && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserError(e))),
        );
      }
    }
  }
}

class _GamesPageContent extends StatelessWidget {
  const _GamesPageContent({
    required this.isDesktop,
    required this.isCreating,
    required this.isFinding,
    required this.turnTimeSec,
    required this.onTurnTimeChanged,
    required this.gridSize,
    required this.onGridSizeChanged,
    required this.onCreateGame,
    required this.onFindGame,
    required this.invites,
    required this.activeAsync,
    required this.onAcceptInvite,
    required this.onDeclineInvite,
    required this.onShowCreatorInfo,
    required this.contentPadding,
  });

  final bool isDesktop;
  final bool isCreating;
  final bool isFinding;
  final int turnTimeSec;
  final void Function(int) onTurnTimeChanged;
  final int gridSize;
  final void Function(int) onGridSizeChanged;
  final VoidCallback onCreateGame;
  final VoidCallback onFindGame;
  final List<GameInvite> invites;
  final AsyncValue<ActiveGameItem?> activeAsync;
  final void Function(BuildContext, String) onAcceptInvite;
  final void Function(String) onDeclineInvite;
  final void Function(BuildContext, GameInvite) onShowCreatorInfo;
  final double contentPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (isDesktop) {
                final width = constraints.maxWidth;
                const minCardWidth = 320.0;
                const gap = 16.0;
                const gameCards = 1;
                final crossAxisCount = (width / (minCardWidth + gap)).floor().clamp(1, 4);
                final effectiveCount = crossAxisCount > gameCards ? gameCards : crossAxisCount;
                final maxW = effectiveCount == 1
                    ? (width * 0.9).clamp(380.0, 520.0)
                    : width;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: effectiveCount,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      childAspectRatio: 2.6,
                      children: [_TictactoeGameCard(
                        isCreating: isCreating,
                        isFinding: isFinding,
                        turnTimeSec: turnTimeSec,
                        onTurnTimeChanged: onTurnTimeChanged,
                        gridSize: gridSize,
                        onGridSizeChanged: onGridSizeChanged,
                        onCreateGame: onCreateGame,
                        onFindGame: onFindGame,
                      )],
                    ),
                  ),
                );
              }
              return _TictactoeGameCard(
                isCreating: isCreating,
                isFinding: isFinding,
                turnTimeSec: turnTimeSec,
                onTurnTimeChanged: onTurnTimeChanged,
                gridSize: gridSize,
                onGridSizeChanged: onGridSizeChanged,
                onCreateGame: onCreateGame,
                onFindGame: onFindGame,
              );
            },
          ),
          if (invites.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Вас пригласили',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...invites.map(
              (inv) => GradientCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child: Text(
                        (inv.creatorName.isNotEmpty ? inv.creatorName[0] : '?').toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentStart,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.creatorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.grid_on_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatGridSize(inv.gridSize),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatTurnTime(inv.turnTimeSec),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onShowCreatorInfo(context, inv),
                      icon: const Icon(Icons.info_outline_rounded),
                      tooltip: 'Информация о пользователе',
                    ),
                    IconButton(
                      onPressed: () => onDeclineInvite(inv.lobbyId),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Отклонить',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => onAcceptInvite(context, inv.lobbyId),
                      icon: const Icon(Icons.check_rounded),
                      tooltip: 'Принять',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accentStart,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          activeAsync.when(
            data: (active) {
              if (active == null) return const SizedBox.shrink();
              if (active.type == 'game' && active.gameId != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: GradientCard(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => context.push('/games/tictactoe/game/${active.gameId}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Icon(Icons.sports_esports_rounded, size: 40, color: AppColors.accentStart),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  active.isMyTurn ? 'Ваш ход' : 'Ход соперника',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Текущая игра',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LobbiesPageContent extends StatelessWidget {
  const _LobbiesPageContent({
    required this.lobbiesAsync,
    required this.isDesktop,
    required this.onJoinLobby,
    required this.contentPadding,
  });

  final AsyncValue<List<LobbyItem>> lobbiesAsync;
  final bool isDesktop;
  final void Function(BuildContext, String) onJoinLobby;
  final double contentPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Открытые лобби',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          lobbiesAsync.when(
            data: (lobbies) {
              if (lobbies.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Нет открытых лобби. Нажмите «Найти игру» или создайте своё.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isDesktop ? 15 : 14,
                    ),
                  ),
                );
              }
              return Column(
                children: lobbies
                    .map(
                      (lobby) => Padding(
                        padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 6),
                        child: GradientCard(
                          padding: EdgeInsets.all(isDesktop ? 20 : 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_3x3_rounded,
                                size: isDesktop ? 36 : 32,
                                color: AppColors.accentStart,
                              ),
                              SizedBox(width: isDesktop ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lobby.creatorName.trim().isNotEmpty ? lobby.creatorName : 'Игрок',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        fontSize: isDesktop ? 16 : 14,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatTurnTime(lobby.turnTimeSec),
                                          style: TextStyle(
                                            fontSize: isDesktop ? 14 : 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.grid_on_rounded,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatGridSize(lobby.gridSize),
                                          style: TextStyle(
                                            fontSize: isDesktop ? 14 : 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filled(
                                onPressed: () => onJoinLobby(context, lobby.id),
                                icon: const Icon(Icons.login_rounded),
                                tooltip: 'Присоединиться',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.accentStart,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentStart,
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Не удалось загрузить лобби. ${formatUserError(err, fallback: 'Попробуйте обновить страницу.')}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TictactoeGameCard extends StatelessWidget {
  const _TictactoeGameCard({
    required this.isCreating,
    required this.isFinding,
    required this.turnTimeSec,
    required this.onTurnTimeChanged,
    required this.gridSize,
    required this.onGridSizeChanged,
    required this.onCreateGame,
    required this.onFindGame,
  });

  final bool isCreating;
  final bool isFinding;
  final int turnTimeSec;
  final void Function(int) onTurnTimeChanged;
  final int gridSize;
  final void Function(int) onGridSizeChanged;
  final VoidCallback onCreateGame;
  final VoidCallback onFindGame;

  void _cycleTurnTime() {
    final idx = turnTimeOptions.indexOf(turnTimeSec);
    final next = (idx + 1) % turnTimeOptions.length;
    onTurnTimeChanged(turnTimeOptions[next]);
  }

  void _cycleGridSize() {
    final idx = gridSizeOptions.indexOf(gridSize);
    final next = (idx + 1) % gridSizeOptions.length;
    onGridSizeChanged(gridSizeOptions[next]);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final theme = Theme.of(context);
    return GradientCard(
      padding: EdgeInsets.symmetric(
        horizontal: isMedium ? 18 : (isDesktop ? 24 : 20),
        vertical: isMedium ? 16 : (isDesktop ? 22 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isDesktop ? 52 : 48,
                height: isDesktop ? 52 : 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accentStart, AppColors.accentEnd],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentStart.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.grid_3x3_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: isDesktop ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Крестики-нолики',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: isDesktop ? 20 : 18,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: isMedium ? 6 : (isDesktop ? 8 : 6)),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: isDesktop ? 18 : 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '2',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMedium ? 13 : (isDesktop ? 14 : 13),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isCreating || isFinding ? null : _cycleTurnTime,
                            borderRadius: BorderRadius.circular(10),
                            splashColor: AppColors.accentStart.withValues(alpha: 0.2),
                            highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
                            child: Tooltip(
                              message: 'Нажмите для смены времени на ход',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentStart.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: isDesktop ? 18 : 16,
                                      color: AppColors.accentStart,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatTurnTime(turnTimeSec),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.accentStart,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMedium ? 13 : (isDesktop ? 14 : 13),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isCreating || isFinding ? null : _cycleGridSize,
                            borderRadius: BorderRadius.circular(10),
                            splashColor: AppColors.accentStart.withValues(alpha: 0.2),
                            highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
                            child: Tooltip(
                              message: 'Нажмите для смены размера сетки',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentStart.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.grid_on_rounded,
                                      size: isDesktop ? 18 : 16,
                                      color: AppColors.accentStart,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatGridSize(gridSize),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.accentStart,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMedium ? 13 : (isDesktop ? 14 : 13),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMedium ? 16 : (isDesktop ? 24 : 20)),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isCreating || isFinding ? null : onCreateGame,
                  icon: isCreating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 20),
                  label: Text(isCreating ? 'Создание...' : 'Создать игру'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentStart,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isMedium ? 12 : (isDesktop ? 14 : 12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMedium ? 10 : 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCreating || isFinding ? null : onFindGame,
                  icon: isFinding
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentStart,
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 20),
                  label: Text(isFinding ? 'Поиск...' : 'Найти игру'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentStart,
                    side: BorderSide(
                      color: AppColors.accentStart.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isMedium ? 12 : (isDesktop ? 14 : 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GamesTabSwitcher extends StatelessWidget {
  const _GamesTabSwitcher({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final _GamesTab selectedTab;
  final void Function(_GamesTab) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isWide(context);
    final gradient = AppGradients.borderAt(0.22);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.button + 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStart.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.button + 2),
        ),
        child: Row(
          children: [
            _TabSegment(
              label: 'Игры',
              icon: Icons.sports_esports_rounded,
              isSelected: selectedTab == _GamesTab.games,
              onTap: () => onTabChanged(_GamesTab.games),
              isDesktop: isDesktop,
            ),
            _TabSegment(
              label: 'Лобби',
              icon: Icons.group_rounded,
              isSelected: selectedTab == _GamesTab.lobbies,
              onTap: () => onTabChanged(_GamesTab.lobbies),
              isDesktop: isDesktop,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDesktop,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected
            ? AppColors.accentSoft.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: isDesktop ? 14 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isDesktop ? 22 : 20,
                  color: isSelected ? AppColors.accentStart : AppColors.textSecondary,
                ),
                SizedBox(width: isDesktop ? 10 : 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: isDesktop ? 15 : 14,
                    color: isSelected ? AppColors.accentStart : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
