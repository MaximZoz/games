import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/vertical_paged_slider.dart';

const shopEmojiGroupTitles = <String, String>{
  'emotions': 'Эмоции',
  'game': 'Игровые',
  'flags': 'Флажки',
};

/// Порядок групп на витрине смайликов.
const shopEmojiGroupOrder = <String>['emotions', 'game', 'flags'];

String shopEmojiGroupTitle(String group) =>
    shopEmojiGroupTitles[group] ?? group;

/// Список групп смайликов с превью.
class ShopEmojisScreen extends ConsumerStatefulWidget {
  const ShopEmojisScreen({super.key});

  @override
  ConsumerState<ShopEmojisScreen> createState() => _ShopEmojisScreenState();
}

class _ShopEmojisScreenState extends ConsumerState<ShopEmojisScreen> {
  List<ShopItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = ref.read(shopCatalogProvider).valueOrNull;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _items = cached;
          _loading = false;
        });
      }
      unawaited(_reloadSilent());
    });
  }

  Future<void> _reloadSilent() async {
    try {
      final items = await ref.read(shopRepositoryProvider).listShop();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = _items.isNotEmpty ? _items : (cached ?? const <ShopItem>[]);
    final byGroup = <String, List<ShopItem>>{};
    for (final e in items) {
      if (e.kind != 'emoji') continue;
      final g = (e.group ?? '').trim();
      if (g.isEmpty) continue;
      byGroup.putIfAbsent(g, () => []).add(e);
    }
    for (final list in byGroup.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    final groupKeys = [
      ...shopEmojiGroupOrder.where(byGroup.containsKey),
      ...byGroup.keys.where((k) => !shopEmojiGroupOrder.contains(k)),
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
          child: _loading && groupKeys.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : groupKeys.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока пусто',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: groupKeys.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = groupKeys[index];
                        final groupItems = byGroup[group]!;
                        final price = groupItems
                            .map((e) => e.priceBronze)
                            .fold<int>(
                                groupItems.first.priceBronze, math.min);
                        return Material(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/shop/emojis/$group'),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 14, 12, 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ShopEmojiGroupIcon(group: group, size: 40),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shopEmojiGroupTitle(group),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${groupItems.length} смайликов · по ${formatRewardBronze(price)}',
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

/// Эмоции: вертикальные страницы по 9 карточек, точки справа.
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = ref.read(shopCatalogProvider).valueOrNull;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _items = cached;
          _loading = false;
        });
      }
      unawaited(_reloadSilent());
    });
  }

  Future<void> _reloadSilent() async {
    try {
      final items = await ref.read(shopRepositoryProvider).listShop();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<bool> _confirmBuy(ShopItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Купить смайлик?'),
          content: Text(
            '${item.title}\n\n'
            'Цена: ${formatRewardBronze(item.priceBronze)}\n'
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

  void _showPurchased(ShopItem item) {
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: '${item.title}: +10 использований',
      kind: AppSnackKind.success,
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
      _showPurchased(item);
      unawaited(_reloadSilent());
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _openPreview(ShopItem item) async {
    await showCollectionFullscreen(
      context,
      title: item.title,
      animatedName: item.animatedName ?? 'smile',
      fallback: item.emoji,
      subtitle: '${formatRewardBronze(item.priceBronze)} · 10 использований',
      bottomAction: Builder(
        builder: (dialogContext) => FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            unawaited(_buy(item));
          },
          child: const Text('Купить'),
        ),
      ),
    );
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
          child: _loading && emojis.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : emojis.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока пусто',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : VerticalPagedSlider(
                  pageCount: pageCount,
                  itemBuilder: (context, page) {
                    final start = page * _pageSize;
                    final end = math.min(start + _pageSize, emojis.length);
                    final pageItems = emojis.sublist(start, end);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const cols = 3;
                          const rows = 3;
                          const gap = 8.0;
                          final cellW =
                              (constraints.maxWidth - gap * (cols - 1)) / cols;
                          final cellH =
                              (constraints.maxHeight - gap * (rows - 1)) / rows;
                          final ratio =
                              cellH <= 0 ? 0.78 : (cellW / cellH).clamp(0.55, 1.15);
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: gap,
                              crossAxisSpacing: gap,
                              childAspectRatio: ratio,
                            ),
                            itemCount: pageItems.length,
                            itemBuilder: (context, index) {
                              final item = pageItems[index];
                              return _EmojiBuyTile(
                                item: item,
                                busy: _buyInFlight.contains(item.code),
                                onPreview: () => _openPreview(item),
                                onBuy: () => _buy(item),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
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
    required this.onPreview,
    required this.onBuy,
  });

  final ShopItem item;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final name = (item.animatedName ?? '').trim();
    final fallback = item.emoji ?? '🙂';

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: name.isEmpty
                      ? Text(fallback, style: const TextStyle(fontSize: 30))
                      : ShopAnimatedEmoji(
                          animatedName: name,
                          size: 36,
                          fallback: fallback,
                        ),
                ),
              ),
            ),
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
            const SizedBox(height: 2),
            InkWell(
              onTap: busy ? null : onBuy,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BalanceDisplay(
                          bronze: item.priceBronze,
                          coinSize: 11,
                          fontSize: 11,
                          spacing: 4,
                        ),
                      ],
                    ),
                    Text(
                      busy ? '…' : 'Купить · 10 шт.',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
