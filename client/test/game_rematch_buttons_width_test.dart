import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

GameRematchSection _section({List<String> peerIds = const []}) {
  return GameRematchSection(
    rematchLobbyId: null,
    rematchDeclined: false,
    iDeclinedRematch: false,
    isRematching: false,
    isAcceptingRematch: false,
    isFindingGame: false,
    peerIds: peerIds,
    invites: const [],
    onRematch: () {},
    onAccept: (_) {},
    onDecline: (_) {},
    onCancelWait: () {},
    onFindGame: () {},
    compact: true,
  );
}

void main() {
  testWidgets('«Повторить» и «Другой соперник» не растянуты на всю ширину',
      (tester) async {
    const width = 400.0;
    await tester.pumpWidget(_wrap(_section(), width: width));

    final rematchFinder = find.widgetWithText(FramedButton, 'Повторить');
    final otherFinder = find.widgetWithText(FramedButton, 'Другой соперник');
    final rematch = tester.getSize(rematchFinder);
    final other = tester.getSize(otherFinder);

    // Кнопка по содержимому с запасом на паддинги, а не во всю ширину.
    expect(rematch.width, lessThan(width * 0.7));
    expect(other.width, lessThan(width * 0.7));
    // И при этом не схлопнута: текст с иконкой внутри помещается.
    expect(rematch.width, greaterThan(100));
    expect(other.width, greaterThan(100));
    expect(rematch.height, greaterThanOrEqualTo(44));
  });

  testWidgets('кнопки выровнены по центру блока', (tester) async {
    const width = 400.0;
    await tester.pumpWidget(_wrap(_section(), width: width));

    final box = tester.renderObject<RenderBox>(
      find.byType(GameRematchSection),
    );
    final blockCenter =
        box.localToGlobal(box.size.center(Offset.zero)).dx;
    final rematchCenter =
        tester.getCenter(find.widgetWithText(FramedButton, 'Повторить')).dx;
    expect((rematchCenter - blockCenter).abs(), lessThan(1.0));
  });

  testWidgets('в альбоме телефона кнопки реванша стоят в ряд', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_section(), width: 720));

    final rematch = tester.getRect(find.widgetWithText(FramedButton, 'Повторить'));
    final other =
        tester.getRect(find.widgetWithText(FramedButton, 'Другой соперник'));
    expect((rematch.center.dy - other.center.dy).abs(), lessThan(8));
    expect(rematch.right, lessThan(other.left + 1));
  });
}
