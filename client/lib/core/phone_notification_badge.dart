/// Счётчик на иконке: одно уведомление на чат, одно на заявки в друзья,
/// по одному на приглашение в игру и по одному на доступные награды
/// (монеты за вход и дневной доход коллекций).
int phoneNotificationBadge({
  required int chatsWithUnread,
  required int incomingFriends,
  required int gameInvites,
  int dailyReward = 0,
  int collectionIncome = 0,
}) {
  final chats = chatsWithUnread < 0 ? 0 : chatsWithUnread;
  final friends = incomingFriends > 0 ? 1 : 0;
  final invites = gameInvites < 0 ? 0 : gameInvites;
  final rewards = (dailyReward > 0 ? 1 : 0) + (collectionIncome > 0 ? 1 : 0);
  return chats + friends + invites + rewards;
}
