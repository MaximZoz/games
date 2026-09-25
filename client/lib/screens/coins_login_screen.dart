import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

class CoinsLoginScreen extends ConsumerStatefulWidget {
  const CoinsLoginScreen({super.key});

  @override
  ConsumerState<CoinsLoginScreen> createState() => _CoinsLoginScreenState();
}

class _CoinsLoginScreenState extends ConsumerState<CoinsLoginScreen> {
  bool _claimInFlight = false;

  /// Локальный статус после клейма — без спиннера на время invalidate.
  DailyRewardStatus? _optimisticStatus;
  final GlobalKey _claimSourceKey = GlobalKey();
  final GlobalKey _claimButtonKey = GlobalKey();

  Future<void> _claim(DailyRewardStatus status) async {
    if (_claimInFlight || !status.available) return;
    _claimInFlight = true;

    final previous = _optimisticStatus;
    final fromBalance =
        ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    final expectedReward =
        status.milestonesBronze[status.nextStreak] ?? status.nextRewardBronze;
    // Мгновенно: кнопка → «Уже получено», карточки обновляют прогресс.
    setState(() {
      _optimisticStatus = DailyRewardStatus(
        available: false,
        streak: status.nextStreak,
        nextStreak: status.nextStreak,
        nextRewardBronze: status.nextRewardBronze,
        milestonesBronze: status.milestonesBronze,
      );
    });

    try {
      final expectedTo =
          fromBalance + (expectedReward > 0 ? expectedReward : 0);
      if (expectedReward > 0) {
        lockBalanceDisplay(
          ref: ref,
          fromBronze: fromBalance,
          toBronze: expectedTo,
          rewardBronze: expectedReward,
        );
      }
      final result =
          await ref.read(authStateProvider.notifier).claimDailyReward();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _optimisticStatus = DailyRewardStatus(
            available: false,
            streak: result.streak,
            nextStreak: result.streak,
            nextRewardBronze: status.nextRewardBronze,
            milestonesBronze: status.milestonesBronze,
          );
        });
        final reward =
            result.rewardBronze > 0 ? result.rewardBronze : expectedReward;
        if (reward > 0) {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          final sourceKey = globalRectOfKey(_claimSourceKey) != null
              ? _claimSourceKey
              : _claimButtonKey;
          await playBalanceGain(
            ref: ref,
            context: context,
            newBalanceBronze: result.balanceBronze,
            fromBronze: fromBalance,
            rewardBronze: reward,
            sourceKey: sourceKey,
            skipApply: true,
          );
        } else {
          ref.read(balanceGainProvider.notifier).end();
        }
      } else {
        ref.read(balanceGainProvider.notifier).end();
      }
    } catch (_) {
      ref.read(balanceGainProvider.notifier).end();
      if (!mounted) return;
      setState(() => _optimisticStatus = previous);
    } finally {
      _claimInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dailyRewardAsync = ref.watch(dailyRewardStatusProvider);
    void goBack() => context.pop();

    // Не уходим в полноэкранный спиннер при refresh после клейма.
    final cached = dailyRewardAsync.valueOrNull;
    final status = _optimisticStatus ?? cached;

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GamepadBackButton(
            onPressed: goBack,
            tooltip: l10n.commonBack,
          ),
          title: Text(
            l10n.coinsLoginReward,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide(context) ? 720 : 480,
              ),
              child: status != null
                  ? _LoginRewardsBody(
                      status: status,
                      claimSourceKey: _claimSourceKey,
                      claimButtonKey: _claimButtonKey,
                      onClaim: () => unawaited(_claim(status)),
                    )
                  : dailyRewardAsync.hasError
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.coinsLoadRewardsFailed,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      // Только первая загрузка; после клейма спиннера нет.
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginRewardsBody extends StatelessWidget {
  const _LoginRewardsBody({
    required this.status,
    required this.claimSourceKey,
    required this.claimButtonKey,
    required this.onClaim,
  });

  final DailyRewardStatus status;
  final GlobalKey claimSourceKey;
  final GlobalKey claimButtonKey;
  final VoidCallback onClaim;

  static const _milestones = [1, 3, 7, 30];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canClaim = status.available;
    // Плитка: планшет/десктоп и телефон landscape; portrait телефона — как было.
    final useTiles = useDesktopTiles(context);
    final alignTop = isTablet(context) || isPhoneLandscape(context);

    Widget card(int days) => _CompactMilestoneCard(
          targetDays: days,
          rewardBronze: status.milestonesBronze[days] ?? (days == 1 ? 10 : 0),
          streak: status.streak,
          nextStreak: status.nextStreak,
          availableToday: status.available,
          rewardKey: status.nextStreak == days ? claimSourceKey : null,
          compactTile: useTiles,
        );

    final claimButton = Align(
      alignment: Alignment.center,
      child: GamepadFocusBlock(
        radius: AppRadius.button,
        borderWidth: 2.2,
        onActivate: canClaim ? onClaim : null,
        child: Builder(
          builder: (context) {
            final on =
                GamepadFocusBlock.watchOf(context)?.highlighted ?? false;
            final button = FilledButton.icon(
              key: claimButtonKey,
              onPressed: canClaim ? onClaim : () {},
              icon: const Icon(Icons.card_giftcard, size: 18),
              label: Text(
                status.available
                    ? l10n.coinsClaimReward
                    : l10n.coinsAlreadyClaimed,
              ),
              style: AppButtonStyles.of(
                minimumSize: Size(useTiles ? 320 : 44, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                radius: AppRadius.button,
              ).copyWith(
                side: WidgetStatePropertyAll(
                  on
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.buttonBorder),
                ),
              ),
            );
            if (useTiles) return button;
            return SizedBox(width: double.infinity, child: button);
          },
        ),
      ),
    );

    if (useTiles) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, alignTop ? 8 : 16, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio:
                              isPhoneLandscape(context) ? 2.4 : 2.2,
                          children: [
                            for (final days in _milestones) card(days),
                          ],
                        ),
                        const SizedBox(height: 16),
                        claimButton,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < _milestones.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Expanded(child: card(_milestones[i])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          claimButton,
        ],
      ),
    );
  }
}

