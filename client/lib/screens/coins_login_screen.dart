import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/balance_gain_animation.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
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
    final phoneLandscape = isPhoneLandscape(context);

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: phoneLandscape ? 44 : kToolbarHeight,
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
                maxWidth: useDesktopTiles(context) ? 680 : 480,
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

  int? get _nextMilestone {
    for (final days in _milestones) {
      if (status.streak < days) return days;
    }
    return null;
  }

  int get _todayRewardBronze {
    final milestone = status.milestonesBronze[status.nextStreak];
    if (milestone != null && milestone > 0) return milestone;
    return status.nextRewardBronze > 0 ? status.nextRewardBronze : 10;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canClaim = status.available;
    final useTiles = useDesktopTiles(context);
    final phoneLandscape = isPhoneLandscape(context);
    final activeMilestone = _nextMilestone;
    final sourceInMilestone =
        canClaim && _milestones.contains(status.nextStreak);

    Widget card(int days) => _MilestoneCard(
          key: ValueKey('login-milestone-$days'),
          targetDays: days,
          rewardBronze: status.milestonesBronze[days] ?? (days == 1 ? 10 : 0),
          streak: status.streak,
          nextStreak: status.nextStreak,
          availableToday: canClaim,
          isCurrentGoal: activeMilestone == days,
          rewardKey:
              sourceInMilestone && status.nextStreak == days ? claimSourceKey : null,
          dense: phoneLandscape,
        );

    final claimButton = _ClaimRewardButton(
      buttonKey: claimButtonKey,
      canClaim: canClaim,
      onClaim: onClaim,
      label: canClaim ? l10n.coinsClaimReward : l10n.coinsAlreadyClaimed,
      dense: phoneLandscape,
      expand: !phoneLandscape,
    );

    final hero = _StreakHeroCard(
      status: status,
      rewardBronze: _todayRewardBronze,
      rewardKey: sourceInMilestone ? null : claimSourceKey,
      dense: phoneLandscape,
      action: phoneLandscape ? null : claimButton,
      sideAction: phoneLandscape ? claimButton : null,
    );

    if (useTiles) {
      final spacing = phoneLandscape ? 10.0 : 12.0;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          phoneLandscape ? 16 : 20,
          phoneLandscape ? 4 : 12,
          phoneLandscape ? 16 : 20,
          phoneLandscape ? 12 : 24,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            SizedBox(height: spacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: card(_milestones[0])),
                SizedBox(width: spacing),
                Expanded(child: card(_milestones[1])),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: card(_milestones[2])),
                SizedBox(width: spacing),
                Expanded(child: card(_milestones[3])),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hero,
          const SizedBox(height: 12),
          for (var i = 0; i < _milestones.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            card(_milestones[i]),
          ],
        ],
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  const _StreakHeroCard({
    required this.status,
    required this.rewardBronze,
    required this.dense,
    this.rewardKey,
    this.action,
    this.sideAction,
  });

  final DailyRewardStatus status;
  final int rewardBronze;
  final bool dense;
  final GlobalKey? rewardKey;
  final Widget? action;
  final Widget? sideAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = status.available;
    final displayDays = available
        ? (status.streak > 0 ? status.streak : status.nextStreak)
        : (status.streak > 0 ? status.streak : 1);
    final daysTitle = '$displayDays ${_daysWord(displayDays)}';
    final subtitle = available
        ? l10n.coinsLoginAvailableToday
        : l10n.coinsAlreadyClaimed;
    final iconBox = dense ? 40.0 : 48.0;

    return Container(
      key: const ValueKey('login-streak-hero'),
      padding: EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(dense ? 16 : 20),
        border: Border.all(
          color: available
              ? AppColors.accentStart.withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.06),
          width: available ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStart.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(dense ? 12 : 15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  available
                      ? Icons.local_fire_department_rounded
                      : Icons.verified_rounded,
                  color: available
                      ? AppColors.accentStart
                      : const Color(0xFF0EA5E9),
                  size: dense ? 22 : 26,
                ),
              ),
              SizedBox(width: dense ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.coinsLoginStreak,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            daysTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: dense ? 17 : 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: available
                                  ? AppColors.accentSoft
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: available
                                    ? AppColors.accentStart
                                    : const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              KeyedSubtree(
                key: rewardKey,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dense ? 10 : 12,
                    vertical: dense ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceUnified,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: BalanceDisplay(
                    bronze: rewardBronze,
                    coinSize: dense ? 18 : 20,
                    fontSize: dense ? 14 : 15,
                    spacing: 5,
                    animate: available,
                  ),
                ),
              ),
              if (sideAction != null) ...[
                const SizedBox(width: 10),
                IntrinsicWidth(child: sideAction!),
              ],
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

class _ClaimRewardButton extends StatelessWidget {
  const _ClaimRewardButton({
    required this.buttonKey,
    required this.canClaim,
    required this.onClaim,
    required this.label,
    required this.dense,
    this.expand = true,
  });

