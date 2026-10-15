import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';

/// Контент главной страницы. Тулбар (Войти/Регистрация) в [AppShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rewardAvailable =
        ref.watch(dailyRewardAvailableProvider).valueOrNull == true;
    final unclaimedAchievements =
        ref.watch(achievementsUnclaimedCountProvider).valueOrNull ?? 0;
    final unclaimedTasks =
        ref.watch(tasksUnclaimedCountProvider).valueOrNull ?? 0;
    final collectionIncomeAvailable =
        ref.watch(collectionIncomeAvailableProvider);
    final unreadGifts = ref.watch(unreadGiftedCollectionsCountProvider);
    // Прогрев кэша — экраны открываются без спиннера.
    ref.watch(achievementsListProvider);
    ref.watch(tasksListProvider);
    ref.watch(shopCatalogProvider);
    ref.watch(inventoryListProvider);
    ref.watch(collectionIncomeProvider);

    final itemsBadge = (collectionIncomeAvailable ? 1 : 0) + unreadGifts;
    final itemsSubtitle = unreadGifts > 0
        ? l10n.homeItemsGifted
        : (collectionIncomeAvailable
            ? l10n.homeItemsIncome
            : l10n.homeItemsInventory);

    final tiles = useDesktopTiles(context);
    final dense = isPhoneLandscape(context);

    final cards = <Widget>[
      HomeActionCard(
        icon: Icons.emoji_events_rounded,
        title: l10n.homeAchievements,
        subtitle: unclaimedAchievements > 0
            ? l10n.homeAchievementsRewards
            : l10n.homeAchievementsSubtitle,
        badgeCount: unclaimedAchievements,
        onTap: () => context.push('/achievements'),
        dense: dense,
      ),
      HomeActionCard(
        icon: Icons.monetization_on_rounded,
        title: l10n.homeCoins,
        subtitle: rewardAvailable
            ? l10n.homeCoinsDailyReward
            : (unclaimedTasks > 0
                ? l10n.coinsTasksRewards
                : l10n.homeCoinsSubtitle),
        badgeCount: (rewardAvailable ? 1 : 0) + unclaimedTasks,
        onTap: () => context.push('/coins'),
        dense: dense,
      ),
      HomeActionCard(
        icon: Icons.inventory_2_rounded,
        title: l10n.homeItems,
        subtitle: itemsSubtitle,
        badgeCount: itemsBadge,
        onTap: () => context.push('/inventory'),
        dense: dense,
      ),
      HomeActionCard(
        icon: Icons.bar_chart_rounded,
        title: l10n.statsTitle,
        subtitle: l10n.statsAllGames,
        onTap: () => context.push('/stats'),
        dense: dense,
      ),
      HomeActionCard(
        icon: Icons.storefront_rounded,
        title: l10n.homeShop,
        subtitle: l10n.homeShopSubtitle,
        onTap: () => context.push('/shop'),
        dense: dense,
      ),
    ];

    Widget mobileList(BuildContext context) {
      return FocusScope(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView.separated(
                // Нижний зазор только в конце списка, как в настройках.
                // Снаружи он оставлял пустую полосу над иконками меню.
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => cards[i],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FocusScope(
          child: tiles
              ? DesktopTileGrid(
                  itemCount: cards.length,
                  maxCellWidth: dense ? 240 : 320,
                  maxContentWidth: 1100,
                  maxColumns: 3,
                  padding: EdgeInsets.fromLTRB(
                    dense ? 10 : 16,
                    dense ? 4 : 8,
                    dense ? 10 : 16,
                    dense ? 10 : 16,
                  ),
                  itemBuilder: (_, i) => cards[i],
                  mobileBuilder: mobileList,
                )
              : mobileList(context),
        ),
      ),
    );
  }
}
