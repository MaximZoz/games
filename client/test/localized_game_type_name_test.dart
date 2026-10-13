import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('приглашение в Уно не подписывается как крестики-нолики', () {
    final t = l10n();
    expect(localizedGameTypeName('uno', t), 'Уно');
    expect(localizedGameTypeName('domino', t), 'Домино');
    expect(localizedGameTypeName('uno', t), isNot(t.gamesTicTacToe));
    expect(localizedGameTypeName('tictactoe', t), t.gamesTicTacToe);
    expect(localizedGameTypeName('durak', t), t.gamesDurak);
    expect(localizedGameTypeName('poker', t), t.gamesPoker);
    expect(localizedGameTypeName('battleship', t), t.gamesBattleship);
    expect(localizedGameTypeName('nardy', t), t.gamesNardy);
    expect(localizedGameTypeName('nardy', t), isNot(t.gamesTicTacToe));
    expect(localizedGameTypeName('checkers', t), t.gamesCheckers);
    expect(localizeChatTitle('Шашки', t), t.gamesCheckers);
    expect(localizedGameTypeName('chess', t), t.gamesChess);
    expect(localizeChatTitle('Шахматы', t), t.gamesChess);
    expect(localizeChatTitle('Chess', t), t.gamesChess);
    expect(localizedGameTypeName('nardy', t), isNot('nardy'));
    expect(localizedGameTypeName('unknown-game', t), 'unknown-game');
    expect(localizedGameTypeName('unknown-game', t), isNot(t.gamesTicTacToe));
  });

  test('заголовок группового чата Уно локализуется', () {
    final t = l10n();
    expect(localizeChatTitle('Уно', t), t.gamesUno);
    expect(localizeChatTitle('Uno', t), t.gamesUno);
    expect(localizeChatTitle('Козёл', t), t.gamesDomino);
    expect(localizeChatTitle('Домино', t), t.gamesDomino);
    expect(localizeChatTitle('Goat', t), t.gamesDomino);
    expect(localizeChatTitle('Domino', t), t.gamesDomino);
    expect(localizeChatTitle('Нарды', t), t.gamesNardy);
    expect(localizeChatTitle('Backgammon', t), t.gamesNardy);
  });

  test('режим классика не показывается у игр без вариантов', () {
    final t = l10n();
    expect(localizedGameModeLabel(gameType: 'uno', variant: 'classic', l10n: t),
        isEmpty);
    expect(
        localizedGameModeLabel(
            gameType: 'domino', variant: 'kozel', gameMode: 'kozel', l10n: t),
        t.gamesDominoModeKozel);
    expect(
        localizedGameModeLabel(
            gameType: 'domino', variant: 'kozel', gameMode: 'classic', l10n: t),
        t.gamesDominoModeClassic);
    expect(
        localizedGameModeLabel(
            gameType: 'domino', gameMode: 'sea', l10n: t),
        t.gamesDominoModeSea);
    expect(
        localizedGameModeLabel(
            gameType: 'poker', variant: 'classic', gameMode: 'holdem', l10n: t),
        isEmpty);
    expect(
        localizedGameModeLabel(
            gameType: 'chess', variant: 'classic', l10n: t),
        t.gamesChessModeClassic);
    expect(
        localizedGameModeLabel(
            gameType: 'chess', gameMode: 'rapid', l10n: t),
        t.gamesChessModeRapid);
    expect(
        localizedGameModeLabel(
            gameType: 'chess', gameMode: 'blitz', l10n: t),
        t.gamesChessModeBlitz);
    expect(
        localizedGameModeLabel(
            gameType: 'chess', gameMode: 'bullet', l10n: t),
        t.gamesChessModeBullet);
    expect(
        localizedGameModeLabel(
            gameType: 'chess', gameMode: 'chess960', l10n: t),
        t.gamesChessModeClassic);
    expect(
        localizedGameModeLabel(
            gameType: 'go', variant: 'classic', l10n: t),
        isEmpty);
    expect(
        localizedGameModeLabel(
            gameType: 'tictactoe', variant: 'classic', l10n: t),
        t.gamesVariantClassic);
    expect(
        localizedGameModeLabel(
            gameType: 'nardy', gameMode: nardyModeLong, l10n: t),
        t.gamesNardyModeLong);
    expect(
        localizedGameModeLabel(
            gameType: 'nardy', gameMode: nardyModeShort, l10n: t),
        t.gamesNardyModeShort);
    expect(
        localizedGameModeLabel(
            gameType: 'nardy', variant: 'classic', l10n: t),
        isNot(t.gamesVariantClassic));
    expect(
        localizedGameModeLabel(
            gameType: 'checkers', gameMode: 'giveaway', l10n: t),
        t.gamesCheckersModeGiveaway);
    expect(
        localizedGameModeLabel(
            gameType: 'checkers', gameMode: 'russian', l10n: t),
        t.gamesCheckersModeRussian);
  });

  test('лобби уно и нард не рисуют классику из variant', () {
    final t = l10n();
    final uno = LobbyItem.fromJson({
      'id': 'u1',
      'creator_id': 'c',
      'status': 'waiting_matchmake',
      'game_type': 'uno',
      'variant': 'classic',
      'game_mode': 'classic',
    });
    expect(uno.modeLabel(t), isEmpty);
    final domino = LobbyItem.fromJson({
      'id': 'd1',
      'creator_id': 'c',
      'status': 'waiting_matchmake',
      'game_type': 'domino',
      'variant': 'kozel',
      'game_mode': 'kozel',
    });
    expect(domino.isDomino, isTrue);
    expect(domino.modeLabel(t), t.gamesDominoModeKozel);

    final nardy = LobbyItem.fromJson({
      'id': 'n1',
      'creator_id': 'c',
      'status': 'waiting_matchmake',
      'game_type': 'nardy',
      'variant': '',
      'game_mode': nardyModeLong,
    });
    expect(nardy.modeLabel(t), t.gamesNardyModeLong);
    expect(nardy.modeLabel(t), isNot(t.gamesVariantClassic));
  });

  test('реестр и localizedGameTypeName совпадают для всех игр', () {
    final t = l10n();
    expect(gameRegistry.all, isNotEmpty);
    for (final game in gameRegistry.all) {
      expect(game.localizedName(t), isNot(game.id));
      expect(localizedGameTypeName(game.id, t), game.localizedName(t));
    }
  });

  test('статистика нард берёт имя карточки на английском', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(localizedGameTypeName('nardy', en), en.gamesNardy);
    expect(localizedGameTypeName('nardy', en), 'Backgammon');
    expect(localizedGameTypeName('nardy', en), isNot('nardy'));
  });
}
