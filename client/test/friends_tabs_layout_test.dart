import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/friends_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoggedOut extends AuthStateNotifier {
  _LoggedOut(super.ref) {
    state = const AsyncData<AuthUser?>(null);
  }
}

class _SilentUsersCount extends TotalUsersCountNotifier {
  @override
  Future<int?> build() async => null;
}

class _LiveUsersCount extends TotalUsersCountNotifier {
  _LiveUsersCount(this.value);
  final int value;

  @override
  Future<int?> build() async => value;
}

FriendItem _friend(String id, String name) {
  return FriendItem(
    user: FriendUserItem(id: id, email: '$id@test', displayName: name),
    createdAt: '2026-09-02T17:00:00Z',
  );
}

FriendRequestItem _request(String id, String name) {
  return FriendRequestItem(
    requestId: 'req-$id',
    user: FriendUserItem(id: id, email: '$id@test', displayName: name),
    createdAt: '2026-10-01T10:00:00Z',
  );
}

FriendsSnapshot _snapshot({
  int friends = 4,
  int incoming = 0,
  int outgoing = 0,
  int? usersCount = 122,
}) {
  return FriendsSnapshot(
    friends: [
      for (var i = 0; i < friends; i++) _friend('f$i', 'player$i'),
    ],
    incoming: [
      for (var i = 0; i < incoming; i++) _request('in$i', 'in$i'),
    ],
    outgoing: [
      for (var i = 0; i < outgoing; i++) _request('out$i', 'out$i'),
    ],
    usersCount: usersCount,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required FriendsSnapshot snapshot,
  TotalUsersCountNotifier Function()? usersCount,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/friends',
    routes: [
      GoRoute(
        path: '/friends',
        builder: (_, __) => const RepaintBoundary(
          key: ValueKey('friends-shot'),
          child: ColoredBox(
            color: AppColors.surfaceUnified,
            child: FriendsScreen(),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentRoutePathProvider.overrideWith((ref) => '/friends'),
        authStateProvider.overrideWith((ref) => _LoggedOut(ref)),
        friendsSnapshotProvider.overrideWith((ref) => Stream.value(snapshot)),
        totalUsersCountProvider.overrideWith(
          usersCount ?? _SilentUsersCount.new,
        ),
        presenceMapProvider.overrideWith(
          (ref) => Stream<Map<String, PresenceEntry>>.value(const {}),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _saveShot(WidgetTester tester, String name) async {
  final dir = Directory('/opt/cursor/artifacts');
  if (!dir.existsSync()) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('friends-shot')),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  if (image == null) return;
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (bytes == null) return;
  File('${dir.path}/$name').writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
    LocaleService.setLocale(const Locale('ru'));
    GamepadDispatcher.reset();
  });

  testWidgets('счётчик «Найти друга» виден сразу и вкладки стоят рядом',
      (tester) async {
    const size = Size(1280, 760);
    await _pump(
      tester,
      size: size,
      snapshot: _snapshot(),
    );

    expect(find.text('122'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    final friends = tester.getCenter(find.text('Друзья'));
    final findFriend = tester.getCenter(find.text('Найти друга'));
    final search = tester.getTopLeft(find.byType(TextField));

    expect(findFriend.dx - friends.dx, lessThan(280));
    expect(findFriend.dx, lessThan(size.width * 0.45));
    expect(search.dx, lessThan(40));
    expect((search.dx - tester.getTopLeft(find.text('Друзья')).dx).abs(),
        lessThan(24));

    await _saveShot(tester, 'friends-tabs-desktop.png');
  });

  testWidgets('четыре вкладки остаются у левого края сетки', (tester) async {
    const size = Size(1280, 760);
    await _pump(
      tester,
      size: size,
      snapshot: _snapshot(incoming: 2, outgoing: 1),
    );

    expect(find.text('122'), findsOneWidget);
    expect(find.text('Входящие'), findsOneWidget);
    expect(find.text('Исходящие'), findsOneWidget);

    final last = tester.getCenter(find.text('Найти друга'));
    expect(last.dx, lessThan(size.width * 0.55));

    await _saveShot(tester, 'friends-tabs-desktop-all.png');
  });

  testWidgets('живой опрос заменяет число из списка, без нуля', (tester) async {
    await _pump(
      tester,
      size: const Size(1280, 760),
      snapshot: _snapshot(usersCount: 122),
      usersCount: () => _LiveUsersCount(130),
    );

    expect(find.text('130'), findsOneWidget);
    expect(find.text('122'), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('на телефоне счётчик тоже на месте', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      snapshot: _snapshot(incoming: 1),
    );

    expect(find.text('122'), findsOneWidget);
    expect(find.text('Друзья'), findsOneWidget);
    expect(find.text('Найти друга'), findsOneWidget);
    expect(find.text('Входящие'), findsOneWidget);

    await _saveShot(tester, 'friends-tabs-phone.png');
  });
}
