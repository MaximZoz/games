import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/game_lobby_widgets.dart';

const _shareKey = Key('share-link-card');
const _friendsKey = Key('friends-card');

Widget _lobby({int friendsCount = 1}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GameLobbyWaitingLayout(
          maxPlayers: 2,
          stakeBronze: 2,
          stakeLabel: 'Ставка',
          friendsCount: friendsCount,
          padding: const EdgeInsets.all(16),
          shareLinkCard: const SizedBox(
            key: _shareKey,
            height: 64,
            child: ColoredBox(color: Colors.amber),
          ),
          friendsCardBuilder: (expand) => const ColoredBox(
            key: _friendsKey,
            color: Colors.blue,
            child: SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('альбом: ставка и ссылка в одной строке, друзьям остаётся место',
      (tester) async {
    tester.view.physicalSize = const Size(800, 380);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_lobby());
    await tester.pump();

    final stake = tester.getRect(find.byType(LobbyStakeChip));
    final share = tester.getRect(find.byKey(_shareKey));
    final friends = tester.getRect(find.byKey(_friendsKey));

    // Одна строка: вертикальные центры совпадают, ставка левее ссылки.
    expect((stake.center.dy - share.center.dy).abs(), lessThan(2));
    expect(stake.right, lessThanOrEqualTo(share.left));
    // Список друзей ниже строки и занимает основную часть высоты.
    expect(friends.top, greaterThanOrEqualTo(share.bottom));
    expect(friends.height, greaterThan(180));
  });

  testWidgets('портрет: ставка над ссылкой, как было', (tester) async {
    tester.view.physicalSize = const Size(380, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_lobby());
    await tester.pump();

    final stake = tester.getRect(find.byType(LobbyStakeChip));
    final share = tester.getRect(find.byKey(_shareKey));

    expect(stake.bottom, lessThanOrEqualTo(share.top));
  });
}
