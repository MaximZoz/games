import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/responsive.dart';
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
    final collectionIncomeAvailable =
        ref.watch(collectionIncomeAvailableProvider);
    final unreadGifts = ref.watch(unreadGiftedCollectionsCountProvider);
    // Прогрев кэша — экраны открываются без спиннера.
    ref.watch(achievementsListProvider);
    ref.watch(shopCatalogProvider);
    ref.watch(inventoryListProvider);
    ref.watch(collectionIncomeProvider);

    final itemsBadge = (collectionIncomeAvailable ? 1 : 0) + unreadGifts;
    final itemsSubtitle = unreadGifts > 0
        ? l10n.homeItemsGifted
        : (collectionIncomeAvailable
            ? l10n.homeItemsIncome
            : l10n.homeItemsInventory);

    final phoneLandscape = isPhoneLandscape(context);
    // В landscape на телефоне — узкая колонка по центру, чтобы карточки
    // визуально проходили между монетами и логином в верхней панели.
    final maxWidth = phoneLandscape ? 268.0 : 460.0;
    final pad = phoneLandscape
        ? const EdgeInsets.fromLTRB(12, 8, 12, 16)
        : const EdgeInsets.fromLTRB(20, 24, 20, 32);

    final cards = <Widget>[
      HomeActionCard(
        icon: Icons.emoji_events_rounded,
        title: l10n.homeAchievements,
        subtitle: unclaimedAchievements > 0
            ? l10n.homeAchievementsRewards
            : l10n.homeAchievementsSubtitle,
        badgeCount: unclaimedAchievements,
        onTap: () => context.push('/achievements'),
        dense: phoneLandscape,
      ),
      SizedBox(height: phoneLandscape ? 8 : 12),
      HomeActionCard(
        icon: Icons.monetization_on_rounded,
        title: l10n.homeCoins,
        subtitle: rewardAvailable
            ? l10n.homeCoinsDailyReward
            : l10n.homeCoinsSubtitle,
        badgeCount: rewardAvailable ? 1 : 0,
        onTap: () => context.push('/coins'),
        dense: phoneLandscape,
      ),
      SizedBox(height: phoneLandscape ? 8 : 12),
      HomeActionCard(
        icon: Icons.inventory_2_rounded,
        title: l10n.homeItems,
        subtitle: itemsSubtitle,
        badgeCount: itemsBadge,
        onTap: () => context.push('/inventory'),
        dense: phoneLandscape,
      ),
      SizedBox(height: phoneLandscape ? 8 : 12),
      HomeActionCard(
        icon: Icons.bar_chart_rounded,
        title: l10n.statsTitle,
        subtitle: l10n.statsAllGames,
        onTap: () => context.push('/stats'),
        dense: phoneLandscape,
      ),
      SizedBox(height: phoneLandscape ? 8 : 12),
      HomeActionCard(
        icon: Icons.storefront_rounded,
        title: l10n.homeShop,
        subtitle: l10n.homeShopSubtitle,
        onTap: () => context.push('/shop'),
        dense: phoneLandscape,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: pad,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(children: cards),
            ),
          ),
        ),
      ),
    );
  }
}
