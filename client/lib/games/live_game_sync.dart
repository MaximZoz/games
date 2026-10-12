import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/games/battleship/battleship_repository.dart';
import 'package:multigames_client/games/domino/domino_repository.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/games/poker/poker_repository.dart';
import 'package:multigames_client/games/uno/uno_repository.dart';

/// HTTP-сверка, если сокет пропустил кадр. Не чаще: иначе GET затирает свежий WS.
const Duration kGameStateReconcileInterval = Duration(seconds: 2);

bool isRealtimeConnectedEvent(Map<String, dynamic> data) =>
    data['type']?.toString() == 'realtime_connected';

bool isGameStateFor(Map<String, dynamic> data, String gameId) {
  final type = data['type']?.toString() ?? '';
  if (type != 'game_state' && type != 'game_started') return false;
  return data['game_id']?.toString() == gameId;
}

bool hasFullTictactoeView(Map<String, dynamic> data) => data['board'] is List;

bool hasFullBattleshipView(Map<String, dynamic> data) =>
    data.containsKey('phase') &&
    (data.containsKey('my_shots') || data.containsKey('opponent_shots'));

bool hasFullDurakView(Map<String, dynamic> data) =>
    data['hands'] is List && data['trump_card'] is Map;

bool hasFullUnoView(Map<String, dynamic> data) {
  final players = data['players'];
  return players is List && players.isNotEmpty;
}

bool hasFullDominoView(Map<String, dynamic> data) {
  final type = data['game_type']?.toString() ?? '';
  if (type.isNotEmpty && type != 'domino') return false;
  return data['chain'] is List && data.containsKey('boneyard_count');
}

bool hasFullPokerView(Map<String, dynamic> data) =>
    data['players'] is List && data.containsKey('street');

bool hasFullNardyView(Map<String, dynamic> data) =>
    data['board'] is List && (data['board'] as List).length == 24;

int tictactoeProgress(GameStateItem state) {
  var progress = state.filledCellCount;
  if (state.status != 'active') progress += 1000;
  if (state.winningCells != null && state.winningCells!.isNotEmpty) {
    progress += 5;
  }
  return progress;
}

int battleshipProgress(BattleshipGameView state) {
  var progress = state.myShots.length + state.opponentShots.length;
  if (state.p1Ready) progress += 50;
  if (state.p2Ready) progress += 50;
  if (state.phase == 'battle') progress += 200;
  if (state.isOver) progress += 10000;
  return progress;
}

int durakProgress(DurakGameView state) {
  var progress = state.bitoCount * 100;
  progress += state.eliminated.length * 400;
  progress += state.finished.length * 400;
  progress += state.deckSize - state.deckCount;
  if (state.status != 'active') progress += 10000;
  return progress;
}

int unoProgress(UnoGameView state) {
  var progress = state.eventSeq + state.roundNumber * 10000;
  if (state.status != 'active') progress += 1000000;
  return progress;
}

int pokerStreetRank(String street) {
  switch (street) {
    case 'preflop':
      return 1;
    case 'flop':
      return 2;
    case 'turn':
      return 3;
    case 'river':
      return 4;
    case 'showdown':
      return 5;
    case 'over':
      // Фолд-вина: street=over, isHandOver. Раньше default=0 откатывал
      // прогресс ниже preflop и отбрасывал снимок — «Фолд» вспыхивал снова.
      return 6;
    default:
      return 0;
  }
}

int pokerProgress(PokerGameView state) {
  var progress = state.handNumber * 1000 + pokerStreetRank(state.street) * 10;
  if (state.isHandOver) progress += 5;
  if (state.isTableOver || state.isOver) progress += 100000;
  return progress;
}

/// Прогресс партии нард — монотонный счётчик изменений с сервера.
///
/// Позиция не годится: отмена хода возвращает шашку назад, и снимок после
/// отмены выглядел бы «старее» отменённого.
int nardyProgress(NardyGameView state) {
  var progress = state.seq;
  if (state.isOver) progress += 1000000;
  return progress;
}

bool isOlderNardy(NardyGameView incoming, NardyGameView current) {
  if (current.isOver && !incoming.isOver) return true;
  if (incoming.isOver && !current.isOver) return false;
  return nardyProgress(incoming) < nardyProgress(current);
}

/// Старый HTTP/переупорядоченный кадр не должен откатить уже показанный ход.
bool isOlderTictactoe(GameStateItem incoming, GameStateItem current) =>
    tictactoeProgress(incoming) < tictactoeProgress(current);

bool isOlderBattleship(BattleshipGameView incoming, BattleshipGameView current) =>
    battleshipProgress(incoming) < battleshipProgress(current);

bool isOlderDurak(DurakGameView incoming, DurakGameView current) {
  if (incoming.status != 'active' && current.status == 'active') return false;
  if (current.status != 'active' && incoming.status == 'active') return true;
  if (incoming.eliminated.length < current.eliminated.length) return true;
  if (incoming.finished.length < current.finished.length) return true;
  return incoming.bitoCount < current.bitoCount;
}

