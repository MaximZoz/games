import 'dart:async';
import 'dart:math' as math;

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

const shopEmojiGroupTitles = <String, String>{
  'emotions': 'Эмоции',
};

String shopEmojiGroupTitle(String group) =>
    shopEmojiGroupTitles[group] ?? group;

/// Список групп смайликов — сейчас только «Эмоции», один превью-смайлик.
class ShopEmojisScreen extends ConsumerStatefulWidget {
  const ShopEmojisScreen({super.key});

  @override
  ConsumerState<ShopEmojisScreen> createState() => _ShopEmojisScreenState();
}

class _ShopEmojisScreenState extends ConsumerState<ShopEmojisScreen> {
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
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = _items.isNotEmpty ? _items : (cached ?? const <ShopItem>[]);
    final emotions = items
        .where((e) => e.kind == 'emoji' && (e.group ?? '') == 'emotions')
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final preview = emotions.isEmpty ? null : emotions.first;

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
          child: preview == null
              ? const Center(
                  child: Text(
                    'Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Material(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/shop/emojis/emotions'),
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
                                animatedName: preview.animatedName ?? 'smile',
                                size: 40,
                                fallback: preview.emoji,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Эмоции',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${emotions.length} смайликов · по 30 бронзы',
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
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Эмоции: страницы по 9 карточек с плавным листанием.
class ShopEmojiGroupScreen extends ConsumerStatefulWidget {
  const ShopEmojiGroupScreen({super.key, required this.group});

  final String group;

  @override
  ConsumerState<ShopEmojiGroupScreen> createState() =>
      _ShopEmojiGroupScreenState();
}

class _ShopEmojiGroupScreenState extends ConsumerState<ShopEmojiGroupScreen> {
  static const _pageSize = 9;

  List<ShopItem> _items = const [];
  final Set<String> _buyInFlight = {};
  final PageController _pageController = PageController();
  int _pageIndex = 0;

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _reloadSilent() async {
    try {
      final items = await ref.read(shopRepositoryProvider).listShop();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {}
  }

  Future<bool> _confirmBuy(ShopItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Купить смайлик?'),
          content: Text(
            '${item.title}\n\n'
            'Цена: ${item.priceBronze} бронзы\n'
            'Получите: 10 использований',
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

  Future<void> _showPurchased(ShopItem item) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Куплено'),
          content: Text('${item.title}: +10 использований'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ОК'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _buy(ShopItem item) async {
    if (_buyInFlight.contains(item.code)) return;
    final ok = await _confirmBuy(item);
    if (!ok || !mounted) return;

    _buyInFlight.add(item.code);
    setState(() {});
    try {
      final result = await ref.read(shopRepositoryProvider).buy(item.code);
      await ref.read(authStateProvider.notifier).applyBalance(result.balanceBronze);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryCapabilitiesProvider);
      ref.invalidate(shopCatalogProvider);
      if (!mounted) return;
      await _showPurchased(item);
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
    final emojis = items
        .where((e) => e.kind == 'emoji' && (e.group ?? 'other') == widget.group)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final pageCount =
        emojis.isEmpty ? 0 : ((emojis.length + _pageSize - 1) / _pageSize).floor();

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
            shopEmojiGroupTitle(widget.group),
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
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pageCount,
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        physics: const BouncingScrollPhysics(
                          parent: PageScrollPhysics(),
                        ),
                        itemBuilder: (context, page) {
                          final start = page * _pageSize;
                          final end = math.min(start + _pageSize, emojis.length);
                          final pageItems = emojis.sublist(start, end);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final item = pageItems[index];
                                return _EmojiBuyTile(
                                  item: item,
                                  busy: _buyInFlight.contains(item.code),
                                  onBuy: () => _buy(item),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    if (pageCount > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < pageCount; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: i == _pageIndex ? 18 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: i == _pageIndex
                                      ? AppColors.accentStart
                                      : AppColors.accentSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                          ],
                        ),
                      ),
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
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: name.isEmpty
                      ? Text(fallback, style: const TextStyle(fontSize: 34))
                      : ShopAnimatedEmoji(
                          animatedName: name,
                          size: 42,
                          fallback: fallback,
                        ),
                ),
              ),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
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
