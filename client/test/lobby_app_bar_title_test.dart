import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('Своя игра помещается в узкой шапке рядом с поиском',
      (tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            titleSpacing: 8,
            title: const GameLobbyAppBarTitle(
              gameType: 'tictactoe',
              title: 'Своя игра',
            ),
            actions: [
              LobbySearchAction(searching: false, onStart: () {}),
              IconButton(
                icon: const Icon(Icons.rule_rounded),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Своя игра'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final titleRender = tester.renderObject<RenderBox>(find.text('Своя игра'));
    expect(titleRender.size.width, greaterThan(0));
    expect(titleRender.size.height, greaterThan(0));
  });

  testWidgets('нарды и морской бой тоже показывают Своя игра, не название',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 220,
                height: 40,
                child: GameLobbyAppBarTitle(
                  gameType: 'nardy',
                  title: 'Своя игра',
                ),
              ),
              SizedBox(
                width: 220,
                height: 40,
                child: GameLobbyAppBarTitle(
                  gameType: 'battleship',
                  title: 'Своя игра',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Своя игра'), findsNWidgets(2));
    expect(find.text('Нарды'), findsNothing);
    expect(find.text('Морской бой'), findsNothing);
  });
}
