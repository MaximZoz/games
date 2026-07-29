import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/friends/gift_friend_picker.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/shop/unread_gifted_collections.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';

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
      final result =
          await ref.read(shopRepositoryProvider).claimCollectionIncome();
      await ref.read(authStateProvider.notifier).applyBalance(result.balanceBronze);
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
    final refund = (await _catalogPrice(item.code) * 80) ~/ 100;
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
      final result =
          await ref.read(shopRepositoryProvider).sellCollection(item.code);
      await ref.read(authStateProvider.notifier).applyBalance(result.balanceBronze);
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
            l10n.inventoryGiftDesc(catalogTitle(item.code, fallback: item.title, l10n: l10n), friendName),
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
        message: context.l10n.inventoryGifted(catalogTitle(item.code, fallback: item.title, l10n: context.l10n)),
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

    final items = async.valueOrNull ?? const <InventoryItem>[];
    final catalog = ref.watch(shopCatalogProvider).valueOrNull ?? const <ShopItem>[];
    final emojis =
        items.where((e) => e.kind == 'emoji' && e.quantity > 0).toList();
    final frames = items.where((e) => e.kind == 'frame').toList();
    final stakes = items.where((e) => e.kind == 'stake_unlock').toList();
    final collections = items.where((e) => e.kind == 'collection').toList();
    final income = incomeAsync.valueOrNull;
    final incomeAvailable = income?.available == true;
    final unreadGiftCount = _highlightGifts.length;
    final headerBadge = (incomeAvailable ? 1 : 0) + unreadGiftCount;

    final catalogBySet = <String, int>{};
    for (final e in catalog.where((e) => e.kind == 'collection')) {
      final s = (e.collectionSet ?? 'other').trim();
      if (s.isEmpty) continue;
      catalogBySet[s] = (catalogBySet[s] ?? 0) + 1;
    }
    final collectionsBySet = <String, List<InventoryItem>>{};
    for (final it in collections) {
      final s = (it.collectionSet ?? 'other').trim();
      collectionsBySet.putIfAbsent(s.isEmpty ? 'other' : s, () => []).add(it);
    }
    final collectionSetKeys = [
      ...collectionSetOrder.where(collectionsBySet.containsKey),
      ...collectionsBySet.keys.where((k) => !collectionSetOrder.contains(k)),
    ];

    final grouped = <String, List<InventoryItem>>{};
    for (final e in emojis) {
      final g = e.group ?? 'other';
      grouped.putIfAbsent(g, () => []).add(e);
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _Section(
                          title: context.l10n.shopCollections,
                          empty: context.l10n.inventoryNoCollections,
                          children: [
                            if (collections.isNotEmpty &&
                                income != null &&
                                income.amountBronze > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        income.available
                                            ? context.l10n.inventoryIncomeReady(
                                                formatRewardBronzePerDay(
                                                  income.amountBronze,
                                                ),
                                              )
                                            : context.l10n
                                                .inventoryIncomeTomorrow(
                                                formatRewardBronzePerDay(
                                                  income.amountBronze,
                                                ),
                                              ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    if (income.available)
                                      FilledButton(
                                        onPressed:
                                            _claimBusy ? null : _claimIncome,
                                        child: Text(
                                            _claimBusy ? '…' : context.l10n.inventoryClaim),
                                      ),
                                  ],
                                ),
                              ),
                            if (collections.isEmpty)
                              const SizedBox.shrink()
                            else
                              for (final set in collectionSetKeys) ...[
                                _CollectionSetFrame(
                                  title: collectionSetTitle(set),
                                  owned: collectionsBySet[set]?.length ?? 0,
                                  total: catalogBySet[set] ??
                                      (collectionsBySet[set]?.length ?? 0),
                                  onOpenShop: set == 'other'
                                      ? null
                                      : () => context.push(
                                            '/shop/collections/$set',
                                          ),
                                  children: [
                                    for (final it
                                        in collectionsBySet[set] ??
                                            const <InventoryItem>[])
                                      _CollectionInvTile(
                                        item: it,
                                        highlightGift:
                                            _highlightGifts.contains(it.code),
                                        onOpen: () => showCollectionFullscreen(
                                          context,
                                          title: catalogTitle(it.code, fallback: it.title, l10n: context.l10n),
                                          animatedName:
                                              it.animatedName ?? 'sparkles',
                                          fallback: it.emoji,
                                          subtitle:
                                              '+${formatRewardBronzePerDay(it.dailyBronze)}',
                                        ),
                                        onGift: () => _gift(it),
                                        onSell: () => _sell(it),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        for (final g in groupOrder)
                          if (grouped[g]?.isNotEmpty == true) ...[
                            _Section(
                              title: _groupTitles[g] ?? context.l10n.shopEmojis,
                              empty: '',
                              children: [
                                for (final it in grouped[g]!)
                                  _InvTile(
                                    leading: ShopAnimatedEmoji(
                                      animatedName: it.animatedName ?? 'smile',
                                      size: 32,
                                      fallback: it.emoji,
                                    ),
                                    title: catalogTitle(it.code, fallback: it.title, l10n: context.l10n),
                                    subtitle: context.l10n
                                        .inventoryEmojiLeft(it.quantity),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        if (emojis.isEmpty)
                          _Section(
                            title: context.l10n.shopEmojis,
                            empty: context.l10n.inventoryNoEmojis,
                            children: const [],
                          ),
                        if (emojis.isEmpty) const SizedBox(height: 16),
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
                                title: catalogTitle(it.code, fallback: it.title, l10n: context.l10n),
                                subtitle: catalogDescription(it.code, fallback: it.description, l10n: context.l10n),
                              ),
                          ],
                        ),
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
                                title: catalogTitle(it.code, fallback: it.title, l10n: context.l10n),
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
                    ),
        ),
      ),
    );
  }
}

class _CollectionSetFrame extends StatelessWidget {
  const _CollectionSetFrame({
    required this.title,
    required this.owned,
    required this.total,
    required this.children,
    this.onOpenShop,
  });

  final String title;
  final int owned;
  final int total;
  final List<Widget> children;
  final VoidCallback? onOpenShop;

  @override
  Widget build(BuildContext context) {
    final countLabel = total > 0 ? '$owned/$total' : '$owned';
    final header = Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: onOpenShop != null
                  ? AppColors.accentStart
                  : AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          countLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (onOpenShop != null) ...[
          const SizedBox(width: 4),
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
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: header,
                ),
              ),
            )
          else
            header,
          if (children.isNotEmpty) ...[
            const SizedBox(height: 10),
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
    this.highlightGift = false,
  });

  final InventoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onGift;
  final VoidCallback onSell;
  final bool highlightGift;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
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
              InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(10),
                child: ShopAnimatedEmoji(
                  animatedName: item.animatedName ?? 'sparkles',
                  size: 36,
                  fallback: item.emoji,
                ),
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
                      border: Border.all(color: AppColors.surfaceCard, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          catalogTitle(item.code, fallback: item.title, l10n: context.l10n),
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
                  Text(
                    '+${formatRewardBronzePerDay(item.dailyBronze)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.inventoryGift,
            onPressed: onGift,
            icon: const Icon(Icons.card_giftcard_outlined),
          ),
          IconButton(
            tooltip: context.l10n.inventorySell,
            onPressed: onSell,
            icon: const Icon(Icons.sell_outlined),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final String empty;
  final List<Widget> children;

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
        if (children.isEmpty)
          Text(
            empty,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          ...[
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
  });

  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
