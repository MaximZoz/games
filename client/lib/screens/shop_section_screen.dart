import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Раздел магазина для рамок или ставок (одноразовая покупка).
class ShopSectionScreen extends ConsumerStatefulWidget {
  const ShopSectionScreen({
    super.key,
    required this.title,
    required this.kind,
  });

  final String title;
  final String kind;

  @override
  ConsumerState<ShopSectionScreen> createState() => _ShopSectionScreenState();
}

class _ShopSectionScreenState extends ConsumerState<ShopSectionScreen> {
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

  List<ShopItem> _section(List<ShopItem> all) {
    final section = all.where((e) => e.kind == widget.kind).toList();
    section.sort((a, b) {
      if (a.owned != b.owned) return a.owned ? 1 : -1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return section;
  }

  Future<bool> _confirmBuy(ShopItem item) async {
    final isStake = item.kind == 'stake_unlock';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isStake ? 'Купить ставку?' : 'Купить?'),
          content: Text(
            '${item.title}\n\n'
            'Цена: ${formatRewardBronze(item.priceBronze)}',
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
        );
      },
    );
    return result == true;
  }

  Future<void> _buy(ShopItem item) async {
    if (_buyInFlight.contains(item.code) || item.owned) return;
    final ok = await _confirmBuy(item);
    if (!ok || !mounted) return;

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
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: '${item.title} куплен',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _items = previous);
      showAppSnackBar(
        context,
        message: e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), ''),
        kind: AppSnackKind.error,
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
    final section = _section(items);

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
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: section.isEmpty
              ? const Center(
                  child: Text(
                    'Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: section.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = section[index];
                    return _ShopItemCard(
                      item: item,
                      busy: _buyInFlight.contains(item.code),
                      onBuy: () => _buy(item),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.busy,
    required this.onBuy,
  });

  final ShopItem item;
  final bool busy;
  final VoidCallback onBuy;

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
          _preview(item),
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
                if (item.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                BalanceDisplay(
                  bronze: item.priceBronze,
                  coinSize: 14,
                  fontSize: 13,
                  spacing: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _preview(ShopItem item) {
    if (item.kind == 'frame') {
      final hex = (item.frameColor ?? '#B87333').replaceFirst('#', '');
      final color = Color(int.parse('FF$hex', radix: 16));
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          color: AppColors.surfaceCard,
        ),
        child: Icon(Icons.person, color: color.withValues(alpha: 0.85), size: 22),
      );
    }
    if (item.kind == 'stake_unlock') {
      final stake = item.stakeSilver ?? item.stakeBronze ?? '?';
      return Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Text(
          '$stake',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }
    return const SizedBox(width: 48, height: 48);
  }
}
