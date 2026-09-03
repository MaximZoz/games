import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/battleship/battleship_provider.dart';
import 'package:multigames_client/games/battleship/battleship_rules.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/poker/poker_provider.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/games/uno/uno_provider.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/games/framework/framework.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/ui/widgets/nardy_game_icon.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/poker_game_icon.dart';
import 'package:multigames_client/ui/widgets/uno_game_icon.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';

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

class _GamesScreenState extends ConsumerState<GamesScreen>
    with SingleTickerProviderStateMixin {
  bool _isCreating = false;
  bool _isFinding = false;
  _GamesTab _selectedTab = _GamesTab.games;
  late final TabController _hubTabs;
  int _selectedTurnTimeSec = 0; // 0=без лимита, 10, 30, 60, 600
  String _selectedVariant = variantClassic;

  /// true — активна кнопка игроков (2/3/4); false — кнопка режима.
  bool _playersControlActive = false;
  int _selectedStakeBronze = 2; // free: 2, 10, 50; + bought silver/gold
  bool _settingsHydrated = false;
  Timer? _lobbyRefreshTimer;

  @override
  void initState() {
    super.initState();
    _hubTabs = TabController(
      length: 2,
      vsync: this,
      animationDuration: gamesLobbyTabAnimation,
    );
    _hubTabs.addListener(_onHubTabsTick);
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
    final saved = ref.read(userGameSettingsProvider('tictactoe')).valueOrNull;
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
    ref.read(userGameSettingsProvider('tictactoe').notifier).updateLocal(
          UserGameSettings(
            gameType: 'tictactoe',
            turnTimeSec: _selectedTurnTimeSec,
            variant: _selectedVariant,
            swapRule: false,
            firstMoveRestriction: false,
            stakeBronze: _selectedStakeBronze,
          ),
        );
  }

  void _onPlayersChipTap() {
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
    setState(() {
      const cycle = _modeCycleVariants;
      if (_playersControlActive ||
          _selectedVariant == variantMulti3 ||
          _selectedVariant == variantMulti4) {
        // С игроков → 2 участника и сразу следующий режим.
        _playersControlActive = false;
        final base = (_selectedVariant == variantMulti3 ||
                _selectedVariant == variantMulti4)
            ? variantClassic
            : parseVariant(_selectedVariant);
        final idx = cycle.indexOf(base);
        _selectedVariant = cycle[(idx < 0 ? 0 : idx + 1) % cycle.length];
      } else {
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
    _hubTabs.removeListener(_onHubTabsTick);
    _hubTabs.dispose();
    _stopLobbyPoll();
    super.dispose();
  }

  void _onHubTabsTick() {
    final value = _hubTabs.animation?.value ?? _hubTabs.index.toDouble();
    final tab = gamesLobbyTabIndexForAnimation(value) == 0
        ? _GamesTab.games
        : _GamesTab.lobbies;
    if (_selectedTab != tab) {
      _applySelectedTab(tab);
    }
  }

  void _startLobbyPoll() {
    _lobbyRefreshTimer?.cancel();
    // Чаще: отмена/старт должны быстро убирать карточку, даже без WS.
    _lobbyRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        unawaited(ref.read(openLobbiesProvider.notifier).reloadQuiet());
        unawaited(
          ref.read(gameInvitesProvider.notifier).hydrateFromServer(
                ref.read(gamesRepositoryProvider),
              ),
        );
      },
    );
  }

  void _stopLobbyPoll() {
    _lobbyRefreshTimer?.cancel();
    _lobbyRefreshTimer = null;
  }

  void _onTabChanged(_GamesTab tab) {
    final index = tab == _GamesTab.games ? 0 : 1;
    if (_hubTabs.index != index) {
      _hubTabs.animateTo(
        index,
        duration: gamesLobbyTabAnimation,
        curve: Curves.easeOutCubic,
      );
    }
    if (_selectedTab == tab) return;
    _applySelectedTab(tab);
  }

  void _applySelectedTab(_GamesTab tab) {
    setState(() => _selectedTab = tab);
    if (tab == _GamesTab.lobbies) {
      unawaited(ref.read(openLobbiesProvider.notifier).reloadQuiet());
      unawaited(
        ref.read(gameInvitesProvider.notifier).hydrateFromServer(
              ref.read(gamesRepositoryProvider),
            ),
      );
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
    final observation = ref.watch(observationGameProvider);
    final caps = ref.watch(inventoryCapabilitiesProvider).valueOrNull;
    // После GetActive / join — сразу в активную партию или «Войти в игру».
    ref.listen<AsyncValue<ActiveGameItem?>>(activeGameProvider, (prev, next) {
      final active = next.valueOrNull;
      if (active == null) return;
      final path =
          GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
      if (path != '/games') return;
      if (hasBlockingActiveMatch(active)) {
        goToActiveSession(context, active);
        return;
      }
      if (!hasActiveLobby(active)) return;
      // Живая партия (пин) важнее автоухода в лобби-инвайт.
      if (ref.read(blockingGamePinProvider)?.gameId.isNotEmpty ?? false) {
        return;
      }
      if (hasBlockingActiveMatch(prev?.valueOrNull)) {
        return;
      }
      goToActiveSession(context, active);
    });
    // Подхватываем конфиг крестиков из БД, когда он лениво догрузится.
    ref.listen<AsyncValue<UserGameSettings>>(
        userGameSettingsProvider('tictactoe'), (prev, next) {
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
    // Разблокированные ставки; для выбора — только те, что можно оплатить
    // всем balance_bronze (1 серебро = 100 бронзы). Иначе «2» с серебряной
    // монетой (=200) при балансе 1с+1бр даёт «Недостаточно монет».
    final unlockedStakes =
        caps?.allowedStakeBronze ?? List<int>.from(freeStakeOptions);
    final balanceBronze =
        ref.watch(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    final affordable = affordableStakeOptions(balanceBronze, unlockedStakes);
    final availableStakes = affordable.isNotEmpty ? affordable : unlockedStakes;
    if (!availableStakes.contains(_selectedStakeBronze) &&
        availableStakes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final next = clampStakeToAffordable(
          _selectedStakeBronze,
          balanceBronze,
          availableStakes,
        );
        setState(() => _selectedStakeBronze = next);
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
        if (!mounted) return;
        _hubTabs.index = 0;
        setState(() => _selectedTab = _GamesTab.games);
      });
    }
    // Уже есть активная партия/лобби при открытии списка — сразу туда.
    final activeSession = activeAsync.valueOrNull;
    if (!isOffline &&
        activeSession != null &&
        (hasBlockingActiveMatch(activeSession) ||
            hasActiveLobby(activeSession))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final path =
            GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
        if (path != '/games') return;
        goToActiveSession(context, activeSession);
      });
    }

    void playOffline() {
      final offlineVariant = parseVariant(_selectedVariant);
      final qs = <String, String>{
        'variant': offlineVariant,
        'grid': '${gridSizeForVariant(offlineVariant)}',
        // В офлайне всегда чередуем, кто начинает (для 2 игроков).
        'swap': '1',
      };
      final uri = Uri(
        path: '/games/tictactoe/offline',
        queryParameters: qs,
      );
      disposeAllOfflineGameSessions();
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
                padding: EdgeInsets.fromLTRB(
                  contentPadding,
                  phoneLandscape ? 4 : 8,
                  contentPadding,
                  phoneLandscape ? 6 : 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _GamesTabSwitcher(
                      selectedTab: _selectedTab,
                      onTabChanged: _onTabChanged,
                      lobbyBadgeCount: invites.length,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: isOffline
                  ? AppOpaqueSurface(
                      child: RepaintBoundary(
                        key: const ValueKey('games-tab-content'),
                        child: _GamesPageContent(
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
                          stakeBronze: 0,
                          stakeOptionsList: availableStakes,
                          onStakeChanged: (v) {
                            setState(() => _selectedStakeBronze = v);
                            _persistSettings();
                          },
                          onCreateGame: () => _createGame(context, 'invite'),
                          onFindGame: () =>
                              _createGame(context, 'matchmake'),
                          onPlayOffline: playOffline,
                          contentPadding: contentPadding,
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _hubTabs,
                      physics: const PageScrollPhysics(),
                      children: [
                        AppOpaqueSurface(
                          child: RepaintBoundary(
                            key: const ValueKey('games-tab-content'),
                            child: _GamesPageContent(
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
                              stakeBronze: _selectedStakeBronze,
                              stakeOptionsList: availableStakes,
                              onStakeChanged: (v) {
                                setState(() => _selectedStakeBronze = v);
                                _persistSettings();
                              },
                              onCreateGame: () =>
                                  _createGame(context, 'invite'),
                              onFindGame: () =>
                                  _createGame(context, 'matchmake'),
                              onPlayOffline: playOffline,
                              contentPadding: contentPadding,
                            ),
                          ),
                        ),
                        AppOpaqueSurface(
                          child: RepaintBoundary(
                            key: const ValueKey('lobbies-tab-content'),
                            child: _LobbiesPageContent(
                              lobbiesAsync: lobbiesAsync,
                              invites: invites,
                              isDesktop: isDesktop,
                              onJoinLobby: _joinLobby,
                              onShowLobbyRules: _showLobbyRulesInfo,
                              onRefresh: () => unawaited(
                                ref
                                    .read(openLobbiesProvider.notifier)
                                    .reloadQuiet(),
                              ),
                              onAcceptInvite: _acceptInvite,
                              onDeclineInvite: _declineInvite,
                              onShowCreatorInfo: _showCreatorInfo,
                              onShowInviteRules: _showInviteRules,
                              contentPadding: contentPadding,
                              activeAsync: activeAsync,
                              observation: observation,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Обновить баланс и убедиться, что ставка по карману (весь кошелёк).
  Future<bool> _ensureStakeAffordable(int stakeBronze) async {
    try {
      await ref.read(authStateProvider.notifier).refresh();
    } catch (_) {}
    if (!mounted) return false;
    final balance = ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    if (canAffordStake(balanceBronze: balance, stakeBronze: stakeBronze)) {
      return true;
    }
    showAppSnackBar(
      context,
      message: context.l10n.commonInsufficientCoins,
      kind: AppSnackKind.error,
    );
    final caps = ref.read(inventoryCapabilitiesProvider).valueOrNull;
    final unlocked =
        caps?.allowedStakeBronze ?? List<int>.from(freeStakeOptions);
    final next = clampStakeToAffordable(stakeBronze, balance, unlocked);
    if (next != stakeBronze) {
      setState(() => _selectedStakeBronze = next);
      _persistSettings();
    }
    return false;
  }

  Future<void> _createGame(BuildContext context, String mode) async {
    // Async: после конца партии пин/кэш могли ещё держать старый gameId.
    if (await blockJoinIfBusyAsync(context, ref, redirectToActive: true)) {
      return;
    }
    if (!context.mounted) return;
    if (!await _ensureStakeAffordable(_selectedStakeBronze)) return;
    if (!context.mounted) return;
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
        pinBlockingGame(ref, result.gameId);
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
          message: isFinishCurrentGameError(e)
              ? finishCurrentGameMessage
              : formatUserError(e),
          kind: AppSnackKind.error,
        );
        if (isFinishCurrentGameError(e)) {
          try {
            final active =
                await ref.read(activeGameProvider.notifier).refresh();
            if (context.mounted && active != null) {
              goToActiveSession(context, active);
            }
          } catch (_) {}
        }
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

  Future<void> _acceptInvite(BuildContext context, GameInvite inv) async {
    final lobbyId = inv.lobbyId;
    if (await blockJoinIfBusyAsync(
      context,
      ref,
      targetLobbyId: lobbyId,
      redirectToActive: true,
    )) {
      return;
    }
    // Ветвление по game_type: используем правильный repository + роут.
    if (inv.gameType == 'durak') {
      try {
        final res = await ref.read(durakRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'durak',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'durak');
          if (context.mounted) {
            context.go('/games/durak/game/${res.gameId}');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'durak',
                ),
              );
          if (context.mounted) {
            context.go('/games/durak/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    if (inv.gameType == 'battleship') {
      try {
        final res =
            await ref.read(battleshipRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'battleship',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'battleship');
          if (context.mounted) {
            context.go('/games/battleship/game/${res.gameId}');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'battleship',
                ),
              );
          if (context.mounted) {
            context.go('/games/battleship/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    if (inv.gameType == 'poker') {
      try {
        final res = await ref.read(pokerRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'poker',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'poker');
          if (context.mounted) {
            context.go('/games/poker/game/${res.gameId}');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'poker',
                ),
              );
          if (context.mounted) {
            context.go('/games/poker/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    if (inv.gameType == 'uno') {
      try {
        final res = await ref.read(unoRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'uno',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'uno');
          if (context.mounted) {
            context.go('/games/uno/game/${res.gameId}');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'uno',
                ),
              );
          if (context.mounted) {
            context.go('/games/uno/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
      if (result.joined && result.waitingMore) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        ref.invalidate(openLobbiesProvider);
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        if (context.mounted) {
          context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        }
        return;
      }
      if (result.joined && result.gameId != null) {
        pinBlockingGame(ref, result.gameId);
        _navigateToJoinedGame(result.gameId!);
      }
    } on GamesException catch (e) {
      if (!context.mounted) return;
      if (e.statusCode == 409 || isFinishCurrentGameError(e)) {
        _showInviteError(e);
        // Только серверная active-сессия — не URL старой партии.
        final active = ref.read(activeGameProvider).valueOrNull;
        if (active != null &&
            (hasBlockingActiveMatch(active) || hasActiveLobby(active))) {
          goToActiveSession(context, active);
        }
        return;
      }
      if (_isAlreadyInLobbyError(e)) {
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        if (context.mounted) {
          context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        }
        return;
      }
      ref.read(gameInvitesProvider.notifier).remove(lobbyId);
      _showInviteError(e);
    } catch (e) {
      // Лобби уже нет — убрать «висящее» приглашение.
      ref.read(gameInvitesProvider.notifier).remove(lobbyId);
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
        message: isFinishCurrentGameError(error)
            ? finishCurrentGameMessage
            : formatUserError(error),
        kind: AppSnackKind.error,
      );
    }
  }

  /// Правила приглашения по game_type: инжектируем нужный набор.
  Widget _inviteRulesWidget(GameInvite inv) {
    if (inv.isDurak) {
      return rulesTextLines(durakRuleLines(
        mode: inv.durakMode,
        players: inv.maxPlayers,
        deckSize: inv.deckSize,
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
      ));
    }
    if (inv.isBattleship) {
      return rulesTextLines(battleshipRuleLines(
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
        l10n: context.l10n,
      ));
    }
    if (inv.isPoker) {
      return rulesTextLines(pokerRuleLines(
        players: inv.maxPlayers,
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
        l10n: context.l10n,
      ));
    }
    if (inv.isUno) {
      return rulesTextLines(unoRuleLines(
        players: inv.maxPlayers,
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
        l10n: context.l10n,
      ));
    }
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
    unawaited(
      showUserProfileDialog(
        context: context,
        ref: ref,
        userId: inv.creatorId,
        displayName: inv.creatorName,
        avatarKind: inv.creatorAvatarKind,
        avatarValue: inv.creatorAvatarValue,
        messageFrom: 'games',
      ),
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

  Future<void> _declineInvite(String lobbyId,
      {String gameType = 'tictactoe'}) async {
    ref.read(gameInvitesProvider.notifier).remove(lobbyId);
    try {
      if (gameType == 'durak') {
        await ref.read(durakRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'battleship') {
        await ref.read(battleshipRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'poker') {
        await ref.read(pokerRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'uno') {
        await ref.read(unoRepositoryProvider).declineLobby(lobbyId);
      } else {
        await ref.read(gamesRepositoryProvider).declineLobby(lobbyId);
      }
    } catch (_) {
      // Карточка уже скрыта локально; сервер мог уже закрыть лобби.
    }
  }

  Future<void> _joinLobby(
    BuildContext context,
    String lobbyId, {
    String gameType = 'tictactoe',
  }) async {
    if (await blockJoinIfBusyAsync(
      context,
      ref,
      targetLobbyId: lobbyId,
      redirectToActive: true,
    )) {
      return;
    }
    // Durak — свой стек API и роутов.
    if (gameType == 'durak') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res = await ref.read(durakRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'durak',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'durak');
          context.go('/games/durak/game/${res.gameId}');
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'durak',
                ),
              );
          context.go('/games/durak/lobby/$lobbyId?mode=invite');
        }
      } on GamesException catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          message: isFinishCurrentGameError(e)
              ? finishCurrentGameMessage
              : formatUserError(e),
          kind: AppSnackKind.error,
        );
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context,
              message: formatUserError(e), kind: AppSnackKind.error);
        }
      }
      return;
    }
    if (gameType == 'battleship') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res =
            await ref.read(battleshipRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'battleship',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'battleship');
          context.go('/games/battleship/game/${res.gameId}');
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'battleship',
                ),
              );
          context.go('/games/battleship/lobby/$lobbyId?mode=invite');
        }
      } on GamesException catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          message: isFinishCurrentGameError(e)
              ? finishCurrentGameMessage
              : formatUserError(e),
          kind: AppSnackKind.error,
        );
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context,
              message: formatUserError(e), kind: AppSnackKind.error);
        }
      }
      return;
    }
    if (gameType == 'poker') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res = await ref.read(pokerRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'poker',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'poker');
          context.go('/games/poker/game/${res.gameId}');
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'poker',
                ),
              );
          context.go('/games/poker/lobby/$lobbyId?mode=invite');
        }
      } on GamesException catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          message: isFinishCurrentGameError(e)
              ? finishCurrentGameMessage
              : formatUserError(e),
          kind: AppSnackKind.error,
        );
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context,
              message: formatUserError(e), kind: AppSnackKind.error);
        }
      }
      return;
    }
    if (gameType == 'uno') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res = await ref.read(unoRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'uno',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'uno');
          context.go('/games/uno/game/${res.gameId}');
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'uno',
                ),
              );
          context.go('/games/uno/lobby/$lobbyId?mode=invite');
        }
      } on GamesException catch (error) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          message: isFinishCurrentGameError(error)
              ? finishCurrentGameMessage
              : formatUserError(error),
          kind: AppSnackKind.error,
        );
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            message: formatUserError(error),
            kind: AppSnackKind.error,
          );
        }
      }
      return;
    }
    try {
      ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(lobbyId);
      if (!context.mounted) return;
      ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
      ref.invalidate(openLobbiesProvider);
      if (result.joined && result.waitingMore) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
        context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        return;
      }
      if (result.joined && result.gameId != null) {
        pinBlockingGame(ref, result.gameId);
        context.push('/games/tictactoe/game/${result.gameId}');
      }
    } on GamesException catch (e) {
      if (!context.mounted) return;
      if (e.statusCode == 409 || isFinishCurrentGameError(e)) {
        showAppSnackBar(
          context,
          message: finishCurrentGameMessage,
          kind: AppSnackKind.error,
        );
        final active = resolveActiveForGuard(ref, context);
        if (active != null) goToActiveSession(context, active);
        return;
      }
      if (_isAlreadyInLobbyError(e)) {
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(type: 'lobby', lobbyId: lobbyId),
            );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        context.go('/games/tictactoe/lobby/$lobbyId?mode=invite');
        return;
      }
      showAppSnackBar(
        context,
        message: formatUserError(e),
        kind: AppSnackKind.error,
      );
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

  bool _isAlreadyInLobbyError(Object e) {
    if (e is! GamesException) return false;
    if (e.statusCode != 400) return false;
    final msg = e.message.toLowerCase();
    return msg.contains('already in lobby') || msg.contains('уже в лобби');
  }

  void _showLobbyRulesInfo(BuildContext context, LobbyItem lobby) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDesktop = MediaQuery.sizeOf(ctx).width >= 700;
        final Widget body;
        if (lobby.isBattleship) {
          body = rulesTextLines(battleshipRuleLines(
            turnTimeSec: lobby.turnTimeSec,
            stakeBronze: lobby.stakeBronze,
            l10n: context.l10n,
          ));
        } else if (lobby.isDurak) {
          body = rulesTextLines(durakRuleLines(
            mode: lobby.gameMode,
            players: lobby.maxPlayers,
            deckSize: lobby.deckSize,
            turnTimeSec: lobby.turnTimeSec,
            stakeBronze: lobby.stakeBronze,
          ));
        } else if (lobby.isPoker) {
          body = rulesTextLines(pokerRuleLines(
            players: lobby.maxPlayers,
            turnTimeSec: lobby.turnTimeSec,
            stakeBronze: lobby.stakeBronze,
          ));
        } else if (lobby.isUno) {
          body = rulesTextLines(unoRuleLines(
            players: lobby.maxPlayers,
            turnTimeSec: lobby.turnTimeSec,
            stakeBronze: lobby.stakeBronze,
          ));
        } else {
          body = buildTictactoeRulesTextWidget(
            variant: lobby.variant,
            gridSize: lobby.gridSize,
            turnTimeSec: lobby.turnTimeSec,
            swapRule: lobby.swapRule,
            firstMoveRestriction: lobby.firstMoveRestriction,
            stakeBronze: lobby.stakeBronze,
          );
        }
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: isDesktop ? 40 : 24,
          ),
          title: Text(context.l10n.gamesRules),
          content: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
            child: SingleChildScrollView(child: body),
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

