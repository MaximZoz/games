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
}
