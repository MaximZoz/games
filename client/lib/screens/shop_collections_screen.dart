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

/// Хаб коллекций — список групп (как «Эмоции» у смайликов).
class ShopCollectionsScreen extends ConsumerStatefulWidget {
  const ShopCollectionsScreen({super.key});

  @override
  ConsumerState<ShopCollectionsScreen> createState() =>
      _ShopCollectionsScreenState();
}

class _ShopCollectionsScreenState extends ConsumerState<ShopCollectionsScreen> {
  List<ShopItem> _items = const [];

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

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    // Слушаем каталог: после покупки в группе хаб остаётся в стеке и должен
    // сразу подхватить owned, а не держать устаревший _items.
    ref.listen<AsyncValue<List<ShopItem>>>(shopCatalogProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null && mounted) {
        setState(() => _items = data);
      }
    });
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = cached ?? _items;
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

    final orderedSets = bySet.keys.toList()
      ..sort((a, b) {
        final aItems = bySet[a]!;
        final bItems = bySet[b]!;
        final aDaily = aItems.fold<int>(0, (s, e) => s + e.dailyBronze);
        final bDaily = bItems.fold<int>(0, (s, e) => s + e.dailyBronze);
        final aPrice = aItems.fold<int>(0, (s, e) => s + e.priceBronze);
        final bPrice = bItems.fold<int>(0, (s, e) => s + e.priceBronze);
        // Цена за 1 бронзу дохода в день (меньше = выгоднее).
        final aRatio = aDaily <= 0
            ? double.infinity
            : aPrice / aDaily;
        final bRatio = bDaily <= 0
            ? double.infinity
            : bPrice / bDaily;
        final byRatio = aRatio.compareTo(bRatio);
        if (byRatio != 0) return byRatio;
        final ai = collectionSetOrder.indexOf(a);
        final bi = collectionSetOrder.indexOf(b);
        return (ai < 0 ? 999 : ai).compareTo(bi < 0 ? 999 : bi);
      });

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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: orderedSets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final set = orderedSets[index];
                    final groupItems = bySet[set]!;
                    final preview = groupItems.first;
                    final setDaily = groupItems.fold<int>(
                      0,
                      (sum, e) => sum + e.dailyBronze,
                    );
                    final ownedCount = groupItems.where((e) => e.owned).length;
                    return Material(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await context.push('/shop/collections/$set');
                          if (!mounted) return;
                          ref.invalidate(shopCatalogProvider);
                          await _reloadSilent();
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              ShopAnimatedEmoji(
                                animatedName: preview.animatedName ?? 'sparkles',
                                size: 40,
                                fallback: preview.emoji,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      collectionSetTitle(set),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$ownedCount/${groupItems.length} · '
                                      'бонус группы +${formatRewardBronzePerDay(setDaily)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Предметы одной группы коллекций.
class ShopCollectionGroupScreen extends ConsumerStatefulWidget {
  const ShopCollectionGroupScreen({super.key, required this.set});

  final String set;

  @override
  ConsumerState<ShopCollectionGroupScreen> createState() =>
      _ShopCollectionGroupScreenState();
}

class _ShopCollectionGroupScreenState
    extends ConsumerState<ShopCollectionGroupScreen> {
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
          'Цена: ${formatRewardBronze(item.priceBronze)}\n'
          'Доход: +${formatRewardBronzePerDay(item.dailyBronze)}\n'
          'Покупка один раз\n'
          'Продажа: ${formatRewardBronze(item.sellRefundBronze)} (80%)',
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
      // Дождаться свежего каталога, чтобы хаб групп сразу увидел счётчик.
      try {
        final fresh = await ref.read(shopCatalogProvider.future);
        if (mounted) setState(() => _items = fresh);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} добавлен в профиль'),
          behavior: SnackBarBehavior.floating,
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
    final groupItems = items
        .where((e) =>
            e.kind == 'collection' && (e.collectionSet ?? 'other') == widget.set)
        .toList()
      ..sort((a, b) {
        final byPrice = a.priceBronze.compareTo(b.priceBronze);
        if (byPrice != 0) return byPrice;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    final setDaily =
        groupItems.fold<int>(0, (sum, e) => sum + e.dailyBronze);
    final ownedCount = groupItems.where((e) => e.owned).length;
    final complete =
        ownedCount == groupItems.length && groupItems.isNotEmpty;

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
            collectionSetTitle(widget.set),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: groupItems.isEmpty
              ? const Center(
                  child: Text(
                    'Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: groupItems.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        complete
                            ? 'Собрано · бонус группы +${formatRewardBronzePerDay(setDaily)}'
                            : 'Собрано $ownedCount/${groupItems.length} · '
                                'бонус группы +${formatRewardBronzePerDay(setDaily)} при полном наборе',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    final item = groupItems[index - 1];
                    return _CollectionShopCard(
                      item: item,
                      busy: _buyInFlight.contains(item.code),
                      onBuy: () => _buy(item),
                      onPreview: () => showCollectionFullscreen(
                        context,
                        title: item.title,
                        animatedName: item.animatedName ?? 'sparkles',
                        fallback: item.emoji,
                        subtitle: collectionItemSubtitle(item.dailyBronze),
                        bottomAction: item.owned
                            ? null
                            : Builder(
                                builder: (dialogContext) => FilledButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    unawaited(_buy(item));
                                  },
                                  child: const Text('Купить'),
                                ),
                              ),
                      ),
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

  static String _priceAmountLabel(int bronze) =>
      '${rewardCoinAmount(bronze)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
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
                  collectionItemSubtitle(item.dailyBronze),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CoinIcon(
                      coinType: rewardCoinType(item.priceBronze),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _priceAmountLabel(item.priceBronze),
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
                color: Color(0xFF2E7D32),
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
