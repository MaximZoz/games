/// Счётчик на иконке, как у Android: одно уведомление на чат,
/// одно на заявки в друзья и по одному на каждое приглашение в игру.
int phoneNotificationBadge({
  required int chatsWithUnread,
  required int incomingFriends,
  required int gameInvites,
}) {
  final chats = chatsWithUnread < 0 ? 0 : chatsWithUnread;
  final friends = incomingFriends > 0 ? 1 : 0;
  final invites = gameInvites < 0 ? 0 : gameInvites;
  return chats + friends + invites;
}
