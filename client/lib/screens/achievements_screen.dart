import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/achievements/achievements_repository.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key, this.asTasks = false});

  /// Экран заданий внутри «Монет» — тот же UI, другой каталог.
  final bool asTasks;

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  List<AchievementItem> _items = const [];
  final Set<String> _claimInFlight = {};
  final Map<String, GlobalKey> _rewardKeys = {};

  GlobalKey _rewardKeyFor(String code) =>
      _rewardKeys.putIfAbsent(code, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    // Сразу рисуем кэш, сортировку обновляем фоном без спиннера.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cached = widget.asTasks
          ? ref.read(tasksListProvider).valueOrNull
          : ref.read(achievementsListProvider).valueOrNull;
      if (cached != null && cached.isNotEmpty) {
        setState(() => _items = sortAchievements(cached));
      }
      unawaited(_reloadSilent());
    });
  }

  Future<void> _reloadSilent() async {
    try {
      final repo = ref.read(achievementsRepositoryProvider);
      final items =
          widget.asTasks ? await repo.listTasks() : await repo.list();
      if (!mounted) return;
      final sorted = sortAchievements(items);
      setState(() => _items = sorted);
      // Обновляем кэш провайдера без loading-состояния.
      if (widget.asTasks) {
        ref.invalidate(tasksUnclaimedCountProvider);
      } else {
        ref.invalidate(achievementsUnclaimedCountProvider);
      }
    } catch (_) {
      // Оставляем то, что уже на экране.
    }
  }

  Future<void> _claim(AchievementItem item) async {
    if (_claimInFlight.contains(item.code) || !item.isUnlocked) return;
    _claimInFlight.add(item.code);

    // Мгновенно: кнопка → «Получено», карточка остаётся, список пересортируется.
    final previous = _items;
    setState(() {
      _items = sortAchievements([
        for (final a in _items)
          if (a.code == item.code)
            AchievementItem(
              code: a.code,
              title: a.title,
              description: a.description,
              rewardBronze: a.rewardBronze,
              rewardItemCode: a.rewardItemCode,
              progress: a.target,
              target: a.target,
              status: 'claimed',
            )
          else
            a,
      ]);
    });

    try {
      final result =
          await ref.read(achievementsRepositoryProvider).claim(item.code);
      final reward = result.rewardBronze > 0
          ? result.rewardBronze
          : item.rewardBronze;
      if (mounted && reward > 0) {
        await playBalanceGain(
          ref: ref,
          context: context,
          newBalanceBronze: result.balanceBronze,
          rewardBronze: reward,
          sourceKey: _rewardKeyFor(item.code),
        );
      } else {
        await ref
            .read(authStateProvider.notifier)
            .applyBalance(result.balanceBronze);
      }
      if (widget.asTasks) {
        ref.invalidate(tasksUnclaimedCountProvider);
      } else {
        ref.invalidate(achievementsUnclaimedCountProvider);
      }
      ref.invalidate(inventoryCapabilitiesProvider);
      ref.invalidate(inventoryListProvider);
      // Тихо подтянуть актуальный список в кэш (без спиннера на UI).
      unawaited(() async {
        try {
          final repo = ref.read(achievementsRepositoryProvider);
          final fresh =
              widget.asTasks ? await repo.listTasks() : await repo.list();
          // Не дергаем invalidate list — иначе FutureProvider уйдёт в loading.
          if (mounted) {
            setState(() => _items = sortAchievements(fresh));
          }
        } catch (_) {}
      }());
    } catch (e) {
      if (!mounted) return;
      setState(() => _items = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _claimInFlight.remove(item.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();

    // Подхватываем кэш провайдера, если локальный список ещё пуст.
    final cached = widget.asTasks
        ? ref.watch(tasksListProvider).valueOrNull
        : ref.watch(achievementsListProvider).valueOrNull;
    final items = _items.isNotEmpty
        ? _items
        : (cached != null ? sortAchievements(cached) : const <AchievementItem>[]);

    final l10n = context.l10n;
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
            tooltip: l10n.commonBack,
          ),
          title: Text(
            widget.asTasks ? l10n.coinsTasks : l10n.homeAchievements,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isPhoneLandscape(context) ? double.infinity : 520,
              ),
              child: items.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return _AchievementCard(
                          item: item,
                          rewardKey: _rewardKeyFor(item.code),
                          onClaim: item.isUnlocked
                              ? () => unawaited(_claim(item))
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.item,
    required this.rewardKey,
    required this.onClaim,
  });

  final AchievementItem item;
  final GlobalKey rewardKey;
  final VoidCallback? onClaim;

  IconData get _icon {
    switch (item.code) {
      case 'profile_complete':
        return Icons.badge_outlined;
      case 'games_10':
        return Icons.sports_esports_outlined;
      case 'friends_5':
        return Icons.group_outlined;
      case 'wins_bronze_10':
      case 'wins_silver_10':
      case 'wins_gold_10':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progressText = '${item.progress}/${item.target}';
    final frameCode = item.rewardItemCode;
    return GradientCard(
      margin: EdgeInsets.zero,
      animate: false,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (frameCode != null && frameCode.isNotEmpty)
                FramePreviewBadge(frameCode: frameCode, size: 48)
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: AppColors.accentStart),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievementTitle(item.code, fallback: item.title, l10n: l10n),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievementDescription(
                        item.code,
                        fallback: item.description,
                        l10n: l10n,
                      ),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.rewardBronze > 0) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${rewardCoinAmount(item.rewardBronze)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    KeyedSubtree(
                      key: rewardKey,
                      child: CoinIcon(
                        coinType: rewardCoinType(item.rewardBronze),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (item.isLocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: item.target <= 0
                    ? 0
                    : (item.progress / item.target).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.accentSoft,
                color: AppColors.accentStart,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.achievementsProgress(progressText),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ] else if (item.isClaimed)
            Text(
              item.hasFrameReward
                  ? l10n.achievementsFrameClaimed
                  : l10n.achievementsClaimed,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            )
          else
            FilledButton(
              onPressed: onClaim,
              style: AppButtonStyles.of(
                minimumSize: const Size(double.infinity, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignment: Alignment.center,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
              child: Text(
                item.hasFrameReward
                    ? l10n.achievementsOpenFrame
                    : l10n.inventoryClaim,
              ),
            ),
        ],
      ),
    );
  }
}
