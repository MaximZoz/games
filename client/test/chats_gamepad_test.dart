import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chats_gamepad.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
  });

  tearDown(() {
    GamepadService.instance.reset();
  });

  test('вверх/вниз шагают по чатам, влево не меняет индекс', () {
    expect(
      chatsListIndexAfterMove(
        index: 1,
        count: 4,
        action: GamepadAction.down,
      ),
      2,
    );
    expect(
      chatsListIndexAfterMove(
        index: 1,
        count: 4,
        action: GamepadAction.up,
      ),
      0,
    );
    expect(
      chatsListIndexAfterMove(
        index: 0,
        count: 4,
        action: GamepadAction.up,
      ),
      0,
    );
    expect(
      chatsListIndexAfterMove(
        index: 1,
        count: 4,
        action: GamepadAction.right,
      ),
      1,
    );
  });

  test('влево/вправо заходят на кнопки свайпа', () {
    expect(
      chatsActionIndexAfterMove(
        current: null,
        actionCount: 2,
        action: GamepadAction.right,
      ),
      0,
    );
    expect(
      chatsActionIndexAfterMove(
        current: null,
        actionCount: 2,
        action: GamepadAction.scrollLeft,
      ),
      1,
    );
    expect(
      chatsActionIndexAfterMove(
        current: 0,
        actionCount: 2,
        action: GamepadAction.right,
      ),
      1,
    );
    expect(
      chatsActionIndexAfterMove(
        current: 1,
        actionCount: 2,
        action: GamepadAction.right,
      ),
      1,
    );
  });

  test('число кнопок свайпа зависит от блока', () {
    expect(chatsSwipeActionCount(canBlock: true), 2);
    expect(chatsSwipeActionCount(canBlock: false), 1);
  });

  testWidgets('без геймпада LT у нового чата скрыт', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatsGamepadLtHint(
            child: Text('новый'),
          ),
        ),
      ),
    );
    expect(find.text('новый'), findsOneWidget);
    expect(find.byType(GamepadGlyph), findsNothing);
  });
}
