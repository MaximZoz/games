import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/friends/friends_repository.dart';
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
}
