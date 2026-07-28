import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

const collectionSetTitles = <String, String>{
  'legends': 'Легенды',
  'cosmic': 'Космос',
  'jewels': 'Драгоценности',
  'celebration': 'Праздник',
  'nature': 'Природа',
  'adventure': 'Приключения',
};

const collectionSetOrder = [
  'legends',
  'cosmic',
  'jewels',
  'celebration',
  'nature',
  'adventure',
];

String collectionSetTitle(String set) => collectionSetTitles[set] ?? set;

String collectionItemSubtitle(int dailyBronze) =>
    'Коллекция · витрина · подарок · продажа · +${formatRewardBronzePerDay(dailyBronze)}';

/// Полноэкранный просмотр: тап вне «Купить» закрывает; крестика нет.
Future<void> showCollectionFullscreen(
  BuildContext context, {
  required String title,
  required String animatedName,
  String? fallback,
  String? subtitle,
  Widget? bottomAction,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.86),
    builder: (dialogContext) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShopAnimatedEmoji(
                    animatedName: animatedName,
                    size: 180,
                    fallback: fallback,
                    animate: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  if (bottomAction != null) ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {},
                      child: bottomAction,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Секция коллекций в карточке пользователя (по клику на аватар).
/// Загружает витрину по [userId]; если пусто — ничего не рисует.
class PeerCollectionsSection extends ConsumerWidget {
  const PeerCollectionsSection({
    super.key,
    required this.userId,
    this.topPadding = 12,
  });

  final String userId;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.trim().isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<InventoryItem>>(
      future: ref.read(shopRepositoryProvider).listCollectionsShowcase(userId),
      builder: (context, snap) {
        final items = snap.data ?? const <InventoryItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Коллекции',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CollectionShowcaseGrid(items: items),
            ],
          ),
        );
      },
    );
  }
}

/// Горизонтальная полоса картинок коллекций (без карточек и подписей).
class CollectionShowcaseGrid extends StatelessWidget {
  const CollectionShowcaseGrid({
    super.key,
    required this.items,
    this.emptyText = 'Коллекций пока нет',
    this.titleOnlyOnTap = true,
  });

  final List<InventoryItem> items;
  final String emptyText;
  final bool titleOnlyOnTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final it = items[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showCollectionFullscreen(
              context,
              title: it.title,
              animatedName: it.animatedName ?? 'sparkles',
              fallback: it.emoji,
              subtitle: titleOnlyOnTap
                  ? null
                  : collectionItemSubtitle(it.dailyBronze),
            ),
            child: SizedBox(
              width: 52,
              height: 56,
              child: Center(
                child: ShopAnimatedEmoji(
                  animatedName: it.animatedName ?? 'sparkles',
                  size: 44,
                  fallback: it.emoji,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
