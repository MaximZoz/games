// Общий расчёт банка ставки (крестики-нолики / дурак / будущие игры).
// Банк = stake × playerCount. Ничья — возврат ставки.
// Победа в крестиках: банк делится между winnerCount победителями
// (1 победитель → stake×N).
// Дурак multi: доли по местам выхода (см. durakPlaceCredit).
//
// Баланс единый: balance_bronze, 1 серебро = 100 бронзы, 1 золото = 100 серебра.

/// Хватает ли кошелька на ставку (весь balance_bronze, не «остаток бронзы»).
bool canAffordStake({
  required int balanceBronze,
  required int stakeBronze,
}) {
  if (stakeBronze <= 0) return true;
  return balanceBronze >= stakeBronze;
}

/// Разблокированные ставки, которые можно оплатить сейчас.
List<int> affordableStakeOptions(int balanceBronze, List<int> options) {
  return [
    for (final s in options)
      if (s > 0 && s <= balanceBronze) s,
  ];
}

/// Если текущая ставка не по карману — ближайшая меньшая из [options].
int clampStakeToAffordable(
  int stakeBronze,
  int balanceBronze,
  List<int> options,
) {
  if (canAffordStake(
    balanceBronze: balanceBronze,
    stakeBronze: stakeBronze,
  )) {
    return stakeBronze;
  }
  final affordable = affordableStakeOptions(balanceBronze, options);
  if (affordable.isEmpty) return stakeBronze;
  return affordable.last;
}

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

/// Списание ставки в UI: только поражение. Ничья — возврат, не проигрыш.
int stakeLostOnFinish({
  required int stakeBronze,
  required bool isDraw,
  required bool iWon,
}) {
  if (stakeBronze <= 0 || isDraw || iWon) return 0;
  return stakeBronze;
}

/// Чип «+N» / «−N» после партии. Ничья — без чипа (ставка возвращается).
int stakeFinishRewardChip({
  required int stakeBronze,
  required bool isDraw,
  required bool iWon,
  int netProfit = 0,
}) {
  if (stakeBronze <= 0 || isDraw) return 0;
  if (iWon) return netProfit > 0 ? netProfit : stakeBronze;
  return -stakeBronze;
}

/// Показывать чип награды только если партия кончилась не ничьей.
bool stakeShowFinishReward({
  required int stakeBronze,
  required bool isOver,
  required bool isDraw,
  int rewardChip = 0,
}) {
  if (!isOver || stakeBronze <= 0 || isDraw) return false;
  return rewardChip != 0;
}

/// Числители долей банка дурака по местам (знаменатель = playerCount).
/// 3: 2/3 + 1/3; 4: 2/4 + 1/4 + 1/4; 2: весь банк.
List<int> durakPlaceShareNumerators(int playerCount) {
  switch (playerCount) {
    case 3:
      return const [2, 1];
    case 4:
      return const [2, 1, 1];
    default:
      if (playerCount < 2) return const [];
      return [playerCount];
  }
}

/// Кредит с банка за место (place — 1-е, 2-е, …). Проигравший — 0.
/// Если реальных мест меньше долей — остаток уходит 1-му месту.
int durakPlaceCredit({
  required int stake,
  required int playerCount,
  required int place,
  required int placesFilled,
}) {
  if (stake <= 0 || playerCount < 2 || place < 1) return 0;
  final nums = List<int>.from(durakPlaceShareNumerators(playerCount));
  if (nums.isEmpty || place > placesFilled) return 0;
  if (placesFilled < nums.length) {
    var extra = 0;
    for (var i = placesFilled; i < nums.length; i++) {
      extra += nums[i];
    }
    nums.removeRange(placesFilled, nums.length);
    nums[0] += extra;
  }
  if (place > nums.length) return 0;
  final pot = stake * playerCount;
  return pot * nums[place - 1] ~/ playerCount;
}

int durakPlaceNetProfit({
  required int stake,
  required int playerCount,
  required int place,
  required int placesFilled,
}) {
  final credit = durakPlaceCredit(
    stake: stake,
    playerCount: playerCount,
    place: place,
    placesFilled: placesFilled,
  );
  return (credit - stake).clamp(0, credit);
}

/// Кредит с банка покера за место (place — 1-е, 2-е, …).
///
/// 2: 1-й весь банк; 3: 2/3 + возврат ставки + 0; 4: 3/4 + возврат + 0+0;
/// 5: 3/5 + возврат×2 + 0+0; 6: 4/6 + возврат×2 + 0×3.
int pokerPlaceCredit({
  required int stake,
  required int playerCount,
  required int place,
}) {
  if (stake <= 0 || playerCount < 2 || place < 1 || place > playerCount) {
    return 0;
  }
  final pot = stake * playerCount;
  switch (playerCount) {
    case 2:
      return place == 1 ? pot : 0;
    case 3:
      if (place == 1) return pot * 2 ~/ 3;
      if (place == 2) return stake;
      return 0;
    case 4:
      if (place == 1) return pot * 3 ~/ 4;
      if (place == 2) return stake;
      return 0;
    case 5:
      if (place == 1) return pot * 3 ~/ 5;
      if (place == 2 || place == 3) return stake;
      return 0;
    case 6:
      if (place == 1) return pot * 4 ~/ 6;
      if (place == 2 || place == 3) return stake;
      return 0;
    default:
      return place == 1 ? pot : 0;
  }
}

int pokerPlaceNetProfit({
  required int stake,
  required int playerCount,
  required int place,
}) {
  final credit = pokerPlaceCredit(
    stake: stake,
    playerCount: playerCount,
    place: place,
  );
  return (credit - stake).clamp(0, credit);
}
