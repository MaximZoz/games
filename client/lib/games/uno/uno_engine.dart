import 'dart:math';

import 'package:multigames_client/games/uno/uno_card.dart';

abstract final class UnoStatus {
  static const active = 'active';
  static const awaitingColor = 'awaiting_color';
  static const awaitingWd4Challenge = 'awaiting_wd4_challenge';
  static const awaitingDrawnPlay = 'awaiting_drawn_play';
  static const betweenRounds = 'between_rounds';
  static const over = 'over';
}

abstract final class UnoActionType {
  static const play = 'play';
  static const draw = 'draw';
  static const keep = 'keep';
  static const callUno = 'call_uno';
  static const challengeUno = 'challenge_uno';
  static const challengeWd4 = 'challenge_wd4';
  static const chooseColor = 'choose_color';
  static const forfeit = 'forfeit';
  static const nextRound = 'next_round';
}

class UnoAction {
  const UnoAction(
    this.type, {
    this.cardId,
    this.color,
    this.targetUserId,
    this.actorUserId,
  });

  final String type;
  final String? cardId;
  final UnoColor? color;
  final String? targetUserId;
  final String? actorUserId;
}

class UnoPlayer {
  UnoPlayer({
    required this.userId,
    required this.seat,
    List<UnoCard>? hand,
    this.score = 0,
    this.saidUno = false,
    this.forfeited = false,
  }) : hand = hand ?? <UnoCard>[];

  final String userId;
  final int seat;
  final List<UnoCard> hand;
  int score;
  bool saidUno;
  bool forfeited;
}

/// Local UNO rules engine. Its state transitions mirror the server engine.
class UnoEngine {
  UnoEngine._({
    required this.players,
    required this.seed,
    this.targetScore = defaultTargetScore,
  });

  static const int defaultTargetScore = 100;
  static const int multiplayerTargetScore = 300;
  static const int cardsPerHand = 7;

  static int targetScoreForPlayerCount(int playerCount) =>
      playerCount >= 3 ? multiplayerTargetScore : defaultTargetScore;

  final List<UnoPlayer> players;
  final int seed;
  int targetScore;

  List<UnoCard> drawPile = [];
  List<UnoCard> discardPile = [];
  UnoColor currentColor = UnoColor.wild;
  int direction = 1;
  int currentIndex = 0;
  String status = UnoStatus.active;
  int pendingDraw = 0;
  String? drawnCardId;
  String? lastPlayedBy;
  int wild4PlayerIndex = -1;
  int roundNumber = 1;
  final List<String> winnerUserIds = [];
  final List<String> eliminatedOrder = [];

  int dealerIndex = 0;
  int colorChooserIndex = -1;
  int unoVulnerableIndex = -1;
  int pendingRoundWinnerIndex = -1;
  String lastRoundWinnerUserId = '';
  int lastRoundPoints = 0;
  int lastRoundNumber = 0;
  bool wild4WasLegal = false;
  int shuffleCount = 0;
  int eventSeq = 0;
  String lastEventType = '';
  String lastEventActor = '';
  String lastDrawUserId = '';
  int lastDrawCount = 0;
  UnoCard? lastEventCard;
  UnoCard? wild4ProofCard;

  bool get isOver => status == UnoStatus.over;
  UnoCard? get topDiscard => discardPile.isEmpty ? null : discardPile.last;

  factory UnoEngine.newGame({
    required List<String> playerIds,
    int? seed,
    int? targetScore,
  }) {
    if (playerIds.length < 2 || playerIds.length > 10) {
      throw ArgumentError.value(playerIds.length, 'playerIds', 'need 2..10');
    }
    if (playerIds.any((id) => id.trim().isEmpty) ||
        playerIds.toSet().length != playerIds.length) {
      throw ArgumentError.value(playerIds, 'playerIds', 'must be unique');
    }
    final resolved = targetScore == null || targetScore <= 0
        ? targetScoreForPlayerCount(playerIds.length)
        : targetScore;
    final engine = UnoEngine._(
      players: [
        for (var i = 0; i < playerIds.length; i++)
          UnoPlayer(userId: playerIds[i], seat: i),
      ],
      seed: seed ?? DateTime.now().microsecondsSinceEpoch,
      targetScore: resolved,
    );
    engine._startRound();
    return engine;
  }

