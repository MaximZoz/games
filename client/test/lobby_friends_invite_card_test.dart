import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show LobbyPlayer;
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';

import 'test_locale.dart';

FriendsSnapshot _snapshot() {
  return FriendsSnapshot(
    friends: [
      FriendItem(
        user: FriendUserItem(
          id: 'online-1',
          email: 'a@a.a',
          displayName: 'player1',
        ),
        createdAt: '',
      ),
      FriendItem(
        user: FriendUserItem(
          id: 'offline-1',
          email: 'b@b.b',
          displayName: 'player3',
        ),
        createdAt: '',
      ),
    ],
    incoming: const [],
    outgoing: const [],
  );
}

void main() {
  setUp(setUpTestLocaleRu);

  testWidgets('lobby friends card shows Онлайн like Durak', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenceMapProvider.overrideWith(
            (ref) => Stream.value({
              'online-1': PresenceEntry(online: true),
              'offline-1': PresenceEntry(
                online: false,
                lastSeenAt: DateTime.now()
                    .subtract(const Duration(minutes: 3))
                    .toUtc()
                    .toIso8601String(),
              ),
            }),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LobbyFriendsInviteCard(
              friendsAsync: AsyncValue.data(_snapshot()),
              excludeUserIds: const {},
              invitedIds: const {},
              invitingIds: const {},
              cancellingIds: const {},
              listStorageKey: 'test-lobby-friends',
              expand: false,
              onInvite: (_) {},
              onCancel: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('player1'), findsOneWidget);
    expect(find.text('player3'), findsOneWidget);
    expect(find.text('Онлайн'), findsOneWidget);
    expect(find.text('Пригласить'), findsNWidgets(2));
  });

  testWidgets('tap on friend name opens profile callback', (tester) async {
    String? tappedId;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenceMapProvider.overrideWith(
            (ref) => Stream.value({
              'online-1': PresenceEntry(online: true),
            }),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LobbyFriendsInviteCard(
              friendsAsync: AsyncValue.data(_snapshot()),
              excludeUserIds: const {},
              invitedIds: const {},
              invitingIds: const {},
              cancellingIds: const {},
              listStorageKey: 'test-lobby-friends-tap',
              expand: false,
              onInvite: (_) {},
              onCancel: (_) {},
              onFriendTap: (friend) => tappedId = friend.user.id,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('player1'));
    expect(tappedId, 'online-1');
  });

  testWidgets('приглашённый не из друзей виден в списке', (tester) async {
    String? cancelled;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenceMapProvider.overrideWith((ref) => Stream.value(const {})),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LobbyFriendsInviteCard(
              friendsAsync: AsyncValue.data(_snapshot()),
              excludeUserIds: const {},
              invitedIds: const {},
              invitingIds: const {},
              cancellingIds: const {},
              listStorageKey: 'test-lobby-guest',
              expand: false,
              onInvite: (_) {},
              onCancel: (id) => cancelled = id,
              pendingInvites: [
                LobbyPlayer(id: 'guest-1', displayName: 'rival'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('rival'), findsOneWidget);
    expect(find.text('Отправлено'), findsOneWidget);

    await tester.tap(find.text('Отмена'));
    expect(cancelled, 'guest-1');
  });

  testWidgets('друг уже в списке — гостевой строки нет', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenceMapProvider.overrideWith((ref) => Stream.value(const {})),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LobbyFriendsInviteCard(
              friendsAsync: AsyncValue.data(_snapshot()),
              excludeUserIds: const {},
              invitedIds: const {'online-1'},
              invitingIds: const {},
              cancellingIds: const {},
              listStorageKey: 'test-lobby-dup',
              expand: false,
              onInvite: (_) {},
              onCancel: (_) {},
              pendingInvites: [
                LobbyPlayer(id: 'online-1', displayName: 'player1'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('player1'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('отказ друга показывает «Отказ», а не «Отправлено»',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenceMapProvider.overrideWith((ref) => Stream.value(const {})),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LobbyFriendsInviteCard(
              friendsAsync: AsyncValue.data(_snapshot()),
              excludeUserIds: const {},
              invitedIds: const {},
              invitingIds: const {},
              cancellingIds: const {},
              declinedIds: const {'online-1'},
              listStorageKey: 'test-lobby-declined',
              expand: false,
              onInvite: (_) {},
              onCancel: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Отказ'), findsOneWidget);
    expect(find.text('Отправлено'), findsNothing);
  });

  testWidgets('«Поиск» в шапке: кнопка зовёт поиск, во время поиска заблокирована',
      (tester) async {
    var started = 0;
    Widget wrap(bool searching) => MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: LobbySearchAction(
                searching: searching,
                onStart: () => started++,
              ),
            ),
          ),
        );

    await tester.pumpWidget(wrap(false));
    await tester.pump();
    expect(find.text('Поиск игроков'), findsOneWidget);
    await tester.tap(find.text('Поиск игроков'));
    expect(started, 1);

    await tester.pumpWidget(wrap(true));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Поиск игроков'));
    expect(started, 1);
  });

  testWidgets('invite buttons stay compact on desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenceMapProvider.overrideWith(
            (ref) => Stream.value({
              'online-1': PresenceEntry(online: true),
            }),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              child: LobbyFriendsInviteCard(
                friendsAsync: AsyncValue.data(_snapshot()),
                excludeUserIds: const {},
                invitedIds: const {},
                invitingIds: const {},
                cancellingIds: const {},
                listStorageKey: 'test-lobby-friends-btn',
                expand: false,
                onInvite: (_) {},
                onCancel: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final button = tester.getSize(find.byType(LobbyInviteActionButton).first);
    expect(button.width, lessThan(150));
    expect(button.width, greaterThan(70));
  });
}
