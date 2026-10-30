import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/gamepad/gamepad_buy_button.dart';
import 'package:multigames_client/core/shared_prefs_guard.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_buy_slot.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

ShopItem _item(String kind) {
  return ShopItem(
    code: kind,
    kind: kind,
    title: kind,
    description: '',
    priceBronze: 10,
    owned: false,
  );
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: home),
  );
}

void main() {
  tearDown(resetSharedPrefsGuard);

  test('эликсир и смайлик докупаются, остальное — один раз', () {
    expect(_item('elixir').boughtOnce, isFalse);
    expect(_item('emoji').boughtOnce, isFalse);
    expect(_item('collection').boughtOnce, isTrue);
    expect(_item('frame').boughtOnce, isTrue);
    expect(_item('stake_unlock').boughtOnce, isTrue);
    expect(_item('emoji_pack').boughtOnce, isTrue);
  });

  test('зависший SharedPreferences не ждём второй раз', () async {
    loadSharedPreferences = () => Completer<SharedPreferences>().future;
    expect(
      await sharedPreferencesOrNull(timeout: const Duration(milliseconds: 30)),
      isNull,
    );
    expect(sharedPrefsNeedsSessionRetry, isTrue);
    final sw = Stopwatch()..start();
    expect(await sharedPreferencesOrNull(), isNull);
    expect(sw.elapsedMilliseconds, lessThan(200));
  });

  test('после таймаута поздний SharedPreferences всё ещё годится', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'k': 'v'});
    final done = Completer<SharedPreferences>();
    loadSharedPreferences = () => done.future;
    expect(
      await sharedPreferencesOrNull(timeout: const Duration(milliseconds: 30)),
      isNull,
    );
    expect(sharedPrefsNeedsSessionRetry, isTrue);
    done.complete(await SharedPreferences.getInstance());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await sharedPreferencesOrNull();
    expect(prefs, isNotNull);
    expect(prefs!.getString('k'), 'v');
    expect(sharedPrefsReady, isTrue);
  });

  testWidgets('разовая покупка: …, а после успеха только Есть', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        ShopBuySlot(
          once: true,
          busy: true,
          onBuy: () => taps++,
        ),
      ),
    );
    expect(find.text('…'), findsOneWidget);
    expect(find.text('Купить'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(taps, 0);

    await tester.pumpWidget(
      _app(
        ShopBuySlot(
          once: true,
          owned: true,
          onBuy: () => taps++,
        ),
      ),
    );
    expect(find.text('Есть'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Куплено'), findsNothing);
  });

  testWidgets('повторная покупка после … снова Купить', (tester) async {
    await tester.pumpWidget(
      _app(
        const ShopBuySlot(
          busy: true,
          onBuy: _noop,
        ),
      ),
    );
    expect(find.text('…'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        const ShopBuySlot(onBuy: _noop),
      ),
    );
    expect(find.text('Купить'), findsOneWidget);
    expect(find.text('Есть'), findsNothing);
  });

  testWidgets('превью покупки показывает … пока запрос не вернулся',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showCollectionFullscreen(
                  context,
                  title: 'Легендарный',
                  animatedName: 'sparkles',
                  artwork: const SizedBox.shrink(),
                  buyLabel: 'Купить',
                  onBuy: () => gate.future,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Купить'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Купить'));
    await tester.pump();
    expect(find.text('…'), findsOneWidget);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Купить'), findsWidgets);
    expect(find.text('…'), findsNothing);
  });

  testWidgets('занятая кнопка превью не нажимается', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        GamepadBuyButton(
          busy: true,
          label: 'Купить',
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.text('…'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(taps, 0);
  });
}

void _noop() {}