class _GamesPageContent extends ConsumerWidget {
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
  final double contentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneLandscape = isPhoneLandscape(context);

    Widget gameCards(double maxWidth) {
      const gap = 16.0;
      final cols = gamesHubTileColumns(
        maxWidth: maxWidth,
        wide: isDesktop,
      );
      final tileWidth = gamesHubTileWidth(maxWidth: maxWidth, cols: cols);
      final tiles = <Widget>[
        _TictactoeGameCard(
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
        _DurakGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _BattleshipGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _PokerGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _UnoGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _NardyGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
      ];
      return Align(
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        ),
      );
    }

    // ListView без minHeight на весь экран: иначе при скролле карточки
    // «уезжают» в пустоту и визуально пропадают.
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            contentPadding,
            isOffline ? 12 : 8,
            contentPadding,
            isDesktop || phoneLandscape ? 24 : 48,
          ),
          children: [
            gameCards(
              (constraints.maxWidth - contentPadding * 2).clamp(0.0, 2000.0),
            ),
          ],
        );
      },
    );
  }
}

class _LobbiesPageContent extends ConsumerWidget {
  const _LobbiesPageContent({
    required this.lobbiesAsync,
    required this.invites,
    required this.isDesktop,
    required this.onJoinLobby,
    required this.onShowLobbyRules,
    required this.onRefresh,
    required this.onAcceptInvite,
    required this.onDeclineInvite,
    required this.onShowCreatorInfo,
    required this.onShowInviteRules,
    required this.contentPadding,
    required this.activeAsync,
    required this.observation,
  });

