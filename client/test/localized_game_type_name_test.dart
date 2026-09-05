import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('приглашение в Уно не подписывается как крестики-нолики', () {
    final t = l10n();
    expect(localizedGameTypeName('uno', t), 'Уно');
    expect(localizedGameTypeName('uno', t), isNot(t.gamesTicTacToe));
    expect(localizedGameTypeName('tictactoe', t), t.gamesTicTacToe);
    expect(localizedGameTypeName('durak', t), t.gamesDurak);
    expect(localizedGameTypeName('poker', t), t.gamesPoker);
    expect(localizedGameTypeName('battleship', t), t.gamesBattleship);
    expect(localizedGameTypeName('nardy', t), t.gamesNardy);
    expect(localizedGameTypeName('nardy', t), isNot(t.gamesTicTacToe));
    expect(localizedGameTypeName('checkers', t), t.gamesCheckers);
    expect(localizeChatTitle('Шашки', t), t.gamesCheckers);
  });

  test('заголовок группового чата Уно локализуется', () {
    final t = l10n();
    expect(localizeChatTitle('Уно', t), t.gamesUno);
    expect(localizeChatTitle('Uno', t), t.gamesUno);
  });
}
