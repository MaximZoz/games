import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

/// Общий формат правил крестиков-ноликов (игра, лобби, приглашения).
String _buildTictactoeRulesText({
  required int gridSize,
  required int turnTimeSec,
  required bool swapRule,
  required bool firstMoveRestriction,
}) {
  final parts = <String>[
    'Крестики-нолики на поле ${formatGridSize(gridSize)}. Ходят по очереди, X начинает.',
    'Победа: нужно выстроить ${gridSize >= 6 ? 5 : gridSize} в ряд по горизонтали, вертикали или диагонали.',
    turnTimeSec == 0
        ? 'Без ограничения по времени на ход.'
        : 'Время на ход: ${formatTurnTime(turnTimeSec)}.',
  ];
  if (swapRule) {
    parts.add('Смена сторон: O может поменяться местами с X после первого хода X.');
  }
  if (firstMoveRestriction) {
    parts.add('Запрет центра: X не может ходить в центр первым ходом.');
  }
  return parts.join('\n\n');
}

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
  bool _selectedSwapRule = false;
  bool _selectedFirstMoveRestriction = false;
  int _selectedStakeBronze = 1; // 1, 10, 50, 100
  Timer? _lobbyRefreshTimer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mobileToolbarLeadingProvider.notifier).state = null;
        ref.read(authStateProvider.notifier).refresh();
      }
    });
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
                      ref.read(authStateProvider.notifier).refresh();
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
                    swapRule: _selectedSwapRule,
                    onSwapRuleChanged: (v) => setState(() => _selectedSwapRule = v),
                    firstMoveRestriction: _selectedFirstMoveRestriction,
                    onFirstMoveRestrictionChanged: (v) => setState(() => _selectedFirstMoveRestriction = v),
                    stakeBronze: _selectedStakeBronze,
                    onStakeChanged: (v) => setState(() => _selectedStakeBronze = v),
                    onCreateGame: () => _createGame(context, 'invite'),
                    onFindGame: () => _createGame(context, 'matchmake'),
                    invites: invites,
                    activeAsync: activeAsync,
                    onAcceptInvite: _acceptInvite,
                    onDeclineInvite: _declineInvite,
                    onShowCreatorInfo: _showCreatorInfo,
                    onShowInviteRules: _showInviteRules,
                    contentPadding: contentPadding,
                  ),
                  _LobbiesPageContent(
                    lobbiesAsync: lobbiesAsync,
                    isDesktop: isDesktop,
                    onJoinLobby: _joinLobby,
                    onShowLobbyRules: _showLobbyRulesInfo,
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
        swapRule: _selectedSwapRule,
        firstMoveRestriction: _selectedFirstMoveRestriction,
        stakeBronze: _selectedStakeBronze,
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

  String _inviteRulesText(GameInvite inv) {
    return _buildTictactoeRulesText(
      gridSize: inv.gridSize,
      turnTimeSec: inv.turnTimeSec,
      swapRule: inv.swapRule,
      firstMoveRestriction: inv.firstMoveRestriction,
    );
  }

  void _showCreatorInfo(BuildContext context, GameInvite inv) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDesktop = MediaQuery.sizeOf(ctx).width >= 700;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 14,
            vertical: isDesktop ? 40 : 20,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 440 : double.infinity),
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
                      _InviteCreatorAvatar(
                        creatorName: name,
                        avatarKind: user?.avatarKind ?? 'letter',
                        avatarValue: user?.avatarValue,
                        creatorId: inv.creatorId,
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
      },
    );
  }

  void _showInviteRules(BuildContext context, GameInvite inv) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDesktop = MediaQuery.sizeOf(ctx).width >= 700;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 14,
            vertical: isDesktop ? 40 : 20,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 380 : double.infinity),
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
                          'Правила игры',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Закрыть',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    child: Text(
                      _inviteRulesText(inv),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
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

  void _showLobbyRulesInfo(BuildContext context, LobbyItem lobby) {
    final rulesText = _buildTictactoeRulesText(
      gridSize: lobby.gridSize,
      turnTimeSec: lobby.turnTimeSec,
      swapRule: lobby.swapRule,
      firstMoveRestriction: lobby.firstMoveRestriction,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDesktop = MediaQuery.sizeOf(ctx).width >= 700;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: isDesktop ? 40 : 24,
          ),
          title: const Text('Правила'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
            child: SingleChildScrollView(
              child: Text(rulesText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
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
    required this.swapRule,
    required this.onSwapRuleChanged,
    required this.firstMoveRestriction,
    required this.onFirstMoveRestrictionChanged,
    required this.stakeBronze,
    required this.onStakeChanged,
    required this.onCreateGame,
    required this.onFindGame,
    required this.invites,
    required this.activeAsync,
    required this.onAcceptInvite,
    required this.onDeclineInvite,
    required this.onShowCreatorInfo,
    required this.onShowInviteRules,
    required this.contentPadding,
  });

  final bool isDesktop;
  final bool isCreating;
  final bool isFinding;
  final int turnTimeSec;
  final void Function(int) onTurnTimeChanged;
  final int gridSize;
  final void Function(int) onGridSizeChanged;
  final bool swapRule;
  final void Function(bool) onSwapRuleChanged;
  final bool firstMoveRestriction;
  final void Function(bool) onFirstMoveRestrictionChanged;
  final int stakeBronze;
  final void Function(int) onStakeChanged;
  final VoidCallback onCreateGame;
  final VoidCallback onFindGame;
  final List<GameInvite> invites;
  final AsyncValue<ActiveGameItem?> activeAsync;
  final void Function(BuildContext, String) onAcceptInvite;
  final void Function(String) onDeclineInvite;
  final void Function(BuildContext, GameInvite) onShowCreatorInfo;
  final void Function(BuildContext, GameInvite) onShowInviteRules;
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
                        swapRule: swapRule,
                        onSwapRuleChanged: onSwapRuleChanged,
                        firstMoveRestriction: firstMoveRestriction,
                        onFirstMoveRestrictionChanged: onFirstMoveRestrictionChanged,
                        stakeBronze: stakeBronze,
                        onStakeChanged: onStakeChanged,
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
                swapRule: swapRule,
                onSwapRuleChanged: onSwapRuleChanged,
                firstMoveRestriction: firstMoveRestriction,
                onFirstMoveRestrictionChanged: onFirstMoveRestrictionChanged,
                stakeBronze: stakeBronze,
                onStakeChanged: onStakeChanged,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final inviteContent = invites.map(
                  (inv) => _InviteCard(
                    inv: inv,
                    onShowCreatorInfo: onShowCreatorInfo,
                    onShowInviteRules: onShowInviteRules,
                    onDeclineInvite: onDeclineInvite,
                    onAcceptInvite: onAcceptInvite,
                  ),
                );
                if (isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: inviteContent
                            .map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: w,
                                ))
                            .toList(),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: inviteContent
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: w,
                          ))
                      .toList(),
                );
              },
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
    required this.onShowLobbyRules,
    required this.contentPadding,
  });

  final AsyncValue<List<LobbyItem>> lobbiesAsync;
  final bool isDesktop;
  final void Function(BuildContext, String) onJoinLobby;
  final void Function(BuildContext, LobbyItem) onShowLobbyRules;
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
              final lobbyCards = lobbies
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
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
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
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                        if (lobby.stakeBronze > 0)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${lobby.stakeBronze}',
                                                style: TextStyle(
                                                  fontSize: isDesktop ? 14 : 13,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              CoinIcon(
                                                coinType: CoinType.bronze,
                                                size: 14,
                                                showBorder: true,
                                              ),
                                            ],
                                          ),
                                        if (lobby.swapRule)
                                          Tooltip(
                                            message: 'Смена сторон',
                                            child: const Icon(
                                              Icons.swap_horiz_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        if (lobby.firstMoveRestriction)
                                          Tooltip(
                                            message: 'Запрет центра',
                                            child: const Icon(
                                              Icons.block_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => onShowLobbyRules(context, lobby),
                                icon: const Icon(Icons.info_outline_rounded),
                                tooltip: 'Правила игры',
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
                    .toList();
              if (isDesktop) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: lobbyCards,
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: lobbyCards,
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
    required this.swapRule,
    required this.onSwapRuleChanged,
    required this.firstMoveRestriction,
    required this.onFirstMoveRestrictionChanged,
    required this.stakeBronze,
    required this.onStakeChanged,
    required this.onCreateGame,
    required this.onFindGame,
  });

  final bool isCreating;
  final bool isFinding;
  final int turnTimeSec;
  final void Function(int) onTurnTimeChanged;
  final int gridSize;
  final void Function(int) onGridSizeChanged;
  final bool swapRule;
  final void Function(bool) onSwapRuleChanged;
  final bool firstMoveRestriction;
  final void Function(bool) onFirstMoveRestrictionChanged;
  final int stakeBronze;
  final void Function(int) onStakeChanged;
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

  void _cycleStake() {
    final idx = stakeOptions.indexOf(stakeBronze);
    final next = (idx + 1) % stakeOptions.length;
    onStakeChanged(stakeOptions[next]);
  }

  String _buildRulesText() => _buildTictactoeRulesText(
        gridSize: gridSize,
        turnTimeSec: turnTimeSec,
        swapRule: swapRule,
        firstMoveRestriction: firstMoveRestriction,
      );

  List<Widget> _buildChipList({
    required TextTheme? theme,
    required bool isCreating,
    required bool isFinding,
    required bool isDesktop,
    required bool isMedium,
    bool compact = false,
  }) {
    final padV = compact ? 4.0 : 6.0;
    final padH = compact ? 6.0 : 10.0;
    final iconSz = compact ? 14.0 : (isDesktop ? 18.0 : 16.0);
    final fontSz = compact ? 11.0 : (isMedium ? 13.0 : (isDesktop ? 14.0 : 13.0));
    return [
      Container(
        padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
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
              size: iconSz,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: compact ? 3 : 4),
            Text(
              '2',
              style: theme?.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: fontSz,
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
              padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
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
                    size: iconSz,
                    color: AppColors.accentStart,
                  ),
                  SizedBox(width: compact ? 4 : 6),
                  Text(
                    formatTurnTime(turnTimeSec),
                    style: theme?.bodyMedium?.copyWith(
                      color: AppColors.accentStart,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSz,
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
              padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
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
                    size: iconSz,
                    color: AppColors.accentStart,
                  ),
                  SizedBox(width: compact ? 4 : 6),
                  Text(
                    formatGridSize(gridSize),
                    style: theme?.bodyMedium?.copyWith(
                      color: AppColors.accentStart,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSz,
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
          onTap: isCreating || isFinding ? null : _cycleStake,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.accentStart.withValues(alpha: 0.2),
          highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
          child: Tooltip(
            message: 'Ставка за игру (бронза)',
            child: Container(
              padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
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
                  CoinIcon(
                    coinType: CoinType.bronze,
                    size: iconSz,
                    showBorder: true,
                  ),
                  SizedBox(width: compact ? 4 : 6),
                  Text(
                    '$stakeBronze',
                    style: theme?.bodyMedium?.copyWith(
                      color: AppColors.accentStart,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSz,
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
          onTap: isCreating || isFinding
              ? null
              : () => onSwapRuleChanged(!swapRule),
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.accentStart.withValues(alpha: 0.2),
          highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
          child: Tooltip(
            message: 'O может стать X после 1-го хода',
            child: Container(
              padding: EdgeInsets.all(compact ? 4 : 6),
              decoration: BoxDecoration(
                color: swapRule
                    ? AppColors.accentSoft.withValues(alpha: 0.6)
                    : AppColors.textSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: swapRule
                      ? AppColors.accentStart.withValues(alpha: 0.3)
                      : AppColors.textSecondary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                size: iconSz,
                color: swapRule
                    ? AppColors.accentStart
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCreating || isFinding
              ? null
              : () => onFirstMoveRestrictionChanged(!firstMoveRestriction),
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.accentStart.withValues(alpha: 0.2),
          highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
          child: Tooltip(
            message: 'Первый ход не в центр',
            child: Container(
              padding: EdgeInsets.all(compact ? 4 : 6),
              decoration: BoxDecoration(
                color: firstMoveRestriction
                    ? AppColors.accentSoft.withValues(alpha: 0.6)
                    : AppColors.textSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: firstMoveRestriction
                      ? AppColors.accentStart.withValues(alpha: 0.3)
                      : AppColors.textSecondary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.block_rounded,
                size: iconSz,
                color: firstMoveRestriction
                    ? AppColors.accentStart
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  void _showRulesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Правила игры'),
        content: SingleChildScrollView(
          child: Text(_buildRulesText()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
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
                width: isDesktop ? 52 : 44,
                height: isDesktop ? 52 : 44,
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
              SizedBox(width: isDesktop ? 20 : 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
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
                    ),
                    IconButton(
                      onPressed: isCreating || isFinding
                          ? null
                          : () => _showRulesInfo(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Правила игры',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(36, 36),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: width < 400 ? 6 : 10,
              runSpacing: 6,
              alignment: WrapAlignment.start,
              children: _buildChipList(
                theme: theme.textTheme,
                isCreating: isCreating,
                isFinding: isFinding,
                isDesktop: isDesktop,
                isMedium: isMedium,
                compact: width < 400,
              ),
            ),
          ),
          SizedBox(height: isMedium ? 16 : (isDesktop ? 24 : 20)),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isCreating || isFinding ? null : onCreateGame,
                  icon: isCreating
                      ? const SizedBox(
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
                      ? const SizedBox(
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

class _InviteCard extends ConsumerWidget {
  const _InviteCard({
    required this.inv,
    required this.onShowCreatorInfo,
    required this.onShowInviteRules,
    required this.onDeclineInvite,
    required this.onAcceptInvite,
  });

  final GameInvite inv;
  final void Function(BuildContext, GameInvite) onShowCreatorInfo;
  final void Function(BuildContext, GameInvite) onShowInviteRules;
  final void Function(String) onDeclineInvite;
  final void Function(BuildContext, String) onAcceptInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
    final p = presence[inv.creatorId];
    final statusText = p == null
        ? null
        : (p.online ? 'Онлайн' : formatLastSeen(p.lastSeenAt));

    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _InviteCreatorAvatar(
            creatorName: inv.creatorName,
            avatarKind: inv.creatorAvatarKind,
            avatarValue: inv.creatorAvatarValue,
            creatorId: inv.creatorId,
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
                if (statusText != null && statusText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onShowCreatorInfo(context, inv),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Информация об игроке',
          ),
          if (inv.stakeBronze > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${inv.stakeBronze}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const CoinIcon(
                    coinType: CoinType.bronze,
                    size: 18,
                    showBorder: true,
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () => onShowInviteRules(context, inv),
            icon: const Icon(Icons.rule_rounded),
            tooltip: 'Правила игры',
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
    );
  }
}

class _InviteCreatorAvatar extends ConsumerWidget {
  const _InviteCreatorAvatar({
    required this.creatorName,
    required this.avatarKind,
    required this.avatarValue,
    required this.creatorId,
  });

  final String creatorName;
  final String avatarKind;
  final String? avatarValue;
  final String creatorId;

  static const _presetIcons = [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String kind = avatarKind;
    String? value = avatarValue;
    if ((value == null || value.isEmpty) && kind == 'letter') {
      final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
      for (final f in snapshot?.friends ?? []) {
        if (f.user.id == creatorId) {
          kind = f.user.avatarKind;
          value = f.user.avatarValue;
          break;
        }
      }
    }
    Widget avatar;
    if (kind == 'file' && value != null && value.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(value);
      avatar = img != null
          ? CircleAvatar(
              radius: 22,
              backgroundImage: img,
            )
          : _letterAvatar(creatorName);
    } else if (kind == 'preset' && value != null) {
      final idx = int.tryParse(value);
      if (idx != null && idx >= 0 && idx < _presetIcons.length) {
        avatar = CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetIcons[idx], color: AppColors.accentStart, size: 26),
        );
      } else {
        avatar = _letterAvatar(creatorName);
      }
    } else {
      avatar = _letterAvatar(creatorName);
    }
    return avatar;
  }

  Widget _letterAvatar(String name) {
    final letter = name.trim().isEmpty ? '?' : name[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.accentStart,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

