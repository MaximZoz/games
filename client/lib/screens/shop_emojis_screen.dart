import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

const _groupTitles = <String, String>{
  'emotions': 'Эмоции',
  'animals': 'Животные',
  'food': 'Еда и напитки',
  'travel': 'Путешествия',
  'party': 'Праздник и спорт',
  'objects': 'Предметы',
};

const _groupOrder = [
  'emotions',
  'animals',
  'food',
  'travel',
  'party',
  'objects',
];

/// Покупка отдельных анимированных смайликов, сгруппированных по темам.
class ShopEmojisScreen extends ConsumerStatefulWidget {
  const ShopEmojisScreen({super.key});

  @override
  ConsumerState<ShopEmojisScreen> createState() => _ShopEmojisScreenState();
}

class _ShopEmojisScreenState extends ConsumerState<ShopEmojisScreen> {
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
    if (_buyInFlight.contains(item.code)) return;
    _buyInFlight.add(item.code);
    try {
      final result = await ref.read(shopRepositoryProvider).buy(item.code);
      await ref.read(authStateProvider.notifier).applyBalance(result.balanceBronze);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryCapabilitiesProvider);
      ref.invalidate(shopCatalogProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Куплено: ${item.title} (+10 шт.)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      unawaited(_reloadSilent());
    } catch (e) {
      if (!mounted) return;
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
    final emojis = items.where((e) => e.kind == 'emoji').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final byGroup = <String, List<ShopItem>>{};
    for (final e in emojis) {
      final g = (e.payload['group'] as String?)?.trim() ?? 'other';
      byGroup.putIfAbsent(g, () => []).add(e);
    }

    final orderedGroups = <String>[
      ..._groupOrder.where(byGroup.containsKey),
      ...byGroup.keys.where((k) => !_groupOrder.contains(k)),
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
            'Смайлики',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: emojis.isEmpty
              ? const Center(
                  child: Text(
                    'Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final group in orderedGroups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                        child: Text(
                          _groupTitles[group] ?? group,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final item in byGroup[group]!)
                            _EmojiBuyTile(
                              item: item,
                              busy: _buyInFlight.contains(item.code),
                              onBuy: () => _buy(item),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmojiBuyTile extends StatelessWidget {
  const _EmojiBuyTile({
    required this.item,
    required this.busy,
    required this.onBuy,
  });

  final ShopItem item;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final name = (item.animatedName ?? '').trim();
    final fallback = item.emoji ?? '🙂';

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onBuy,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 108,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                child: name.isEmpty
                    ? Text(fallback, style: const TextStyle(fontSize: 30))
                    : ShopAnimatedEmoji(
                        animatedName: name,
                        size: 36,
                        fallback: fallback,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(coinType: CoinType.bronze, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${item.priceBronze}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                busy ? '…' : '10 шт.',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
