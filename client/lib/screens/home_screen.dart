import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';

/// Контент главной страницы. Тулбар (Войти/Регистрация) в [AppShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ? 'Вам подарили коллекцию'
        : (collectionIncomeAvailable
            ? 'Можно забрать доход коллекций'
            : 'Ваш инвентарь');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: unclaimedAchievements > 0
                        ? 'Есть награды к получению'
                        : 'Ваши игровые результаты',
                    badgeCount: unclaimedAchievements,
                    onTap: () => context.push('/achievements'),
                  ),
                  const SizedBox(height: 12),
                  HomeActionCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Монеты',
                    subtitle: rewardAvailable
                        ? 'Доступна награда за вход'
                        : 'Баланс и награды',
                    badgeCount: rewardAvailable ? 1 : 0,
                    onTap: () => context.push('/coins'),
                  ),
                  const SizedBox(height: 12),
                  HomeActionCard(
                    icon: Icons.storefront_rounded,
                    title: 'Магазин',
                    subtitle: 'Смайлы, ставки, коллекции',
                    onTap: () => context.push('/shop'),
                  ),
                  const SizedBox(height: 12),
                  HomeActionCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Предметы',
                    subtitle: itemsSubtitle,
                    badgeCount: itemsBadge,
                    onTap: () => context.push('/inventory'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
