import 'package:flutter/material.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
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
    'Коллекция · витрина · подарок · продажа · +$dailyBronze бронзы/день';

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
                    // Не закрывать при тапе по кнопке «Купить».
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

class CollectionShowcaseGrid extends StatelessWidget {
  const CollectionShowcaseGrid({
    super.key,
    required this.items,
    this.emptyText = 'Коллекций пока нет',
  });

  final List<InventoryItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final it in items)
          Material(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showCollectionFullscreen(
                context,
                title: it.title,
                animatedName: it.animatedName ?? 'sparkles',
                fallback: it.emoji,
                subtitle: collectionItemSubtitle(it.dailyBronze),
              ),
              child: Container(
                width: 88,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    ShopAnimatedEmoji(
                      animatedName: it.animatedName ?? 'sparkles',
                      size: 42,
                      fallback: it.emoji,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      it.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (it.dailyBronze > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CoinIcon(coinType: CoinType.bronze, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '+${it.dailyBronze}/день',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