  final AsyncValue<List<LobbyItem>> lobbiesAsync;
  final List<GameInvite> invites;
  final bool isDesktop;
  final void Function(BuildContext, String, {String gameType}) onJoinLobby;
  final void Function(BuildContext, LobbyItem) onShowLobbyRules;
  final VoidCallback onRefresh;
  final void Function(BuildContext, GameInvite) onAcceptInvite;
  final void Function(String, {String gameType}) onDeclineInvite;
  final void Function(BuildContext, GameInvite) onShowCreatorInfo;
  final void Function(BuildContext, GameInvite) onShowInviteRules;
  final double contentPadding;
  final AsyncValue<ActiveGameItem?> activeAsync;
  final ObservationItem? observation;

  Widget _invitesSection(BuildContext context) {
    if (invites.isEmpty) return const SizedBox.shrink();
    final inviteContent = invites.map(
      (inv) => _InviteCard(
        key: ValueKey('invite-${inv.lobbyId}'),
        inv: inv,
        onShowCreatorInfo: onShowCreatorInfo,
        onShowInviteRules: onShowInviteRules,
        onDeclineInvite: onDeclineInvite,
        onAcceptInvite: onAcceptInvite,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            context.l10n.gamesInvitedYou,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(height: 12),
        if (isDesktop || isPhoneLandscape(context))
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const minCardWidth = 360.0;
              const gap = 16.0;
              final crossAxisCount =
                  (width / (minCardWidth + gap)).floor().clamp(1, 4);
              final itemWidth =
                  (width - gap * (crossAxisCount - 1)) / crossAxisCount;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: inviteContent
                    .map((w) => SizedBox(width: itemWidth, child: w))
                    .toList(),
              );
            },
          )
        else
          ...inviteContent.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: w,
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obs = observation;
    return ListView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(contentPadding, 8, contentPadding, 48),
      children: [
        if (obs != null) ...[
          GameObservationCard(
            observation: obs,
            active: activeAsync.valueOrNull,
          ),
          const SizedBox(height: 16),
        ],
        _invitesSection(context),
        lobbiesAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (lobbies) {
            // Пустое лобби — без заглушки («Лобби» / refresh).
            if (lobbies.isEmpty) {
              return const SizedBox.shrink();
            }
            final lobbyCards = lobbies
                .map(
                  (lobby) => Padding(
                    padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 6),
                    child: GradientCard(
                      animate: false,
                      padding: EdgeInsets.all(isDesktop ? 20 : 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GameTypeIcon(
                            gameType: lobby.gameType,
                            size: isDesktop ? 36 : 32,
                            color: AppColors.accentStart,
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizedGameTypeName(
                                    lobby.gameType,
                                    context.l10n,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: isDesktop ? 16 : 14,
                                  ),
                                ),
                                Text(
                                  lobby.creatorName.trim().isNotEmpty
                                      ? lobby.creatorName
                                      : context.l10n.commonPlayer,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                    fontSize: isDesktop ? 13 : 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (lobby.stakeBronze > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formatStakeAmount(
                                                lobby.stakeBronze),
                                            style: TextStyle(
                                              fontSize: isDesktop ? 14 : 13,
                                              color: AppColors.textSecondary,
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
                                    if (!lobby.isPoker)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            lobby.isBattleship
                                                ? Icons.grid_on_rounded
                                                : lobby.isDurak
                                                    ? Icons.swap_horiz_rounded
                                                    : Icons.extension_rounded,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lobby.isBattleship
                                                ? '10×10'
                                                : lobby.isDurak
                                                    ? '${durakModeLabel(lobby.gameMode, context.l10n)} · ${durakDeckLabel(lobby.deckSize, context.l10n)}'
                                                    : variantShortLabel(
                                                        lobby.variant),
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
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${lobby.maxPlayers}',
                                          style: TextStyle(
                                            fontSize: isDesktop ? 14 : 13,
                                            color: AppColors.textSecondary,
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
                            onPressed: () => onShowLobbyRules(context, lobby),
                            icon: const Icon(Icons.info_outline_rounded),
                            tooltip: context.l10n.gamesRulesTitle,
                          ),
                          IconButton.filled(
                            onPressed: () => onJoinLobby(context, lobby.id,
                                gameType: lobby.gameType),
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
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const minCardWidth = 360.0;
                  const gap = 16.0;
                  final crossAxisCount =
                      (width / (minCardWidth + gap)).floor().clamp(1, 4);
                  final itemWidth =
                      (width - gap * (crossAxisCount - 1)) / crossAxisCount;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.center,
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
                },
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
    );
  }
}

/// Карточка «Дурак» — визуально идентична `_TictactoeGameCard`, использует
/// общие виджеты `GameCard*` из `ui/widgets/game_card_widgets.dart`.
class _DurakGameCard extends ConsumerStatefulWidget {
  const _DurakGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_DurakGameCard> createState() => _DurakGameCardState();
}

class _DurakGameCardState extends ConsumerState<_DurakGameCard> {
  // Свои настройки (не общие с крестиками) — hydrate из userGameSettings(durak).
  int _players = 2;
  int _deckSize = 36;
  String _gameMode = 'podkidnoi'; // podkidnoi | perevodnoi
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  bool _settingsHydrated = false;
  bool _creating = false;
  bool _finding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateFromSaved();
    });
  }

  void _hydrateFromSaved() {
    if (_settingsHydrated) return;
    final saved = ref.read(userGameSettingsProvider('durak')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _players = saved.maxPlayers.clamp(2, 4);
      _deckSize = durakClampDeckForPlayers(_players, saved.deckSize);
      _gameMode = saved.gameMode == 'perevodnoi' ? 'perevodnoi' : 'podkidnoi';
      _turnTimeSec =
          turnTimeOptions.contains(saved.turnTimeSec) ? saved.turnTimeSec : 60;
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('durak').notifier).updateLocal(
          gameCardSettings(
            gameType: 'durak',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
            deckSize: _deckSize,
            maxPlayers: _players,
            gameMode: _gameMode,
          ),
        );
  }

  Future<bool> _ensureStakeAffordable() async {
    try {
      await ref.read(authStateProvider.notifier).refresh();
    } catch (_) {}
    if (!mounted) return false;
    final balance = ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    if (canAffordStake(balanceBronze: balance, stakeBronze: _stakeBronze)) {
      return true;
    }
    showAppSnackBar(
      context,
      message: context.l10n.commonInsufficientCoins,
      kind: AppSnackKind.error,
    );
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final next = clampStakeToAffordable(_stakeBronze, balance, options);
    if (next != _stakeBronze) {
      setState(() => _stakeBronze = next);
      _persistSettings();
    }
    return false;
  }

  Future<void> _create(String mode) async {
    if (await blockJoinIfBusyAsync(context, ref, redirectToActive: true)) {
      return;
    }
    if (!context.mounted) return;
    if (!await _ensureStakeAffordable()) return;
    if (!context.mounted) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final repo = ref.read(durakRepositoryProvider);
      final result = await repo.createLobby(
        mode: mode,
        maxPlayers: _players,
        deckSize: _deckSize,
        gameMode: _gameMode,
        turnTimeSec: _turnTimeSec,
        stakeBronze: _stakeBronze,
      );
      if (!mounted) return;
      final lobbyId = result.lobbyId;
      final gameId = result.gameId;
      if (gameId != null && gameId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: lobbyId.isEmpty ? null : lobbyId,
                gameType: 'durak',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'durak');
        context.push('/games/durak/game/$gameId');
      } else if (lobbyId.isEmpty) {
        // Сервер не вернул ни лобби, ни партию — не строим битый роут.
        showAppSnackBar(
          context,
          message: context.l10n.commonTryLater,
          kind: AppSnackKind.error,
        );
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'durak',
              ),
            );
        context.push('/games/durak/lobby/$lobbyId?mode=$mode');
      }
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: isFinishCurrentGameError(e)
            ? finishCurrentGameMessage
            : formatUserError(e),
        kind: AppSnackKind.error,
      );
      // Сервер видит активную партию, а кэш мог отстать — увести в неё.
      if (isFinishCurrentGameError(e)) {
        try {
          final active = await ref.read(activeGameProvider.notifier).refresh();
          if (!mounted) return;
          if (active != null) goToActiveSession(context, active);
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context,
          message: formatUserError(e), kind: AppSnackKind.error);
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
          _finding = false;
        });
      }
    }
  }

  void _cyclePlayers() {
    setState(() {
      _players = _players == 4 ? 2 : _players + 1;
      _deckSize = durakClampDeckForPlayers(_players, _deckSize);
    });
    _persistSettings();
  }

  void _cycleGameMode() {
    // Подкидной ↔ переводной всегда доступны, без сброса игроков/колоды.
    setState(() {
      _gameMode = _gameMode == 'podkidnoi' ? 'perevodnoi' : 'podkidnoi';
    });
    _persistSettings();
  }

  void _cycleDeck() {
    setState(() {
      final options = durakDeckSizesForPlayers(_players);
      final i = options.indexOf(_deckSize);
      _deckSize = options[(i < 0 ? 0 : i + 1) % options.length];
    });
    _persistSettings();
  }

  void _cycleTurnTime() {
    setState(() {
      const arr = [20, 60, 600, 0];
      _turnTimeSec = arr[(arr.indexOf(_turnTimeSec) + 1) % arr.length];
    });
    _persistSettings();
  }

  void _cycleStake() {
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final idx = options.indexOf(_stakeBronze);
    final next = options[(idx < 0 ? 0 : idx + 1) % options.length];
    setState(() => _stakeBronze = next);
    _persistSettings();
  }

  String _modeLabel(String m) => durakModeLabel(m, context.l10n);

  String _deckLabel(int n) => durakDeckLabel(n, context.l10n);

  @override
  Widget build(BuildContext context) {
    // Поздняя подгрузка настроек с сервера.
    ref.listen<AsyncValue<UserGameSettings>>(userGameSettingsProvider('durak'),
        (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _players = saved.maxPlayers.clamp(2, 4);
        _deckSize = durakClampDeckForPlayers(_players, saved.deckSize);
        _gameMode = saved.gameMode == 'perevodnoi' ? 'perevodnoi' : 'podkidnoi';
        _turnTimeSec = turnTimeOptions.contains(saved.turnTimeSec)
            ? saved.turnTimeSec
            : 60;
        _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
      });
    });
    final available = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    if (!available.contains(_stakeBronze) && available.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _stakeBronze = available.first);
        if (_settingsHydrated) _persistSettings();
      });
    }

    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final busy = _creating || _finding;

    final chips = <Widget>[
      GameCardChip(
        selected: true,
        icon: Icons.groups_rounded,
        label: '$_players',
        onTap: busy ? null : _cyclePlayers,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: busy ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
      GameCardChip(
        selected: true,
        icon: Icons.swap_horiz_rounded,
        label: _modeLabel(_gameMode),
        onTap: busy ? null : _cycleGameMode,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      GameCardChip(
        selected: true,
        icon: DurakGameIcon.iconData,
        iconChild: DurakGameIcon(
          size: isDesktop ? 18 : 16,
          color: AppColors.accentStart,
        ),
        label: _deckLabel(_deckSize),
        onTap: busy ? null : _cycleDeck,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    ];

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesDurak,
        icon: DurakGameIcon.iconData,
        iconChild: const DurakGameIcon(size: 26, color: Colors.white),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: busy ? null : _cycleStake,
        onInfoTap: busy ? null : () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.gamesFindMatch,
        findingLabel: context.l10n.commonSearching,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: () {
          final qs = <String, String>{
            'deck': '$_deckSize',
            'players': '$_players',
            'mode': _gameMode,
          };
          disposeAllOfflineGameSessions();
          context.push(
            Uri(path: '/games/durak/offline', queryParameters: qs).toString(),
          );
        },
        isCreating: _creating,
        isFinding: _finding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: rulesTextLines(durakRuleLines(
        mode: _gameMode,
        players: _players,
        deckSize: _deckSize,
        turnTimeSec: _turnTimeSec,
        stakeBronze: _stakeBronze,
        offlineBot: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }
}

/// Карточка «Морской бой» — ставка и время хода; офлайн — игра с ботом.
class _BattleshipGameCard extends ConsumerStatefulWidget {
  const _BattleshipGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_BattleshipGameCard> createState() =>
      _BattleshipGameCardState();
}

class _BattleshipGameCardState extends ConsumerState<_BattleshipGameCard> {
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  bool _settingsHydrated = false;
  bool _creating = false;
  bool _finding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateFromSaved();
    });
  }

  void _hydrateFromSaved() {
    if (_settingsHydrated) return;
    final saved = ref.read(userGameSettingsProvider('battleship')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _turnTimeSec =
          turnTimeOptions.contains(saved.turnTimeSec) ? saved.turnTimeSec : 60;
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('battleship').notifier).updateLocal(
          gameCardSettings(
            gameType: 'battleship',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
          ),
        );
  }

  Future<bool> _ensureStakeAffordable() async {
    try {
      await ref.read(authStateProvider.notifier).refresh();
    } catch (_) {}
    if (!mounted) return false;
    final balance = ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    if (canAffordStake(balanceBronze: balance, stakeBronze: _stakeBronze)) {
      return true;
    }
    showAppSnackBar(
      context,
      message: context.l10n.commonInsufficientCoins,
      kind: AppSnackKind.error,
    );
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final next = clampStakeToAffordable(_stakeBronze, balance, options);
    if (next != _stakeBronze) {
      setState(() => _stakeBronze = next);
      _persistSettings();
    }
    return false;
  }

  Future<void> _create(String mode) async {
    if (await blockJoinIfBusyAsync(context, ref, redirectToActive: true)) {
      return;
    }
    if (!context.mounted) return;
    if (!await _ensureStakeAffordable()) return;
    if (!context.mounted) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final repo = ref.read(battleshipRepositoryProvider);
      final result = await repo.createLobby(
        mode: mode,
        turnTimeSec: _turnTimeSec,
        stakeBronze: _stakeBronze,
      );
      if (!mounted) return;
      final lobbyId = result.lobbyId;
      final gameId = result.gameId;
      if (gameId != null && gameId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: lobbyId.isEmpty ? null : lobbyId,
                gameType: 'battleship',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'battleship');
        context.push('/games/battleship/game/$gameId');
      } else if (lobbyId.isEmpty) {
        showAppSnackBar(
          context,
          message: context.l10n.commonTryLater,
          kind: AppSnackKind.error,
        );
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'battleship',
              ),
            );
        context.push('/games/battleship/lobby/$lobbyId?mode=$mode');
      }
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: isFinishCurrentGameError(e)
            ? finishCurrentGameMessage
            : formatUserError(e),
        kind: AppSnackKind.error,
      );
      if (isFinishCurrentGameError(e)) {
        try {
          final active = await ref.read(activeGameProvider.notifier).refresh();
          if (!mounted) return;
          if (active != null) goToActiveSession(context, active);
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context,
          message: formatUserError(e), kind: AppSnackKind.error);
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
          _finding = false;
        });
      }
    }
  }

  void _cycleTurnTime() {
    setState(() {
      const arr = [20, 60, 600, 0];
      _turnTimeSec = arr[(arr.indexOf(_turnTimeSec) + 1) % arr.length];
    });
    _persistSettings();
  }

  void _cycleStake() {
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final idx = options.indexOf(_stakeBronze);
    final next = options[(idx < 0 ? 0 : idx + 1) % options.length];
    setState(() => _stakeBronze = next);
    _persistSettings();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserGameSettings>>(
        userGameSettingsProvider('battleship'), (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _turnTimeSec = turnTimeOptions.contains(saved.turnTimeSec)
            ? saved.turnTimeSec
            : 60;
        _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
      });
    });
    final available = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    if (!available.contains(_stakeBronze) && available.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _stakeBronze = available.first);
        if (_settingsHydrated) _persistSettings();
      });
    }

    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final busy = _creating || _finding;

    final chips = <Widget>[
      // Как в крестиках: «2» игрока, всегда тёмная и неактивная.
      GameCardChip(
        selected: false,
        icon: Icons.groups_rounded,
        label: '2',
        onTap: null,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: busy ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
    ];

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesBattleship,
        icon: Icons.directions_boat_filled_rounded,
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: busy || widget.isOffline ? null : _cycleStake,
        onInfoTap: busy ? null : () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.gamesFindMatch,
        findingLabel: context.l10n.commonSearching,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: () {
          disposeAllOfflineGameSessions();
          context.push('/games/battleship/offline');
        },
        isCreating: _creating,
        isFinding: _finding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.rulesBattleshipTitle,
      content: rulesTextLines(battleshipRuleLines(
        turnTimeSec: _turnTimeSec,
        stakeBronze: _stakeBronze,
        offlineBot: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }
}

/// Карточка «Покер» — превью настроек; игра пока в разработке.
/// Карточка «Покер» (Texas Hold'em) — игроки/время/ставка; офлайн — игра с ботами.
class _PokerGameCard extends ConsumerStatefulWidget {
  const _PokerGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_PokerGameCard> createState() => _PokerGameCardState();
}

class _PokerGameCardState extends ConsumerState<_PokerGameCard> {
  // Онлайн и офлайн: стол с 2–6 мест, как в других играх.
  static const _playerOptions = <int>[2, 3, 4, 5, 6];

  int _players = 2;
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  bool _settingsHydrated = false;
  bool _creating = false;
  bool _finding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateFromSaved();
    });
  }

  void _hydrateFromSaved() {
    if (_settingsHydrated) return;
    final saved = ref.read(userGameSettingsProvider('poker')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _players = saved.maxPlayers.clamp(2, 6);
      _turnTimeSec =
          turnTimeOptions.contains(saved.turnTimeSec) ? saved.turnTimeSec : 60;
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('poker').notifier).updateLocal(
          gameCardSettings(
            gameType: 'poker',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
            maxPlayers: _players,
          ),
        );
  }

  Future<bool> _ensureStakeAffordable() async {
    try {
      await ref.read(authStateProvider.notifier).refresh();
    } catch (_) {}
    if (!mounted) return false;
    final balance = ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    if (canAffordStake(balanceBronze: balance, stakeBronze: _stakeBronze)) {
      return true;
    }
    showAppSnackBar(
      context,
      message: context.l10n.commonInsufficientCoins,
      kind: AppSnackKind.error,
    );
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final next = clampStakeToAffordable(_stakeBronze, balance, options);
    if (next != _stakeBronze) {
      setState(() => _stakeBronze = next);
      _persistSettings();
    }
    return false;
  }

  Future<void> _create(String mode) async {
    if (await blockJoinIfBusyAsync(context, ref, redirectToActive: true)) {
      return;
    }
    if (!context.mounted) return;
    if (!await _ensureStakeAffordable()) return;
    if (!context.mounted) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final repo = ref.read(pokerRepositoryProvider);
      final result = await repo.createLobby(
        mode: mode,
        maxPlayers: _players,
        turnTimeSec: _turnTimeSec,
        stakeBronze: _stakeBronze,
      );
      if (!mounted) return;
      final lobbyId = result.lobbyId;
      final gameId = result.gameId;
      if (gameId != null && gameId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: lobbyId.isEmpty ? null : lobbyId,
                gameType: 'poker',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'poker');
        context.push('/games/poker/game/$gameId');
      } else if (lobbyId.isEmpty) {
        showAppSnackBar(
          context,
          message: context.l10n.commonTryLater,
          kind: AppSnackKind.error,
        );
      } else {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'poker',
              ),
            );
        context.push('/games/poker/lobby/$lobbyId?mode=$mode');
      }
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: isFinishCurrentGameError(e)
            ? finishCurrentGameMessage
            : formatUserError(e),
        kind: AppSnackKind.error,
      );
      if (isFinishCurrentGameError(e)) {
        try {
          final active = await ref.read(activeGameProvider.notifier).refresh();
          if (!mounted) return;
          if (active != null) goToActiveSession(context, active);
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context,
          message: formatUserError(e), kind: AppSnackKind.error);
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
          _finding = false;
        });
      }
    }
  }

  void _cyclePlayers() {
    final i = _playerOptions.indexOf(_players);
    setState(() {
      _players = _playerOptions[(i < 0 ? 0 : i + 1) % _playerOptions.length];
    });
    _persistSettings();
  }

  void _cycleTurnTime() {
    setState(() {
      final i = turnTimeOptions.indexOf(_turnTimeSec);
      _turnTimeSec =
          turnTimeOptions[(i < 0 ? 0 : i + 1) % turnTimeOptions.length];
    });
    _persistSettings();
  }

  void _cycleStake() {
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final idx = options.indexOf(_stakeBronze);
    setState(() {
      _stakeBronze = options[(idx < 0 ? 0 : idx + 1) % options.length];
    });
    _persistSettings();
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: rulesTextLines(pokerRuleLines(
        players: _players < 2 ? 2 : _players,
        turnTimeSec: _turnTimeSec,
        stakeBronze: _stakeBronze,
        offlineBot: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserGameSettings>>(userGameSettingsProvider('poker'),
        (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _players = saved.maxPlayers.clamp(2, 6);
        _turnTimeSec = turnTimeOptions.contains(saved.turnTimeSec)
            ? saved.turnTimeSec
            : 60;
        _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
      });
    });

    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final busy = _creating || _finding;
    final available = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    if (!available.contains(_stakeBronze) && available.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _stakeBronze = available.first);
        if (_settingsHydrated) _persistSettings();
      });
    }

    final chips = <Widget>[
      GameCardChip(
        selected: true,
        icon: Icons.groups_rounded,
        label: '$_players',
        onTap: busy ? null : _cyclePlayers,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: busy ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
    ];

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesPoker,
        icon: PokerGameIcon.iconData,
        iconChild: const PokerGameIcon(size: 26, color: Colors.white),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: busy || widget.isOffline ? null : _cycleStake,
        onInfoTap: busy ? null : () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.gamesFindMatch,
        findingLabel: context.l10n.commonSearching,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: () {
          final n = _players < 2 ? 2 : _players;
          disposeAllOfflineGameSessions();
          context.push(
            Uri(
              path: '/games/poker/offline',
              queryParameters: {'players': '$n'},
            ).toString(),
          );
        },
        isCreating: _creating,
        isFinding: _finding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }
}

