part of 'games_screen.dart';

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
                mode: mode,
              ),
            );
        context.push(lobbyScreenPath(lobbyId, gameType: 'durak', mode: mode));
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
        onInfoTap: () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
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
                mode: mode,
              ),
            );
        context.push(
          lobbyScreenPath(lobbyId, gameType: 'battleship', mode: mode),
        );
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
        onInfoTap: () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
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
                mode: mode,
              ),
            );
        context.push(lobbyScreenPath(lobbyId, gameType: 'poker', mode: mode));
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
        onInfoTap: () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
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
                mode: mode,
              ),
            );
        context.push(lobbyScreenPath(lobbyId, gameType: 'uno', mode: mode));
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
        onInfoTap: () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
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

  List<Widget> _buildChipList({
    required BuildContext context,
    required bool isCreating,
    required bool isFinding,
    required bool isDesktop,
    required bool isMedium,
  }) {
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
      GameCardChip(
        selected: playersSelected,
        icon: Icons.groups_rounded,
        label: playersLabel,
        onTap: busy ? null : onPlayersChipTap,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!isOffline)
        Tooltip(
          message: context.l10n.gamesTapChangeTurnTime,
          child: GameCardChip(
            selected: true,
            icon: Icons.timer_outlined,
            label: formatTurnTime(turnTimeSec),
            onTap: busy ? null : _cycleTurnTime,
            isDesktop: isDesktop,
            isMedium: isMedium,
          ),
        ),
      GameCardChip(
        selected: modeSelected,
        icon: modeIcon,
        label: variantLabel(modeVariant),
        onTap: busy ? null : onModeChipTap,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    ];
  }

  void _showRulesInfo(BuildContext context) {
    showGameRulesDialog(
      context: context,
      content: _buildRulesWidget(),
      closeLabel: context.l10n.commonClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = isWide(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMedium = width >= 700 && width < 950;
    // Без appear-анимации: при возврате из лобби карточка иначе «мигает»
    // (opacity 0→1), хотя выход уже мгновенный.
    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesTicTacToe,
        icon: Icons.grid_3x3_rounded,
        stakeBronze: !isOffline && stakeBronze > 0 ? stakeBronze : null,
        stakeLabel: formatStakeAmount(stakeBronze),
        stakeCoinType: stakeCoinType(stakeBronze),
        onStakeTap: isCreating || isFinding ? null : _cycleStake,
        onInfoTap: () => _showRulesInfo(context),
        busy: isCreating || isFinding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: _buildChipList(
        context: context,
        isCreating: isCreating,
        isFinding: isFinding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: onCreateGame,
        findLabel: context.l10n.lobbySearchPlayers,
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
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      descendantsAreFocusable: false,
      descendantsAreTraversable: false,
      child: GamepadTabSticks(
      child: Container(
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
                                      : inv.isDurak ||
                                              inv.isNardy ||
                                              inv.isCheckers
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

  Future<void> _create(String mode) async {
    if (_creating || _finding) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final result = await ref.read(nardyRepositoryProvider).createLobby(
            mode: mode,
            gameMode: _gameMode,
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
                gameType: 'nardy',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'nardy');
        context.push('/games/nardy/game/$gameId');
      } else if (lobbyId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'nardy',
                mode: mode,
              ),
            );
        context.push(lobbyScreenPath(lobbyId, gameType: 'nardy', mode: mode));
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

  void _playOffline() {
    disposeAllOfflineGameSessions();
    context.push(
      Uri(
        path: '/games/nardy/offline',
        queryParameters: {'mode': _gameMode},
      ).toString(),
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
          onTap: _creating || _finding ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
    ];
    final busy = _creating || _finding;

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
        onStakeTap: widget.isOffline || busy ? null : _cycleStake,
        onInfoTap: () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        isCreating: _creating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
        findingLabel: context.l10n.commonSearching,
        isFinding: _finding,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: _playOffline,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      content: rulesTextLines(nardyRuleLines(
        gameMode: _gameMode,
        turnTimeSec: widget.isOffline ? 0 : _turnTimeSec,
        stakeBronze: widget.isOffline ? 0 : _stakeBronze,
        offline: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }
}

class _CheckersGameCard extends ConsumerStatefulWidget {
  const _CheckersGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_CheckersGameCard> createState() => _CheckersGameCardState();
}

class _CheckersGameCardState extends ConsumerState<_CheckersGameCard> {
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  String _gameMode = CheckersEngine.modeRussian;
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
    final saved = ref.read(userGameSettingsProvider('checkers')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _turnTimeSec =
          turnTimeOptions.contains(saved.turnTimeSec) ? saved.turnTimeSec : 60;
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
      _gameMode = CheckersEngine.normalizeMode(saved.gameMode);
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('checkers').notifier).updateLocal(
          gameCardSettings(
            gameType: 'checkers',
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
    setState(() => _gameMode = CheckersEngine.nextMode(_gameMode));
    _persistSettings();
  }

  Future<void> _create(String mode) async {
    if (_creating || _finding) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final result = await ref.read(checkersRepositoryProvider).createLobby(
            mode: mode,
            gameMode: _gameMode,
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
                gameType: 'checkers',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'checkers');
        context.push('/games/checkers/game/$gameId');
      } else if (lobbyId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'checkers',
              ),
            );
        context.push('/games/checkers/lobby/$lobbyId?mode=$mode');
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

  void _playOffline() {
    disposeAllOfflineGameSessions();
    context.push(
      Uri(
        path: '/games/checkers/offline',
        queryParameters: {'mode': _gameMode},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserGameSettings>>(
        userGameSettingsProvider('checkers'), (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _turnTimeSec = turnTimeOptions.contains(saved.turnTimeSec)
            ? saved.turnTimeSec
            : 60;
        _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
        _gameMode = CheckersEngine.normalizeMode(saved.gameMode);
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
        label: checkersModeLabel(_gameMode, context.l10n),
        onTap: _cycleGameMode,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: _creating || _finding ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
    ];
    final busy = _creating || _finding;

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesCheckers,
        icon: CheckersGameIcon.iconData,
        iconChild: const CheckersGameIcon(size: 26, color: Colors.white),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: widget.isOffline || busy ? null : _cycleStake,
        onInfoTap: busy ? null : () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        isCreating: _creating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
        findingLabel: context.l10n.commonSearching,
        isFinding: _finding,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: _playOffline,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      content: rulesTextLines(checkersRuleLines(
        gameMode: _gameMode,
        turnTimeSec: widget.isOffline ? 0 : _turnTimeSec,
        stakeBronze: widget.isOffline ? 0 : _stakeBronze,
        offline: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }
}

class _ChessGameCard extends ConsumerStatefulWidget {
  const _ChessGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_ChessGameCard> createState() => _ChessGameCardState();
}

class _ChessGameCardState extends ConsumerState<_ChessGameCard> {
  int _turnTimeSec = 60;
  int _stakeBronze = 2;
  String _gameMode = chessModeClassic;
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
    final saved = ref.read(userGameSettingsProvider('chess')).valueOrNull;
    if (saved == null) return;
    _settingsHydrated = true;
    setState(() {
      _turnTimeSec = chessNormalizeTurnTime(saved.turnTimeSec);
      _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
      _gameMode = chessNormalizeMode(saved.gameMode);
    });
  }

  void _persistSettings() {
    ref.read(userGameSettingsProvider('chess').notifier).updateLocal(
          gameCardSettings(
            gameType: 'chess',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
            gameMode: _gameMode,
          ),
        );
  }

  void _cycleTurnTime() {
    setState(() => _turnTimeSec = chessNextTurnTime(_turnTimeSec));
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
    setState(() => _gameMode = chessNextMode(_gameMode));
    _persistSettings();
  }

  Future<void> _create(String mode) async {
    if (_creating || _finding) return;
    setState(() {
      _creating = mode == 'invite';
      _finding = mode == 'matchmake';
    });
    try {
      final result = await ref.read(chessRepositoryProvider).createLobby(
            mode: mode,
            gameMode: _gameMode,
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
                gameType: 'chess',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'chess');
        context.push('/games/chess/game/$gameId');
      } else if (lobbyId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'chess',
              ),
            );
        context.push('/games/chess/lobby/$lobbyId?mode=$mode');
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

  void _playOffline() {
    disposeAllOfflineGameSessions();
    context.push(
      Uri(
        path: '/games/chess/offline',
        queryParameters: {'mode': _gameMode},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserGameSettings>>(
        userGameSettingsProvider('chess'), (prev, next) {
      final saved = next.valueOrNull;
      if (saved == null || _settingsHydrated) return;
      _settingsHydrated = true;
      setState(() {
        _turnTimeSec = chessNormalizeTurnTime(saved.turnTimeSec);
        _stakeBronze = saved.stakeBronze < 2 ? 2 : saved.stakeBronze;
        _gameMode = chessNormalizeMode(saved.gameMode);
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
        label: chessModeLabel(_gameMode, context.l10n),
        onTap: _cycleGameMode,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      if (!widget.isOffline)
        GameCardChip(
          selected: true,
          icon: Icons.timer_outlined,
          label: formatTurnTime(_turnTimeSec),
          onTap: _creating || _finding ? null : _cycleTurnTime,
          isDesktop: isDesktop,
          isMedium: isMedium,
        ),
    ];
    final busy = _creating || _finding;

    return GameCardShell(
      isDesktop: isDesktop,
      isMedium: isMedium,
      header: GameCardHeader(
        title: context.l10n.gamesChess,
        icon: ChessGameIcon.iconData,
        iconChild: const ChessGameIcon(size: 26, color: Colors.white),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: widget.isOffline || busy ? null : _cycleStake,
        onInfoTap: busy ? null : () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        isCreating: _creating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
        findingLabel: context.l10n.commonSearching,
        isFinding: _finding,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: _playOffline,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
    );
  }

  void _showRules(BuildContext context) {
    showGameRulesDialog(
      context: context,
      content: rulesTextLines(chessRuleLines(
        gameMode: _gameMode,
        turnTimeSec: widget.isOffline ? 0 : _turnTimeSec,
        stakeBronze: widget.isOffline ? 0 : _stakeBronze,
        offline: widget.isOffline,
        l10n: context.l10n,
      )),
      closeLabel: context.l10n.commonClose,
    );
  }
}

/// Карточка «Козёл»: 2–4 игрока, время хода, ставка и локальные боты.
class _DominoGameCard extends ConsumerStatefulWidget {
  const _DominoGameCard({
    required this.isOffline,
    required this.stakeOptionsList,
  });

  final bool isOffline;
  final List<int> stakeOptionsList;

  @override
  ConsumerState<_DominoGameCard> createState() => _DominoGameCardState();
}

class _DominoGameCardState extends ConsumerState<_DominoGameCard> {
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
    final saved = ref.read(userGameSettingsProvider('domino')).valueOrNull;
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
    ref.read(userGameSettingsProvider('domino').notifier).updateLocal(
          gameCardSettings(
            gameType: 'domino',
            turnTimeSec: _turnTimeSec,
            stakeBronze: _stakeBronze,
            maxPlayers: _players,
            variant: 'kozel',
            gameMode: 'kozel',
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
    if (canAffordStake(balanceBronze: balance, stakeBronze: _stakeBronze)) {
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
      final result = await ref.read(dominoRepositoryProvider).createLobby(
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
                gameType: 'domino',
              ),
            );
        pinBlockingGame(ref, gameId, gameType: 'domino');
        context.push('/games/domino/game/$gameId');
      } else if (lobbyId.isNotEmpty) {
        ref.read(activeGameProvider.notifier).setLocal(
              ActiveGameItem(
                type: 'lobby',
                lobbyId: lobbyId,
                gameType: 'domino',
                mode: mode,
              ),
            );
        context.push(lobbyScreenPath(lobbyId, gameType: 'domino', mode: mode));
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
      content: rulesTextLines(dominoRuleLines(
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
      userGameSettingsProvider('domino'),
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
        title: context.l10n.gamesDomino,
        icon: Icons.grid_view_rounded,
        iconChild: const DominoGameIcon(size: 26),
        stakeBronze: widget.isOffline ? null : _stakeBronze,
        stakeLabel: formatStakeAmount(_stakeBronze),
        stakeCoinType: stakeCoinType(_stakeBronze),
        onStakeTap: busy || widget.isOffline ? null : _cycleStake,
        onInfoTap: () => _showRules(context),
        busy: busy,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
      chips: chips,
      actions: GameCardActionsRow(
        createLabel: context.l10n.gamesCreate,
        creatingLabel: context.l10n.commonCreating,
        onCreate: () => _create('invite'),
        findLabel: context.l10n.lobbySearchPlayers,
        findingLabel: context.l10n.commonSearching,
        onFind: () => _create('matchmake'),
        offline: widget.isOffline,
        offlinePlayLabel: context.l10n.gamesPlay,
        onOfflinePlay: () {
          disposeAllOfflineGameSessions();
          context.push(Uri(
            path: '/games/domino/offline',
            queryParameters: {'players': '$_players'},
          ).toString());
        },
        isCreating: _creating,
        isFinding: _finding,
        isDesktop: isDesktop,
        isMedium: isMedium,
      ),
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
