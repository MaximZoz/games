import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

void main() {
  test('acting seat is current player while game is live', () {
    expect(
      GameActorHighlight.isActingSeat(
        isCurrentActor: true,
        isOver: false,
      ),
      isTrue,
    );
    expect(
      GameActorHighlight.isActingSeat(
        isCurrentActor: true,
        isOver: true,
      ),
      isFalse,
    );
    expect(
      GameActorHighlight.isActingSeat(
        isCurrentActor: true,
        isOver: false,
        eliminated: true,
      ),
      isFalse,
    );
    expect(
      GameActorHighlight.isActingSeat(
        isCurrentActor: false,
        isOver: false,
      ),
      isFalse,
    );
    expect(
      GameActorHighlight.isActingSeat(
        isCurrentActor: true,
        isOver: false,
        paused: true,
      ),
      isFalse,
    );
  });
}
