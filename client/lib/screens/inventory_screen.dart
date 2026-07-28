import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
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

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _claimBusy = false;

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
        message: 'Получено +${result.quantity} бронзы',
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Продать?'),
        content: Text('${item.title}\nВернётся около $refund бронзы (80%).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Продать'),
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
        message: 'Продано: +${result.quantity} бронзы',
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
    if (friends.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Сначала добавьте друзей',
        kind: AppSnackKind.info,
      );
      return;
    }
    final toId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Подарить другу'),
        children: [
          for (final f in friends)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f.user.id),
              child: Text(
                f.user.displayName?.trim().isNotEmpty == true
                    ? f.user.displayName!
                    : f.user.email,
              ),
            ),
        ],
      ),
    );
    if (toId == null || toId.isEmpty || !mounted) return;
    try {
      await ref.read(shopRepositoryProvider).giftCollection(item.code, toId);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(collectionIncomeProvider);
      ref.invalidate(chatsListProvider);
      ref.read(chatsListCacheProvider.notifier).state = null;
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Подарено: ${item.title}',
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
    final emojis =
        items.where((e) => e.kind == 'emoji' && e.quantity > 0).toList();
    final frames = items.where((e) => e.kind == 'frame').toList();
    final stakes = items.where((e) => e.kind == 'stake_unlock').toList();
    final collections = items.where((e) => e.kind == 'collection').toList();
    final income = incomeAsync.valueOrNull;
    final incomeAvailable = income?.available == true;

    final grouped = <String, List<InventoryItem>>{};
    for (final e in emojis) {
      final g = e.group ?? 'other';
      grouped.putIfAbsent(g, () => []).add(e);
    }
    final groupOrder = [
      'emotions',
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
            tooltip: 'Назад',
          ),
          title: Row(
            children: [
              Text(
                'Предметы',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (incomeAvailable) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentStart,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
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
              ? const Center(
                  child: Text(
                    'Не удалось загрузить предметы',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : items.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока ничего нет — загляните в магазин',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _Section(
                          title: 'Коллекции',
                          empty: 'Нет коллекций — купите в магазине',
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
                                            ? 'Доход: +${formatRewardBronzePerDay(income.amountBronze)}'
                                                '${income.setBonusBronze > 0 ? ' (группы +${formatRewardBronzePerDay(income.setBonusBronze)})' : ''}'
                                            : 'Доход завтра: ${formatRewardBronzePerDay(income.amountBronze)}'
                                                '${income.setBonusBronze > 0 ? ' (группы +${formatRewardBronzePerDay(income.setBonusBronze)})' : ''}',
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
                                            _claimBusy ? '…' : 'Забрать'),
                                      ),
                                  ],
                                ),
                              ),
                            for (final it in collections)
                              _CollectionInvTile(
                                item: it,
                                onOpen: () => showCollectionFullscreen(
                                  context,
                                  title: it.title,
                                  animatedName: it.animatedName ?? 'sparkles',
                                  fallback: it.emoji,
                                  subtitle:
                                      '+${formatRewardBronzePerDay(it.dailyBronze)}',
                                ),
                                onGift: () => _gift(it),
                                onSell: () => _sell(it),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        for (final g in groupOrder)
                          if (grouped[g]?.isNotEmpty == true) ...[
                            _Section(
                              title: _groupTitles[g] ?? 'Смайлики',
                              empty: '',
                              children: [
                                for (final it in grouped[g]!)
                                  _InvTile(
                                    leading: ShopAnimatedEmoji(
                                      animatedName: it.animatedName ?? 'smile',
                                      size: 32,
                                      fallback: it.emoji,
                                    ),
                                    title: it.title,
                                    subtitle: 'Осталось ${it.quantity}',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        if (emojis.isEmpty)
                          const _Section(
                            title: 'Смайлики',
                            empty: 'Нет смайликов — купите в магазине',
                            children: [],
                          ),
                        if (emojis.isEmpty) const SizedBox(height: 16),
                        _Section(
                          title: 'Рамки',
                          empty: 'Нет рамок',
                          children: [
                            for (final it in frames)
                              _InvTile(
                                leading: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _parseColor(it.frameColor) ??
                                          AppColors.accentStart,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                title: it.title,
                                subtitle: it.description,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Ставки',
                          empty: 'Нет купленных ставок',
                          children: [
                            for (final it in stakes)
                              _InvTile(
                                leading: const CoinIcon(
                                  coinType: CoinType.silver,
                                  size: 26,
                                ),
                                title: it.title,
                                subtitle:
                                    'Можно ставить ${it.stakeSilver ?? (it.stakeBronze ?? 0) ~/ 100} серебра',
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

class _CollectionInvTile extends StatelessWidget {
  const _CollectionInvTile({
    required this.item,
    required this.onOpen,
    required this.onGift,
    required this.onSell,
  });

  final InventoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onGift;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
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
            tooltip: 'Подарить',
            onPressed: onGift,
            icon: const Icon(Icons.card_giftcard_outlined),
          ),
          IconButton(
            tooltip: 'Продать',
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

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(v);
}
