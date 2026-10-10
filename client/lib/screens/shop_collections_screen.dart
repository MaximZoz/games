import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_condition.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/pending_purchases.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_section_help.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';

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
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    });
  }

  Future<void> _reloadSilent() async {
    try {
      final List<ShopItem> items;
      if (ref.read(isOfflineProvider)) {
        items = await ref.read(shopCatalogProvider.future);
      } else {
        items = await ref.read(shopRepositoryProvider).listShop();
        final user = ref.read(authStateProvider).valueOrNull;
        if (user != null && items.isNotEmpty) {
          await OfflineDiskCache.saveShop(user.id, items);
        }
      }
      if (!mounted) return;
      setState(() => _items = items);
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    // Слушаем каталог: после покупки в группе хаб остаётся в стеке и должен
    // сразу подхватить owned, а не держать устаревший _items.
    ref.listen<AsyncValue<List<ShopItem>>>(shopCatalogProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null && data.isNotEmpty && mounted) {
        setState(() => _items = data);
      }
    });
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = (cached != null && cached.isNotEmpty) ? cached : _items;
    final collections = items
        .where(
            (e) => e.kind == 'collection' && !isRetiredCollectionItem(e.code))
        .toList();

    final bySet = <String, List<ShopItem>>{};
    for (final e in collections) {
      final s = (e.collectionSet ?? 'other').trim();
      bySet.putIfAbsent(s.isEmpty ? 'other' : s, () => []).add(e);
    }
    for (final list in bySet.values) {
      list.sort((a, b) => compareCollectionItemsByDaily(
            a.dailyBronze,
            b.dailyBronze,
            a.sortOrder,
            b.sortOrder,
          ));
    }

    final orderedSets = bySet.keys.toList()
      ..sort((a, b) => compareCollectionSetsByDaily(
            a,
            b,
            collectionSetBonusBronze,
          ));

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GamepadBackButton(
            onPressed: goBack,
            tooltip: context.l10n.commonBack,
          ),
          title: Text(
            context.l10n.shopCollections,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          actions: [
            ShopSectionHelpButton(
              title: context.l10n.shopCollections,
              body: context.l10n.shopCollectionsHelp,
              showConditionScale: true,
            ),
          ],
        ),
        body: SafeArea(
          child: orderedSets.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.shopEmpty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : DesktopTileGrid(
                  itemCount: orderedSets.length,
                  maxCellWidth: isPhoneLandscape(context) ? 240 : 320,
                  maxContentWidth: 1100,
                  maxColumns: 3,
                  padding: EdgeInsets.fromLTRB(
                    isPhoneLandscape(context) ? 12 : 16,
                    8,
                    isPhoneLandscape(context) ? 12 : 16,
                    24,
                  ),
                  itemBuilder: (context, index) => _buildCollectionSetTile(
                    context,
                    orderedSets[index],
                    bySet,
                  ),
                  mobileBuilder: (context) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: orderedSets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildCollectionSetTile(
                          context,
                          orderedSets[index],
                          bySet,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCollectionSetTile(
    BuildContext context,
    String set,
    Map<String, List<ShopItem>> bySet,
  ) {
    final groupItems = bySet[set]!;
    final preview = groupItems.first;
    final setDaily = shopSetDaily(set, groupItems);
    final ownedCount = groupItems.where((e) => e.owned).length;
    Future<void> openSet() async {
      await context.push('/shop/collections/$set');
      if (!mounted) return;
      ref.invalidate(shopCatalogProvider);
      await _reloadSilent();
    }

    return GamepadFocusBlock(
      radius: 16,
      onActivate: () => unawaited(openSet()),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(16),
          onTap: () => unawaited(openSet()),
          child: Builder(
            builder: (inner) {
              return Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: GamepadFocusBlock.frameColor(
                      inner,
                      Colors.black.withValues(alpha: 0.06),
                    ),
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
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                context.l10n.shopSetProgress(
                                  ownedCount,
                                  groupItems.length,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (setDaily > 0) ...[
                                Text(
                                  '·',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                BalanceDisplay(
                                  bronze: setDaily,
                                  prefix: ownedCount >= groupItems.length
                                      ? '+'
                                      : null,
                                  perDay: true,
                                  coinSize: 14,
                                  fontSize: 12,
                                  spacing: 4,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  opacity: ownedCount >= groupItems.length
                                      ? 1
                                      : 0.35,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    ShopSectionHelpButton(
                      title: collectionSetTitle(set),
                      body: context.l10n.shopCollectionsHelp,
                      showConditionScale: true,
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
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
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    });
  }

  Future<void> _reloadSilent() async {
    try {
      final List<ShopItem> items;
      if (ref.read(isOfflineProvider)) {
        items = await ref.read(shopCatalogProvider.future);
      } else {
        items = await ref.read(shopRepositoryProvider).listShop();
        final user = ref.read(authStateProvider).valueOrNull;
        if (user != null && items.isNotEmpty) {
          await OfflineDiskCache.saveShop(user.id, items);
        }
      }
      if (!mounted) return;
      setState(() => _items = items);
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    } catch (_) {}
  }

  Future<bool> _buy(
    ShopItem item, {
    bool confirm = true,
    bool announceOwned = true,
  }) async {
    if (_buyInFlight.contains(item.code) || item.owned) return false;
    final l10n = context.l10n;
    if (confirm) {
      final ok = await showGamepadConfirmDialog(
        context: context,
        title: l10n.shopBuyCollectionTitle,
        message:
            '${catalogTitle(item.code, fallback: item.title, l10n: l10n)}\n\n'
            '${l10n.shopPrice(formatRewardBronze(item.priceBronze))}\n'
            '${l10n.shopDailyIncome('+${formatRewardBronzePerDay(item.dailyBronze)}')}\n'
            '${l10n.shopBuyOnce}',
        confirmLabel: l10n.shopBuy,
      );
      if (!ok || !mounted) return false;
    }

    _buyInFlight.add(item.code);
    setState(() {
      _items = [
        for (final it in _items)
          if (it.code == item.code) it.copyWith(owned: true) else it,
      ];
    });
    try {
      final wasOffline = ref.read(isOfflineProvider);
      await ref.read(pendingPurchasesProvider.notifier).buyOrQueue(item.code);
      if (!wasOffline) {
        ref.invalidate(inventoryListProvider);
        ref.invalidate(shopCatalogProvider);
        ref.invalidate(collectionIncomeProvider);
        try {
          final fresh = await ref.read(shopCatalogProvider.future);
          if (mounted) setState(() => _items = fresh);
        } catch (_) {}
      }
      if (!mounted) return false;
      if (wasOffline) {
        showAppSnackBar(
          context,
          message: context.l10n.shopPurchaseQueued,
          kind: AppSnackKind.success,
        );
      } else if (announceOwned) {
        await showGamepadOwnedDialog(
          context: context,
          message:
              catalogTitle(item.code, fallback: item.title, l10n: context.l10n),
        );
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _items = [
          for (final it in _items)
            if (it.code == item.code) it.copyWith(owned: false) else it,
        ];
      });
      showAppSnackBar(
        context,
        message: e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), ''),
        kind: AppSnackKind.error,
      );
      return false;
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
            e.kind == 'collection' &&
            (e.collectionSet ?? 'other') == widget.set)
        .toList()
      ..sort((a, b) => compareCollectionItemsByDaily(
            a.dailyBronze,
            b.dailyBronze,
            a.sortOrder,
            b.sortOrder,
          ));

    final setDaily = shopSetDaily(widget.set, groupItems);
    final ownedCount = groupItems.where((e) => e.owned).length;
    final complete = ownedCount == groupItems.length && groupItems.isNotEmpty;

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GamepadBackButton(
            onPressed: goBack,
            tooltip: context.l10n.commonBack,
          ),
          title: Text(
            collectionSetTitle(widget.set),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          actions: [
            ShopSectionHelpButton(
              title: collectionSetTitle(widget.set),
              body: context.l10n.shopCollectionsHelp,
              showConditionScale: true,
            ),
          ],
        ),
        body: SafeArea(
          child: groupItems.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.shopEmpty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : _buildCollectionGroupBody(
                  groupItems: groupItems,
                  complete: complete,
                  ownedCount: ownedCount,
                  setDaily: setDaily,
                ),
        ),
      ),
    );
  }

  Widget _collectionProgressHeader({
    required bool complete,
    required int ownedCount,
    required int total,
    required int setDaily,
  }) {
    final l10n = context.l10n;
    return Row(
      children: [
        Flexible(
          child: Text(
            complete
                ? l10n.shopSetComplete
                : l10n.shopSetProgress(ownedCount, total),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (setDaily > 0) ...[
          const SizedBox(width: 8),
          BalanceDisplay(
            bronze: setDaily,
            prefix: complete ? '+' : null,
            perDay: true,
            coinSize: 14,
            fontSize: 12,
            spacing: 4,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            opacity: complete ? 1 : 0.32,
          ),
        ],
      ],
    );
  }

  Widget _collectionShopCardFor(ShopItem item) {
    return _CollectionShopCard(
      item: item,
      busy: _buyInFlight.contains(item.code),
      onBuy: () => _buy(item),
      onPreview: () => showCollectionFullscreen(
        context,
        title:
            catalogTitle(item.code, fallback: item.title, l10n: context.l10n),
        animatedName: item.animatedName ?? 'sparkles',
        fallback: item.emoji,
        subtitle: collectionItemSubtitle(shopCollectionDaily(item)),
        condition: item.owned ? null : CollectionCondition.fresh,
        acquiredAt:
            item.owned ? parseCollectionAcquiredAt(item.acquiredAt) : null,
        conditionShift: item.conditionShift,
        vintageAt: parseCollectionAcquiredAt(item.vintageAt),
        onBuy: item.owned
            ? null
            : () async {
                final bought =
                    await _buy(item, confirm: true, announceOwned: false);
                if (!bought || !mounted) return;
                Navigator.of(context).pop();
                if (!mounted) return;
                await showGamepadOwnedDialog(
                  context: context,
                  message: catalogTitle(item.code,
                      fallback: item.title, l10n: context.l10n),
                );
              },
        buyLabel: context.l10n.shopBuy,
      ),
    );
  }

  Widget _buildCollectionGroupBody({
    required List<ShopItem> groupItems,
    required bool complete,
    required int ownedCount,
    required int setDaily,
  }) {
    final progress = _collectionProgressHeader(
      complete: complete,
      ownedCount: ownedCount,
      total: groupItems.length,
      setDaily: setDaily,
    );

    if (!useDesktopTiles(context)) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: groupItems.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) return progress;
          return _collectionShopCardFor(groupItems[index - 1]);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DesktopContentFrame(
            maxWidth: 1080,
            child: progress,
          ),
        ),
        Expanded(
          child: DesktopTileGrid(
            itemCount: groupItems.length,
            maxCellWidth: 340,
            maxContentWidth: 1080,
            itemBuilder: (context, index) =>
                _collectionShopCardFor(groupItems[index]),
            mobileBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      ],
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
    return GamepadFocusBlock(
      radius: 18,
      onActivate: onPreview,
      child: Builder(
        builder: (inner) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: GamepadFocusBlock.frameColor(
                  inner,
                  Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                canRequestFocus: false,
                onTap: onPreview,
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  children: [
                    ShopAnimatedEmoji(
                      animatedName: item.animatedName ?? 'sparkles',
                      size: 52,
                      fallback: item.emoji,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catalogTitle(item.code,
                                fallback: item.title, l10n: context.l10n),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            collectionItemSubtitle(shopCollectionDaily(item)),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
                    if (item.owned)
                      Text(
                        context.l10n.shopHave,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: busy ? null : onBuy,
                        child: Text(busy ? '…' : context.l10n.shopBuy),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
