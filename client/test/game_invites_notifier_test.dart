import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/nardy/nardy_rules.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

GameInvite invite({
  required String lobbyId,
  required String creatorId,
  String name = 'A',
}) {
  return GameInvite(
    lobbyId: lobbyId,
    creatorId: creatorId,
    creatorName: name,
    gameType: 'tictactoe',
  );
}

void main() {
  setUp(() {
    LocaleService.setLocale(const Locale('ru'));
  });

  AppLocalizations l10n() => lookupAppLocalizations(const Locale('ru'));

  test('GameInvitesNotifier add dedupes by lobbyId', () {
    final n = GameInvitesNotifier();
    n.add(invite(lobbyId: 'L1', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L1', creatorId: 'c1', name: 'A2'));
    expect(n.state.length, 1);
    n.add(invite(lobbyId: 'L2', creatorId: 'c2', name: 'B'));
    expect(n.state.length, 2);
  });

  test('remove / removeByCreatorId / clear', () {
    final n = GameInvitesNotifier();
    n.add(invite(lobbyId: 'L1', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L2', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L3', creatorId: 'c2', name: 'B'));
    n.remove('L1');
    expect(n.state.map((e) => e.lobbyId), ['L2', 'L3']);
    n.removeByCreatorId('c1');
    expect(n.state.map((e) => e.lobbyId), ['L3']);
    n.clear();
    expect(n.state, isEmpty);
  });

  test('resolveJoined removes lobby and other invites from same creator', () {
    final n = GameInvitesNotifier();
    n.add(invite(lobbyId: 'L1', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L2', creatorId: 'c1'));
    n.add(invite(lobbyId: 'L3', creatorId: 'c2', name: 'B'));
    n.resolveJoined('L1');
    expect(n.state.map((e) => e.lobbyId), ['L3']);
  });

  test('resolveJoined removes only matching lobby when creator unknown', () {
    final n = GameInvitesNotifier();
    n.add(invite(lobbyId: 'L2', creatorId: 'c2'));
    n.resolveJoined('L1');
    expect(n.state.map((e) => e.lobbyId), ['L2']);
  });

  test('sameVisibleCard / lists: одинаковые инвайты не считаем новыми', () {
    final a = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Ann');
    final b = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Ann');
    final c = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Bob');
    expect(a.sameVisibleCard(b), isTrue);
    expect(a.sameVisibleCard(c), isFalse);
    expect(gameInviteListsVisuallySame([a], [b]), isTrue);
    expect(gameInviteListsVisuallySame([a], [c]), isFalse);
    expect(gameInviteListsVisuallySame([a], []), isFalse);
  });

  test('nardy invite shows short/long mode instead of classic', () {
    final short = GameInvite(
      lobbyId: 'N1',
      creatorId: 'c1',
      creatorName: 'Ann',
      gameType: 'nardy',
      durakMode: nardyModeShort,
    );
    final long = GameInvite(
      lobbyId: 'N2',
      creatorId: 'c2',
      creatorName: 'Bob',
      gameType: 'nardy',
      durakMode: nardyModeLong,
    );

    expect(short.isNardy, isTrue);
    expect(short.modeLabel, l10n().gamesNardyModeShort);
    expect(long.modeLabel, l10n().gamesNardyModeLong);
    expect(short.modeLabel, isNot(l10n().gamesVariantClassic));
    expect(long.modeLabel, isNot(l10n().gamesVariantClassic));
  });

  test('uno invite has no classic mode chip', () {
    final uno = GameInvite(
      lobbyId: 'U1',
      creatorId: 'c1',
      creatorName: 'Ann',
      gameType: 'uno',
      variant: 'classic',
    );
    expect(uno.modeLabel, isEmpty);
    expect(uno.modeLabel, isNot(l10n().gamesVariantClassic));
  });

  test('hydrate не стирает свежий WS-инвайт, если GET пустой', () {
    final ws = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Ann');
    final now = DateTime(2026, 9, 3, 14, 0, 0);
    final merged = mergeHydratedGameInvites(
      snapshot: [ws],
      current: [ws],
      fromServer: const [],
      localSeenAt: {'L1': now.subtract(const Duration(seconds: 2))},
      now: now,
    );
    expect(merged.map((e) => e.lobbyId), ['L1']);
  });

  test('hydrate оставляет инвайт, пришедший во время GET', () {
    final before = invite(lobbyId: 'L1', creatorId: 'c1');
    final during = invite(lobbyId: 'L2', creatorId: 'c2', name: 'B');
    final now = DateTime(2026, 9, 3, 14, 0, 0);
    final merged = mergeHydratedGameInvites(
      snapshot: [before],
      current: [before, during],
      fromServer: const [],
      localSeenAt: {
        'L1': now.subtract(const Duration(minutes: 2)),
        'L2': now,
      },
      now: now,
    );
    expect(merged.map((e) => e.lobbyId), ['L2']);
  });

  test('hydrate после grace убирает карточку, которой нет на сервере', () {
    final old = invite(lobbyId: 'L1', creatorId: 'c1');
    final now = DateTime(2026, 9, 3, 14, 0, 0);
    final merged = mergeHydratedGameInvites(
      snapshot: [old],
      current: [old],
      fromServer: const [],
      localSeenAt: {'L1': now.subtract(const Duration(minutes: 2))},
      now: now,
    );
    expect(merged, isEmpty);
  });

  test('карточка со ссылки не пропадает, если сервер её не знает', () {
    final link = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Zoz');
    final now = DateTime(2026, 9, 3, 14, 0, 0);
    final merged = mergeHydratedGameInvites(
      snapshot: [link],
      current: [link],
      fromServer: const [],
      localSeenAt: {'L1': now.subtract(const Duration(minutes: 2))},
      now: now,
      heldIds: {'L1'},
    );
    expect(merged.map((e) => e.lobbyId), ['L1']);
  });

  test('hold и resolveJoined снимают карточку', () {
    final n = GameInvitesNotifier();
    n.hold(invite(lobbyId: 'L1', creatorId: 'c1', name: 'Zoz'));
    expect(n.state.map((e) => e.lobbyId), ['L1']);
    n.resolveJoined('L1');
    expect(n.state, isEmpty);
  });

  test('отказ не даёт ссылке вернуть стол, новый зов — даёт', () {
    final n = GameInvitesNotifier();
    final card = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Zoz');
    n.hold(card);
    n.dismiss('L1');
    n.hold(card);
    expect(n.state, isEmpty);
    n.add(card);
    expect(n.state.map((e) => e.lobbyId), ['L1']);
  });

  test('опрос после отказа не поднимает карточку из устаревшего ответа', () {
    final card = invite(lobbyId: 'L1', creatorId: 'c1', name: 'Zoz');
    final now = DateTime(2026, 9, 3, 14, 0, 0);
    final merged = mergeHydratedGameInvites(
      snapshot: [card],
      current: [card],
      fromServer: [card],
      localSeenAt: {'L1': now},
      now: now,
      heldIds: {'L1'},
      dismissedIds: {'L1'},
    );
    expect(merged, isEmpty);
  });
}
