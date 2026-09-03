import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_utils.dart';

/// Как `_buildSetup`: доска в `Expanded` по остатку, кнопки снизу (две строки).
void main() {
  testWidgets('Android: доска расстановки и две строки кнопок без overflow', (
    tester,
  ) async {
    const phone = Size(360, 640);
    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    FlutterError? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final ex = details.exception;
      if (ex is FlutterError && '$ex'.contains('overflowed')) {
        overflow = ex;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: phone,
            padding: EdgeInsets.only(top: 24, bottom: 48),
            viewPadding: EdgeInsets.only(top: 24, bottom: 48),
            textScaler: TextScaler.linear(1.15),
          ),
          child: Scaffold(
            appBar: AppBar(title: const Text('Battleship')),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 72),
                  const Text('Расстановка'),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final cell = fitBattleshipCellSize(
                                  maxWidth: constraints.maxWidth,
                                  maxHeight: constraints.maxHeight,
                                  maxCell: 36,
                                );
                                final side = cell * kBattleshipBoardSize +
                                    2 * (kBattleshipBoardSize - 1);
                                return Center(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(
                                      width: side,
                                      height: side,
                                      child: const ColoredBox(
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.casino_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Случайная расстановка',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                onPressed: () {},
                                icon: const Icon(Icons.rotate_right_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {},
                              child: const Text('Подтвердить'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(overflow, isNull);
    expect(tester.takeException(), isNull);
  });
}
