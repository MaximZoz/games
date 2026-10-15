import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/shop/pending_purchases.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';
import 'package:multigames_client/ui/widgets/snug_bottom_list.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/vertical_paged_slider.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';

/// Порядок групп на витрине смайликов.
const shopEmojiGroupOrder = <String>['emotions', 'game', 'flags'];

Map<String, String> get shopEmojiGroupTitles {
  final l10n = LocaleService.l10n;
  return {
    'emotions': l10n.emojiGroupEmotions,
    'game': l10n.emojiGroupGame,
    'flags': l10n.emojiGroupFlags,
  };
}

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
      setState(() {
        _items = items;
        _loading = false;
      });
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    ref.listen<AsyncValue<List<ShopItem>>>(shopCatalogProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null && data.isNotEmpty && mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    });
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = _items.isNotEmpty ? _items : (cached ?? const <ShopItem>[]);
    final byGroup = <String, List<ShopItem>>{};
    for (final e in items) {
      if (e.kind != 'emoji') continue;
      final g = (e.group ?? '').trim();
      if (g.isEmpty) continue;
      byGroup.putIfAbsent(g, () => []).add(e);
    }
    final preferredFlagIso = preferredFlagIsoForLocale(
      effectiveAppLocale(ref.watch(appLocaleProvider)),
    );
    for (final entry in byGroup.entries) {
      entry.value.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (entry.key == 'flags') {
        preferFlagIsoFirst<ShopItem>(
          entry.value,
          preferredIso: preferredFlagIso,
          codeOf: (e) => e.code,
          animatedNameOf: (e) => e.animatedName,
        );
      }
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
          leading: GamepadBackButton(
            onPressed: goBack,
            tooltip: context.l10n.commonBack,
          ),
          title: Text(
            context.l10n.shopEmojis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: _loading && groupKeys.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : groupKeys.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.shopEmpty,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : DesktopTileGrid(
                      itemCount: groupKeys.length,
                      maxCellWidth: isPhoneLandscape(context) ? 240 : 320,
                      maxContentWidth: 1100,
                      maxColumns: 3,
                      padding: EdgeInsets.fromLTRB(
                        isPhoneLandscape(context) ? 12 : 16,
                        8,
                        isPhoneLandscape(context) ? 12 : 16,
                        24,
                      ),
                      itemBuilder: (context, index) => _emojiGroupTile(
                        context,
                        groupKeys[index],
                        byGroup[groupKeys[index]]!,
                      ),
                      mobileBuilder: (context) => Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: SnugBottomList(
                            children: [
                              for (final key in groupKeys)
                                _emojiGroupTile(
                                  context,
                                  key,
                                  byGroup[key]!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _emojiGroupTile(
    BuildContext context,
    String group,
    List<ShopItem> groupItems,
  ) {
    final price = groupItems
        .map((e) => e.priceBronze)
        .fold<int>(groupItems.first.priceBronze, math.min);
    return GamepadFocusBlock(
      radius: 16,
      onActivate: () => context.push('/shop/emojis/$group'),
      child: Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/shop/emojis/$group'),
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
              ShopEmojiGroupIcon(group: group, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      context.l10n.shopEmojiGroupMeta(
                        groupItems.length,
                        formatRewardBronze(price),
                      ),
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
      setState(() {
        _items = items;
        _loading = false;
      });
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<bool> _confirmBuy(ShopItem item) async {
    final l10n = context.l10n;
    return showGamepadConfirmDialog(
      context: context,
      title: l10n.shopBuyEmojiTitle,
      message:
          '${catalogTitle(item.code, fallback: item.title, l10n: l10n)}\n\n'
          '${l10n.shopPrice(formatRewardBronze(item.priceBronze))}\n'
          '${l10n.shopEmojiUses}',
      confirmLabel: l10n.shopBuy,
    );
  }

  void _showPurchased(ShopItem item) {
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: context.l10n.shopEmojiBought(catalogTitle(item.code, fallback: item.title, l10n: context.l10n)),
      kind: AppSnackKind.success,
    );
  }

  Future<void> _buy(ShopItem item, {bool confirm = true}) async {
    if (_buyInFlight.contains(item.code)) return;
    if (confirm) {
      final ok = await _confirmBuy(item);
      if (!ok || !mounted) return;
    }

    _buyInFlight.add(item.code);
    setState(() {});
    try {
      final wasOffline = ref.read(isOfflineProvider);
      await ref.read(pendingPurchasesProvider.notifier).buyOrQueue(item.code);
      if (!wasOffline) {
        ref.invalidate(inventoryListProvider);
        ref.invalidate(inventoryCapabilitiesProvider);
        ref.invalidate(shopCatalogProvider);
        unawaited(_reloadSilent());
      }
      if (!mounted) return;
      if (wasOffline) {
        showAppSnackBar(
          context,
          message: context.l10n.shopPurchaseQueued,
          kind: AppSnackKind.success,
        );
      } else {
        _showPurchased(item);
      }
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
      title: catalogTitle(item.code, fallback: item.title, l10n: context.l10n),
      animatedName: item.animatedName ?? 'smile',
      fallback: item.emoji,
      subtitle: context.l10n.shopEmojiPriceUses(
        formatRewardBronze(item.priceBronze),
      ),
      onBuy: () => unawaited(_buy(item)),
      buyLabel: context.l10n.shopBuy,
    );
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    ref.listen<AsyncValue<List<ShopItem>>>(shopCatalogProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null && data.isNotEmpty && mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    });
    final cached = ref.watch(shopCatalogProvider).valueOrNull;
    final items = _items.isNotEmpty ? _items : (cached ?? const <ShopItem>[]);
    final emojis = items
        .where((e) => e.kind == 'emoji' && (e.group ?? 'other') == widget.group)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (widget.group == 'flags') {
      preferFlagIsoFirst<ShopItem>(
        emojis,
        preferredIso: preferredFlagIsoForLocale(
          effectiveAppLocale(ref.watch(appLocaleProvider)),
        ),
        codeOf: (e) => e.code,
        animatedNameOf: (e) => e.animatedName,
      );
    }

    final fillTiles = shopEmojiFillViewport(context);

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
            shopEmojiGroupTitle(widget.group),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: _loading && emojis.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : emojis.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.shopEmpty,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, outer) {
                        final pad = fillTiles
                            ? const EdgeInsets.fromLTRB(8, 4, 8, 8)
                            : const EdgeInsets.fromLTRB(10, 8, 2, 10);
                        final innerW =
                            (outer.maxWidth - pad.horizontal).clamp(1.0, 4000.0);
                        final innerH =
                            (outer.maxHeight - pad.vertical).clamp(1.0, 4000.0);
                        final cols =
                            shopTileColumns(context, maxWidth: innerW);
                        final rows = shopTileRows(context, maxHeight: innerH);
                        final pageSize = (cols * rows).clamp(1, 48);
                        final pageCount = emojis.isEmpty
                            ? 0
                            : ((emojis.length + pageSize - 1) / pageSize)
                                .floor();
                        final slider = VerticalPagedSlider(
                          pageCount: pageCount,
                          itemBuilder: (context, page) {
                            final start = page * pageSize;
                            final end = math.min(
                              start + pageSize,
                              emojis.length,
                            );
                            final pageItems = emojis.sublist(start, end);
                            return Padding(
                              padding: pad,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final pageCols = shopTileColumns(
                                    context,
                                    maxWidth: constraints.maxWidth,
                                  );
                                  const gap = 8.0;
                                  if (fillTiles) {
                                    return ShopFillGrid(
                                      columns: pageCols,
                                      rows: rows,
                                      itemCount: pageItems.length,
                                      gap: gap,
                                      itemBuilder: (context, index) {
                                        final item = pageItems[index];
                                        return _EmojiBuyTile(
                                          item: item,
                                          busy: _buyInFlight
                                              .contains(item.code),
                                          onPreview: () =>
                                              _openPreview(item),
                                          onBuy: () => _buy(item),
                                        );
                                      },
                                    );
                                  }
                                  final pageRows = (pageItems.length /
                                          pageCols)
                                      .ceil()
                                      .clamp(1, rows);
                                  final cellW = (constraints.maxWidth -
                                          gap * (pageCols - 1)) /
                                      pageCols;
                                  final cellH = (constraints.maxHeight -
                                          gap * (pageRows - 1)) /
                                      pageRows;
                                  final rawRatio =
                                      cellH <= 0 ? 0.78 : cellW / cellH;
                                  final ratio = rawRatio.clamp(0.55, 1.15);
                                  return GridView.builder(
                                    clipBehavior: Clip.hardEdge,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: pageCols,
                                      mainAxisSpacing: gap,
                                      crossAxisSpacing: gap,
                                      childAspectRatio: ratio,
                                    ),
                                    itemCount: pageItems.length,
                                    itemBuilder: (context, index) {
                                      final item = pageItems[index];
                                      return _EmojiBuyTile(
                                        item: item,
                                        busy: _buyInFlight
                                            .contains(item.code),
                                        onPreview: () =>
                                            _openPreview(item),
                                        onBuy: () => _buy(item),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        );
                        return DesktopContentFrame(
                          maxWidth: fillTiles
                              ? double.infinity
                              : (isWide(context) ? 720 : double.infinity),
                          child: fillTiles
                              ? SizedBox.expand(child: slider)
                              : slider,
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

    return GamepadFocusBlock(
      radius: 18,
      onActivate: onPreview,
      child: Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(18),
      // Не клипаем жёстко содержимое: Lottie/emoji часто чуть выходят за бокс.
      clipBehavior: Clip.none,
      child: Builder(
        builder: (inner) {
          return Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
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
        child: Column(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  canRequestFocus: false,
                  onTap: onPreview,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = math.min(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        // Чуть меньше ячейки — запас снизу/сверху, без обрезки.
                        final emojiSize = (side * 0.82).clamp(20.0, 56.0);
                        return Center(
                          child: name.isEmpty
                              ? Text(
                                  fallback,
                                  style: TextStyle(
                                    fontSize: emojiSize * 0.85,
                                    height: 1,
                                  ),
                                )
                              : ShopAnimatedEmoji(
                                  animatedName: name,
                                  size: emojiSize,
                                  fallback: fallback,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Text(
              catalogTitle(item.code, fallback: item.title, l10n: context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            InkWell(
              canRequestFocus: false,
              onTap: busy ? null : onBuy,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BalanceDisplay(
                      bronze: item.priceBronze,
                      coinSize: 11,
                      fontSize: 11,
                      spacing: 4,
                    ),
                    Text(
                      busy ? '…' : context.l10n.shopBuyTen,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.1,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
        },
      ),
      ),
    );
  }
}
