import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/shared_lobby.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';

const lobbyOpeningScreenKey = ValueKey<String>('lobby-opening-screen');

/// Экран ожидания между тапом «Создать игру» / «Поиск игроков» и лобби.
///
/// Тап сразу уводит с карточки на этот экран: кнопку под ним второй раз не
/// нажать. Выглядит как лобби во время загрузки, поэтому готовый стол
/// встаёт на его место без смены шапки.
class LobbyOpening {
  LobbyOpening._(this._navigator, this._route, this._router);

  /// Столько экран ожидания живёт под уже открытым лобби: его страница
  /// проявляется плавно, и сквозь неё не должна мелькнуть карточка игры.
  static const lingerUnderLobby = Duration(milliseconds: 300);

  /// Запас на случай, если роутер так и не применил маршрут.
  static const routeTimeout = Duration(seconds: 10);

  final NavigatorState _navigator;
  final Route<void> _route;
  final GoRouter? _router;
  bool _closed = false;

  /// Показать экран ожидания поверх карточек игр.
  static LobbyOpening start(
    BuildContext context, {
    required String gameType,
    required String mode,
  }) {
    final navigator = Navigator.of(context);
    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) =>
          LobbyOpeningScreen(gameType: gameType, mode: mode),
    );
    unawaited(navigator.push(route));
    return LobbyOpening._(navigator, route, GoRouter.maybeOf(context));
  }

  /// Открыть лобби или партию и дождаться, пока роутер покажет маршрут.
  ///
  /// `push` у роутера отвечает только после редиректов, а они ходят в сеть.
  /// Пока маршрут не применён, экран ожидания остаётся на месте.
  Future<void> push(String location) async {
    final router = _router;
    if (router == null) return;
    final delegate = router.routerDelegate;
    final before = delegate.currentConfiguration;
    final applied = Completer<void>();
    void onChange() {
      if (applied.isCompleted) return;
      if (delegate.currentConfiguration != before) applied.complete();
    }

    delegate.addListener(onChange);
    try {
      unawaited(router.push<void>(location));
      await applied.future.timeout(routeTimeout, onTimeout: () {});
    } finally {
      delegate.removeListener(onChange);
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Убрать экран ожидания. Вызывать всегда: и после перехода, и при ошибке.
  void close() {
    if (_closed) return;
    _closed = true;
    if (!_route.isActive) return;
    if (_route.isCurrent) {
      _navigator.removeRoute(_route);
      return;
    }
    Timer(lingerUnderLobby, () {
      if (_navigator.mounted && _route.isActive) {
        _navigator.removeRoute(_route);
      }
    });
  }
}

/// Заглушка лобби: та же шапка, что у стола, и индикатор загрузки.
class LobbyOpeningScreen extends StatelessWidget {
  const LobbyOpeningScreen({
    super.key,
    required this.gameType,
    required this.mode,
  });

  final String gameType;

  /// `invite` — «Своя игра», `matchmake` — «Лобби».
  final String mode;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppOpaqueSurface(
        key: lobbyOpeningScreenKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            // Стрелка на своём месте, но без действия: запрос уже ушёл.
            leading: IconButton(
              tooltip: context.l10n.commonBack,
              onPressed: null,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            titleSpacing: 8,
            title: GameLobbyAppBarTitle(
              gameType: gameType,
              title: lobbyAppBarTitle(initialMode: mode),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
        ),
      ),
    );
  }
}