bool isOlderUno(UnoGameView incoming, UnoGameView current) {
  if (incoming.roundNumber != current.roundNumber) {
    return incoming.roundNumber < current.roundNumber;
  }
  return incoming.eventSeq < current.eventSeq;
}

bool isOlderDomino(DominoGameView incoming, DominoGameView current) {
  if (incoming.round != current.round) return incoming.round < current.round;
  return incoming.eventSeq < current.eventSeq;
}

bool isOlderPoker(PokerGameView incoming, PokerGameView current) {
  if (incoming.handNumber != current.handNumber) {
    return incoming.handNumber < current.handNumber;
  }
  // Конец раздачи/стола не должен проигрывать кадру «ещё хожу».
  if (current.isTableOver && !incoming.isTableOver) return true;
  if (incoming.isTableOver && !current.isTableOver) return false;
  if (current.isOver && !incoming.isOver) return true;
  if (incoming.isOver && !current.isOver) return false;
  if (current.isHandOver && !incoming.isHandOver) return true;
  if (incoming.isHandOver && !current.isHandOver) return false;
  return pokerProgress(incoming) < pokerProgress(current);
}

/// Кнопки хода: не показывать фолд после своего хода, пока сервер не подтвердил.
bool pokerShouldKeepActionBarHidden({
  required bool hideUntilSync,
  required bool isMyTurn,
  required bool isHandOver,
  required bool isOver,
  required bool meFolded,
}) {
  if (!hideUntilSync) return false;
  if (isOver || isHandOver || meFolded || !isMyTurn) return false;
  return true;
}

bool pokerActionBarVisible({
  required bool isOver,
  required bool isHandOver,
  required bool isMyTurn,
  required bool hasLegalActions,
  required bool meFolded,
  required bool hideUntilSync,
}) =>
    !isOver &&
    !isHandOver &&
    isMyTurn &&
    hasLegalActions &&
    !meFolded &&
    !hideUntilSync;

BattleshipGameView mergeBattleshipMeta(
  BattleshipGameView? previous,
  BattleshipGameView incoming,
) {
  if (previous == null) return incoming;
  return incoming.copyWith(
    p1DisplayName: incoming.p1DisplayName ?? previous.p1DisplayName,
    p2DisplayName: incoming.p2DisplayName ?? previous.p2DisplayName,
    p1AvatarKind: incoming.p1AvatarKind == 'letter' &&
            previous.p1AvatarKind != 'letter'
        ? previous.p1AvatarKind
        : incoming.p1AvatarKind,
    p2AvatarKind: incoming.p2AvatarKind == 'letter' &&
            previous.p2AvatarKind != 'letter'
        ? previous.p2AvatarKind
        : incoming.p2AvatarKind,
    p1AvatarValue: incoming.p1AvatarValue ?? previous.p1AvatarValue,
    p2AvatarValue: incoming.p2AvatarValue ?? previous.p2AvatarValue,
    p1FrameCode: incoming.p1FrameCode ?? previous.p1FrameCode,
    p2FrameCode: incoming.p2FrameCode ?? previous.p2FrameCode,
    p1FrameColor: incoming.p1FrameColor ?? previous.p1FrameColor,
    p2FrameColor: incoming.p2FrameColor ?? previous.p2FrameColor,
    lobbyId: incoming.lobbyId.isNotEmpty ? incoming.lobbyId : previous.lobbyId,
  );
}

bool isTransientGamesError(Object error) {
  if (error is GamesException) {
    if (error.statusCode == 502 || error.statusCode == 503) return true;
    final key = error.errorKey.toLowerCase();
    final msg = error.message.toLowerCase();
    return key.contains('temporarily unavailable') ||
        msg.contains('temporarily unavailable') ||
        msg.contains('временно недоступно') ||
        msg.contains('попробуйте позже');
  }
  final text = error.toString().toLowerCase();
  return text.contains('temporarily unavailable') ||
      text.contains('socket') ||
      text.contains('connection');
}

Future<T> fetchGameWithRetry<T>(Future<T> Function() fetch) async {
  Object? lastError;
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      return await fetch();
    } catch (error) {
      lastError = error;
      if (!isTransientGamesError(error) || attempt == 3) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }
  Error.throwWithStackTrace(lastError!, StackTrace.current);
}

/// Слушает WS и редкий poll. Полный view — сразу; ping/reconnect — HTTP.
void listenLiveGameSync({
  required Ref ref,
  required String gameId,
  required bool Function(Map<String, dynamic> data) hasFullView,
  required void Function(Map<String, dynamic> data) onFullState,
  required void Function() onReconcile,
}) {
  final subscription = ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      if (isRealtimeConnectedEvent(data)) {
        onReconcile();
        return;
      }
      if (!isGameStateFor(data, gameId)) return;
      if (hasFullView(data)) {
        onFullState(data);
      } else {
        onReconcile();
      }
    },
  );
  ref.onDispose(subscription.close);

  final poll = Stream<void>.periodic(kGameStateReconcileInterval).listen((_) {
    onReconcile();
  });
  ref.onDispose(poll.cancel);
}
