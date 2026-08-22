import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/uno_game_screen.dart';

import 'test_locale.dart';

UnoPlayerView _player({required bool forfeited}) {
  return UnoPlayerView(
    id: 'opp',
    seat: 1,
    hand: const [],
    handCount: forfeited ? 0 : 5,
    score: 12,
    saidUno: false,
    forfeited: forfeited,
    displayName: 'Игрок',
  );
}

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('вышедший соперник затемнён и зачёркнут', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: UnoOpponentHand(
            player: _player(forfeited: true),
            name: 'Игрок',
            active: false,
            displayCount: 0,
          ),
        ),
      ),
    );

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0.45);
    final name = tester.widget<Text>(find.text('Игрок'));
    expect(name.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('активный соперник не затемнён', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: UnoOpponentHand(
            player: _player(forfeited: false),
            name: 'Игрок',
            active: true,
            displayCount: 5,
          ),
        ),
      ),
    );

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1);
    final name = tester.widget<Text>(find.text('Игрок'));
    expect(name.style?.decoration, isNull);
  });
}
