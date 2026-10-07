import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/chats/chat_room_gamepad.dart';
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

  test('вверх идёт к старым, вниз к новым, без цикла', () {
    expect(
      chatRoomMessageIndexAfterMove(
        index: 2,
        count: 5,
        action: GamepadAction.up,
      ),
      1,
    );
    expect(
      chatRoomMessageIndexAfterMove(
        index: 2,
        count: 5,
        action: GamepadAction.down,
      ),
      3,
    );
    expect(
      chatRoomMessageIndexAfterMove(
        index: 0,
        count: 5,
        action: GamepadAction.up,
      ),
      0,
    );
    expect(
      chatRoomMessageIndexAfterMove(
        index: 4,
        count: 5,
        action: GamepadAction.down,
      ),
      4,
    );
    expect(
      chatRoomMessageIndexAfterMove(
        index: 2,
        count: 5,
        action: GamepadAction.left,
      ),
      2,
    );
  });

  test('на краю ленты стрелка переключает полосу', () {
    expect(
      chatRoomZoneAfterVertical(
        zone: ChatRoomGamepadZone.messages,
        action: GamepadAction.up,
        messageIndex: 0,
        messageCount: 4,
        hasToolbar: true,
      ),
      ChatRoomGamepadZone.toolbar,
    );
    expect(
      chatRoomZoneAfterVertical(
        zone: ChatRoomGamepadZone.messages,
        action: GamepadAction.down,
        messageIndex: 3,
        messageCount: 4,
        hasToolbar: true,
      ),
      ChatRoomGamepadZone.composer,
    );
    expect(
      chatRoomZoneAfterVertical(
        zone: ChatRoomGamepadZone.messages,
        action: GamepadAction.down,
        messageIndex: 1,
        messageCount: 4,
        hasToolbar: true,
      ),
      ChatRoomGamepadZone.messages,
    );
    expect(
      chatRoomZoneAfterVertical(
        zone: ChatRoomGamepadZone.toolbar,
        action: GamepadAction.down,
        messageIndex: 0,
        messageCount: 4,
        hasToolbar: true,
      ),
      ChatRoomGamepadZone.messages,
    );
    expect(
      chatRoomZoneAfterVertical(
        zone: ChatRoomGamepadZone.composer,
        action: GamepadAction.up,
        messageIndex: 3,
        messageCount: 4,
        hasToolbar: true,
      ),
      ChatRoomGamepadZone.messages,
    );
  });

  test('правый стик листает окно и оставляет первое на экране', () {
    expect(
      chatRoomPageIndex(
        index: 8,
        count: 20,
        step: 5,
        visualUp: true,
      ),
      3,
    );
    expect(
      chatRoomPageIndex(
        index: 8,
        count: 20,
        step: 5,
        visualUp: false,
      ),
      13,
    );
    expect(
      chatRoomPageIndex(
        index: 1,
        count: 20,
        step: 5,
        visualUp: true,
      ),
      0,
    );
    expect(chatRoomPageStep(viewport: 400, itemExtent: 80), 5);
  });

  test('вбок — ответ, в меню A и стик не закрывают', () {
    expect(chatRoomHorizontalIsReply(GamepadAction.left), isTrue);
    expect(chatRoomHorizontalIsReply(GamepadAction.scrollRight), isTrue);
    expect(chatRoomHorizontalIsReply(GamepadAction.up), isFalse);
    expect(chatRoomActionMenuKeepsOpen(GamepadAction.confirm), isTrue);
    expect(chatRoomActionMenuKeepsOpen(GamepadAction.down), isTrue);
    expect(chatRoomActionMenuKeepsOpen(GamepadAction.cancel), isFalse);
    expect(chatRoomActionMenuKeepsOpen(GamepadAction.actionX), isFalse);
  });

  testWidgets('без геймпада глиф полосы скрыт', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatRoomGamepadLaneHint(
            action: GamepadAction.down,
            child: Text('шапка'),
          ),
        ),
      ),
    );
    expect(find.text('шапка'), findsOneWidget);
    expect(find.byType(GamepadGlyph), findsNothing);
  });
}
