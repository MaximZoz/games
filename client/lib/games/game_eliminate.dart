import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_navigation.dart';
import 'games_provider.dart';
import 'games_repository.dart';

/// Общая логика выбывания (крестики / дурак): active → observation до конца партии.
void enterGameObservation(
  WidgetRef ref,
  String gameId, {
  String gameType = 'tictactoe',
}) {
  final prev = ref.read(activeGameProvider).valueOrNull;
  final prevObs = ref.read(observationGameProvider);
  // Не затирать durak/poker→tictactoe дефолтом с экрана крестиков.
  var gt = normalizeGameType(gameType);
  if (prevObs != null && prevObs.gameId == gameId) {
    final prevGt = normalizeGameType(prevObs.gameType);
    if ((prevGt == 'durak' || prevGt == 'poker') && gt != prevGt) {
      gt = prevGt;
    }
  }
  ref.read(activeGameProvider.notifier).setObservationLocal(
        ObservationItem(
          gameId: gameId,
          lobbyId: prev?.lobbyId ?? prevObs?.lobbyId,
          gameType: gt,
        ),
      );
  if (prev?.gameId == gameId) {
    ref.read(activeGameProvider.notifier).clearLocal();
  }
}
