import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/elixir_icon.dart';
import 'package:multigames_client/shop/elixir_labels.dart';
import 'package:multigames_client/shop/pending_purchases.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_section_help.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/shop/shop_repository.dart';

/// Хаб эликсиров: омоложение, старение, ускорение.
class ShopElixirsScreen extends ConsumerStatefulWidget {
  const ShopElixirsScreen({super.key});

  @override
  ConsumerState<ShopElixirsScreen> createState() => _ShopElixirsScreenState();
}

class _ShopElixirsScreenState extends ConsumerState<ShopElixirsScreen> {
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
    ref.listen<AsyncValue<List<ShopItem>>>(shopCatalogProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null && data.isNotEmpty && mounted) {
        setState(() => _items = data);
      }
    });
    final l10n = context.l10n;
    final elixirs = _items.where((e) => e.kind == 'elixir').toList();

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading:
              GamepadBackButton(onPressed: goBack, tooltip: l10n.commonBack),
          title: Text(l10n.shopElixirs),
          actions: [
            ShopSectionHelpButton(
              title: l10n.shopElixirs,
              body: l10n.shopElixirsHelp,
            ),
          ],
        ),
        body: SafeArea(
          child: elixirs.isEmpty
              ? Center(
                  child: Text(
                    l10n.shopEmpty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : useDesktopTiles(context)
                  ? DesktopTileGrid(
                      itemCount: elixirEffectOrder.length,
                      maxCellWidth: 340,
                      maxContentWidth: 1080,
                      itemBuilder: (context, index) => _effectTile(
                        context,
                        elixirEffectOrder[index],
                        elixirs,
                      ),
                      mobileBuilder: (_) => const SizedBox.shrink(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: elixirEffectOrder.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _effectTile(
                        context,
                        elixirEffectOrder[index],
                        elixirs,
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _effectTile(
      BuildContext context, String effect, List<ShopItem> elixirs) {
    final sample = elixirs.cast<ShopItem?>().firstWhere(
          (e) => e!.elixirEffect == effect,
          orElse: () => null,
        );
    final set = sample?.collectionSet ?? 'jewels';
    return GamepadFocusBlock(
      radius: 16,
      onActivate: () => context.push('/shop/elixirs/$effect'),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/shop/elixirs/$effect'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ElixirIcon(set: set, effect: effect, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    elixirGroupTitle(context.l10n, effect),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Шесть эликсиров одного действия, от дешёвого набора к дорогому.
class ShopElixirGroupScreen extends ConsumerStatefulWidget {
  const ShopElixirGroupScreen({super.key, required this.effect});

  final String effect;

  @override
  ConsumerState<ShopElixirGroupScreen> createState() =>
      _ShopElixirGroupScreenState();
}

class _ShopElixirGroupScreenState extends ConsumerState<ShopElixirGroupScreen> {
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
      final items = ref.read(isOfflineProvider)
          ? await ref.read(shopCatalogProvider.future)
          : await ref.read(shopRepositoryProvider).listShop();
      if (!mounted) return;
      setState(() => _items = items);
      scheduleFocusFirstVisibleGamepadTargetIfPending();
    } catch (_) {}
  }

  List<ShopItem> get _group {
    final items = _items
        .where((e) => e.kind == 'elixir' && e.elixirEffect == widget.effect)
        .toList();
    items.sort((a, b) => a.priceBronze.compareTo(b.priceBronze));
    return items;
  }

  Future<bool> _buy(ShopItem item) async {
    if (_buyInFlight.contains(item.code)) return false;
    final l10n = context.l10n;
    final title = elixirTitle(l10n, item.collectionSet, item.elixirEffect);
    final ok = await showGamepadConfirmDialog(
      context: context,
      title: title,
      message: l10n.shopPrice(formatRewardBronze(item.priceBronze)),
      confirmLabel: l10n.shopBuy,
    );
    if (!ok || !mounted) return false;
    setState(() => _buyInFlight.add(item.code));
    try {
      await ref.read(pendingPurchasesProvider.notifier).buyOrQueue(item.code);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(shopCatalogProvider);
      final fresh = await ref.read(shopCatalogProvider.future);
      if (mounted) setState(() => _items = fresh);
      return true;
    } catch (e) {
      if (!mounted) return false;
      showAppSnackBar(
        context,
        message: e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), ''),
        kind: AppSnackKind.error,
      );
      return false;
    } finally {
      if (mounted) setState(() => _buyInFlight.remove(item.code));
    }
  }

  Future<void> _afterBuy(ShopItem item, {required bool closePreview}) async {
    final bought = await _buy(item);
    if (!bought || !mounted) return;
    if (closePreview) Navigator.of(context).pop();
    if (!mounted) return;
    await showGamepadOwnedDialog(
      context: context,
      message: elixirTitle(
        context.l10n,
        item.collectionSet,
        item.elixirEffect,
      ),
    );
  }

  void _preview(ShopItem item) {
    final l10n = context.l10n;
    final set = item.collectionSet ?? '';
    showCollectionFullscreen(
      context,
      title: elixirTitle(l10n, set, item.elixirEffect),
      animatedName: 'sparkles',
      artwork: ElixirIcon(
        set: set,
        effect: item.elixirEffect ?? widget.effect,
        size: 180,
      ),
      subtitle:
          '${elixirEffectHelp(l10n, item.elixirEffect)}\n${l10n.elixirSetOnly(collectionSetTitle(set))}',
      onBuy: () => _afterBuy(item, closePreview: true),
      buyLabel: l10n.shopBuy,
    );
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();
    final l10n = context.l10n;
    final group = _group;
    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading:
              GamepadBackButton(onPressed: goBack, tooltip: l10n.commonBack),
          title: Text(elixirGroupTitle(l10n, widget.effect)),
        ),
        body: SafeArea(
          child: group.isEmpty
              ? Center(
                  child: Text(
                    l10n.shopEmpty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : useDesktopTiles(context)
                  ? DesktopTileGrid(
                      itemCount: group.length,
                      maxCellWidth: 340,
                      maxContentWidth: 1080,
                      itemBuilder: (context, index) =>
                          _card(context, group[index]),
                      mobileBuilder: (_) => const SizedBox.shrink(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: group.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _card(context, group[index]),
                    ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, ShopItem item) {
    final l10n = context.l10n;
    final busy = _buyInFlight.contains(item.code);
    final ownedQty = ref
            .watch(inventoryListProvider)
            .valueOrNull
            ?.where((e) => e.code == item.code)
            .fold<int>(0, (sum, e) => sum + e.quantity) ??
        0;
    return GamepadFocusBlock(
      radius: 18,
      onActivate: () => _preview(item),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _preview(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ElixirIcon(
                  set: item.collectionSet ?? 'celebration',
                  effect: item.elixirEffect ?? widget.effect,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        elixirTitle(
                            l10n, item.collectionSet, item.elixirEffect),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BalanceDisplay(
                        bronze: item.priceBronze,
                        coinSize: 14,
                        fontSize: 13,
                        spacing: 6,
                      ),
                      if (ownedQty > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.inventoryEmojiLeft(ownedQty),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FilledButton(
                  onPressed:
                      busy ? null : () => _afterBuy(item, closePreview: false),
                  child: Text(busy ? '…' : l10n.shopBuy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
