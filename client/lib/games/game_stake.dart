// Общий расчёт банка ставки (крестики-нолики / дурак / будущие игры).
// Банк = stake × playerCount. Ничья — возврат ставки.
// Победа: банк делится между winnerCount победителями
// (1 победитель → весь банк stake×N, как в multi-крестиках).

/// Выплата одному победителю из банка (кредит на баланс).
int stakeWinnerCredit({
  required int stake,
  required int playerCount,
  required int winnerCount,
}) {
  if (stake <= 0 || playerCount < 2 || winnerCount < 1) return 0;
  final pot = stake * playerCount;
  return pot ~/ winnerCount;
}

/// Чистый плюс к доматчевому балансу (без возврата своей ставки).
int stakeWinnerNetProfit({
  required int stake,
  required int playerCount,
  required int winnerCount,
}) {
  final credit = stakeWinnerCredit(
    stake: stake,
    playerCount: playerCount,
    winnerCount: winnerCount,
  );
  return (credit - stake).clamp(0, credit);
}
