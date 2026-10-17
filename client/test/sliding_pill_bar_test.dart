import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/sliding_pill_bar.dart';

void main() {
  testWidgets('плашка едет за пальцем и встаёт на вкладку', (tester) async {
    final selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, index, _) {
                  return SlidingPillBar(
                    itemCount: 3,
                    selectedIndex: index,
                    onChanged: (next) => selected.value = next,
                    itemBuilder: (context, i, isSelected) {
                      return Text(isSelected ? '$i' : '·');
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byType(SlidingPillBar));
    final slot = bar.width / 3;
    final gesture = await tester.startGesture(
      Offset(bar.left + 12, bar.center.dy),
    );
    await gesture.moveTo(Offset(bar.left + slot + slot / 2, bar.center.dy));
    await tester.pump();

    expect(selected.value, 1);
    final mid = tester.getCenter(find.byKey(const ValueKey('sliding-pill')));
    expect(mid.dx, greaterThan(bar.left + slot));
    expect(mid.dx, lessThan(bar.left + slot * 2));
    expect(
      tester.getSize(find.byKey(const ValueKey('sliding-pill'))).width,
      lessThan(slot - 16),
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    final pill = tester.getCenter(find.byKey(const ValueKey('sliding-pill')));
    final label = tester.getCenter(find.text('1'));
    expect((pill.dx - label.dx).abs(), lessThan(12));
  });

  testWidgets('узкая плашка обнимает подпись, а не всю полоску',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.surfaceUnified,
          body: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              key: ValueKey('pill-shot'),
              child: ColoredBox(
                color: AppColors.surfaceUnified,
                child: SizedBox(
                  width: 360,
                  child: SlidingPillBar(
                    shrinkWrap: true,
                    itemCount: 2,
                    selectedIndex: 0,
                    onChanged: _ignore,
                    itemBuilder: (context, i, selected) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            i == 0
                                ? Icons.sports_esports_rounded
                                : Icons.group_rounded,
                            size: 20,
                            color: selected
                                ? AppColors.accentStart
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            i == 0 ? 'Игры' : 'Лобби',
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.accentStart
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pill = tester.getSize(find.byKey(const ValueKey('sliding-pill')));
    final games = tester.getSize(find.text('Игры'));
    expect(pill.width, greaterThan(games.width));
    expect(pill.width, lessThan(180));
    final pillRect = tester.getRect(find.byKey(const ValueKey('sliding-pill')));
    final gamesRect = tester.getRect(find.text('Игры'));
    expect(
      (pillRect.center.dy - gamesRect.center.dy).abs(),
      lessThan(2),
      reason: 'заливка должна быть по центру подписи, а не ниже неё',
    );

    final dir = Directory('/opt/cursor/artifacts');
    if (!dir.existsSync()) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('pill-shot')),
    );
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
    if (image == null) return;
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    if (bytes == null) return;
    File('${dir.path}/games-lobby-pill.png')
        .writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void _ignore(int _) {}
