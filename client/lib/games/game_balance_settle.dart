import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'games_provider.dart';

/// Партии, для которых анимация ±монет уже показана в этой сессии приложения.
///
/// Нужна при повторном входе из карточки «Наблюдение»: виджет создаётся заново
/// и локальные `_balanceGainPlayed` / `_midFinishedHandled` сбрасываются.
final gameBalanceSettledIdsProvider = StateProvider<Set<String>>((ref) => {});

bool isGameBalanceSettled(WidgetRef ref, String gameId) {
  final id = gameId.trim();
  if (id.isEmpty) return false;
  return ref.read(gameBalanceSettledIdsProvider).contains(id);
}

void markGameBalanceSettled(WidgetRef ref, String gameId) {
  final id = gameId.trim();
  if (id.isEmpty) return;
  final cur = ref.read(gameBalanceSettledIdsProvider);
  if (cur.contains(id)) return;
  ref.read(gameBalanceSettledIdsProvider.notifier).state = {...cur, id};
}

/// Экран открыт уже как наблюдение (карточка «Наблюдение» / повторный вход).
bool openedAsGameObserver(WidgetRef ref, String gameId) {
  final id = gameId.trim();
  if (id.isEmpty) return false;
  return ref.read(observationGameProvider)?.gameId == id;
}
