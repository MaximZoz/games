import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/app_theme.dart';

void main() {
  testWidgets('AppOpaqueSurface fills with the app surface color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppOpaqueSurface(child: SizedBox.shrink()),
      ),
    );

    final box = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
    expect(box.color, AppColors.surfaceUnified);
    expect(box.color.a, 1.0);
  });

  test('Android window color matches Flutter surface', () {
    expect(AppColors.surfaceUnified, const Color(0xFFE8ECF4));
  });

  test('status bar overlay uses the same opaque surface color', () {
    expect(AppOverlays.systemUi.statusBarColor, AppColors.surfaceUnified);
    expect(AppOverlays.systemUi.statusBarColor!.a, 1.0);
    expect(AppOverlays.systemUi.systemStatusBarContrastEnforced, isFalse);
    expect(AppOverlays.systemUi.systemNavigationBarColor, AppColors.surfaceUnified);
  });
}
