import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/domino/domino_provider.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/lobby_guest.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/screens/domino_lobby_screen.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  test('гость по ссылке не считается участником лобби', () {
    expect(
      lobbyUserIsMember(
        userId: 'alena',
        creatorId: 'host',
        playerIds: const ['host'],
        players: [LobbyPlayer(id: 'host', displayName: 'Хозяин')],
      ),
      isFalse,
    );
    expect(
      lobbyUserIsMember(
        userId: 'host',
        creatorId: 'host',
        playerIds: const ['host'],
      ),
      isTrue,
    );
    expect(
      lobbyCreatorDisplayName(
        creatorId: 'host',
        players: [LobbyPlayer(id: 'host', displayName: 'Хозяин')],
      ),
      'Хозяин',
    );
  });

  testWidgets('ссылка приглашения открывает вход, а не стол хозяина',
      (tester) async {
    const lobbyId = 'lobby-1';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dominoLobbyProvider.overrideWith((ref, id) async {
            return DominoLobbyView(
              id: id,
              creatorId: 'host',
              status: 'waiting_invite',
              mode: 'invite',
              maxPlayers: 2,
              turnTimeSec: 0,
              stakeBronze: 2,
              playerIds: const ['host'],
              players: [LobbyPlayer(id: 'host', displayName: 'Хозяин')],
              invited: [LobbyPlayer(id: 'alena', displayName: 'Алёна')],
            );
          }),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DominoLobbyScreen(lobbyId: lobbyId, initialMode: 'invite'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Войти в игру'), findsWidgets);
    expect(find.text('Хозяин приглашает вас сыграть в Домино'), findsOneWidget);
    expect(find.text('Отправить ссылку на игру'), findsNothing);
    expect(find.text('Отправлено'), findsNothing);
    expect(find.text('Поиск игроков'), findsNothing);
    expect(find.text('Алёна'), findsNothing);
    expect(find.text('Своя игра'), findsNothing);
  });
}
