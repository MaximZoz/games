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

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
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

  List<ShopItem> _sortedSection(List<ShopItem> all, String kind) {
    final section = all.where((e) => e.kind == kind).toList();
    section.sort((a, b) {
      if (a.owned != b.owned) return a.owned ? 1 : -1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return section;
  }

  Future<void> _buy(ShopItem item) async {
    if (_buyInFlight.contains(item.code) || item.owned) return;
    _buyInFlight.add(item.code);
    final previous = _items;
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
      ref.invalidate(inventoryCapabilitiesProvider);
      ref.invalidate(shopCatalogProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _items = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _buyInFlight.remove(item.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = _items.isNotEmpty ? _items : (cached ?? const <ShopItem>[]);
    final emojis = _sortedSection(items, 'emoji');
    final frames = _sortedSection(items, 'frame');
    final stakes = _sortedSection(items, 'stake_unlock');

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
            'Магазин',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _ShopSection(
                      title: 'Смайлики',
                      items: emojis,
                      onBuy: _buy,
                    ),
                    const SizedBox(height: 16),
                    _ShopSection(
                      title: 'Рамки',
                      items: frames,
                      onBuy: _buy,
                    ),
                    const SizedBox(height: 16),
                    _ShopSection(
                      title: 'Ставки',
                      items: stakes,
                      onBuy: _buy,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({
    required this.title,
    required this.items,
    required this.onBuy,
  });

  final String title;
  final List<ShopItem> items;
  final Future<void> Function(ShopItem) onBuy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text(
            'Пока нет товаров',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ShopCard(
              item: items[i],
              onBuy: items[i].owned
                  ? null
                  : () => unawaited(onBuy(items[i])),
            ),
          ],
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.item, required this.onBuy});

  final ShopItem item;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final leading = switch (item.kind) {
      'emoji' => ShopAnimatedEmoji(
          animatedName: item.animatedName ?? 'smile',
          size: 32,
          fallback: item.emoji,
        ),
      'stake_unlock' => const CoinIcon(coinType: CoinType.silver, size: 28),
      'frame' => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _parseColor(item.frameColor) ?? AppColors.accentStart,
              width: 3,
            ),
          ),
        ),
      _ => const Icon(Icons.shopping_bag_outlined),
    };

    final subtitle = switch (item.kind) {
      'stake_unlock' =>
        'Ставка ${item.stakeSilver ?? (item.stakeBronze ?? 0) ~/ 100} серебра',
      _ => item.description,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          leading,
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (item.owned)
            Text(
              'Куплено',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            FilledButton(
              onPressed: onBuy,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentStart,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: const Size(0, 40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _priceLabel(item.priceBronze),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  CoinIcon(
                    coinType: _priceCoinType(item.priceBronze),
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _priceLabel(int bronze) {
    if (bronze >= 10000 && bronze % 10000 == 0) return '${bronze ~/ 10000}';
    if (bronze >= 100 && bronze % 100 == 0) return '${bronze ~/ 100}';
    return '$bronze';
  }

  CoinType _priceCoinType(int bronze) {
    if (bronze >= 10000) return CoinType.gold;
    if (bronze >= 100) return CoinType.silver;
    return CoinType.bronze;
  }
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(v);
}
