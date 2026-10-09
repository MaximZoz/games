import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_host.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/profile/profile_gallery_gamepad.dart';
import 'package:multigames_client/profile/profile_gallery_widgets.dart';
import 'package:multigames_client/profile/profile_photos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GamepadDispatcher.reset();
    GamepadFocusRegistry.reset();
    GamepadService.debugPollNative = false;
    GamepadService.instance.reset();
  });

  tearDown(() {
    GamepadService.instance.reset();
  });

  test('стик и стрелки листают галерею по кругу границ', () {
    expect(
      profileGalleryIndexAfterMove(
        index: 0,
        count: 3,
        action: GamepadAction.right,
      ),
      1,
    );
    expect(
      profileGalleryIndexAfterMove(
        index: 2,
        count: 3,
        action: GamepadAction.down,
      ),
      2,
    );
    expect(
      profileGalleryIndexAfterMove(
        index: 1,
        count: 3,
        action: GamepadAction.scrollLeft,
      ),
      0,
    );
    expect(
      profileGalleryIndexAfterMove(
        index: 0,
        count: 3,
        action: GamepadAction.up,
      ),
      0,
    );
  });

  test('любая кнопка закрывает галерею, стик — нет', () {
    expect(profileGalleryActionCloses(GamepadAction.confirm), isTrue);
    expect(profileGalleryActionCloses(GamepadAction.cancel), isTrue);
    expect(profileGalleryActionCloses(GamepadAction.actionX), isTrue);
    expect(profileGalleryActionCloses(GamepadAction.left), isFalse);
    expect(profileGalleryActionCloses(GamepadAction.scrollRight), isFalse);
  });

  testWidgets('A в галерее закрывает, вправо листает', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var closed = false;
    var index = 0;
    const photo = ProfilePhotoMeta(
      id: 'p1',
      userId: 'u1',
      slot: 0,
      imageMime: 'image/jpeg',
    );
    const photo2 = ProfilePhotoMeta(
      id: 'p2',
      userId: 'u1',
      slot: 1,
      imageMime: 'image/jpeg',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: GamepadHost(
            child: ProfilePhotoViewerBody(
              photos: const [photo, photo2],
              selectedIndex: index,
              avatarPhoto: const ColoredBox(
                key: ValueKey('hero'),
                color: Colors.purple,
              ),
              imageBuilder: (_, {BoxFit fit = BoxFit.cover}) =>
                  const ColoredBox(color: Colors.blue),
              onSelectIndex: (next) => index = next,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    GamepadService.instance.start();
    GamepadService.instance.setDevicesForTest(const [
      GamepadDevice(id: 'pad', name: 'Xbox Wireless Controller', index: 0),
    ]);
    GamepadService.instance.emit(GamepadAction.right);
    await tester.pump(const Duration(milliseconds: 40));
    expect(index, 1);
    expect(closed, isFalse);
    GamepadService.instance.emit(GamepadAction.confirm);
    await tester.pump(const Duration(milliseconds: 40));
    expect(closed, isTrue);
  });
}
