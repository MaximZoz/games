// «Создать игру» / «Поиск игроков»: один тап сразу уводит с карточки.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/lobby_opening.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

import 'test_locale.dart';

/// Карточка игры: тот же порядок, что в `_create` — флаг, экран ожидания,
/// запрос, переход, сброс флага.
class _Card extends StatefulWidget {
  const _Card({required this.request, required this.onTap});

  /// Ответ сервера: путь лобби или ошибка.
  final Future<String> Function() request;
  final VoidCallback onTap;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _creating = false;
  String? _error;

  Future<void> _create() async {
    if (_creating) return;
    widget.onTap();
    setState(() => _creating = true);
    final opening =
        LobbyOpening.start(context, gameType: 'durak', mode: 'invite');
    try {
      final location = await widget.request();
      await opening.push(location);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      opening.close();
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: _create,
            child: Text(_creating ? 'busy' : 'create'),
          ),
          if (_error != null) Text('error: $_error'),
        ],
      ),
    );
  }
}

class _Harness {
  _Harness({this.redirectGate});

  final request = Completer<String>();

  /// Пока не завершён, роутер держит редирект лобби (как запрос к API).
  final Completer<void>? redirectGate;
  int taps = 0;

  late final router = GoRouter(
    initialLocation: '/games',
    redirect: (context, state) async {
      final gate = redirectGate;
      if (gate != null && state.uri.path.startsWith('/games/durak/lobby/')) {
        await gate.future;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/games',
        builder: (_, __) =>
            _Card(request: () => request.future, onTap: () => taps++),
      ),
      GoRoute(
        path: '/games/durak/lobby/:id',
        builder: (_, state) =>
            Scaffold(body: Text('lobby ${state.pathParameters['id']}')),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}

final _cover = find.byKey(lobbyOpeningScreenKey);

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('тап сразу открывает экран ожидания с шапкой лобби',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.pump();

    await tester.tap(find.text('create'));
    await tester.pump();

    expect(_cover, findsOneWidget);
    expect(find.text('Своя игра'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Карточка закрыта экраном ожидания: кнопки на экране больше нет.
    expect(find.text('create').hitTestable(), findsNothing);
    expect(find.text('busy').hitTestable(), findsNothing);
    expect(h.taps, 1);

    h.request.complete('/games/durak/lobby/L1');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('повторные тапы по месту кнопки не создают вторую игру',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.pump();
    final at = tester.getCenter(find.text('create'));

    await tester.tapAt(at);
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(h.taps, 1);
    expect(_cover, findsOneWidget);

    h.request.complete('/games/durak/lobby/L1');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('lobby L1'), findsOneWidget);
    expect(h.taps, 1);
  });

  testWidgets('экран ожидания держится, пока роутер не показал лобби',
      (tester) async {
    final gate = Completer<void>();
    final h = _Harness(redirectGate: gate);
    await h.pump(tester);
    await tester.pump();

    await tester.tap(find.text('create'));
    await tester.pump();
    h.request.complete('/games/durak/lobby/L1');
    await tester.pump();

    // Сервер ответил, редирект лобби ещё в пути: карточка не возвращается.
    await tester.pump(const Duration(seconds: 3));
    expect(_cover, findsOneWidget);
    expect(find.text('lobby L1'), findsNothing);
    expect(find.text('create').hitTestable(), findsNothing);
    expect(find.text('busy').hitTestable(), findsNothing);

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('lobby L1'), findsOneWidget);

    await tester.pump(LobbyOpening.lingerUnderLobby);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_cover, findsNothing);

    // Назад из лобби ведёт на карточки, а не на экран ожидания.
    h.router.pop();
    await tester.pumpAndSettle();
    expect(_cover, findsNothing);
    expect(find.text('create').hitTestable(), findsOneWidget);
  });

  testWidgets('ошибка создания возвращает на карточку', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.pump();

    await tester.tap(find.text('create'));
    await tester.pump();
    expect(_cover, findsOneWidget);

    h.request.completeError('boom');
    await tester.pump();
    await tester.pump();

    expect(_cover, findsNothing);
    expect(find.text('error: boom'), findsOneWidget);
    expect(find.text('create').hitTestable(), findsOneWidget);

    // Кнопка снова работает.
    await tester.tap(find.text('create'));
    await tester.pump();
    expect(h.taps, 2);
  });

  testWidgets('«назад» не закрывает экран ожидания', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.pump();

    await tester.tap(find.text('create'));
    await tester.pump();

    final back = find.descendant(
      of: _cover,
      matching: find.byIcon(Icons.arrow_back_rounded),
    );
    expect(back, findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: back, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNull,
    );

    // Системная кнопка «назад».
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_cover, findsOneWidget);
    expect(h.taps, 1);

    h.request.complete('/games/durak/lobby/L1');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('режим поиска показывает заголовок «Лобби», узкий экран',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LobbyOpeningScreen(gameType: 'tictactoe', mode: 'matchmake'),
      ),
    );
    await tester.pump();

    expect(find.text('Лобби'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
