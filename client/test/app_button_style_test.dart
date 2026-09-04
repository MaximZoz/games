import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_button.dart';

void main() {
  test('единый стиль: светлый фон, лавандовая рамка, чёрный текст', () {
    final style = AppButtonStyles.of();
    expect(style.backgroundColor!.resolve({}), AppColors.buttonFill);
    expect(style.foregroundColor!.resolve({}), AppColors.textPrimary);
    expect(style.side!.resolve({})!.color, AppColors.buttonBorder);
    expect(AppColors.buttonFill, const Color(0xFFF5F5F7));
    expect(AppColors.buttonBorder, const Color(0xFFB3B3E6));
  });

  testWidgets('тема FilledButton и OutlinedButton совпадает с AppButtonStyles',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          filledButtonTheme: FilledButtonThemeData(style: AppButtonStyles.of()),
          outlinedButtonTheme:
              OutlinedButtonThemeData(style: AppButtonStyles.of()),
        ),
        home: Scaffold(
          body: Column(
            children: [
              FilledButton(onPressed: () {}, child: const Text('Сохранить')),
              OutlinedButton(onPressed: () {}, child: const Text('Отмена')),
            ],
          ),
        ),
      ),
    );

    final context = tester.element(find.text('Сохранить'));
    final filled = Theme.of(context).filledButtonTheme.style!;
    final outlined = Theme.of(context).outlinedButtonTheme.style!;
    expect(filled.backgroundColor!.resolve({}), AppColors.buttonFill);
    expect(filled.foregroundColor!.resolve({}), AppColors.textPrimary);
    expect(filled.side!.resolve({})!.color, AppColors.buttonBorder);
    expect(outlined.backgroundColor!.resolve({}), AppColors.buttonFill);
    expect(outlined.side!.resolve({})!.color, AppColors.buttonBorder);
  });

  testWidgets('AppButton рисует светлый фон и лавандовую рамку', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(onPressed: () {}, label: 'Сохранить'),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.buttonFill);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.side.color, AppColors.buttonBorder);
    expect(find.text('Сохранить'), findsOneWidget);
  });
}