  /// Test/support constructor for deterministic controlled positions.
  factory UnoEngine.controlled({
    required List<UnoPlayer> players,
    required List<UnoCard> drawPile,
    required UnoCard topDiscard,
    UnoColor? currentColor,
    int currentIndex = 0,
    int direction = 1,
    int targetScore = defaultTargetScore,
  }) {
    final engine = UnoEngine._(
      players: players,
      seed: 1,
      targetScore: targetScore,
    );
    engine
      ..drawPile = List.of(drawPile)
      ..discardPile = [topDiscard]
      ..currentColor = currentColor ?? topDiscard.color
      ..currentIndex = currentIndex
      ..direction = direction
      ..status = UnoStatus.active;
    return engine;
  }

  List<String> legalActions(int playerIndex) {
    if (isOver || playerIndex < 0 || playerIndex >= players.length) {
      return const [];
    }
    if (status == UnoStatus.betweenRounds) {
      return players[playerIndex].forfeited
          ? const []
          : const [UnoActionType.nextRound];
    }
    final actions = <String>[];
    if (unoVulnerableIndex >= 0 &&
        unoVulnerableIndex != playerIndex &&
        currentIndex == playerIndex) {
      actions.add(UnoActionType.challengeUno);
    }
    if (unoVulnerableIndex == playerIndex &&
        players[playerIndex].hand.length == 1) {
      actions.add(UnoActionType.callUno);
    }
    if (status == UnoStatus.awaitingColor && colorChooserIndex == playerIndex) {
      actions.add(UnoActionType.chooseColor);
      return actions;
    }
    if (status == UnoStatus.awaitingWd4Challenge &&
        currentIndex == playerIndex) {
      actions
        ..add(UnoActionType.challengeWd4)
        ..add(UnoActionType.draw);
      return actions;
    }
    if (status == UnoStatus.awaitingDrawnPlay && currentIndex == playerIndex) {
      actions
        ..add(UnoActionType.play)
        ..add(UnoActionType.keep);
      return actions;
    }
    if (status != UnoStatus.active || currentIndex != playerIndex) {
      return actions;
    }
    if (hasLegalPlay(playerIndex)) {
      actions.add(UnoActionType.play);
    } else {
      actions.add(UnoActionType.draw);
    }
    return actions;
  }

  bool canPlay(int playerIndex, UnoCard card) {
    if (playerIndex < 0 ||
        playerIndex >= players.length ||
        topDiscard == null ||
        !card.matches(topDiscard!, currentColor)) {
      return false;
    }
    if (status == UnoStatus.awaitingDrawnPlay && card.id != drawnCardId) {
      return false;
    }
    return true;
  }