  final GlobalKey buttonKey;
  final bool canClaim;
  final VoidCallback onClaim;
  final String label;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      outlined: false,
      radius: AppRadius.button,
      borderWidth: 2.2,
      onActivate: canClaim ? onClaim : null,
      child: Builder(
        builder: (context) {
          final focusSide = GamepadFocusBlock.buttonSide(context);
          final defaultSide = BorderSide(
            color: canClaim
                ? AppColors.accentStart
                : AppColors.buttonBorder.withValues(alpha: 0.7),
          );
          final side = focusSide.width > 1 ? focusSide : defaultSide;
          final fg = canClaim ? Colors.white : AppColors.textSecondary;
          final button = FilledButton.icon(
            key: buttonKey,
            onPressed: canClaim ? onClaim : () {},
            icon: Icon(
              canClaim
                  ? Icons.card_giftcard_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
            ),
            label: Text(label),
            style: AppButtonStyles.of(
              minimumSize: Size(44, dense ? 38 : 46),
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 14 : 16,
                vertical: dense ? 8 : 12,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              radius: AppRadius.button,
              foregroundColor: fg,
              textStyle: TextStyle(
                fontSize: dense ? 13 : 15,
                fontWeight: FontWeight.w700,
                color: fg,
                decoration: TextDecoration.none,
              ),
            ).copyWith(
              backgroundColor: WidgetStatePropertyAll(
                canClaim ? AppColors.accentStart : AppColors.surfaceUnified,
              ),
              foregroundColor: WidgetStatePropertyAll(fg),
              iconColor: WidgetStatePropertyAll(fg),
              overlayColor: WidgetStatePropertyAll(
                canClaim
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
              ),
              side: WidgetStatePropertyAll(side),
            ),
          );
          if (!expand) return button;
          return SizedBox(width: double.infinity, child: button);
        },
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    super.key,
    required this.targetDays,
    required this.rewardBronze,
    required this.streak,
    required this.nextStreak,
    required this.availableToday,
    required this.isCurrentGoal,
    this.rewardKey,
    this.dense = false,
  });

  final int targetDays;
  final int rewardBronze;
  final int streak;
  final int nextStreak;
  final bool availableToday;
  final bool isCurrentGoal;
  final GlobalKey? rewardKey;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final doneDays = streak.clamp(0, targetDays);
    final completed = streak >= targetDays;
    final isTodaysTarget = availableToday && nextStreak == targetDays;
    final remaining = completed ? 0 : (targetDays - doneDays);
    final progress = targetDays <= 0
        ? 0.0
        : (doneDays + (isTodaysTarget ? 0.35 : 0)) / targetDays;

    final title = '$targetDays ${_daysWord(targetDays)}';

    final progressLabel = completed
        ? '$targetDays/$targetDays · ${l10n.achievementsClaimed}'
        : isTodaysTarget
            ? l10n.coinsStreakToday(doneDays, targetDays)
            : remaining == 1
                ? l10n.coinsStreakOneDayLeft(doneDays, targetDays)
                : l10n.coinsStreakDaysLeft(doneDays, targetDays, remaining);

    final highlight = isTodaysTarget || isCurrentGoal;
    final borderColor = completed
        ? const Color(0xFF34B7F1).withValues(alpha: 0.45)
        : highlight
            ? AppColors.accentStart.withValues(alpha: 0.55)
            : Colors.black.withValues(alpha: 0.07);

    final badgeBg = completed
        ? const Color(0xFFE0F2FE)
        : highlight
            ? AppColors.accentSoft
            : AppColors.surfaceUnified;
    final badgeFg = completed
        ? const Color(0xFF0284C7)
        : highlight
            ? AppColors.accentStart
            : AppColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(dense ? 14 : 18),
        border: Border.all(
          color: borderColor,
          width: highlight ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        dense ? 12 : 14,
        dense ? 10 : 12,
        dense ? 12 : 14,
        dense ? 10 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: dense ? 26 : 30,
                height: dense ? 26 : 30,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(dense ? 8 : 10),
                ),
                alignment: Alignment.center,
                child: completed
                    ? Icon(
                        Icons.check_rounded,
                        size: dense ? 16 : 18,
                        color: badgeFg,
                      )
                    : Text(
                        '$targetDays',
                        style: TextStyle(
                          fontSize: dense ? 12 : 13,
                          fontWeight: FontWeight.w800,
                          color: badgeFg,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 14 : 15,
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
                  coinSize: dense ? 18 : 20,
                  fontSize: dense ? 13 : 14,
                  spacing: 4,
                  animate: isTodaysTarget || isCurrentGoal,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 10),
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
          SizedBox(height: dense ? 5 : 6),
          Text(
            progressLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: completed || highlight
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: completed
                  ? const Color(0xFF0284C7)
                  : AppColors.textSecondary,
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
