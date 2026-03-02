import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';
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
  Timer? _lobbyRefreshTimer;

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

  @override
  void dispose() {
    _stopLobbyPoll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobbiesAsync = ref.watch(openLobbiesProvider);
    final invites = ref.watch(gameInvitesProvider);
    final activeAsync = ref.watch(activeGameProvider);

    final isDesktop = isWide(context);
    final contentPadding = isDesktop ? 32.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _GamesTabSwitcher(
                          selectedTab: _selectedTab,
                          onTabChanged: (tab) {
                            setState(() => _selectedTab = tab);
                            if (tab == _GamesTab.lobbies) {
                              ref.invalidate(openLobbiesProvider);
                              _startLobbyPoll();
                            } else {
                              _stopLobbyPoll();
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 28 : 20),
                    if (_selectedTab == _GamesTab.games) ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (isDesktop) {
                          final width = constraints.maxWidth;
                          const minCardWidth = 320.0;
                          const maxCardWidth = 420.0;
                          const gap = 16.0;
                          final crossAxisCount = (width / (minCardWidth + gap)).floor().clamp(1, 4);
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: crossAxisCount == 1
                                    ? maxCardWidth + 2 * gap
                                    : width,
                              ),
                              child: GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: gap,
                                crossAxisSpacing: gap,
                                childAspectRatio: 1.95,
                                children: [_TictactoeGameCard(
                                  isCreating: _isCreating,
                                  isFinding: _isFinding,
                                  onCreateGame: () => _createGame(context, 'invite'),
                                  onFindGame: () => _createGame(context, 'matchmake'),
                                )],
                              ),
                            ),
                          );
                        }
                        return _TictactoeGameCard(
                          isCreating: _isCreating,
                          isFinding: _isFinding,
                          onCreateGame: () => _createGame(context, 'invite'),
                          onFindGame: () => _createGame(context, 'matchmake'),
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
                                  (inv.creatorName.isNotEmpty
                                          ? inv.creatorName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.accentStart,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                    const Text(
                                      'Приглашение в крестики-нолики',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _declineInvite(inv.lobbyId),
                                child: const Text('Отклонить'),
                              ),
                              FilledButton(
                                onPressed: () => _acceptInvite(context, inv.lobbyId),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentStart,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Принять'),
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
                                onTap: () =>
                                    context.push('/games/tictactoe/game/${active.gameId}'),
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sports_esports_rounded,
                                      size: 40,
                                      color: AppColors.accentStart,
                                    ),
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
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
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
                    if (_selectedTab == _GamesTab.lobbies) ...[
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
                                    padding: EdgeInsets.symmetric(
                                      vertical: isDesktop ? 8 : 6,
                                    ),
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
                                                  lobby.creatorName.trim().isNotEmpty
                                                      ? lobby.creatorName
                                                      : 'Игрок',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                    fontSize: isDesktop ? 16 : 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Ожидает соперника',
                                                  style: TextStyle(
                                                    fontSize: isDesktop ? 14 : 13,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed: () => _joinLobby(context, lobby.id),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.accentStart,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isDesktop ? 24 : 16,
                                                vertical: isDesktop ? 14 : 12,
                                              ),
                                            ),
                                            child: const Text('Присоединиться'),
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
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Future<void> _createGame(BuildContext context, String mode) async {
    setState(() {
      if (mode == 'invite') _isCreating = true;
      else _isFinding = true;
    });
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.createLobby(mode: mode);
      if (!mounted) return;
      if (result.matched && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      } else {
        context.push('/games/tictactoe/lobby/${result.lobbyId}');
      }
    } catch (e) {
      if (mounted) {
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
      if (!mounted) return;
      if (result.joined && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserError(e))),
        );
      }
    }
  }

  void _declineInvite(String lobbyId) {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
  }

  Future<void> _joinLobby(BuildContext context, String lobbyId) async {
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      if (!mounted) return;
      ref.invalidate(openLobbiesProvider);
      if (result.joined && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatUserError(e))),
        );
      }
    }
  }
}

class _TictactoeGameCard extends StatelessWidget {
  const _TictactoeGameCard({
    required this.isCreating,
    required this.isFinding,
    required this.onCreateGame,
    required this.onFindGame,
  });

  final bool isCreating;
  final bool isFinding;
  final VoidCallback onCreateGame;
  final VoidCallback onFindGame;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isWide(context);
    final theme = Theme.of(context);
    return GradientCard(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 20,
        vertical: isDesktop ? 22 : 20,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Крестики-нолики',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: isDesktop ? 20 : 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '2 игрока',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accentStart,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 6),
                    Text(
                      'Классическая игра на двоих',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isDesktop ? 14 : 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 20),
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
                      vertical: isDesktop ? 14 : 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      vertical: isDesktop ? 14 : 12,
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
