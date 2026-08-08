import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'games_provider.dart';
import 'games_repository.dart';

/// Общая логика выбывания (крестики / дурак): active → observation до конца партии.
void enterGameObservation(WidgetRef ref, String gameId) {
  final prev = ref.read(activeGameProvider).valueOrNull;
  ref.read(activeGameProvider.notifier).setObservationLocal(
        ObservationItem(
          gameId: gameId,
          lobbyId: prev?.lobbyId,
        ),
      );
  if (prev?.gameId == gameId) {
    ref.read(activeGameProvider.notifier).clearLocal();
  }
}
