import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/l10n/l10n.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

enum _GamesTab { games, lobbies }

/// Режимы для второй кнопки: Классика → Гомоку → Ультимейт.
const _modeCycleVariants = <String>[
  variantClassic,
  variantGomoku,
  variantUltimate,
];

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _isCreating = false;
  bool _isFinding = false;
  _GamesTab _selectedTab = _GamesTab.games;
  int _selectedTurnTimeSec = 0; // 0=без лимита, 10, 30, 60, 600
  String _selectedVariant = variantClassic;
  /// true — активна кнопка игроков (2/3/4); false — кнопка режима.
  bool _playersControlActive = false;
  int _selectedStakeBronze = 1; // free: 1, 10, 50; + bought silver
  bool _settingsHydrated = false;
  Timer? _lobbyRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mobileToolbarLeadingProvider.notifier).state = null;
        ref.read(authStateProvider.notifier).refresh();
        _hydrateFromSavedSettings();
      }
    });
  }

  void _hydrateFromSavedSettings() {
    if (_settingsHydrated) return;
    final saved = ref.read(userGameSettingsProvider).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _selectedTurnTimeSec = saved.turnTimeSec;
      _selectedVariant = saved.variant;
      _playersControlActive =
          saved.variant == variantMulti3 || saved.variant == variantMulti4;
      _selectedStakeBronze = saved.stakeBronze;
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider.notifier).updateLocal(
          UserGameSettings(
            turnTimeSec: _selectedTurnTimeSec,
            variant: _selectedVariant,
            swapRule: false,
            firstMoveRestriction: false,
            stakeBronze: _selectedStakeBronze,
          ),
        );
  }

  void _onPlayersChipTap() {
    final offline = ref.read(isOfflineProvider);
    if (offline) return;
    setState(() {
      if (!_playersControlActive) {
        // Переключились с режимов → игроки фиолетовые, режим «Классика» тёмный.
        _playersControlActive = true;
        _selectedVariant = variantClassic; // 2 игрока
      } else {
        // 2 → 3 → 4 → 2
        final n = configForVariant(_selectedVariant).maxPlayers;
        if (n <= 2) {
          _selectedVariant = variantMulti3;
        } else if (n == 3) {
          _selectedVariant = variantMulti4;
        } else {
          _selectedVariant = variantClassic;
        }
      }
    });
    _persistSettings();
  }

  void _onModeChipTap() {
    final offline = ref.read(isOfflineProvider);
    setState(() {
      if (_playersControlActive ||
          _selectedVariant == variantMulti3 ||
          _selectedVariant == variantMulti4) {
        // С игроков → режимы: 2 тёмные, Классика фиолетовая.
        _playersControlActive = false;
        _selectedVariant = variantClassic;
      } else {
        final cycle = offline
            ? const [variantClassic, variantGomoku]
            : _modeCycleVariants;
        final current = parseVariant(_selectedVariant);
        final idx = cycle.indexOf(current);
        final next = (idx < 0 ? 0 : idx + 1) % cycle.length;
        _selectedVariant = cycle[next];
      }
    });
    _persistSettings();
  }

  @override
  void dispose() {
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
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    if (tab == _GamesTab.lobbies) {
      ref.invalidate(openLobbiesProvider);
      _startLobbyPoll();
    } else {
      _stopLobbyPoll();
      ref.read(authStateProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobbiesAsync = ref.watch(openLobbiesProvider);
    final invites = ref.watch(gameInvitesProvider);
    final activeAsync = ref.watch(activeGameProvider);
    final caps = ref.watch(inventoryCapabilitiesProvider).valueOrNull;
    // Подхватываем конфиг из БД, когда он лениво догрузится.
    ref.listen<AsyncValue<UserGameSettings>>(userGameSettingsProvider,
        (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _selectedTurnTimeSec = saved.turnTimeSec;
        _selectedVariant = saved.variant;
        _playersControlActive =
            saved.variant == variantMulti3 || saved.variant == variantMulti4;
        _selectedStakeBronze = saved.stakeBronze;
      });
    });
    final availableStakes =
        caps?.allowedStakeBronze ?? List<int>.from(freeStakeOptions);
    if (!availableStakes.contains(_selectedStakeBronze) &&
        availableStakes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedStakeBronze = availableStakes.first);
        if (_settingsHydrated) _persistSettings();
      });
    }

    final isDesktop = isWide(context);
    final phoneLandscape = isPhoneLandscape(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final contentPadding =
        phoneLandscape ? 12.0 : (isMedium ? 20.0 : (isDesktop ? 32.0 : 24.0));
    final isOffline = ref.watch(isOfflineProvider);
    if (isOffline && _selectedTab != _GamesTab.games) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedTab = _GamesTab.games);
      });
    }

    void playOffline() {
      final offlineVariant = (_selectedVariant == variantClassic ||
              _selectedVariant == variantGomoku)
          ? _selectedVariant
          : variantClassic;
      final qs = <String, String>{
        'variant': offlineVariant,
        'grid': '${gridSizeForVariant(offlineVariant)}',
        // В офлайне всегда чередуем, кто начинает.
        'swap': '1',
      };
      final uri = Uri(
        path: '/games/tictactoe/offline',
        queryParameters: qs,
      );
      context.go(uri.toString());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isOffline)
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
            SizedBox(height: isDesktop ? 8 : 20),
            Expanded(
              // IndexedStack вместо PageView: ветка /games в StatefulShell
              // indexedStack остаётся живой при /login|/register (PWA),
              // а PageController с viewport=0 после возврата ломает смену табов.
              child: IndexedStack(
                index:
                    isOffline ? 0 : (_selectedTab == _GamesTab.games ? 0 : 1),
                sizing: StackFit.expand,
                children: [
                  _GamesPageContent(
                    isDesktop: isDesktop,
                    isCreating: _isCreating,
                    isFinding: _isFinding,
                    isOffline: isOffline,
                    turnTimeSec: _selectedTurnTimeSec,
                    onTurnTimeChanged: (v) {
                      setState(() => _selectedTurnTimeSec = v);
                      _persistSettings();
                    },
                    variant: _selectedVariant,
                    playersControlActive: _playersControlActive,
                    onPlayersChipTap: _onPlayersChipTap,
                    onModeChipTap: _onModeChipTap,
                    stakeBronze: isOffline ? 0 : _selectedStakeBronze,
                    stakeOptionsList: availableStakes,
                    onStakeChanged: (v) {
                      setState(() => _selectedStakeBronze = v);
                      _persistSettings();
                    },
                    onCreateGame: () => _createGame(context, 'invite'),
                    onFindGame: () => _createGame(
                      context,
                      configForVariant(_selectedVariant).maxPlayers > 2
                          ? 'invite'
                          : 'matchmake',
                    ),
                    onPlayOffline: playOffline,
                    invites: isOffline ? const [] : invites,
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
                    onRefresh: () => ref.invalidate(openLobbiesProvider),
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
        variant: _selectedVariant,
        gridSize: gridSizeForVariant(_selectedVariant),
        swapRule: false,
        firstMoveRestriction: false,
        stakeBronze: _selectedStakeBronze,
        addBotsAfter30s: false,
      );
      if (!context.mounted) return;
      if (result.matched && result.gameId != null) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: result.gameId,
                lobbyId: result.lobbyId,
              ),
            );
        context.push('/games/tictactoe/game/${result.gameId}');
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: result.lobbyId,
              ),
            );
        context.push(
          '/games/tictactoe/lobby/${result.lobbyId}?mode=$mode',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: formatUserError(e),
          kind: AppSnackKind.error,
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
    ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      if (result.joined && result.gameId != null) {
        _navigateToJoinedGame(result.gameId!);
      }
    } catch (e) {
      _showInviteError(e);
    }
  }

  void _navigateToJoinedGame(String gameId) {
    if (!mounted) return;
    navigateToGame(
      GoRouter.of(context),
      ref.read(gameNavigationCoordinatorProvider),
      gameId,
    );
  }

  void _showInviteError(Object error) {
    if (mounted) {
      showAppSnackBar(
        context,
        message: formatUserError(error),
        kind: AppSnackKind.error,
      );
    }
  }

  Widget _inviteRulesWidget(GameInvite inv) {
    return buildTictactoeRulesTextWidget(
      variant: inv.variant,
      gridSize: inv.gridSize,
      turnTimeSec: inv.turnTimeSec,
      swapRule: inv.swapRule,
      firstMoveRestriction: inv.firstMoveRestriction,
      stakeBronze: inv.stakeBronze,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.35,
      ),
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
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 440 : double.infinity),
            child: Consumer(
              builder: (context, ref, _) {
                final snapshot = ref.watch(friendsSnapshotProvider).valueOrNull;
                final presence =
                    ref.watch(presenceMapProvider).valueOrNull ?? const {};
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
                    : (p.online
                        ? context.l10n.commonOnlineCap
                        : formatLastSeen(p.lastSeenAt));
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
                            tooltip: context.l10n.commonClose,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      if (about != null && about.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.commonAboutMe,
                          style: const TextStyle(
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
                      HeadToHeadSection(
                        opponentId: inv.creatorId,
                        opponentName: name,
                      ),
                      PeerCollectionsSection(userId: inv.creatorId),
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
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 380 : double.infinity),
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
                          context.l10n.gamesRulesTitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.commonClose,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    child: _inviteRulesWidget(inv),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _declineInvite(String lobbyId) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      await ref.read(gamesRepositoryProvider).declineLobby(lobbyId);
    } catch (_) {
      // Карточка уже скрыта локально; сервер мог уже закрыть лобби.
    }
  }

  Future<void> _joinLobby(BuildContext context, String lobbyId) async {
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      if (!context.mounted) return;
      ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
      ref.invalidate(openLobbiesProvider);
      if (result.joined && result.gameId != null) {
        context.push('/games/tictactoe/game/${result.gameId}');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: formatUserError(e),
          kind: AppSnackKind.error,
        );
      }
    }
  }

  void _showLobbyRulesInfo(BuildContext context, LobbyItem lobby) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDesktop = MediaQuery.sizeOf(ctx).width >= 700;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: isDesktop ? 40 : 24,
          ),
          title: Text(context.l10n.gamesRules),
          content: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
            child: SingleChildScrollView(
              child: buildTictactoeRulesTextWidget(
                variant: lobby.variant,
                gridSize: lobby.gridSize,
                turnTimeSec: lobby.turnTimeSec,
                swapRule: lobby.swapRule,
                firstMoveRestriction: lobby.firstMoveRestriction,
                stakeBronze: lobby.stakeBronze,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.commonClose),
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
    required this.isOffline,
    required this.turnTimeSec,
    required this.onTurnTimeChanged,
    required this.variant,
    required this.playersControlActive,
    required this.onPlayersChipTap,
    required this.onModeChipTap,
    required this.stakeBronze,
    required this.stakeOptionsList,
    required this.onStakeChanged,
    required this.onCreateGame,
    required this.onFindGame,
    required this.onPlayOffline,
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
  final bool isOffline;
  final int turnTimeSec;
  final void Function(int) onTurnTimeChanged;
  final String variant;
  final bool playersControlActive;
  final VoidCallback onPlayersChipTap;
  final VoidCallback onModeChipTap;
  final int stakeBronze;
  final List<int> stakeOptionsList;
  final void Function(int) onStakeChanged;
  final VoidCallback onCreateGame;
  final VoidCallback onFindGame;
  final VoidCallback onPlayOffline;
  final List<GameInvite> invites;
  final AsyncValue<ActiveGameItem?> activeAsync;
  final void Function(BuildContext, String) onAcceptInvite;
  final void Function(String) onDeclineInvite;
  final void Function(BuildContext, GameInvite) onShowCreatorInfo;
  final void Function(BuildContext, GameInvite) onShowInviteRules;
  final double contentPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          primary: false,
          physics: (isDesktop || isPhoneLandscape(context) || isTablet(context))
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            contentPadding,
            0,
            contentPadding,
            isDesktop ? 24 : 48,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight.isFinite &&
                        constraints.maxHeight > 100
                    ? constraints.maxHeight
                    : 400,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final phoneLandscape = isPhoneLandscape(context);
                      final tablet = isTablet(context);
                      if (isDesktop || phoneLandscape) {
                        // Одна карточка игры — по центру, достаточно широкая,
                        // чтобы «Крестики-нолики» не обрезалось на планшете.
                        final minCardWidth =
                            phoneLandscape ? 300.0 : (tablet ? 440.0 : 400.0);
                        final maxCardWidth =
                            phoneLandscape ? 420.0 : (tablet ? 560.0 : 520.0);
                        final availableWidth = constraints.maxWidth;
                        final cardWidth = availableWidth
                            .clamp(minCardWidth, maxCardWidth)
                            .toDouble();
                        return SizedBox(
                          width: availableWidth,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: cardWidth,
                              child: _TictactoeGameCard(
                                isCreating: isCreating,
                                isFinding: isFinding,
                                isOffline: isOffline,
                                turnTimeSec: turnTimeSec,
                                onTurnTimeChanged: onTurnTimeChanged,
                                variant: variant,
                                playersControlActive: playersControlActive,
                                onPlayersChipTap: onPlayersChipTap,
                                onModeChipTap: onModeChipTap,
                                stakeBronze: stakeBronze,
                                stakeOptionsList: stakeOptionsList,
                                onStakeChanged: onStakeChanged,
                                onCreateGame: onCreateGame,
                                onFindGame: onFindGame,
                                onPlayOffline: onPlayOffline,
                              ),
                            ),
                          ),
                        );
                      }
                      return _TictactoeGameCard(
                        isCreating: isCreating,
                        isFinding: isFinding,
                        isOffline: isOffline,
                        turnTimeSec: turnTimeSec,
                        onTurnTimeChanged: onTurnTimeChanged,
                        variant: variant,
                        playersControlActive: playersControlActive,
                        onPlayersChipTap: onPlayersChipTap,
                        onModeChipTap: onModeChipTap,
                        stakeBronze: stakeBronze,
                        stakeOptionsList: stakeOptionsList,
                        onStakeChanged: onStakeChanged,
                        onCreateGame: onCreateGame,
                        onFindGame: onFindGame,
                        onPlayOffline: onPlayOffline,
                      );
                    },
                  ),
                  if (invites.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        context.l10n.gamesInvitedYou,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
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
                          final width = constraints.maxWidth;
                          const minCardWidth = 360.0;
                          const gap = 16.0;
                          final crossAxisCount = (width / (minCardWidth + gap))
                              .floor()
                              .clamp(1, 4);
                          final itemWidth =
                              (width - gap * (crossAxisCount - 1)) /
                                  crossAxisCount;
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: width),
                              child: Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                alignment: WrapAlignment.center,
                                children: inviteContent
                                    .map((w) => SizedBox(
                                          width: itemWidth,
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
                              onTap: () => context.push(
                                  '/games/tictactoe/game/${active.gameId}'),
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  Icon(Icons.sports_esports_rounded,
                                      size: 40, color: AppColors.accentStart),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          active.isMyTurn
                                              ? context.l10n.gamesMyTurn
                                              : context.l10n.gamesOpponentTurn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          context.l10n.gamesCurrentGame,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 16),
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
            ),
          ),
        );
      },
    );
  }
}

