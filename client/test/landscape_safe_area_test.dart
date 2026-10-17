import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/responsive.dart';

/// Геометрия iPhone в альбоме: вырез сбоку и полоска home indicator снизу.
const _iphoneLandscape = EdgeInsets.only(left: 59, right: 59, bottom: 21);

void main() {
  group('shellStatusBarExtent', () {
    test('альбом партии: status bar остаётся, даже если тулбар спрятан', () {
      expect(
        shellStatusBarExtent(viewPaddingTop: 24, collapseForInput: false),
        24,
      );
    });

    test('клавиатура в альбоме: полоску можно схлопнуть', () {
      expect(
        shellStatusBarExtent(viewPaddingTop: 24, collapseForInput: true),
        0,
      );
    });
  });

  group('landscapeContentSafeArea', () {
    test('портрет: отступы даёт нижнее меню, здесь их нет', () {
      expect(
        landscapeContentSafeArea(
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          phoneLandscape: false,
          railVisible: true,
        ),
        EdgeInsets.zero,
      );
    });

    test('альбом: низ и правый вырез отступаем, левый съедает рейл', () {
      expect(
        landscapeContentSafeArea(
          viewPadding: _iphoneLandscape,
          phoneLandscape: true,
          railVisible: true,
        ),
        const EdgeInsets.only(right: 59, bottom: 21),
      );
    });

    test('альбом без рейла: левый вырез отступаем сами', () {
      expect(
        landscapeContentSafeArea(
          viewPadding: _iphoneLandscape,
          phoneLandscape: true,
          railVisible: false,
        ),
        _iphoneLandscape,
      );
    });

    test('телефон без выреза: отступов нет', () {
      expect(
        landscapeContentSafeArea(
          viewPadding: EdgeInsets.zero,
          phoneLandscape: true,
          railVisible: true,
        ),
        EdgeInsets.zero,
      );
    });
  });

  group('landscapeRailLeadingInset', () {
    test('альбом с рейлом на Android: сдвигаем рейл от левой системной панели',
        () {
      expect(
        landscapeRailLeadingInset(
          viewPadding: const EdgeInsets.only(left: 48, right: 24, top: 0),
          phoneLandscape: true,
          railVisible: true,
          platform: TargetPlatform.android,
        ),
        48,
      );
    });

    test('альбом с рейлом на iOS: кнопки меню прижаты к левому краю (inset = 0)',
        () {
      expect(
        landscapeRailLeadingInset(
          viewPadding: _iphoneLandscape,
          phoneLandscape: true,
          railVisible: true,
          platform: TargetPlatform.iOS,
        ),
        0,
      );
    });

    test('без рейла левый inset остаётся контенту, не рейлу', () {
      expect(
        landscapeRailLeadingInset(
          viewPadding: _iphoneLandscape,
          phoneLandscape: true,
          railVisible: false,
          platform: TargetPlatform.android,
        ),
        0,
      );
    });

    test('альбом iPhone: шапка отходит от скруглённых углов', () {
      expect(
        phoneLandscapeCornerInset(
          phoneLandscape: true,
          platform: TargetPlatform.iOS,
        ),
        phoneLandscapeCornerInsetPx,
      );
    });

    test('Android и портрет: дополнительный сдвиг шапки не нужен', () {
      expect(
        phoneLandscapeCornerInset(
          phoneLandscape: true,
          platform: TargetPlatform.android,
        ),
        0,
      );
      expect(
        phoneLandscapeCornerInset(
          phoneLandscape: false,
          platform: TargetPlatform.iOS,
        ),
        0,
      );
    });

    test('портрет: рейл не сдвигаем', () {
      expect(
        landscapeRailLeadingInset(
          viewPadding: const EdgeInsets.only(left: 48, top: 24),
          phoneLandscape: false,
          railVisible: true,
          platform: TargetPlatform.android,
        ),
        0,
      );
    });
  });

  testWidgets('альбом: контенту остаётся высота без home indicator',
      (tester) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late Size box;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(852, 393),
          viewPadding: _iphoneLandscape,
          padding: _iphoneLandscape,
        ),
        child: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            return Padding(
              padding: landscapeContentSafeArea(
                viewPadding: media.viewPadding,
                phoneLandscape: isPhoneLandscape(context),
                railVisible: true,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  box = constraints.biggest;
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(box.height, 393 - 21);
    expect(box.width, 852 - 59);
  });

  testWidgets(
      'альбом iPhone: NavigationRail прижат к левому краю экрана (x = 0, ширина 56)',
      (tester) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late Offset contentTopLeft;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, platform: TargetPlatform.iOS),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(852, 393),
            viewPadding: _iphoneLandscape,
            padding: _iphoneLandscape,
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final media = MediaQuery.of(context);
                final narrowLandscape = isPhoneLandscape(context);
                return Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: landscapeRailLeadingInset(
                          viewPadding: media.viewPadding,
                          phoneLandscape: narrowLandscape,
                          railVisible: true,
                          platform: Theme.of(context).platform,
                        ),
                      ),
                      child: MediaQuery.removePadding(
                        context: context,
                        removeLeft: narrowLandscape,
                        removeBottom: narrowLandscape,
                        child: NavigationRail(
                          minWidth: narrowLandscape ? 56 : null,
                          selectedIndex: 0,
                          labelType: NavigationRailLabelType.none,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.home),
                              label: Text('Главная'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.sports_esports),
                              label: Text('Игры'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (ctx) {
                          return const SizedBox.expand(
                            key: ValueKey('landscape-content'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    final railBox = tester.getRect(find.byType(NavigationRail));
    contentTopLeft =
        tester.getTopLeft(find.byKey(const ValueKey('landscape-content')));
    expect(railBox.left, 0);
    expect(railBox.width, 56);
    expect(contentTopLeft.dx, 56);
  });
}
