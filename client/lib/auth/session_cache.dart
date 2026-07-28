import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';

/// Полный сброс пользовательских кэшей при logout/login.
void clearUserScopedCaches(Ref ref) {
  ref.read(dailyRewardFromRealtimeProvider.notifier).state = null;
  ref.read(chatsListCacheProvider.notifier).state = null;
  ref.read(chatRemovedIdProvider.notifier).state = null;
  ref.read(gameInvitesProvider.notifier).clear();
  clearPresenceOverrides(ref);
  ref.invalidate(authUserProvider);
  ref.invalidate(dailyRewardStatusProvider);
  ref.invalidate(dailyRewardAvailableProvider);
  ref.invalidate(shopCatalogProvider);
  ref.invalidate(inventoryListProvider);
  ref.invalidate(inventoryCapabilitiesProvider);
  ref.invalidate(collectionIncomeProvider);
  ref.invalidate(achievementsListProvider);
  ref.invalidate(achievementsUnclaimedCountProvider);
  ref.read(unreadGiftedCollectionsProvider.notifier).clear();
}