class _CompactMilestoneCard extends StatelessWidget {
  const _CompactMilestoneCard({
    required this.targetDays,
    required this.rewardBronze,
    required this.streak,
    required this.nextStreak,
    required this.availableToday,
    this.rewardKey,
    this.compactTile = false,
  });

  final int targetDays;
  final int rewardBronze;
  final int streak;
  final int nextStreak;
  final bool availableToday;
  final GlobalKey? rewardKey;
  final bool compactTile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final doneDays = streak.clamp(0, targetDays);
    final completed = streak >= targetDays;
    final isTodaysTarget = availableToday && nextStreak == targetDays;
    final remaining = completed ? 0 : (targetDays - doneDays);
    final pendingToday = availableToday &&
        !completed &&
        nextStreak <= targetDays &&
        nextStreak == doneDays + 1;
    final progress = targetDays <= 0
        ? 0.0
        : (doneDays + (pendingToday ? 0.35 : 0)) / targetDays;

    final title = '$targetDays ${_daysWord(targetDays)}';

    final progressLabel = completed
        ? '$targetDays/$targetDays'
        : pendingToday
            ? l10n.coinsStreakToday(doneDays, targetDays)
            : remaining == 1
                ? l10n.coinsStreakOneDayLeft(doneDays, targetDays)
                : l10n.coinsStreakDaysLeft(doneDays, targetDays, remaining);

    final borderColor = completed
        ? const Color(0xFF34B7F1).withValues(alpha: 0.5)
        : isTodaysTarget
            ? AppColors.accentStart.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isTodaysTarget ? 1.4 : 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              KeyedSubtree(
                key: rewardKey,
                child: BalanceDisplay(
                  bronze: rewardBronze,
                  coinSize: 18,
                  fontSize: 13,
                  spacing: 4,
                  animate: isTodaysTarget || pendingToday,
                ),
              ),
            ],
          ),
          if (compactTile) const SizedBox(height: 16) else const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.accentSoft.withValues(alpha: 0.55),
              color:
                  completed ? const Color(0xFF34B7F1) : AppColors.accentStart,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _daysWord(int n) {
  final l10n = LocaleService.l10n;
  final abs = n.abs();
  final mod10 = abs % 10;
  final mod100 = abs % 100;
  if (mod10 == 1 && mod100 != 11) return l10n.coinsDayOne;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return l10n.coinsDayFew;
  }
  return l10n.coinsDayMany;
}