  bool hasLegalPlay(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) return false;
    return players[playerIndex].hand.any((card) => canPlay(playerIndex, card));
  }

  void apply(UnoAction action) {
    if (isOver) throw StateError('match is over');
    if (action.type == UnoActionType.nextRound) {
      _applyNextRound();
      return;
    }
    if (action.type == UnoActionType.forfeit) {
      _applyForfeit(action.actorUserId);
      return;
    }
    if (status == UnoStatus.betweenRounds) {
      throw StateError('wait for the next round');
    }
    lastDrawUserId = '';
    lastDrawCount = 0;
    lastEventCard = null;
    switch (action.type) {
      case UnoActionType.play:
        _applyPlay(action);
      case UnoActionType.draw:
        _applyDraw();
      case UnoActionType.keep:
        _applyKeep();
      case UnoActionType.callUno:
        _applyCallUno(action.actorUserId);
      case UnoActionType.challengeUno:
        _applyChallengeUno(action.actorUserId, action.targetUserId);
      case UnoActionType.challengeWd4:
        _applyChallengeWd4();
      case UnoActionType.chooseColor:
        _applyChooseColor(action.color);
      default:
        throw StateError('unknown UNO action ${action.type}');
    }
  }

  void _startRound() {
    drawPile = buildUnoDeck(seed: seed + (roundNumber - 1) * 104729);
    discardPile = [];
    direction = 1;
    status = UnoStatus.active;
    pendingDraw = 0;
    drawnCardId = null;
    lastPlayedBy = null;
    wild4PlayerIndex = -1;
    colorChooserIndex = -1;
    unoVulnerableIndex = -1;
    pendingRoundWinnerIndex = -1;
    wild4WasLegal = false;
    shuffleCount = 0;
    wild4ProofCard = null;
    winnerUserIds.clear();
    _noteEvent('deal', '', null);
    for (final player in players) {
      player
        ..hand.clear()
        ..saidUno = false;
    }
    for (var dealt = 0; dealt < cardsPerHand; dealt++) {
      for (final player in players) {
        if (!player.forfeited) player.hand.add(_drawOne()!);
      }
    }
    final topIndex = drawPile.lastIndexWhere((candidate) => !candidate.isWild);
    if (topIndex < 0) throw StateError('no colored opening card');
    final top = drawPile.removeAt(topIndex);
    discardPile.add(top);
    currentColor = top.color;

    final first = _nextActive(dealerIndex);
    currentIndex = first;
    switch (top.kind) {
      case UnoCardKind.skip:
        currentIndex = _nextActive(first);
      case UnoCardKind.reverse:
        if (_activePlayerCount == 2) {
          currentIndex = _nextActive(first);
        } else {
          direction = -1;
          currentIndex = _nextActive(dealerIndex);
        }
      case UnoCardKind.drawTwo:
        _drawCards(first, 2);
        currentIndex = _nextActive(first);
      case UnoCardKind.number || UnoCardKind.wild || UnoCardKind.wildDrawFour:
        break;
    }
  }

  void _applyPlay(UnoAction action) {
    if (status != UnoStatus.active && status != UnoStatus.awaitingDrawnPlay) {
      throw StateError('cannot play while status is $status');
    }
    final playerIndex = currentIndex;
    if (playerIndex < 0 ||
        playerIndex >= players.length ||
        players[playerIndex].forfeited) {
      throw StateError('no active current player');
    }
    final cardIndex =
        players[playerIndex].hand.indexWhere((c) => c.id == action.cardId);
    if (cardIndex < 0) throw StateError('card is not in current hand');
    final card = players[playerIndex].hand[cardIndex];
    if (status == UnoStatus.awaitingDrawnPlay && card.id != drawnCardId) {
      throw StateError('only the drawn card may be played');
    }
    if (topDiscard == null || !card.matches(topDiscard!, currentColor)) {
      throw StateError('card does not match');
    }
    final chosenColor = action.color;
    if (chosenColor != null && !chosenColor.isPlayableColor) {
      throw StateError('invalid chosen color');
    }

    var wild4Legal = true;
    wild4ProofCard = null;
    if (card.kind == UnoCardKind.wildDrawFour) {
      for (final entry in players[playerIndex].hand.asMap().entries) {
        if (entry.key != cardIndex &&
            !entry.value.isWild &&
            entry.value.color == currentColor) {
          wild4Legal = false;
          wild4ProofCard = entry.value;
          break;
        }
      }
    }

    _expireUnoWindow();
    final player = players[playerIndex];
    player.hand.removeAt(cardIndex);
    player.saidUno = false;
    discardPile.add(card);
    drawnCardId = null;
    lastPlayedBy = player.userId;
    _noteEvent('play', player.userId, card);
    pendingRoundWinnerIndex = -1;
    if (player.hand.length == 1) unoVulnerableIndex = playerIndex;
    if (player.hand.isEmpty) {
      unoVulnerableIndex = -1;
      pendingRoundWinnerIndex = playerIndex;
    }

    switch (card.kind) {
      case UnoCardKind.number:
        currentColor = card.color;
        currentIndex = _nextActive(playerIndex);
        status = UnoStatus.active;
      case UnoCardKind.skip:
        currentColor = card.color;
        currentIndex = _nextActive(_nextActive(playerIndex));
        status = UnoStatus.active;
      case UnoCardKind.reverse:
        currentColor = card.color;
        if (_activePlayerCount == 2) {
          currentIndex = _nextActive(_nextActive(playerIndex));
        } else {
          direction *= -1;
          currentIndex = _nextActive(playerIndex);
        }
        status = UnoStatus.active;
      case UnoCardKind.drawTwo:
        currentColor = card.color;
        final target = _nextActive(playerIndex);
        pendingDraw = 2;
        _drawCards(target, pendingDraw);
        pendingDraw = 0;
        currentIndex = _nextActive(target);
        status = UnoStatus.active;
      case UnoCardKind.wild:
        if (chosenColor == null) {
          colorChooserIndex = playerIndex;
          status = UnoStatus.awaitingColor;
          currentIndex = playerIndex;
          return;
        }
        currentColor = chosenColor;
        currentIndex = _nextActive(playerIndex);
        status = UnoStatus.active;
      case UnoCardKind.wildDrawFour:
        wild4PlayerIndex = playerIndex;
        wild4WasLegal = wild4Legal;
        pendingDraw = 4;
        if (chosenColor == null) {
          colorChooserIndex = playerIndex;
          status = UnoStatus.awaitingColor;
          currentIndex = playerIndex;
          return;
        }
        currentColor = chosenColor;
        currentIndex = _nextActive(playerIndex);
        status = UnoStatus.awaitingWd4Challenge;
    }
    _finishPendingRound();
  }

  void _applyDraw() {
    if (status == UnoStatus.awaitingWd4Challenge) {
      _expireUnoWindow();
      final challenger = currentIndex;
      final actor = players[challenger].userId;
      _noteEvent('draw', actor, null);
      _drawCards(challenger, pendingDraw);
      pendingDraw = 0;
      wild4PlayerIndex = -1;
      wild4WasLegal = false;
      wild4ProofCard = null;
      currentIndex = _nextActive(challenger);
      status = UnoStatus.active;
      _finishPendingRound();
      return;
    }
    if (status != UnoStatus.active) {
      throw StateError('cannot draw while status is $status');
    }
    if (hasLegalPlay(currentIndex)) {
      throw StateError('current player has a legal card');
    }
    _expireUnoWindow();
    final actor = players[currentIndex].userId;
    _noteEvent('draw', actor, null);
    final card = _drawOne();
    if (card == null) {
      currentIndex = _nextActive(currentIndex);
      return;
    }
    final player = players[currentIndex];
    player
      ..hand.add(card)
      ..saidUno = false;
    lastDrawUserId = actor;
    lastDrawCount = 1;
    if (card.matches(topDiscard!, currentColor)) {
      drawnCardId = card.id;
      status = UnoStatus.awaitingDrawnPlay;
    } else {
      currentIndex = _nextActive(currentIndex);
    }
  }

  void _applyKeep() {
    if (status != UnoStatus.awaitingDrawnPlay) {
      throw StateError('keep is only allowed after drawing');
    }
    _expireUnoWindow();
    drawnCardId = null;
    status = UnoStatus.active;
    currentIndex = _nextActive(currentIndex);
  }

  void _applyCallUno(String? actorUserId) {
    final index = unoVulnerableIndex;
    if (index < 0 ||
        index >= players.length ||
        players[index].hand.length != 1) {
      throw StateError('no player can call UNO');
    }
    final actor = _playerIndex(actorUserId);
    if (actor >= 0 && actor != index) {
      throw StateError('only the vulnerable player can call UNO');
    }
    players[index].saidUno = true;
    unoVulnerableIndex = -1;
  }

  void _applyChallengeUno(String? actorUserId, String? targetUserId) {
    final actor = _playerIndex(actorUserId);
    final target = _playerIndex(targetUserId);
    if (actor < 0 || players[actor].forfeited) {
      throw StateError('challenger is not a player');
    }
    if (target < 0 || target != unoVulnerableIndex || target == actor) {
      throw StateError('player cannot be challenged');
    }
    if (players[target].saidUno || players[target].hand.length != 1) {
      throw StateError('player is not vulnerable');
    }
    _drawCards(target, 2);
    unoVulnerableIndex = -1;
  }

  void _applyChallengeWd4() {
    if (status != UnoStatus.awaitingWd4Challenge) {
      throw StateError('no Wild Draw Four can be challenged');
    }
    _expireUnoWindow();
    final challenger = currentIndex;
    final offender = wild4PlayerIndex;
    if (offender < 0 || offender >= players.length) {
      throw StateError('invalid Wild Draw Four player');
    }
    if (wild4WasLegal) {
      _noteEvent('draw', players[challenger].userId, null);
      _drawCards(challenger, 6);
      currentIndex = _nextActive(challenger);
    } else {
      _noteEvent('wd4_reveal', players[offender].userId, wild4ProofCard);
      _drawCards(offender, 4);
      currentIndex = challenger;
      pendingRoundWinnerIndex = -1;
    }
    pendingDraw = 0;
    wild4PlayerIndex = -1;
    wild4WasLegal = false;
    wild4ProofCard = null;
    status = UnoStatus.active;
    _finishPendingRound();
  }

  void _applyChooseColor(UnoColor? color) {
    if (status != UnoStatus.awaitingColor) {
      throw StateError('no color choice is pending');
    }
    if (color == null || !color.isPlayableColor) {
      throw StateError('invalid chosen color');
    }
    final chooser = colorChooserIndex;
    if (chooser < 0 || chooser >= players.length) {
      throw StateError('invalid color chooser');
    }
    currentColor = color;
    colorChooserIndex = -1;
    if (wild4PlayerIndex == chooser && pendingDraw == 4) {
      currentIndex = _nextActive(chooser);
      status = UnoStatus.awaitingWd4Challenge;
      return;
    }
    currentIndex = _nextActive(chooser);
    status = UnoStatus.active;
    _finishPendingRound();
  }

  void _applyForfeit(String? actorUserId) {
    var index = _playerIndex(actorUserId);
    if (index < 0) index = currentIndex;
    if (index < 0 || index >= players.length || players[index].forfeited) {
      throw StateError('no active player to forfeit');
    }
    _expireUnoWindow();
    _noteEvent('forfeit', players[index].userId, null);
    players[index]
      ..forfeited = true
      ..saidUno = false
      ..hand.clear();
    eliminatedOrder.add(players[index].userId);
    drawnCardId = null;
    pendingDraw = 0;
    wild4PlayerIndex = -1;
    wild4WasLegal = false;
    colorChooserIndex = -1;
    pendingRoundWinnerIndex = -1;
    if (_activePlayerCount == 1) {
      final winner = players.firstWhere((player) => !player.forfeited);
      currentIndex = winner.seat;
      winnerUserIds
        ..clear()
        ..add(winner.userId);
      status = UnoStatus.over;
      return;
    }
    if (currentIndex == index || players[currentIndex].forfeited) {
      currentIndex = _nextActive(index);
    }
    status = UnoStatus.active;
  }

  void _finishPendingRound() {
    if (pendingRoundWinnerIndex < 0) return;
    final winner = pendingRoundWinnerIndex;
    pendingRoundWinnerIndex = -1;
    final points = players
        .asMap()
        .entries
        .where((entry) => entry.key != winner)
        .expand((entry) => entry.value.hand)
        .fold<int>(0, (total, card) => total + card.points);
    players[winner].score += points;
    unoVulnerableIndex = -1;
    pendingDraw = 0;
    drawnCardId = null;
    wild4PlayerIndex = -1;
    colorChooserIndex = -1;
    lastRoundWinnerUserId = players[winner].userId;
    lastRoundPoints = points;
    lastRoundNumber = roundNumber;
    _noteEvent('round_scored', players[winner].userId, null);
    if (players[winner].score >= targetScore) {
      status = UnoStatus.over;
      currentIndex = winner;
      winnerUserIds
        ..clear()
        ..add(players[winner].userId);
      return;
    }
    status = UnoStatus.betweenRounds;
    currentIndex = winner;
  }

  void _applyNextRound() {
    if (status != UnoStatus.betweenRounds) {
      throw StateError('next round is not pending');
    }
    roundNumber++;
    dealerIndex = _nextActiveClockwise(dealerIndex);
    _startRound();
  }

  void _noteEvent(String type, String actor, UnoCard? card) {
    eventSeq++;
    lastEventType = type;
    lastEventActor = actor;
    lastEventCard = card;
  }

  void _drawCards(int playerIndex, int count) {
    if (playerIndex < 0 || playerIndex >= players.length) return;
    var drawn = 0;
    for (var i = 0; i < count; i++) {
      final card = _drawOne();
      if (card == null) break;
      players[playerIndex].hand.add(card);
      drawn++;
    }
    if (drawn > 0) {
      lastDrawUserId = players[playerIndex].userId;
      lastDrawCount = drawn;
    }
    if (players[playerIndex].hand.length != 1) {
      players[playerIndex].saidUno = false;
    }
  }

  UnoCard? _drawOne() {
    if (drawPile.isEmpty) {
      if (discardPile.length <= 1) return null;
      final top = discardPile.removeLast();
      drawPile = List.of(discardPile);
      discardPile = [top];
      shuffleCount++;
      drawPile.shuffle(
        Random(seed + roundNumber * 104729 + shuffleCount * 7919),
      );
    }
    return drawPile.isEmpty ? null : drawPile.removeLast();
  }

  int _nextActive(int index) => _nextActiveInDirection(index, direction);
  int _nextActiveClockwise(int index) => _nextActiveInDirection(index, 1);

  int _nextActiveInDirection(int index, int stepDirection) {
    for (var step = 1; step <= players.length; step++) {
      var next = (index + stepDirection * step) % players.length;
      if (next < 0) next += players.length;
      if (!players[next].forfeited) return next;
    }
    return index;
  }

  int get _activePlayerCount =>
      players.where((player) => !player.forfeited).length;

  int _playerIndex(String? userId) {
    if (userId == null || userId.isEmpty) return -1;
    return players.indexWhere((player) => player.userId == userId);
  }

  void _expireUnoWindow() {
    if (unoVulnerableIndex >= 0) unoVulnerableIndex = -1;
  }
}
