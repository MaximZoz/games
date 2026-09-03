import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';

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
}
