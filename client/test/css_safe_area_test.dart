import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/css_safe_area.dart';

const _base = MediaQueryData(size: Size(852, 393));

void main() {
  group('mediaWithCssSafeArea', () {
    test('вырезы из CSS попадают в padding и viewPadding', () {
      final media = mediaWithCssSafeArea(
        media: _base,
        cssInsets: const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      );
      expect(media.viewPadding.left, 59);
      expect(media.viewPadding.bottom, 21);
      expect(media.padding.bottom, 21);
    });

    test('под клавиатурой нижний вырез не действует', () {
      final media = mediaWithCssSafeArea(
        media: _base.copyWith(
          viewInsets: const EdgeInsets.only(bottom: 336),
        ),
        cssInsets: const EdgeInsets.only(bottom: 34),
      );
      expect(media.viewPadding.bottom, 34);
      expect(media.padding.bottom, 0);
    });

    test('данные платформы не занижаются', () {
      final media = mediaWithCssSafeArea(
        media: _base.copyWith(
          viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        cssInsets: const EdgeInsets.only(top: 0, bottom: 21),
      );
      expect(media.viewPadding.top, 47);
      expect(media.viewPadding.bottom, 34);
    });
  });

  testWidgets('без вырезов метрики не подменяются', (tester) async {
    late MediaQueryData seen;
    await tester.pumpWidget(
      MediaQuery(
        data: _base,
        child: CssSafeArea(
          child: Builder(
            builder: (context) {
              seen = MediaQuery.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(seen.viewPadding, EdgeInsets.zero);
  });
}
