import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/friends/friends_gamepad.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
  });

  tearDown(() {
    GamepadService.instance.reset();
  });

  test('правый стик листает вкладки по кругу', () {
    expect(
      friendsTabIndexAfterScroll(
        index: 0,
        length: 4,
        action: GamepadAction.scrollRight,
      ),
      1,
    );
    expect(
      friendsTabIndexAfterScroll(
        index: 0,
        length: 4,
        action: GamepadAction.scrollDown,
      ),
      1,
    );
    expect(
      friendsTabIndexAfterScroll(
        index: 0,
        length: 4,
        action: GamepadAction.scrollLeft,
      ),
      3,
    );
    expect(
      friendsTabIndexAfterScroll(
        index: 3,
        length: 4,
        action: GamepadAction.scrollUp,
      ),
      2,
    );
  });

  test('вверх/вниз шагают по карточкам с учётом колонок', () {
    expect(
      friendsCardIndexAfterMove(
        index: 1,
        count: 6,
        columns: 2,
        action: GamepadAction.down,
      ),
      3,
    );
    expect(
      friendsCardIndexAfterMove(
        index: 3,
        count: 6,
        columns: 2,
        action: GamepadAction.up,
      ),
      1,
    );
    expect(
      friendsCardIndexAfterMove(
        index: 0,
        count: 3,
        columns: 1,
        action: GamepadAction.up,
      ),
      0,
    );
  });

  test('влево/вправо заходят на кнопки карточки', () {
    expect(
      friendsActionIndexAfterMove(
        current: null,
        actionCount: 2,
        action: GamepadAction.right,
      ),
      0,
    );
    expect(
      friendsActionIndexAfterMove(
        current: null,
        actionCount: 2,
        action: GamepadAction.left,
      ),
      1,
    );
    expect(
      friendsActionIndexAfterMove(
        current: 0,
        actionCount: 2,
        action: GamepadAction.right,
      ),
      1,
    );
    expect(
      friendsActionIndexAfterMove(
        current: 1,
        actionCount: 2,
        action: GamepadAction.right,
      ),
      1,
    );
  });

  testWidgets('без геймпада LT-подпись скрыта', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FriendsGamepadLtHint(
            child: Text('поиск'),
          ),
        ),
      ),
    );
    expect(find.text('поиск'), findsOneWidget);
    expect(find.byType(GamepadGlyph), findsNothing);
  });
}
