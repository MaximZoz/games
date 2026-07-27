import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/vertical_paged_slider.dart';

const _setOrder = [
  'legends',
  'cosmic',
  'jewels',
  'celebration',
  'nature',
  'adventure',
];

/// Магазин коллекций: одна группа = один экран, сортировка по цене внутри.
class ShopCollectionsScreen extends ConsumerStatefulWidget {
  const ShopCollectionsScreen({super.key});

  @override
  ConsumerState<ShopCollectionsScreen> createState() =>
      _ShopCollectionsScreenState();
}

class _ShopCollectionsScreenState extends ConsumerState<ShopCollectionsScreen> {
  List<ShopItem> _items = const [];
  final Set<String> _buyInFlight = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = ref.read(shopCatalogProvider).valueOrNull;
      if (cached != null && cached.isNotEmpty) {
        setState(() => _items = cached);
      }
      unawaited(_reloadSilent());
    });
  }

  Future<void> _reloadSilent() async {
    try {
      final items = await ref.read(shopRepositoryProvider).listShop();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {}
  }

  Future<void> _buy(ShopItem item) async {
    if (_buyInFlight.contains(item.code) || item.owned) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Купить коллекцию?'),
        content: Text(
          '${item.title}\n\n'
          'Цена: ${item.priceBronze} бронзы\n'
          'Доход: +${item.weeklyBronze} бронзы в неделю\n'
          'Покупка один раз\n'
          'Продажа: ${item.sellRefundBronze} бронзы (80%)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Купить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    _buyInFlight.add(item.code);
    setState(() {
      _items = [
        for (final it in _items)
          if (it.code == item.code) it.copyWith(owned: true) else it,
      ];
    });
    try {
      final result = await ref.read(shopRepositoryProvider).buy(item.code);
      await ref.read(authStateProvider.notifier).applyBalance(result.balanceBronze);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(shopCatalogProvider);
      ref.invalidate(collectionIncomeProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Куплено'),
          content: Text('${item.title} добавлен в профиль'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [
          for (final it in _items)
            if (it.code == item.code) it.copyWith(owned: false) else it,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _buyInFlight.remove(item.code);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = _items.isNotEmpty ? _items : (cached ?? const <ShopItem>[]);
    final collections = items.where((e) => e.kind == 'collection').toList();

    final bySet = <String, List<ShopItem>>{};
    for (final e in collections) {
      final s = (e.collectionSet ?? 'other').trim();
      bySet.putIfAbsent(s.isEmpty ? 'other' : s, () => []).add(e);
    }
    for (final list in bySet.values) {
      list.sort((a, b) {
        final byPrice = a.priceBronze.compareTo(b.priceBronze);
        if (byPrice != 0) return byPrice;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    }

    final orderedSets = <String>[
      ..._setOrder.where(bySet.containsKey),
      ...bySet.keys.where((k) => !_setOrder.contains(k)),
    ];

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
            tooltip: 'Назад',
          ),
          title: Text(
            'Коллекции',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: orderedSets.isEmpty
              ? const Center(
                  child: Text(
                    'Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : VerticalPagedSlider(
                  pageCount: orderedSets.length,
                  itemBuilder: (context, page) {
                    final set = orderedSets[page];
                    final pageItems = bySet[set]!;
                    final setWeekly = pageItems.fold<int>(
                      0,
                      (sum, e) => sum + e.weeklyBronze,
                    );
                    final ownedCount =
                        pageItems.where((e) => e.owned).length;
                    final complete = ownedCount == pageItems.length &&
                        pageItems.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collectionSetTitles[set] ?? set,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                complete
                                    ? 'Собрано · бонус группы +$setWeekly бронзы/нед.'
                                    : 'Собрано $ownedCount/${pageItems.length} · '
                                        'бонус группы +$setWeekly при полном наборе',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 4, 16),
                            itemCount: pageItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = pageItems[index];
                              return _CollectionShopCard(
                                item: item,
                                busy: _buyInFlight.contains(item.code),
                                onBuy: () => _buy(item),
                                onPreview: () => showCollectionFullscreen(
                                  context,
                                  title: item.title,
                                  animatedName:
                                      item.animatedName ?? 'sparkles',
                                  fallback: item.emoji,
                                  subtitle: item.description,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _CollectionShopCard extends StatelessWidget {
  const _CollectionShopCard({
    required this.item,
    required this.busy,
    required this.onBuy,
    required this.onPreview,
  });

  final ShopItem item;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onPreview,
            borderRadius: BorderRadius.circular(12),
            child: ShopAnimatedEmoji(
              animatedName: item.animatedName ?? 'sparkles',
              size: 52,
              fallback: item.emoji,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${item.weeklyBronze} бронзы / нед. · продажа ${item.sellRefundBronze}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CoinIcon(coinType: CoinType.bronze, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item.priceBronze}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.owned)
            const Text(
              'Куплено',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          else
            FilledButton(
              onPressed: busy ? null : onBuy,
              child: Text(busy ? '…' : 'Купить'),
            ),
        ],
      ),
    );
  }
}
