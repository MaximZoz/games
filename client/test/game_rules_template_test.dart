import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/battleship/battleship_rules.dart';
import 'package:multigames_client/games/checkers/checkers_engine.dart';
import 'package:multigames_client/games/checkers/checkers_rules.dart';
import 'package:multigames_client/games/chess/chess_rules.dart';
import 'package:multigames_client/games/domino/domino_mode.dart';
import 'package:multigames_client/games/domino/domino_rules.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/game_rules_template.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/games/poker/poker_rules.dart';
import 'package:multigames_client/games/uno/uno_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  final t = lookupAppLocalizations(const Locale('ru'));

  /// Правила каждой игры: онлайн со ставкой и офлайн с ботом.
  Map<String, List<String>> allRules({required bool offline}) {
    final stake = offline ? 0 : 200;
    final time = offline ? 0 : 60;
    return {
      'tictactoe': buildTictactoeRulesText(
        gridSize: 3,
        turnTimeSec: time,
        swapRule: true,
        firstMoveRestriction: true,
        stakeBronze: stake,
        includeTurnTime: !offline,
        offlineBot: offline,
      ).split('\n\n'),
      'durak': durakRuleLines(
        mode: 'perevodnoi',
        players: 2,
        deckSize: 36,
        turnTimeSec: time,
        stakeBronze: stake,
        offlineBot: offline,
        l10n: t,
      ),
      'battleship': battleshipRuleLines(
        turnTimeSec: time,
        stakeBronze: stake,
        offlineBot: offline,
        l10n: t,
      ),
      'poker': pokerRuleLines(
        players: 4,
        turnTimeSec: time,
        stakeBronze: stake,
        offlineBot: offline,
        l10n: t,
      ),
      'uno': unoRuleLines(
        players: 3,
        turnTimeSec: time,
        stakeBronze: stake,
        offlineBot: offline,
        l10n: t,
      ),
      'domino': dominoRuleLines(
        players: 2,
        turnTimeSec: time,
        stakeBronze: stake,
        offlineBot: offline,
        mode: dominoModeSea,
        l10n: t,
      ),
      'nardy': nardyRuleLines(
        gameMode: nardyModeLong,
        turnTimeSec: time,
        stakeBronze: stake,
        offline: offline,
        l10n: t,
      ),
      'checkers': checkersRuleLines(
        gameMode: CheckersEngine.modeCorners,
        turnTimeSec: time,
        stakeBronze: stake,
        offline: offline,
        l10n: t,
      ),
      'chess': chessRuleLines(
        gameMode: chessModeBlitz,
        turnTimeSec: time,
        stakeBronze: stake,
        offline: offline,
        l10n: t,
      ),
    };
  }

  test('шаблон: ставка → игроки → режим → время на ход → правила', () {
    final lines = gameRuleLines(
      stakeBronze: 200,
      players: 3,
      mode: 'Свой',
      turnTimeSec: 20,
      rules: const ['А', 'Б'],
      l10n: t,
    );
    expect(lines, [
      rulesStakeLine(200, t),
      'Игроки: 3.',
      'Режим: Свой.',
      t.rulesTurnTime(formatTurnTime(20)),
      'А',
      'Б',
    ]);
  });

  test('онлайн: у всех игр одна шапка в одном порядке', () {
    final rules = allRules(offline: false);
    expect(rules.length, 9);
    rules.forEach((game, lines) {
      expect(lines.length, greaterThan(kGameRulesHeaderLines), reason: game);
      expect(lines[0], startsWith('Ставка: '), reason: game);
      expect(lines[1], startsWith('Игроки: '), reason: game);
      expect(lines[2], startsWith('Режим: '), reason: game);
      expect(lines[3], startsWith('Время на ход: '), reason: game);
      // Шапка не повторяется в правилах.
      for (final line in lines.skip(kGameRulesHeaderLines)) {
        expect(line, isNot(startsWith('Ставка: ')), reason: game);
        expect(line, isNot(startsWith('Игроки: ')), reason: game);
        expect(line, isNot(startsWith('Режим: ')), reason: game);
        expect(line, isNot(startsWith('Время на ход: ')), reason: game);
      }
    });
  });

  test('офлайн: шапка та же — без ставки и без лимита', () {
    allRules(offline: true).forEach((game, lines) {
      expect(lines[0], 'Без ставки.', reason: game);
      expect(lines[1], startsWith('Игроки: '), reason: game);
      expect(lines[2], startsWith('Режим: '), reason: game);
      expect(lines[3], 'Без ограничения по времени на ход.', reason: game);
    });
  });

  test('число игроков и режим берутся из настроек партии', () {
    final rules = allRules(offline: false);
    expect(rules['poker']![1], 'Игроки: 4.');
    expect(rules['uno']![1], 'Игроки: 3.');
    expect(rules['durak']![2], 'Режим: Переводной.');
    expect(rules['poker']![2], 'Режим: Техасский холдем.');
    expect(rules['domino']![2], 'Режим: Морской.');
    expect(rules['chess']![2], 'Режим: Блиц.');
  });

  test('всё сверх шапки уходит в правила', () {
    final rules = allRules(offline: false);
    expect(rules['durak']![4], 'Колода: 36 карт.');
    expect(rules['chess']![4], t.rulesChessClockBlitz);
    expect(rules['battleship']![4], startsWith('Время на расстановку: '));
  });
}
