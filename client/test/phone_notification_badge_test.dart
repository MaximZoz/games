import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/phone_notification_badge.dart';

void main() {
  test('бейдж как шторка Android: чат, одна заявка, приглашения', () {
    expect(
      phoneNotificationBadge(
        chatsWithUnread: 2,
        incomingFriends: 4,
        gameInvites: 1,
      ),
      4,
    );
    expect(
      phoneNotificationBadge(
        chatsWithUnread: 0,
        incomingFriends: 0,
        gameInvites: 0,
      ),
      0,
    );
    expect(
      phoneNotificationBadge(
        chatsWithUnread: 0,
        incomingFriends: 0,
        gameInvites: 0,
        dailyReward: 1,
        collectionIncome: 1,
      ),
      2,
    );
    expect(
      phoneNotificationBadge(
        chatsWithUnread: 1,
        incomingFriends: 0,
        gameInvites: 0,
        dailyReward: 1,
        collectionIncome: 1,
      ),
      3,
    );
    expect(
      phoneNotificationBadge(
        chatsWithUnread: -3,
        incomingFriends: -1,
        gameInvites: -2,
        dailyReward: -1,
        collectionIncome: -2,
      ),
      0,
    );
  });
}