/// Карточка UNO: 2–4 игрока, время хода, ставка и локальные боты.
class _UnoGameCard extends ConsumerStatefulWidget {
  const _UnoGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_UnoGameCard> createState() => _UnoGameCardState();
}

class _UnoGameCardState extends ConsumerState<_UnoGameCard> {
  int _players = 2;
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  bool _settingsHydrated = false;
  bool _creating = false;
  bool _finding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateFromSaved();
    });
  }

  void _hydrateFromSaved() {
    if (_settingsHydrated) return;
    final saved = ref.read(userGameSettingsProvider('uno')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _players = saved.maxPlayers.clamp(2, 4);
      _turnTimeSec =
          turnTimeOptions.contains(saved.turnTimeSec) ? saved.turnTimeSec : 60;
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('uno').notifier).updateLocal(
          gameCardSettings(
            gameType: 'uno',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
            maxPlayers: _players,
          ),
        );
  }

  void _cyclePlayers() {
    setState(() => _players = _players == 4 ? 2 : _players + 1);
    _persistSettings();
  }

  void _cycleTurnTime() {
    setState(() {
      const arr = [20, 60, 600, 0];
      _turnTimeSec = arr[(arr.indexOf(_turnTimeSec) + 1) % arr.length];
    });
    _persistSettings();
  }

  void _cycleStake() {
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final index = options.indexOf(_stakeBronze);
    setState(() {
      _stakeBronze = options[(index < 0 ? 0 : index + 1) % options.length];
    });
    _persistSettings();
  }

  Future<bool> _ensureStakeAffordable() async {
    try {
      await ref.read(authStateProvider.notifier).refresh();
    } catch (_) {}
    if (!mounted) return false;
    final balance = ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    if (canAffordStake(
      balanceBronze: balance,
      stakeBronze: _stakeBronze,
    )) {
      return true;
    }
    showAppSnackBar(
      context,
      message: context.l10n.commonInsufficientCoins,
      kind: AppSnackKind.error,
    );
    return false;
  }

  Future<void> _create(String mode) async {
    if (await blockJoinIfBusyAsync(context, ref, redirectToActive: true)) {
      return;
    }
    if (!mounted || !await _ensureStakeAffordable() || !mounted) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final result = await ref.read(unoRepositoryProvider).createLobby(
            mode: mode,
            maxPlayers: _players,
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
          );
      if (!mounted) return;
      final gameId = result.gameId?.trim() ?? '';
      final lobbyId = result.lobbyId.trim();
      if (gameId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'game',
                gameId: gameId,
                lobbyId: lobbyId.isEmpty ? null : lobbyId,
                gameType: 'uno',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'uno');
        context.push('/games/uno/game/$gameId');
      } else if (lobbyId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'uno',
              ),
            );
        context.push('/games/uno/lobby/$lobbyId?mode=$mode');
      } else {
        throw GamesException(503, context.l10n.commonTryLater);
      }
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: isFinishCurrentGameError(error)
            ? finishCurrentGameMessage
            : formatUserError(error),
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
          _finding = false;
        });
      }
    }
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: rulesTextLines(unoRuleLines(
        players: _players,
        turnTimeSec: _turnTimeSec,
        stakeBronze: widget.isOffline ? 0 : _stakeBronze,
        offlineBot: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserGameSettings>>(
      userGameSettingsProvider('uno'),
      (_, next) {
        final saved = next.valueOrNull;
        if (saved == null || _settingsHydrated) return;
        _settingsHydrated = true;
        setState(() {
          _players = saved.maxPlayers.clamp(2, 4);
          _turnTimeSec = turnTimeOptions.contains(saved.turnTimeSec)
              ? saved.turnTimeSec
              : 60;
          _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
        });
      },
    );
    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    final busy = _creating || _finding;
    final available = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    if (available.isNotEmpty && !available.contains(_stakeBronze)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _stakeBronze = available.first);
        if (_settingsHydrated) _persistSettings();
      });
    }

    final chips = <Widget>[
      GameCardChip(
        selected: true,
        icon: Icons.groups_rounded,
        label: '$_players',
        onTap: busy ? null : _cyclePlayers,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: busy ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
    ];

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesUno,
        icon: Icons.style_rounded,
        iconChild: const UnoGameIcon(size: 26),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: busy || widget.isOffline ? null : _cycleStake,
        onInfoTap: busy ? null : () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.gamesFindMatch,
        findingLabel: context.l10n.commonSearching,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: () {
          disposeAllOfflineGameSessions();
          context.push(
            Uri(
              path: '/games/uno/offline',
              queryParameters: {'players': '$_players'},
            ).toString(),
          );
        },
        isCreating: _creating,
        isFinding: _finding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
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
    final playersSelected = playersControlActive;
    final playersLabel =
        playersSelected ? '${configForVariant(variant).maxPlayers}' : '2';
    // Кнопка режима: активна → Классика/Гомоку/Ультимейт; иначе тёмная «Классика».
    final modeSelected = !playersControlActive;
    final modeVariant = modeSelected ? parseVariant(variant) : variantClassic;
    final modeIcon = modeVariant == variantGomoku
        ? Icons.grid_on_rounded
        : modeVariant == variantUltimate
            ? Icons.dashboard_customize_rounded
            : Icons.close_rounded;
    return [
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
    showGameRulesDialog(
      context: context,
      title: context.l10n.gamesRulesTitle,
      content: _buildRulesWidget(),
      closeLabel: context.l10n.commonClose,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GameCardTitle(
                        title: context.l10n.gamesTicTacToe,
                        isDesktop: isDesktop,
                        isMedium: isMedium,
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
          // Общий виджет — тот же, что у карточки Дурака.
          GameCardActionsRow(
            createLabel: context.l10n.gamesCreate,
            creatingLabel: context.l10n.commonCreating,
            onCreate: onCreateGame,
            findLabel: context.l10n.gamesFindMatch,
            findingLabel: context.l10n.commonSearching,
            onFind: onFindGame,
            offline: isOffline,
            offlinePlayLabel: context.l10n.gamesPlay,
            onOfflinePlay: onPlayOffline,
            isCreating: isCreating,
            isFinding: isFinding,
            isDesktop: isDesktop,
            isMedium: isMedium,
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
    this.lobbyBadgeCount = 0,
  });

  final _GamesTab selectedTab;
  final void Function(_GamesTab) onTabChanged;
  final int lobbyBadgeCount;

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
              badgeCount: lobbyBadgeCount,
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
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDesktop;
  final int badgeCount;

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
            label: badgeCount > 0 ? '$label, $badgeCount' : label,
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            // Место под бейдж справа сверху от текста.
                            padding: EdgeInsets.only(
                              right: badgeCount > 0 ? 14 : 0,
                              top: badgeCount > 0 ? 2 : 0,
                            ),
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: isDesktop ? 15 : 14,
                                color: isSelected
                                    ? AppColors.accentStart
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              right: -2,
                              top: -8,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  badgeCount > 99 ? '99+' : '$badgeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
    super.key,
    required this.inv,
    required this.onShowCreatorInfo,
    required this.onShowInviteRules,
    required this.onDeclineInvite,
    required this.onAcceptInvite,
  });

  final GameInvite inv;
  final void Function(BuildContext, GameInvite) onShowCreatorInfo;
  final void Function(BuildContext, GameInvite) onShowInviteRules;
  final void Function(String, {String gameType}) onDeclineInvite;
  final void Function(BuildContext, GameInvite) onAcceptInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const iconSz = 16.0;
    return GradientCard(
      animate: false,
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
                      GestureDetector(
                        onTap: () => onShowCreatorInfo(context, inv),
                        child: _InviteGameIcon(gameType: inv.gameType),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: InkWell(
                          onTap: () => onShowCreatorInfo(context, inv),
                          borderRadius: BorderRadius.circular(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _inviteGameTitle(context, inv.gameType),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                inv.creatorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
                            if (inv.modeLabel.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Tooltip(
                                message: context.l10n.gamesRulesTitle,
                                child: Icon(
                                  inv.isBattleship
                                      ? Icons.grid_on_rounded
                                      : inv.isDurak
                                          ? Icons.swap_horiz_rounded
                                          : Icons.extension_rounded,
                                  size: iconSz,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                inv.modeLabel,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                            if (inv.isDurak) ...[
                              DurakGameIcon(
                                size: iconSz,
                                color: AppColors.textSecondary,
                              ),
                              Text(
                                durakDeckLabel(inv.deckSize, context.l10n),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
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
                  onPressed: () =>
                      onDeclineInvite(inv.lobbyId, gameType: inv.gameType),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: context.l10n.commonDecline,
                  style: IconButton.styleFrom(foregroundColor: Colors.red),
                ),
                IconButton.filled(
                  onPressed: () => onAcceptInvite(context, inv),
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

String _inviteGameTitle(BuildContext context, String gameType) {
  return localizedGameTypeName(gameType, context.l10n);
}

/// Карточка «Нарды» — 2 игрока, короткие/длинные, время и ставка; игра в разработке.
class _NardyGameCard extends ConsumerStatefulWidget {
  const _NardyGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_NardyGameCard> createState() => _NardyGameCardState();
}

class _NardyGameCardState extends ConsumerState<_NardyGameCard> {
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  String _gameMode = nardyModeShort;
  bool _settingsHydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateFromSaved();
    });
  }

  void _hydrateFromSaved() {
    if (_settingsHydrated) return;
    final saved = ref.read(userGameSettingsProvider('nardy')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _turnTimeSec =
          turnTimeOptions.contains(saved.turnTimeSec) ? saved.turnTimeSec : 60;
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
      _gameMode = nardyNormalizeMode(saved.gameMode);
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('nardy').notifier).updateLocal(
          gameCardSettings(
            gameType: 'nardy',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
            gameMode: _gameMode,
          ),
        );
  }

  void _cycleTurnTime() {
    setState(() {
      const arr = [20, 60, 600, 0];
      _turnTimeSec = arr[(arr.indexOf(_turnTimeSec) + 1) % arr.length];
    });
    _persistSettings();
  }

  void _cycleStake() {
    final options = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    final idx = options.indexOf(_stakeBronze);
    final next = options[(idx < 0 ? 0 : idx + 1) % options.length];
    setState(() => _stakeBronze = next);
    _persistSettings();
  }

  void _cycleGameMode() {
    setState(() {
      _gameMode =
          _gameMode == nardyModeShort ? nardyModeLong : nardyModeShort;
    });
    _persistSettings();
  }

  void _showInDevelopment() {
    showAppSnackBar(
      context,
      message: context.l10n.gamesInDevelopment,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserGameSettings>>(
        userGameSettingsProvider('nardy'), (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _turnTimeSec = turnTimeOptions.contains(saved.turnTimeSec)
            ? saved.turnTimeSec
            : 60;
        _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
        _gameMode = nardyNormalizeMode(saved.gameMode);
      });
    });
    final available = widget.stakeOptionsList.isEmpty
        ? freeStakeOptions
        : widget.stakeOptionsList;
    if (!available.contains(_stakeBronze) && available.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _stakeBronze = available.first);
        if (_settingsHydrated) _persistSettings();
      });
    }

    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;

    final chips = <Widget>[
      GameCardChip(
        selected: false,
        icon: Icons.groups_rounded,
        label: '2',
        onTap: null,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      GameCardChip(
        selected: true,
        icon: Icons.swap_horiz_rounded,
        label: nardyModeLabel(_gameMode, context.l10n),
        onTap: _cycleGameMode,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
      GameCardChip(
        selected: false,
        icon: Icons.construction_rounded,
        label: context.l10n.gamesInDevelopment,
        onTap: null,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    ];

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesNardy,
        icon: NardyGameIcon.iconData,
        iconChild: const NardyGameIcon(size: 26, color: Colors.white),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: widget.isOffline ? null : _cycleStake,
        onInfoTap: () => _showRules(context),
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: _showInDevelopment,
        findLabel: context.l10n.gamesFindMatch,
        findingLabel: context.l10n.commonSearching,
        onFind: _showInDevelopment,
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: _showInDevelopment,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      title: context.l10n.rulesNardyTitle,
      content: rulesTextLines(nardyRuleLines(
        gameMode: _gameMode,
        turnTimeSec: widget.isOffline ? 0 : _turnTimeSec,
        stakeBronze: widget.isOffline ? 0 : _stakeBronze,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }
}

class _InviteGameIcon extends StatelessWidget {
  const _InviteGameIcon({required this.gameType});

  final String gameType;

  @override
  Widget build(BuildContext context) {
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
      child: GameTypeIcon(
        gameType: gameType,
        size: 26,
        color: Colors.white,
      ),
    );
  }
}
