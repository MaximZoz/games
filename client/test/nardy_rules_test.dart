import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('режим short/long и подписи', () {
    final t = l10n();
    expect(nardyNormalizeMode(null), nardyModeShort);
    expect(nardyNormalizeMode('long'), nardyModeLong);
    expect(nardyNormalizeMode('podkidnoi'), nardyModeShort);
    expect(nardyModeLabel(nardyModeShort, t), t.gamesNardyModeShort);
    expect(nardyModeLabel(nardyModeLong, t), t.gamesNardyModeLong);
  });

  test('правила содержат игроков, режим, время и ставку', () {
    final t = l10n();
    final short = nardyRuleLines(
      gameMode: nardyModeShort,
      turnTimeSec: 60,
      stakeBronze: 10,
      l10n: t,
    );
    expect(short, contains(t.rulesNardyPlayers));
    expect(short, contains(t.rulesNardyMode(t.gamesNardyModeShort)));
    expect(short, contains(t.rulesNardyPlayShort));
    expect(short, isNot(contains(t.rulesNardyPlayLong)));

    final long = nardyRuleLines(
      gameMode: nardyModeLong,
      turnTimeSec: 0,
      stakeBronze: 0,
      l10n: t,
    );
    expect(long, contains(t.rulesNardyPlayLong));
    expect(long, contains(t.rulesNoTimeLimit));
  });

  testWidgets('диалог правил нард использует общий заголовок', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showGameRulesDialog(
                  context: context,
                  content: rulesTextLines(
                    nardyRuleLines(
                      gameMode: nardyModeLong,
                      turnTimeSec: 600,
                      stakeBronze: 2,
                      l10n: context.l10n,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Правила игры'), findsOneWidget);
    expect(find.text('Нарды — правила'), findsNothing);
    expect(find.textContaining('Игроки: 2.'), findsOneWidget);
  });

  test('автоподтверждение скрывает Готово и само завершает ход', () {
    expect(
      nardyShouldShowEndTurn(
        autoConfirm: false,
        isMyTurn: true,
        isOver: false,
        needsRoll: false,
        hasLegalMoves: false,
      ),
      isTrue,
    );
    expect(
      nardyShouldShowEndTurn(
        autoConfirm: true,
        isMyTurn: true,
        isOver: false,
        needsRoll: false,
        hasLegalMoves: false,
      ),
      isFalse,
    );
    expect(
      nardyShouldAutoEndTurn(
        autoConfirm: true,
        isMyTurn: true,
        isOver: false,
        needsRoll: false,
        hasLegalMoves: false,
      ),
      isTrue,
    );
    expect(
      nardyShouldAutoEndTurn(
        autoConfirm: true,
        isMyTurn: true,
        isOver: false,
        needsRoll: false,
        hasLegalMoves: true,
      ),
      isFalse,
    );
    expect(
      nardyShouldAutoEndTurn(
        autoConfirm: false,
        isMyTurn: true,
        isOver: false,
        needsRoll: false,
        hasLegalMoves: false,
      ),
      isFalse,
    );
    expect(
      nardyCanEndTurn(
        isMyTurn: false,
        isOver: false,
        needsRoll: false,
        hasLegalMoves: false,
      ),
      isFalse,
    );
    expect(
      nardyShouldShowAutoConfirm(isMyTurn: true, isOver: false),
      isTrue,
    );
    expect(
      nardyShouldShowAutoConfirm(isMyTurn: false, isOver: false),
      isFalse,
    );
    expect(
      nardyShouldShowAutoConfirm(isMyTurn: true, isOver: true),
      isFalse,
    );
  });
}
