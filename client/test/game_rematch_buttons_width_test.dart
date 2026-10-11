import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

Widget _wrap(Widget child, {double width = 400}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [child],
          ),
        ),
      ),
    ),
  );
}

GameRematchSection _section({
  List<String> peerIds = const [],
  List<GameInvite> invites = const [],
  String? rematchLobbyId,
  RematchTable? table,
}) {
  return GameRematchSection(
    rematchLobbyId: rematchLobbyId,
    rematchDeclined: false,
    iDeclinedRematch: false,
    isRematching: false,
    isAcceptingRematch: false,
    isFindingGame: false,
    peerIds: peerIds,
    invites: invites,
    onRematch: () {},
    onAccept: (_) {},
    onDecline: (_) {},
    onCancelWait: () {},
    onFindGame: () {},
    compact: true,
    table: table,
  );
}

void main() {
  testWidgets('«Повторить» и «Другой соперник» всегда в одну линию',
      (tester) async {
    for (final width in [320.0, 360.0, 400.0]) {
      await tester.pumpWidget(_wrap(_section(), width: width));
      final rematch =
          tester.getRect(find.widgetWithText(FramedButton, 'Повторить'));
      final other = tester
          .getRect(find.widgetWithText(FramedButton, 'Другой соперник'));
      expect((rematch.center.dy - other.center.dy).abs(), lessThan(8));
      expect(rematch.right, lessThanOrEqualTo(other.left + 1));
      final box = tester.getRect(find.byType(GameRematchSection));
      expect(rematch.left, greaterThanOrEqualTo(box.left - 1));
      expect(other.right, lessThanOrEqualTo(box.right + 1));
      expect(find.text('Повторить'), findsOneWidget);
      expect(find.text('Другой соперник'), findsOneWidget);
    }
  });

  testWidgets('ожидание соперника прячет кнопки повтора', (tester) async {
    await tester.pumpWidget(_wrap(_section(rematchLobbyId: 'lobby')));
    expect(find.text('Повторить'), findsNothing);
    expect(find.text('Другой соперник'), findsNothing);
    expect(find.text('Ожидание соперника'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('входящий реванш — только принять или отклонить', (tester) async {
    final invite = GameInvite(
      lobbyId: 'l',
      creatorId: 'opp',
      creatorName: 'Opp',
      gameType: 'chess',
      stakeBronze: 0,
      durakMode: 'blitz',
    );
    await tester.pumpWidget(_wrap(_section(
      peerIds: const ['opp'],
      invites: [invite],
      table: const RematchTable(
        gameType: 'chess',
        stakeBronze: 0,
        gameMode: 'blitz',
      ),
    )));
    expect(find.text('Соперник предлагает реванш'), findsOneWidget);
    expect(find.text('Принять'), findsOneWidget);
    expect(find.text('Отклонить'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
    expect(find.text('Другой соперник'), findsNothing);
  });

  testWidgets('приглашение в другую игру не считается реваншем',
      (tester) async {
    final invite = GameInvite(
      lobbyId: 'l',
      creatorId: 'opp',
      creatorName: 'Opp',
      gameType: 'chess',
      stakeBronze: 2,
      durakMode: 'blitz',
      variant: 'blitz',
    );
    await tester.pumpWidget(_wrap(_section(
      peerIds: const ['opp'],
      invites: [invite],
      table: const RematchTable(
        gameType: 'tictactoe',
        stakeBronze: 2,
        variant: 'classic',
      ),
    )));
    expect(find.text('Соперник предлагает реванш'), findsNothing);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Другой соперник'), findsOneWidget);
  });
}
