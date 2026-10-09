import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/rematch_match.dart';

GameInvite _invite({
  String gameType = 'chess',
  String gameMode = 'blitz',
  int stake = 2,
  String variant = 'blitz',
  int deckSize = 36,
}) {
  return GameInvite(
    lobbyId: 'l',
    creatorId: 'opp',
    creatorName: 'Opp',
    gameType: gameType,
    stakeBronze: stake,
    durakMode: gameMode,
    variant: variant,
    deckSize: deckSize,
  );
}

void main() {
  const peers = ['opp'];
  const chess = RematchTable(
    gameType: 'chess',
    stakeBronze: 2,
    gameMode: 'blitz',
  );

  test('тот же режим и ставка — реванш', () {
    expect(inviteIsRematch(_invite(), chess, peers), isTrue);
  });

  test('другая игра, режим или ставка — не реванш', () {
    expect(
      inviteIsRematch(_invite(gameType: 'checkers', gameMode: 'russian'), chess, peers),
      isFalse,
    );
    expect(
      inviteIsRematch(_invite(gameMode: 'bullet', variant: 'bullet'), chess, peers),
      isFalse,
    );
    expect(inviteIsRematch(_invite(stake: 10), chess, peers), isFalse);
    expect(inviteIsRematch(_invite(), chess, const ['other']), isFalse);
  });

  test('крестики сравнивают вариант, дурак — колоду', () {
    const ttt = RematchTable(
      gameType: 'tictactoe',
      stakeBronze: 2,
      variant: 'gomoku',
    );
    expect(
      inviteIsRematch(
        _invite(gameType: 'tictactoe', variant: 'gomoku', gameMode: 'podkidnoi'),
        ttt,
        peers,
      ),
      isTrue,
    );
    expect(
      inviteIsRematch(
        _invite(gameType: 'tictactoe', variant: 'classic', gameMode: 'podkidnoi'),
        ttt,
        peers,
      ),
      isFalse,
    );
    const durak = RematchTable(
      gameType: 'durak',
      stakeBronze: 2,
      gameMode: 'podkidnoi',
      deckSize: 36,
    );
    expect(
      inviteIsRematch(
        _invite(gameType: 'durak', gameMode: 'podkidnoi'),
        durak,
        peers,
      ),
      isTrue,
    );
    expect(
      inviteIsRematch(_invite(gameType: 'durak', deckSize: 52), durak, peers),
      isFalse,
    );
  });
}
