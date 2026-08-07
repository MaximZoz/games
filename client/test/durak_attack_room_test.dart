import 'package:flutter_test/flutter_test.dart';

/// Зеркало серверного MaxAttacksThisRound / клиентского _attackRoom.
int attackRoom({
  required int defenderHand,
  required int beaten,
  required int tableLen,
  int pending = 0,
  int maxAttacks = 6,
  bool firstRound = false,
}) {
  var maxPairs = beaten + defenderHand;
  if (maxPairs < 1) maxPairs = 1;
  if (maxAttacks < maxPairs) maxPairs = maxAttacks;
  if (firstRound && maxPairs > 5) maxPairs = 5;
  final room = maxPairs - tableLen - pending;
  return room < 0 ? 0 : room;
}

void main() {
  test('5 in hand, 2 undefended → throw-in room 3', () {
    expect(
      attackRoom(defenderHand: 5, beaten: 0, tableLen: 2),
      3,
    );
  });

  test('3 beaten + hand 3 → room 3 (up to MaxAttacks)', () {
    expect(
      attackRoom(defenderHand: 3, beaten: 3, tableLen: 3),
      3,
    );
  });

  test('pending attacks reduce room', () {
    expect(
      attackRoom(defenderHand: 5, beaten: 0, tableLen: 2, pending: 1),
      2,
    );
  });

  test('never exceeds MaxAttacks', () {
    expect(
      attackRoom(defenderHand: 10, beaten: 0, tableLen: 0, maxAttacks: 6),
      6,
    );
  });

  test('first round caps at 5 including first attack', () {
    expect(
      attackRoom(defenderHand: 6, beaten: 0, tableLen: 0, firstRound: true),
      5,
    );
    expect(
      attackRoom(defenderHand: 6, beaten: 0, tableLen: 5, firstRound: true),
      0,
    );
  });
}
