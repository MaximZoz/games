import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/friends/gift_friend_picker.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_condition.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/elixir_icon.dart';
import 'package:multigames_client/shop/elixir_labels.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_section_help.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/utils/user_error.dart';

Map<String, String> get _groupTitles {
  final l10n = LocaleService.l10n;
  return {
    'emotions': l10n.emojiGroupEmotions,
    'game': l10n.emojiGroupGame,
    'flags': l10n.emojiGroupFlags,
    'animals': l10n.emojiGroupAnimals,
    'food': l10n.emojiGroupFood,
    'travel': l10n.emojiGroupTravel,
    'party': l10n.emojiGroupParty,
    'objects': l10n.emojiGroupObjects,
  };
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _claimBusy = false;

  /// Копии непрочитанных подарков на момент открытия экрана (для бейджа на плитке).
  Set<String> _highlightGifts = const {};
  bool _clearedUnread = false;
  final GlobalKey _claimIncomeKey = GlobalKey();
  final Map<String, GlobalKey> _sellKeys = {};

  GlobalKey _sellKeyFor(String code) =>
      _sellKeys.putIfAbsent(code, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _clearedUnread) return;
      _clearedUnread = true;
      final unread = ref.read(unreadGiftedCollectionsProvider);
      setState(() => _highlightGifts = {...unread});
      ref.read(unreadGiftedCollectionsProvider.notifier).clear();
    });
  }

  Future<void> _claimIncome() async {
    if (_claimBusy) return;
    setState(() => _claimBusy = true);
    try {
      final fromBalance =
          ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
      final result =
          await ref.read(shopRepositoryProvider).claimCollectionIncome();
      if (!mounted) return;
      if (result.quantity > 0) {
        await playBalanceGain(
          ref: ref,
          context: context,
          newBalanceBronze: result.balanceBronze,
          fromBronze: fromBalance,
          rewardBronze: result.quantity,
          sourceKey: _claimIncomeKey,
        );
      } else {
        await ref
            .read(authStateProvider.notifier)
            .applyBalance(result.balanceBronze);
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: context.l10n.inventoryClaimedAmount(
          formatRewardBronze(result.quantity),
        ),
        kind: AppSnackKind.success,
      );
      ref.invalidate(collectionIncomeProvider);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), ''),
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _claimBusy = false);
    }
  }

  Future<void> _sell(InventoryItem item) async {
    final refund = collectionRefundBronze(
      priceBronze: await _catalogPrice(item.code),
      acquiredAt: item.acquiredAt,
      conditionShift: item.conditionShift,
      vintageAt: item.vintageAt,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.inventorySellTitle),
        content: Text(
          '${catalogTitle(item.code, fallback: item.title, l10n: l10n)}\n${l10n.inventorySellDesc(formatRewardBronze(refund))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.inventorySell),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final fromBalance =
          ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
      final result =
          await ref.read(shopRepositoryProvider).sellCollection(item.code);
      if (!mounted) return;
      if (result.quantity > 0) {
        await playBalanceGain(
          ref: ref,
          context: context,
          newBalanceBronze: result.balanceBronze,
          fromBronze: fromBalance,
          rewardBronze: result.quantity,
          sourceKey: _sellKeyFor(item.code),
        );
      } else {
        await ref
            .read(authStateProvider.notifier)
            .applyBalance(result.balanceBronze);
      }
      ref.invalidate(inventoryListProvider);
      ref.invalidate(shopCatalogProvider);
      ref.invalidate(collectionIncomeProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: context.l10n.inventorySold(
          formatRewardBronze(result.quantity),
        ),
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), ''),
        kind: AppSnackKind.error,
      );
    }
  }

  Future<int> _catalogPrice(String code) async {
    final catalog = ref.read(shopCatalogProvider).valueOrNull;
    final fromCache = catalog?.where((e) => e.code == code).firstOrNull;
    if (fromCache != null) return fromCache.priceBronze;
    try {
      final items = await ref.read(shopRepositoryProvider).listShop();
      return items.where((e) => e.code == code).firstOrNull?.priceBronze ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _gift(InventoryItem item) async {
    final friends =
        ref.read(friendsSnapshotProvider).valueOrNull?.friends ?? const [];
    final l10n = context.l10n;
    if (friends.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.inventoryNeedFriends,
        kind: AppSnackKind.info,
      );
      return;
    }
    final toId = await showGiftFriendPicker(context);
    if (toId == null || toId.isEmpty || !mounted) return;

    FriendUserItem? friend;
    for (final f in friends) {
      if (f.user.id == toId) {
        friend = f.user;
        break;
      }
    }
    final friendName = () {
      final name = friend?.displayName?.trim();
      if (name != null && name.isNotEmpty) return name;
      return l10n.commonUser;
    }();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.inventoryGiftTitle),
          content: Text(
            l10n.inventoryGiftDesc(
                catalogTitle(item.code, fallback: item.title, l10n: l10n),
                friendName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.inventoryGift),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(shopRepositoryProvider).giftCollection(item.code, toId);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(collectionIncomeProvider);
      ref.invalidate(chatsListProvider);
      ref.read(chatsListCacheProvider.notifier).state = null;
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: context.l10n.inventoryGifted(
            catalogTitle(item.code, fallback: item.title, l10n: context.l10n)),
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: formatUserError(
          e,
          fallback: context.l10n.commonGenericError,
        ),
        kind: AppSnackKind.error,
      );
    }
  }

  bool _elixirFits(InventoryItem elixir, InventoryItem collection) {
    if ((elixir.collectionSet ?? '') != (collection.collectionSet ?? '')) {
      return false;
    }
    final acquired = parseCollectionAcquiredAt(collection.acquiredAt);
    if (acquired == null) return false;
    final now = DateTime.now().toUtc();
    final condition = collectionConditionEffective(
      acquired: acquired,
      now: now,
      shift: collection.conditionShift,
      vintageAt: parseCollectionAcquiredAt(collection.vintageAt),
    );
    return elixirCanApply(
      effect: elixir.elixirEffect ?? '',
      condition: condition,
      vintageAt: parseCollectionAcquiredAt(collection.vintageAt),
      acquired: acquired,
      now: now,
    );
  }

  Future<({int shift, DateTime? vintageAt, int quantity})?> _applyElixir(
    BuildContext dialogContext,
    InventoryItem elixir,
    InventoryItem collection,
  ) async {
    final l10n = dialogContext.l10n;
    final ok = await showGamepadConfirmDialog(
      context: dialogContext,
      title: l10n.elixirConfirmTitle,
      message: l10n.elixirConfirmBody(
        elixirTitle(l10n, elixir.collectionSet, elixir.elixirEffect),
        catalogTitle(collection.code, fallback: collection.title, l10n: l10n),
      ),
      confirmLabel: elixirUseLabel(l10n, elixir.elixirEffect ?? 'rejuvenate'),
    );
    if (!ok || !mounted) return null;
    try {
      final result = await ref.read(shopRepositoryProvider).applyElixir(
            elixirCode: elixir.code,
            collectionCode: collection.code,
          );
      ref.invalidate(inventoryListProvider);
      ref.invalidate(shopCatalogProvider);
      if (!mounted) return null;
      showAppSnackBar(
        context,
        message: context.l10n.elixirApplied,
        kind: AppSnackKind.success,
      );
      return (
        shift: result.conditionShift,
        vintageAt: parseCollectionAcquiredAt(result.vintageAt),
        quantity: result.elixirQuantity,
      );
    } catch (e) {
      if (!mounted) return null;
      showAppSnackBar(
        context,
        message: formatUserError(e, fallback: context.l10n.commonGenericError),
        kind: AppSnackKind.error,
      );
      return null;
    }
  }

  Future<void> _openCollection(
    InventoryItem it,
    List<InventoryItem> elixirs,
  ) {
    final l10n = context.l10n;
    final actions = <CollectionElixirButton>[];
    for (final effect in elixirEffectOrder) {
      InventoryItem? elixir;
      for (final candidate in elixirs) {
        if (candidate.elixirEffect == effect &&
            candidate.collectionSet == it.collectionSet &&
            candidate.quantity > 0) {
          elixir = candidate;
          break;
        }
      }
      if (elixir == null || !_elixirFits(elixir, it)) continue;
      final chosen = elixir;
      actions.add(
        CollectionElixirButton(
          effect: effect,
          label: elixirUseLabel(l10n, effect),
          onPressed: () => _applyElixir(context, chosen, it),
        ),
      );
    }
    return showCollectionFullscreen(
      context,
      title: catalogTitle(it.code, fallback: it.title, l10n: l10n),
      animatedName: it.animatedName ?? 'sparkles',
      fallback: it.emoji,
      acquiredAt: parseCollectionAcquiredAt(it.acquiredAt),
      conditionShift: it.conditionShift,
      vintageAt: parseCollectionAcquiredAt(it.vintageAt),
      elixirActions: actions,
    );
  }

  Future<InventoryItem?> _pickCollection(
    BuildContext dialogContext,
    List<InventoryItem> targets,
  ) {
    final l10n = dialogContext.l10n;
    return showDialog<InventoryItem>(
      context: dialogContext,
      builder: (ctx) {
        return GamepadScope(
          exclusive: true,
          onAction: (action) {
            if (action.isDirection) {
              handleGamepadUiAction(ctx, action);
              return true;
            }
            if (action == GamepadAction.confirm) {
              handleGamepadUiAction(ctx, action);
              return true;
            }
            Navigator.of(ctx).pop();
            return true;
          },
          child: AlertDialog(
            title: Text(l10n.elixirPickCollection),
            content: SizedBox(
              width: 420,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < targets.length; i++)
                    GamepadFocusBlock(
                      autofocus: i == 0,
                      radius: 12,
                      onActivate: () => Navigator.of(ctx).pop(targets[i]),
                      child: ListTile(
                        onTap: () => Navigator.of(ctx).pop(targets[i]),
                        title: Text(
                          catalogTitle(
                            targets[i].code,
                            fallback: targets[i].title,
                            l10n: l10n,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openElixir(
    InventoryItem elixir,
    List<InventoryItem> collections,
  ) async {
    final l10n = context.l10n;
    final set = elixir.collectionSet ?? '';
    final targets = collections
        .where((c) => _elixirFits(elixir, c))
        .toList(growable: false);
    await showCollectionFullscreen(
      context,
      title: elixirTitle(l10n, set, elixir.elixirEffect),
      animatedName: 'sparkles',
      artwork: ElixirIcon(
        set: set,
        effect: elixir.elixirEffect ?? 'rejuvenate',
        size: 180,
      ),
      subtitle:
          '${elixirEffectHelp(l10n, elixir.elixirEffect)}\n${l10n.elixirSetOnly(collectionSetTitle(set))}\n${l10n.inventoryEmojiLeft(elixir.quantity)}',
      onBuy: targets.isEmpty
          ? null
          : () async {
              final picked = await _pickCollection(context, targets);
              if (picked == null || !mounted) return;
              final applied = await _applyElixir(context, elixir, picked);
              if (applied != null && mounted) {
                Navigator.of(context).pop();
              }
            },
      buyLabel: targets.isEmpty ? null : l10n.elixirUse,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Set<String>>(unreadGiftedCollectionsProvider, (prev, next) {
      if (next.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _highlightGifts = {..._highlightGifts, ...next});
        ref.read(unreadGiftedCollectionsProvider.notifier).clear();
      });
    });

    final async = ref.watch(inventoryListProvider);
    final incomeAsync = ref.watch(collectionIncomeProvider);
    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }

    final isOffline = ref.watch(isOfflineProvider);
    final items = async.valueOrNull ?? const <InventoryItem>[];
    final catalog =
        ref.watch(shopCatalogProvider).valueOrNull ?? const <ShopItem>[];
    final emojis =
        items.where((e) => e.kind == 'emoji' && e.quantity > 0).toList();
    final frames = items.where((e) => e.kind == 'frame').toList();
    final stakes = isOffline
        ? const <InventoryItem>[]
        : items.where((e) => e.kind == 'stake_unlock').toList();
    final collections = items
        .where(
            (e) => e.kind == 'collection' && !isRetiredCollectionItem(e.code))
        .toList();
    final elixirs =
        items.where((e) => e.kind == 'elixir' && e.quantity > 0).toList();
    final income = incomeAsync.valueOrNull;
    final incomeAvailable = income?.available == true;
    final unreadGiftCount = _highlightGifts.length;
    final headerBadge = (incomeAvailable ? 1 : 0) + unreadGiftCount;

    final catalogBySet = <String, int>{};
    for (final e in catalog.where(
        (e) => e.kind == 'collection' && !isRetiredCollectionItem(e.code))) {
      final s = (e.collectionSet ?? 'other').trim();
      if (s.isEmpty) continue;
      catalogBySet[s] = (catalogBySet[s] ?? 0) + 1;
    }
    final collectionsBySet = <String, List<InventoryItem>>{};
    for (final it in collections) {
      final s = (it.collectionSet ?? 'other').trim();
      collectionsBySet.putIfAbsent(s.isEmpty ? 'other' : s, () => []).add(it);
    }
    for (final list in collectionsBySet.values) {
      list.sort((a, b) => compareCollectionItemsByDaily(
            a.dailyBronze,
            b.dailyBronze,
            0,
            0,
          ));
    }
    final collectionSetKeys = collectionsBySet.keys.toList()
      ..sort((a, b) => compareCollectionSetsByDaily(
            a,
            b,
            collectionSetBonusBronze,
          ));

    final grouped = <String, List<InventoryItem>>{};
    for (final e in emojis) {
      final g = e.group ?? 'other';
      grouped.putIfAbsent(g, () => []).add(e);
    }
    final preferredFlagIso = preferredFlagIsoForLocale(
      effectiveAppLocale(ref.watch(appLocaleProvider)),
    );
    final flagGroup = grouped['flags'];
    if (flagGroup != null) {
      preferFlagIsoFirst<InventoryItem>(
        flagGroup,
        preferredIso: preferredFlagIso,
        codeOf: (e) => e.code,
        animatedNameOf: (e) => e.animatedName,
      );
    }
    final groupOrder = [
      'emotions',
      'game',
      'flags',
      'animals',
      'food',
      'travel',
      'party',
      'objects',
      ...grouped.keys.where((k) => !_groupTitles.containsKey(k)),
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
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.inventoryTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (headerBadge > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentStart,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    headerBadge > 99 ? '99+' : '$headerBadge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        body: SafeArea(
          child: async.hasError && items.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.inventoryLoadFailed,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : items.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.inventoryEmpty,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : DesktopContentFrame(
                      maxWidth: 1080,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        children: [
                          // Группы коллекций — колонка на всю ширину (не Wrap
                          // «кривых» плиток). Внутри группы карточки — плиткой.
                          _CollectionsBlock(
                            income: income,
                            claimIncomeKey: _claimIncomeKey,
                            claimBusy: _claimBusy,
                            onClaimIncome: _claimIncome,
                            collectionsEmpty: collections.isEmpty,
                            collectionSetKeys: collectionSetKeys,
                            collectionsBySet: collectionsBySet,
                            catalogBySet: catalogBySet,
                            highlightGifts: _highlightGifts,
                            sellKeyFor: _sellKeyFor,
                            onGift: _gift,
                            onSell: _sell,
                            onOpen: (it) => _openCollection(it, elixirs),
                          ),
                          const SizedBox(height: 16),
                          _ElixirsBlock(
                            elixirs: elixirs,
                            onOpen: (it) => _openElixir(it, collections),
                          ),
                          const SizedBox(height: 16),
                          _EmojisBlock(
                            groupOrder: groupOrder,
                            grouped: grouped,
                            groupTitles: _groupTitles,
                          ),
                          const SizedBox(height: 16),
                          _Section(
                            title: context.l10n.inventoryFrames,
                            empty: context.l10n.inventoryNoFrames,
                            children: [
                              for (final it in frames)
                                _InvTile(
                                  leading: FramePreviewBadge(
                                    frameCode: it.code,
                                    size: 36,
                                  ),
                                  title: catalogTitle(it.code,
                                      fallback: it.title, l10n: context.l10n),
                                  subtitle: catalogDescription(it.code,
                                      fallback: it.description,
                                      l10n: context.l10n),
                                ),
                            ],
                          ),
                          if (!isOffline) ...[
                            const SizedBox(height: 16),
                            _Section(
                              title: context.l10n.shopStakes,
                              empty: context.l10n.inventoryNoStakes,
                              children: [
                                for (final it in stakes)
                                  _InvTile(
                                    leading: CoinIcon(
                                      coinType: it.stakeGold != null
                                          ? CoinType.gold
                                          : CoinType.silver,
                                      size: 26,
                                    ),
                                    title: catalogTitle(it.code,
                                        fallback: it.title, l10n: context.l10n),
                                    subtitle: it.stakeGold != null
                                        ? context.l10n.inventoryStakeGold(
                                            '${it.stakeGold}',
                                          )
                                        : context.l10n.inventoryStakeSilver(
                                            '${it.stakeSilver ?? (it.stakeBronze ?? 0) ~/ 100}',
                                          ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _CollectionsBlock extends StatelessWidget {
  const _CollectionsBlock({
    required this.income,
    required this.claimIncomeKey,
    required this.claimBusy,
    required this.onClaimIncome,
    required this.collectionsEmpty,
    required this.collectionSetKeys,
    required this.collectionsBySet,
    required this.catalogBySet,
    required this.highlightGifts,
    required this.sellKeyFor,
    required this.onGift,
    required this.onSell,
    required this.onOpen,
  });

  final CollectionIncomeInfo? income;
  final GlobalKey claimIncomeKey;
  final bool claimBusy;
  final VoidCallback onClaimIncome;
  final bool collectionsEmpty;
  final List<String> collectionSetKeys;
  final Map<String, List<InventoryItem>> collectionsBySet;
  final Map<String, int> catalogBySet;
  final Set<String> highlightGifts;
  final GlobalKey Function(String code) sellKeyFor;
  final void Function(InventoryItem item) onGift;
  final void Function(InventoryItem item) onSell;
  final void Function(InventoryItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final tileSets = useDesktopTiles(context);
    final setFrames = <Widget>[
      for (final set in collectionSetKeys)
        Builder(
          builder: (context) {
            final ownedItems = collectionsBySet[set] ?? const <InventoryItem>[];
            final ownedCount = ownedItems.length;
            final totalCount = catalogBySet[set] ?? ownedCount;
            final complete = totalCount > 0 && ownedCount >= totalCount;
            final allVintage = complete &&
                ownedItems.every(
                  (it) => collectionOwnedIsVintage(
                    acquiredAt: it.acquiredAt,
                    conditionShift: it.conditionShift,
                    vintageAt: it.vintageAt,
                  ),
                );
            final setBonus =
                collectionSetIncomeBronze(set, allVintage: allVintage);
            return _CollectionSetFrame(
              title: collectionSetTitle(set),
              owned: ownedCount,
              total: totalCount,
              setBonusBronze: setBonus,
              onOpenShop: set == 'other'
                  ? null
                  : () => context.push('/shop/collections/$set'),
              children: [
                for (final it
                    in collectionsBySet[set] ?? const <InventoryItem>[])
                  _CollectionInvTile(
                    item: it,
                    sellSourceKey: sellKeyFor(it.code),
                    highlightGift: highlightGifts.contains(it.code),
                    onOpen: () => onOpen(it),
                    onGift: () => onGift(it),
                    onSell: () => onSell(it),
                  ),
              ],
            );
          },
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              context.l10n.shopCollections,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            ShopSectionHelpButton(
              title: context.l10n.shopCollections,
              body: context.l10n.shopCollectionsHelp,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!collectionsEmpty && income != null && income!.amountBronze > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: claimIncomeKey,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          income!.available
                              ? context.l10n.inventoryIncomeReadyLabel
                              : context.l10n.inventoryIncomeTomorrowLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        BalanceDisplay(
                          bronze: income!.amountBronze,
                          prefix: income!.available ? '+' : null,
                          perDay: true,
                          coinSize: 16,
                          fontSize: 13,
                          spacing: 5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (income!.available)
                  FilledButton(
                    onPressed: claimBusy ? null : onClaimIncome,
                    child: Text(
                      claimBusy ? '…' : context.l10n.inventoryClaim,
                    ),
                  ),
              ],
            ),
          ),
        if (collectionsEmpty)
          Text(
            context.l10n.inventoryNoCollections,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else if (tileSets && isTablet(context))
          // Планшет: группы коллекций плиткой (2 в ряд).
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final cols = constraints.maxWidth >= 700 ? 2 : 1;
              final itemWidth =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final frame in setFrames)
                    SizedBox(width: itemWidth, child: frame),
                ],
              );
            },
          )
        else
          // Десктоп и телефон: группы колонкой на всю ширину (без «кривизны»).
          for (var i = 0; i < setFrames.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            setFrames[i],
          ],
      ],
    );
  }
}

class _CollectionSetFrame extends StatelessWidget {
  const _CollectionSetFrame({
    required this.title,
    required this.owned,
    required this.total,
    required this.children,
    this.setBonusBronze = 0,
    this.onOpenShop,
  });

  final String title;
  final int owned;
  final int total;
  final int setBonusBronze;
  final List<Widget> children;
  final VoidCallback? onOpenShop;

  @override
  Widget build(BuildContext context) {
    final countLabel = total > 0 ? '$owned/$total' : '$owned';
    final complete = total > 0 && owned >= total;
    final header = Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: onOpenShop != null
                        ? AppColors.accentStart
                        : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (setBonusBronze > 0) ...[
                const SizedBox(width: 8),
                BalanceDisplay(
                  bronze: setBonusBronze,
                  prefix: complete ? '+' : null,
                  perDay: true,
                  coinSize: 15,
                  fontSize: 12,
                  spacing: 4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  opacity: complete ? 1 : 0.32,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          countLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (onOpenShop != null) ...[
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.accentStart.withValues(alpha: 0.9),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.accentSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onOpenShop != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenShop,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: header,
                ),
              ),
            )
          else
            header,
          if (children.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (useDesktopTiles(context))
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final maxCell = isPhoneLandscape(context)
                      ? 200.0
                      : (isTablet(context) ? 220.0 : 260.0);
                  final maxCols = shopTileColumns(context);
                  final cols = (constraints.maxWidth / (maxCell + gap))
                      .floor()
                      .clamp(1, maxCols);
                  final itemWidth =
                      (constraints.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final child in children)
                        SizedBox(width: itemWidth, child: child),
                    ],
                  );
                },
              )
            else
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                children[i],
              ],
          ],
        ],
      ),
    );
  }
}

class _CollectionInvTile extends StatelessWidget {
  const _CollectionInvTile({
    required this.item,
    required this.onOpen,
    required this.onGift,
    required this.onSell,
    required this.sellSourceKey,
    this.highlightGift = false,
  });

  final InventoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onGift;
  final VoidCallback onSell;
  final GlobalKey sellSourceKey;
  final bool highlightGift;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      radius: 14,
      onActivate: onOpen,
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: highlightGift
                    ? AppColors.accentStart.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.06),
                width: highlightGift ? 1.4 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ShopAnimatedEmoji(
                      animatedName: item.animatedName ?? 'sparkles',
                      size: 36,
                      fallback: item.emoji,
                    ),
                    if (highlightGift)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.accentStart,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surfaceCard, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              catalogTitle(item.code,
                                  fallback: item.title, l10n: context.l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (highlightGift)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.l10n.chatGift,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentStart,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      BalanceDisplay(
                        bronze: collectionDailyIncomeBronze(
                          baseBronze: item.dailyBronze,
                          acquiredAt: item.acquiredAt,
                          conditionShift: item.conditionShift,
                          vintageAt: item.vintageAt,
                        ),
                        prefix: '+',
                        perDay: true,
                        coinSize: 14,
                        fontSize: 12,
                        spacing: 4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.inventoryGift,
                  onPressed: onGift,
                  icon: const Icon(Icons.card_giftcard_outlined),
                ),
                if (collectionCanSell(
                  acquiredAt: item.acquiredAt,
                  conditionShift: item.conditionShift,
                  vintageAt: item.vintageAt,
                ))
                  KeyedSubtree(
                    key: sellSourceKey,
                    child: IconButton(
                      tooltip: context.l10n.inventorySell,
                      onPressed: onSell,
                      icon: const Icon(Icons.sell_outlined),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ElixirsBlock extends StatelessWidget {
  const _ElixirsBlock({
    required this.elixirs,
    required this.onOpen,
  });

  final List<InventoryItem> elixirs;
  final void Function(InventoryItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<InventoryItem>>{};
    for (final it in elixirs) {
      final effect = it.elixirEffect ?? 'rejuvenate';
      grouped.putIfAbsent(effect, () => []).add(it);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final ai = elixirSetOrder.indexOf(a.collectionSet ?? '');
        final bi = elixirSetOrder.indexOf(b.collectionSet ?? '');
        return ai.compareTo(bi);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.shopElixirs,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (elixirs.isEmpty)
          Text(
            context.l10n.inventoryNoElixirs,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          for (final effect in elixirEffectOrder) ...[
            if ((grouped[effect] ?? const []).isNotEmpty) ...[
              Text(
                elixirGroupTitle(context.l10n, effect),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final it in grouped[effect]!) ...[
                _InvTile(
                  leading: ElixirIcon(
                    set: it.collectionSet ?? 'celebration',
                    effect: effect,
                    size: 36,
                  ),
                  title: elixirTitle(
                    context.l10n,
                    it.collectionSet,
                    effect,
                  ),
                  subtitle: context.l10n.inventoryEmojiLeft(it.quantity),
                  onTap: () => onOpen(it),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
      ],
    );
  }
}

class _EmojisBlock extends StatelessWidget {
  const _EmojisBlock({
    required this.groupOrder,
    required this.grouped,
    required this.groupTitles,
  });

  final List<String> groupOrder;
  final Map<String, List<InventoryItem>> grouped;
  final Map<String, String> groupTitles;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    for (final g in groupOrder) {
      final items = grouped[g];
      if (items == null || items.isEmpty) continue;
      sections.add(
        _Section(
          title: groupTitles[g] ?? context.l10n.shopEmojis,
          empty: '',
          nested: true,
          children: [
            for (final it in items)
              _InvTile(
                leading: ShopAnimatedEmoji(
                  animatedName: it.animatedName ?? 'smile',
                  size: 32,
                  fallback: it.emoji,
                ),
                title: catalogTitle(it.code,
                    fallback: it.title, l10n: context.l10n),
                subtitle: context.l10n.inventoryEmojiLeft(it.quantity),
                onTap: () => showCollectionFullscreen(
                  context,
                  title: catalogTitle(
                    it.code,
                    fallback: it.title,
                    l10n: context.l10n,
                  ),
                  animatedName: it.animatedName ?? 'smile',
                  fallback: it.emoji,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.shopEmojis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (sections.isEmpty)
          Text(
            context.l10n.inventoryNoEmojis,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            sections[i],
          ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.children,
    this.nested = false,
  });

  final String title;
  final String empty;
  final List<Widget> children;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: nested ? 14 : 16,
            color: nested ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(
            empty,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else if (useDesktopTiles(context))
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              // Эмоции и пр.: на планшете/landscape до 4 в ряд.
              final maxCell = isPhoneLandscape(context)
                  ? 180.0
                  : (isTablet(context) ? 200.0 : 240.0);
              final maxCols = shopTileColumns(context);
              final cols = (constraints.maxWidth / (maxCell + gap))
                  .floor()
                  .clamp(1, maxCols);
              final itemWidth =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final child in children)
                    SizedBox(width: itemWidth, child: child),
                ],
              );
            },
          )
        else ...[
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      ],
    );
  }
}

class _InvTile extends StatelessWidget {
  const _InvTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      radius: 14,
      onActivate: onTap,
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
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
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
