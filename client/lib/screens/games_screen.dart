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
import 'package:multigames_client/games/domino/domino_mode.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/domino/domino_rules.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_provider.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/chess/chess_provider.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/games/framework/framework.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/offline_session_hold.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_scroll_dismiss.dart';
import 'package:multigames_client/core/gamepad/gamepad_tab_sticks.dart';
import 'package:multigames_client/core/gamepad/gamepad_scroll_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/games/games_gamepad.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/ui/widgets/sliding_pill_bar.dart';
import 'package:multigames_client/games/game_stake.dart';
import 'package:multigames_client/core/local_notify.dart';
import 'package:multigames_client/core/push_nav_paths.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/domino_game_icon.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/ui/widgets/checkers_game_icon.dart';
import 'package:multigames_client/ui/widgets/chess_game_icon.dart';
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

part 'game_hub_cards.dart';

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
  String? _lobbiesTabStamp;

  void _scheduleLobbiesTabFromRoute() {
    if (ref.read(isOfflineProvider)) return;
    final uri = GoRouterState.of(context).uri;
    if (!uriWantsGamesLobbiesTab(uri)) return;
    final stamp = uri.toString();
    if (_lobbiesTabStamp == stamp) return;
    _lobbiesTabStamp = stamp;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(isOfflineProvider)) return;
      if (_selectedTab != _GamesTab.lobbies) {
        _onTabChanged(_GamesTab.lobbies);
        return;
      }
      unawaited(
        ref.read(gameInvitesProvider.notifier).hydrateFromServer(
              ref.read(gamesRepositoryProvider),
            ),
      );
    });
  }

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
    scheduleFocusEdgeGamepadTarget(last: false);
  }

  bool _onGamepad(GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (!action.isScroll) return false;
    final route = ModalRoute.of(context);
    if (!gamesGamepadAllowsHubScroll(
      popupOpen: isGamepadPopupOpen(context),
      exclusive: GamepadDispatcher.hasExclusive,
      routeCovered: route != null && !route.isCurrent,
    )) {
      return true;
    }
    if (gamesHubScrollSwitchesTab(action)) {
      if (ref.read(isOfflineProvider) || _hubTabs.length <= 1) return true;
      final next = gamesHubTabIndexAfterScroll(
        index: _hubTabs.index,
        length: _hubTabs.length,
        action: action,
      );
      if (next != _hubTabs.index) {
        _onTabChanged(next == 0 ? _GamesTab.games : _GamesTab.lobbies);
      }
      return true;
    }
    if (gamesHubScrollPagesCards(action)) {
      scrollGamepadByPage(
        action == GamepadAction.scrollUp ? -1 : 1,
        context: context,
      );
      return true;
    }
    return false;
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
    _scheduleLobbiesTabFromRoute();
    final lobbiesAsync = ref.watch(openLobbiesProvider);
    final invites = ref.watch(gameInvitesProvider);
    final activeAsync = ref.watch(activeGameProvider);
    final observation = ref.watch(observationGameProvider);
    final caps = ref.watch(inventoryCapabilitiesProvider).valueOrNull;
    // После GetActive / join — сразу в активную партию или «Войти в игру».
    ref.listen<AsyncValue<ActiveGameItem?>>(activeGameProvider, (prev, next) {
      final active = next.valueOrNull;
      if (active == null) return;
      // Пуш уже открыл чат или чужое лобби — не подменять своей «Своя игра».
      if (pushOpenedRouteRecently()) return;
      final uri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
      if (uri.path != '/games') return;
      // Вкладка «Лобби» — список открытых столов и «Вас пригласили».
      if (uriWantsGamesLobbiesTab(uri) || _selectedTab == _GamesTab.lobbies) {
        return;
      }
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
        if (pushOpenedRouteRecently()) return;
        final uri =
            GoRouter.of(context).routerDelegate.currentConfiguration.uri;
        if (uri.path != '/games') return;
        if (uriWantsGamesLobbiesTab(uri) || _selectedTab == _GamesTab.lobbies) {
          return;
        }
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

    return GamepadScope(
      onAction: _onGamepad,
      child: Scaffold(
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
                      progress: _hubTabs.animation,
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
                mode: mode,
              ),
            );
        context.push(
          lobbyScreenPath(result.lobbyId, mode: mode),
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
    if (inv.gameType == 'domino') {
      try {
        final res = await ref.read(dominoRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'domino',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'domino');
          if (context.mounted) {
            context.go('/games/domino/game/${res.gameId}');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'domino',
                ),
              );
          if (context.mounted) {
            context.go('/games/domino/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    if (inv.gameType == 'nardy') {
      try {
        final res = await ref.read(nardyRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        final gameId = res.gameId?.trim() ?? '';
        if (res.joined && gameId.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: gameId,
                  gameType: 'nardy',
                ),
              );
          pinBlockingGame(ref, gameId, gameType: 'nardy');
          if (context.mounted) {
            context.go('/games/nardy/game/$gameId');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'nardy',
                ),
              );
          if (context.mounted) {
            context.go('/games/nardy/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    if (inv.gameType == 'checkers') {
      try {
        final res =
            await ref.read(checkersRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        final gameId = res.gameId?.trim() ?? '';
        if (res.joined && gameId.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: gameId,
                  gameType: 'checkers',
                ),
              );
          pinBlockingGame(ref, gameId, gameType: 'checkers');
          if (context.mounted) {
            context.go('/games/checkers/game/$gameId');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'checkers',
                ),
              );
          if (context.mounted) {
            context.go('/games/checkers/lobby/$lobbyId?mode=invite');
          }
        }
      } catch (e) {
        ref.read(gameInvitesProvider.notifier).remove(lobbyId);
        _showInviteError(e);
      }
      return;
    }
    if (inv.gameType == 'chess') {
      try {
        final res = await ref.read(chessRepositoryProvider).joinLobby(lobbyId);
        ref.read(gameInvitesProvider.notifier).resolveJoined(lobbyId);
        final gameId = res.gameId?.trim() ?? '';
        if (res.joined && gameId.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: gameId,
                  gameType: 'chess',
                ),
              );
          pinBlockingGame(ref, gameId, gameType: 'chess');
          if (context.mounted) {
            context.go('/games/chess/game/$gameId');
          }
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'chess',
                ),
              );
          if (context.mounted) {
            context.go('/games/chess/lobby/$lobbyId?mode=invite');
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
    if (inv.isDomino) {
      return rulesTextLines(dominoRuleLines(
        players: inv.maxPlayers,
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
        mode: inv.durakMode,
        l10n: context.l10n,
      ));
    }
    if (inv.isNardy) {
      return rulesTextLines(nardyRuleLines(
        gameMode: inv.durakMode,
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
        l10n: context.l10n,
      ));
    }
    if (inv.isCheckers) {
      return rulesTextLines(checkersRuleLines(
        gameMode: inv.durakMode,
        turnTimeSec: inv.turnTimeSec,
        stakeBronze: inv.stakeBronze,
        l10n: context.l10n,
      ));
    }
    if (inv.isChess) {
      return rulesTextLines(chessRuleLines(
        gameMode: inv.durakMode,
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
        return wrapGamepadScrollDismissDialog(
          dialogContext: ctx,
          child: Dialog(
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
        ),
        );
      },
    );
  }

  Future<void> _declineInvite(String lobbyId,
      {String gameType = 'tictactoe'}) async {
    ref.read(gameInvitesProvider.notifier).dismiss(lobbyId);
    unawaited(cancelLocalNotificationsForTag(
      gameInviteNotificationTag(gameType: gameType, lobbyId: lobbyId),
    ));
    try {
      if (gameType == 'durak') {
        await ref.read(durakRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'battleship') {
        await ref.read(battleshipRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'poker') {
        await ref.read(pokerRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'uno') {
        await ref.read(unoRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'domino') {
        await ref.read(dominoRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'nardy') {
        await ref.read(nardyRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'checkers') {
        await ref.read(checkersRepositoryProvider).declineLobby(lobbyId);
      } else if (gameType == 'chess') {
        await ref.read(chessRepositoryProvider).declineLobby(lobbyId);
      } else {
        await ref.read(gamesRepositoryProvider).declineLobby(lobbyId);
      }
    } catch (_) {
      // Карточка уже скрыта локально; сервер мог уже закрыть лобби.
    }
  }

  void _goLobbyScreen(
    BuildContext context, {
    required String lobbyId,
    required String gameType,
    required String mode,
  }) {
    ref.read(activeGameProvider.notifier).setLocal(
          ActiveGameItem(
            type: 'lobby',
            lobbyId: lobbyId,
            gameType: gameType,
            mode: mode,
          ),
        );
    if (context.mounted) {
      context.go(lobbyScreenPath(lobbyId, gameType: gameType, mode: mode));
    }
  }

  Future<void> _joinLobby(
    BuildContext context,
    String lobbyId, {
    String gameType = 'tictactoe',
    String mode = 'matchmake',
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
          _goLobbyScreen(
            context,
            lobbyId: lobbyId,
            gameType: 'durak',
            mode: mode,
          );
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
          _goLobbyScreen(
            context,
            lobbyId: lobbyId,
            gameType: 'battleship',
            mode: mode,
          );
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
          _goLobbyScreen(
            context,
            lobbyId: lobbyId,
            gameType: 'poker',
            mode: mode,
          );
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
          _goLobbyScreen(
            context,
            lobbyId: lobbyId,
            gameType: 'uno',
            mode: mode,
          );
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
    if (gameType == 'domino') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res = await ref.read(dominoRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        if (res.joined && res.gameId != null && res.gameId!.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: res.gameId,
                  gameType: 'domino',
                ),
              );
          pinBlockingGame(ref, res.gameId, gameType: 'domino');
          context.go('/games/domino/game/${res.gameId}');
          return;
        }
        if (res.joined) {
          _goLobbyScreen(
            context,
            lobbyId: lobbyId,
            gameType: 'domino',
            mode: mode,
          );
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
    if (gameType == 'nardy') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res = await ref.read(nardyRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        final gameId = res.gameId?.trim() ?? '';
        if (res.joined && gameId.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: gameId,
                  gameType: 'nardy',
                ),
              );
          pinBlockingGame(ref, gameId, gameType: 'nardy');
          context.go('/games/nardy/game/$gameId');
          return;
        }
        if (res.joined) {
          _goLobbyScreen(
            context,
            lobbyId: lobbyId,
            gameType: 'nardy',
            mode: mode,
          );
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
    if (gameType == 'checkers') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res =
            await ref.read(checkersRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        final gameId = res.gameId?.trim() ?? '';
        if (res.joined && gameId.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: gameId,
                  gameType: 'checkers',
                ),
              );
          pinBlockingGame(ref, gameId, gameType: 'checkers');
          context.go('/games/checkers/game/$gameId');
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'checkers',
                ),
              );
          context.go('/games/checkers/lobby/$lobbyId?mode=invite');
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
    if (gameType == 'chess') {
      try {
        ref.read(openLobbiesProvider.notifier).removeLocal(lobbyId);
        final res =
            await ref.read(chessRepositoryProvider).joinLobby(lobbyId);
        if (!context.mounted) return;
        ref.invalidate(openLobbiesProvider);
        final gameId = res.gameId?.trim() ?? '';
        if (res.joined && gameId.isNotEmpty) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'game',
                  gameId: gameId,
                  gameType: 'chess',
                ),
              );
          pinBlockingGame(ref, gameId, gameType: 'chess');
          context.go('/games/chess/game/$gameId');
          return;
        }
        if (res.joined) {
          ref.read(activeGameProvider.notifier).setLocal(
                ActiveGameItem(
                  type: 'lobby',
                  lobbyId: lobbyId,
                  gameType: 'chess',
                ),
              );
          context.go('/games/chess/lobby/$lobbyId?mode=invite');
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
        _goLobbyScreen(
          context,
          lobbyId: lobbyId,
          gameType: 'tictactoe',
          mode: mode,
        );
        ref.invalidate(lobbyDetailProvider(lobbyId));
        unawaited(refreshChatsList(ref, force: true).catchError((_) {}));
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
        _goLobbyScreen(
          context,
          lobbyId: lobbyId,
          gameType: 'tictactoe',
          mode: mode,
        );
        ref.invalidate(lobbyDetailProvider(lobbyId));
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
        } else if (lobby.isDomino) {
          body = rulesTextLines(dominoRuleLines(
            players: lobby.maxPlayers,
            turnTimeSec: lobby.turnTimeSec,
            stakeBronze: lobby.stakeBronze,
            mode: lobby.gameMode,
            l10n: context.l10n,
          ));
        } else if (lobby.isNardy) {
          body = rulesTextLines(nardyRuleLines(
            gameMode: lobby.gameMode,
            turnTimeSec: lobby.turnTimeSec,
            stakeBronze: lobby.stakeBronze,
            l10n: context.l10n,
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
        return wrapGamepadScrollDismissDialog(
          dialogContext: ctx,
          child: AlertDialog(
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
        ),
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
      final screenWidth = MediaQuery.sizeOf(context).width;
      final isMedium = screenWidth >= 700 && screenWidth < 950;
      final titles = [
        context.l10n.gamesTicTacToe,
        context.l10n.gamesDurak,
        context.l10n.gamesBattleship,
        context.l10n.gamesPoker,
        context.l10n.gamesUno,
        context.l10n.gamesDomino,
        context.l10n.gamesNardy,
        context.l10n.gamesCheckers,
        context.l10n.gamesChess,
      ];
      final cols = gamesHubTileColumns(
        maxWidth: maxWidth,
        wide: isDesktop,
        titles: titles,
        isDesktop: isDesktop,
        isMedium: isMedium,
        titleStyle: gamesHubTitleStyle(
          isDesktop: isDesktop,
          isMedium: isMedium,
          base: Theme.of(context).textTheme.titleLarge,
        ),
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
        _DominoGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _NardyGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _CheckersGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
        _ChessGameCard(
          isOffline: isOffline,
          stakeOptionsList: stakeOptionsList,
        ),
      ];
      return Align(
        alignment: Alignment.topCenter,
        child: gamesHubEqualHeightGrid(
          cols: cols,
          gap: gap,
          tileWidth: tileWidth,
          tiles: tiles,
        ),
      );
    }

    // ListView без minHeight на весь экран: иначе при скролле карточки
    // «уезжают» в пустоту и визуально пропадают.
    return LayoutBuilder(
      builder: (context, constraints) {
        return GamepadScrollPager(
          builder: (context, controller) {
            return ListView(
              controller: controller,
              primary: false,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                contentPadding,
                isOffline ? 12 : 8,
                contentPadding,
                isDesktop || phoneLandscape ? 24 : 16,
              ),
              children: [
                gameCards(
                  (constraints.maxWidth - contentPadding * 2)
                      .clamp(0.0, 2000.0),
                ),
              ],
            );
          },
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
  final void Function(BuildContext, String, {String gameType, String mode})
      onJoinLobby;
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
    return GamepadScrollPager(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            contentPadding,
            8,
            contentPadding,
            isDesktop || isPhoneLandscape(context) ? 24 : 16,
          ),
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
                  (lobby) {
                    final modeText = lobby.modeLabel(context.l10n);
                    return Padding(
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
                                    if (modeText.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            lobby.isBattleship
                                                ? Icons.grid_on_rounded
                                                : lobby.isDurak ||
                                                        lobby.isNardy ||
                                                        lobby.isCheckers
                                                    ? Icons.swap_horiz_rounded
                                                    : Icons.extension_rounded,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lobby.isDurak
                                                ? '$modeText · ${durakDeckLabel(lobby.deckSize, context.l10n)}'
                                                : modeText,
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
                            onPressed: () => onJoinLobby(
                              context,
                              lobby.id,
                              gameType: lobby.gameType,
                              mode: lobby.mode.trim().isEmpty
                                  ? 'matchmake'
                                  : lobby.mode,
                            ),
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
                  );
                  },
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
      },
    );
  }
}