class _LobbiesPageContent extends StatelessWidget {
  const _LobbiesPageContent({
    required this.lobbiesAsync,
    required this.isDesktop,
    required this.onJoinLobby,
    required this.onShowLobbyRules,
    required this.onRefresh,
    required this.contentPadding,
  });

  final AsyncValue<List<LobbyItem>> lobbiesAsync;
  final bool isDesktop;
  final void Function(BuildContext, String) onJoinLobby;
  final void Function(BuildContext, LobbyItem) onShowLobbyRules;
  final VoidCallback onRefresh;
  final double contentPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 48),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  lobbiesAsync.when(
                    data: (lobbies) {
                      if (lobbies.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 48 : 36,
                            horizontal: 12,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_off_rounded,
                                size: isDesktop ? 48 : 40,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.gamesLobbyTab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isDesktop ? 16 : 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: onRefresh,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(context.l10n.commonTryRefresh),
                              ),
                            ],
                          ),
                        );
                      }
                      final lobbyCards = lobbies
                          .map(
                            (lobby) => Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 8 : 6),
                              child: GradientCard(
                                padding: EdgeInsets.all(isDesktop ? 20 : 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.grid_3x3_rounded,
                                      size: isDesktop ? 36 : 32,
                                      color: AppColors.accentStart,
                                    ),
                                    SizedBox(width: isDesktop ? 16 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lobby.creatorName.trim().isNotEmpty
                                                ? lobby.creatorName
                                                : context.l10n.commonPlayer,
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
                                              if (lobby.stakeBronze > 0)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      formatStakeAmount(
                                                          lobby.stakeBronze),
                                                      style: TextStyle(
                                                        fontSize:
                                                            isDesktop ? 14 : 13,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    CoinIcon(
                                                      coinType: stakeCoinType(
                                                          lobby.stakeBronze),
                                                      size: 14,
                                                      showBorder: true,
                                                    ),
                                                  ],
                                                ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.timer_outlined,
                                                    size: 14,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    formatTurnTime(
                                                        lobby.turnTimeSec),
                                                    style: TextStyle(
                                                      fontSize:
                                                          isDesktop ? 14 : 13,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.extension_rounded,
                                                    size: 14,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    variantShortLabel(
                                                        lobby.variant),
                                                    style: TextStyle(
                                                      fontSize:
                                                          isDesktop ? 14 : 13,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    size: 14,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${lobby.maxPlayers}',
                                                    style: TextStyle(
                                                      fontSize:
                                                          isDesktop ? 14 : 13,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          onShowLobbyRules(context, lobby),
                                      icon: const Icon(
                                          Icons.info_outline_rounded),
                                      tooltip: context.l10n.gamesRulesTitle,
                                    ),
                                    IconButton.filled(
                                      onPressed: () =>
                                          onJoinLobby(context, lobby.id),
                                      icon: const Icon(Icons.login_rounded),
                                      tooltip: context.l10n.gamesJoin,
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
                        final width = constraints.maxWidth;
                        const minCardWidth = 360.0;
                        const gap = 16.0;
                        final crossAxisCount =
                            (width / (minCardWidth + gap)).floor().clamp(1, 4);
                        final itemWidth = (width - gap * (crossAxisCount - 1)) /
                            crossAxisCount;
                        return Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: width),
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              alignment: WrapAlignment.start,
                              children: [
                                for (var i = 0; i < lobbyCards.length; i++)
                                  SizedBox(
                                    width: itemWidth,
                                    child: lobbyCards[i],
                                  ),
                              ],
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
                        '${context.l10n.gamesLobbyLoadFailed} ${formatUserError(err, fallback: context.l10n.commonTryRefresh)}',
                        style: const TextStyle(color: Colors.red),
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
}

class _TictactoeGameCard extends StatelessWidget {
  const _TictactoeGameCard({
    required this.isCreating,
    required this.isFinding,
    required this.isOffline,
    required this.turnTimeSec,
    required this.onTurnTimeChanged,
    required this.variant,
    required this.playersControlActive,
    required this.onPlayersChipTap,
    required this.onModeChipTap,
    required this.stakeBronze,
    required this.stakeOptionsList,
    required this.onStakeChanged,
    required this.onCreateGame,
    required this.onFindGame,
    required this.onPlayOffline,
  });

  final bool isCreating;
  final bool isFinding;
  final bool isOffline;
  final int turnTimeSec;
  final void Function(int) onTurnTimeChanged;
  final String variant;
  final bool playersControlActive;
  final VoidCallback onPlayersChipTap;
  final VoidCallback onModeChipTap;
  final int stakeBronze;
  final List<int> stakeOptionsList;
  final void Function(int) onStakeChanged;
  final VoidCallback onCreateGame;
  final VoidCallback onFindGame;
  final VoidCallback onPlayOffline;

  void _cycleTurnTime() {
    final idx = turnTimeOptions.indexOf(turnTimeSec);
    final next = (idx + 1) % turnTimeOptions.length;
    onTurnTimeChanged(turnTimeOptions[next]);
  }

  void _cycleStake() {
    final options =
        stakeOptionsList.isEmpty ? freeStakeOptions : stakeOptionsList;
    final idx = options.indexOf(stakeBronze);
    final next = (idx + 1) % options.length;
    onStakeChanged(options[next]);
  }

  Widget _buildRulesWidget() => buildTictactoeRulesTextWidget(
        variant: variant,
        gridSize: gridSizeForVariant(variant),
        turnTimeSec: turnTimeSec,
        swapRule: false,
        firstMoveRestriction: false,
        stakeBronze: stakeBronze,
        includeTurnTime: !isOffline,
        offlineBot: isOffline,
      );

  Widget _selectableChip({
    required bool selected,
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required TextTheme? theme,
    required double padV,
    required double padH,
    required double iconSz,
    required double fontSz,
    required bool compact,
  }) {
    final color = selected ? AppColors.accentStart : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.accentStart.withValues(alpha: 0.2),
        highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentSoft.withValues(alpha: 0.6)
                : AppColors.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.accentStart.withValues(alpha: 0.3)
                  : AppColors.textSecondary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSz, color: color),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: theme?.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSz,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChipList({
    required BuildContext context,
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
    final fontSz =
        compact ? 11.0 : (isMedium ? 13.0 : (isDesktop ? 14.0 : 13.0));
    final busy = isCreating || isFinding;
    // Кнопка игроков: активна → 2/3/4 фиолетовая; иначе тёмная «2».
    final playersSelected = !isOffline && playersControlActive;
    final playersLabel = playersSelected
        ? '${configForVariant(variant).maxPlayers}'
        : '2';
    // Кнопка режима: активна → Классика/Гомоку/Ультимейт; иначе тёмная «Классика».
    final modeSelected = isOffline || !playersControlActive;
    final modeVariant = modeSelected
        ? parseVariant(variant)
        : variantClassic;
    final modeIcon = modeVariant == variantGomoku
        ? Icons.grid_on_rounded
        : modeVariant == variantUltimate
            ? Icons.dashboard_customize_rounded
            : Icons.close_rounded;
    return [
      if (!isOffline)
        _selectableChip(
          selected: playersSelected,
          onTap: busy ? null : onPlayersChipTap,
          icon: Icons.groups_rounded,
          label: playersLabel,
          theme: theme,
          padV: padV,
          padH: padH,
          iconSz: iconSz,
          fontSz: fontSz,
          compact: compact,
        ),
      if (!isOffline)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : _cycleTurnTime,
            borderRadius: BorderRadius.circular(10),
            splashColor: AppColors.accentStart.withValues(alpha: 0.2),
            highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
            child: Tooltip(
              message: context.l10n.gamesTapChangeTurnTime,
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
      _selectableChip(
        selected: modeSelected,
        onTap: busy ? null : onModeChipTap,
        icon: modeIcon,
        label: variantLabel(modeVariant),
        theme: theme,
        padV: padV,
        padH: padH,
        iconSz: iconSz,
        fontSz: fontSz,
        compact: compact,
      ),
    ];
  }

  void _showRulesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.gamesRulesTitle),
        content: SingleChildScrollView(
          child: _buildRulesWidget(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.commonClose),
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
    // Без appear-анимации: при возврате из лобби карточка иначе «мигает»
    // (opacity 0→1), хотя выход уже мгновенный.
    return GradientCard(
      animate: false,
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
                        context.l10n.gamesTicTacToe,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          // На планшете чуть компактнее — полное имя влезает.
                          fontSize: isMedium ? 18 : (isDesktop ? 20 : 18),
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: isMedium || isTablet(context) ? 2 : 1,
                      ),
                    ),
                    if (!isOffline && stakeBronze > 0) ...[
                      SizedBox(width: isMedium ? 8 : (isDesktop ? 16 : 12)),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isCreating || isFinding ? null : _cycleStake,
                          borderRadius: BorderRadius.circular(8),
                          child: Tooltip(
                            message: context.l10n.gamesTapChangeStake,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatStakeAmount(stakeBronze),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CoinIcon(
                                    coinType: stakeCoinType(stakeBronze),
                                    size: 20,
                                    showBorder: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                      onPressed: isCreating || isFinding
                          ? null
                          : () => _showRulesInfo(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: context.l10n.gamesRulesTitle,
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.all(4),
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
                context: context,
                theme: theme.textTheme,
                isCreating: isCreating,
                isFinding: isFinding,
                isDesktop: isDesktop,
                isMedium: isMedium,
                compact: width < 400,
              ),
            ),
          ),
          SizedBox(height: isMedium ? 20 : (isDesktop ? 28 : 20)),
          if (isOffline)
            FilledButton.icon(
              onPressed: onPlayOffline,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(context.l10n.gamesPlay),
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
            )
          else
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
                    label: Text(isCreating
                        ? context.l10n.commonCreating
                        : context.l10n.gamesCreate),
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
                    label: Text(isFinding
                        ? context.l10n.commonSearching
                        : context.l10n.gamesFindMatch),
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
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.button + 2),
        ),
        child: Row(
          children: [
            _TabSegment(
              label: context.l10n.gamesTitle,
              icon: Icons.sports_esports_rounded,
              isSelected: selectedTab == _GamesTab.games,
              onTap: () => onTabChanged(_GamesTab.games),
              isDesktop: isDesktop,
            ),
            _TabSegment(
              label: context.l10n.gamesLobbyTab,
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
          child: Semantics(
            button: true,
            selected: isSelected,
            label: label,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
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
                      color: isSelected
                          ? AppColors.accentStart
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: isDesktop ? 10 : 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: isDesktop ? 15 : 14,
                          color: isSelected
                              ? AppColors.accentStart
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    const iconSz = 16.0;
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _InviteGameIcon(gameType: inv.gameType),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          inv.creatorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => onShowInviteRules(context, inv),
                        icon: const Icon(Icons.rule_rounded, size: 20),
                        tooltip: context.l10n.gamesRulesTitle,
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (inv.stakeBronze > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatStakeAmount(inv.stakeBronze),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              CoinIcon(
                                coinType: stakeCoinType(inv.stakeBronze),
                                size: 18,
                                showBorder: true,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.start,
                          children: [
                            Tooltip(
                              message: context.l10n.gamesTurnTime,
                              child: Icon(Icons.timer_outlined,
                                  size: iconSz, color: AppColors.textSecondary),
                            ),
                            Text(
                              formatTurnTime(inv.turnTimeSec),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: context.l10n.gamesRulesTitle,
                              child: Icon(Icons.extension_rounded,
                                  size: iconSz, color: AppColors.textSecondary),
                            ),
                            Text(
                              variantShortLabel(inv.variant),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Icon(Icons.person_outline_rounded,
                                size: iconSz, color: AppColors.textSecondary),
                            Text(
                              '${inv.maxPlayers}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => onDeclineInvite(inv.lobbyId),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: context.l10n.commonDecline,
                  style: IconButton.styleFrom(foregroundColor: Colors.red),
                ),
                IconButton.filled(
                  onPressed: () => onAcceptInvite(context, inv.lobbyId),
                  icon: const Icon(Icons.check_rounded),
                  tooltip: context.l10n.commonAccept,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentStart,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteGameIcon extends StatelessWidget {
  const _InviteGameIcon({required this.gameType});

  final String gameType;

  @override
  Widget build(BuildContext context) {
    final icon = switch (gameType) {
      'tictactoe' => Icons.grid_3x3_rounded,
      _ => Icons.grid_3x3_rounded,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentStart, AppColors.accentEnd],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 26),
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
          child:
              Icon(_presetIcons[idx], color: AppColors.accentStart, size: 26),
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
