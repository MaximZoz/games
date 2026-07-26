import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

class CoinsLoginScreen extends ConsumerStatefulWidget {
  const CoinsLoginScreen({super.key});

  @override
  ConsumerState<CoinsLoginScreen> createState() => _CoinsLoginScreenState();
}

class _CoinsLoginScreenState extends ConsumerState<CoinsLoginScreen> {
  bool _isClaiming = false;
  String? _lastClaimMessage;

  @override
  Widget build(BuildContext context) {
    final dailyRewardAsync = ref.watch(dailyRewardStatusProvider);
    void goBack() => context.pop();

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
            'Монеты за вход',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: dailyRewardAsync.when(
                data: (status) => _LoginRewardsBody(
                  status: status,
                  isClaiming: _isClaiming,
                  lastClaimMessage: _lastClaimMessage,
                  onClaim: () async {
                    if (_isClaiming) return;
                    setState(() {
                      _isClaiming = true;
                      _lastClaimMessage = null;
                    });
                    final result = await ref
                        .read(authStateProvider.notifier)
                        .claimDailyReward();
                    if (!mounted) return;
                    setState(() {
                      _isClaiming = false;
                      if (result != null) {
                        _lastClaimMessage =
                            'Получено: ${formatRewardBronze(result.rewardBronze)} · день ${result.streak}';
                      }
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Не удалось загрузить награды',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
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
    required this.onClaim,
    required this.isClaiming,
    this.lastClaimMessage,
  });

  final DailyRewardStatus status;
  final Future<void> Function() onClaim;
  final bool isClaiming;
  final String? lastClaimMessage;

  static const _milestones = [1, 3, 7, 30];

  @override
  Widget build(BuildContext context) {
    final canClaim = status.available && !isClaiming;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          status.available
              ? 'Заберите награду за сегодня — день ${status.nextStreak} серии'
              : 'Сегодня уже получено · серия ${status.streak} дн.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (lastClaimMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            lastClaimMessage!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.accentStart,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ..._milestones.map((day) {
          final bronze = status.milestonesBronze[day] ?? (day == 1 ? 10 : 0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MilestoneRewardCard(
              targetDays: day,
              rewardBronze: bronze,
              streak: status.streak,
              nextStreak: status.nextStreak,
              availableToday: status.available,
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: canClaim ? () => onClaim() : null,
            icon: isClaiming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.card_giftcard, size: 18),
            label: Text(
              isClaiming
                  ? '...'
                  : (status.available
                      ? 'Забрать сегодняшнюю награду'
                      : 'Уже получено сегодня'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentStart,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.accentStart.withValues(alpha: 0.45),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneRewardCard extends StatelessWidget {
  const _MilestoneRewardCard({
    required this.targetDays,
    required this.rewardBronze,
    required this.streak,
    required this.nextStreak,
    required this.availableToday,
  });

  final int targetDays;
  final int rewardBronze;
  final int streak;
  final int nextStreak;
  final bool availableToday;

  @override
  Widget build(BuildContext context) {
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

    final title = targetDays == 1
        ? 'Каждый день'
        : '$targetDays ${_daysWord(targetDays)} подряд';

    final statusText = completed
        ? 'Получено · $targetDays из $targetDays'
        : pendingToday
            ? '$doneDays из $targetDays · сегодня закроет день ${doneDays + 1}'
            : remaining == 1
                ? '$doneDays из $targetDays · остался 1 день'
                : '$doneDays из $targetDays · осталось $remaining ${_daysWord(remaining)}';

    final borderColor = completed
        ? const Color(0xFF34B7F1).withValues(alpha: 0.55)
        : isTodaysTarget
            ? AppColors.accentStart.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isTodaysTarget ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: (isTodaysTarget ? AppColors.accentStart : Colors.black)
                .withValues(alpha: isTodaysTarget ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentSoft.withValues(alpha: 0.65),
                ),
                alignment: Alignment.center,
                child: CoinIcon(
                  coinType: rewardCoinType(rewardBronze),
                  size: 28,
                  animate: isTodaysTarget || pendingToday,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRewardBronze(rewardBronze),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentStart.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                completed: completed,
                pendingToday: pendingToday,
                remaining: remaining,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.accentSoft.withValues(alpha: 0.55),
                  color: completed
                      ? const Color(0xFF34B7F1)
                      : AppColors.accentStart,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _DayDotsRow(
            targetDays: targetDays,
            doneDays: doneDays,
            pendingToday: pendingToday,
            completed: completed,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.completed,
    required this.pendingToday,
    required this.remaining,
  });

  final bool completed;
  final bool pendingToday;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (completed) {
      bg = const Color(0xFF34B7F1).withValues(alpha: 0.16);
      fg = const Color(0xFF0288D1);
      label = 'Готово';
    } else if (pendingToday) {
      bg = AppColors.accentSoft;
      fg = AppColors.accentStart;
      label = 'Сегодня';
    } else {
      bg = Colors.black.withValues(alpha: 0.05);
      fg = AppColors.textSecondary;
      label = '−$remaining';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DayDotsRow extends StatelessWidget {
  const _DayDotsRow({
    required this.targetDays,
    required this.doneDays,
    required this.pendingToday,
    required this.completed,
  });

  final int targetDays;
  final int doneDays;
  final bool pendingToday;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (targetDays > 10) {
      return _SegmentedDaysBar(
        targetDays: targetDays,
        doneDays: doneDays,
        pendingToday: pendingToday,
        completed: completed,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(targetDays, (index) {
        final dayNumber = index + 1;
        final filled = dayNumber <= doneDays;
        final isPending = pendingToday && dayNumber == doneDays + 1;
        return _DayDot(
          dayNumber: dayNumber,
          filled: filled,
          pending: isPending,
          completedMilestone: completed,
        );
      }),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.dayNumber,
    required this.filled,
    required this.pending,
    required this.completedMilestone,
  });

  final int dayNumber;
  final bool filled;
  final bool pending;
  final bool completedMilestone;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Color textColor;

    if (filled) {
      fill = completedMilestone ? const Color(0xFF34B7F1) : AppColors.accentStart;
      border = fill;
      textColor = Colors.white;
    } else if (pending) {
      fill = AppColors.accentSoft;
      border = AppColors.accentStart;
      textColor = AppColors.accentStart;
    } else {
      fill = Colors.white;
      border = Colors.black.withValues(alpha: 0.12);
      textColor = AppColors.textSecondary.withValues(alpha: 0.7);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: pending ? 2 : 1),
        boxShadow: pending
            ? [
                BoxShadow(
                  color: AppColors.accentStart.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Text(
        '$dayNumber',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _SegmentedDaysBar extends StatelessWidget {
  const _SegmentedDaysBar({
    required this.targetDays,
    required this.doneDays,
    required this.pendingToday,
    required this.completed,
  });

  final int targetDays;
  final int doneDays;
  final bool pendingToday;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    const segments = 10;
    final perSegment = targetDays / segments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(segments, (index) {
            final start = (index * perSegment).floor();
            final end = ((index + 1) * perSegment).ceil().clamp(0, targetDays);
            final segDone = doneDays >= end;
            final segPartial = !segDone && doneDays > start;
            final segPending = pendingToday &&
                doneDays >= start &&
                doneDays < end &&
                !segDone;

            Color color;
            if (segDone) {
              color =
                  completed ? const Color(0xFF34B7F1) : AppColors.accentStart;
            } else if (segPartial || segPending) {
              color = AppColors.accentStart.withValues(alpha: 0.45);
            } else {
              color = AppColors.accentSoft.withValues(alpha: 0.7);
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == segments - 1 ? 0 : 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '$doneDays / $targetDays дней',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

String _daysWord(int n) {
  final abs = n.abs();
  final mod10 = abs % 10;
  final mod100 = abs % 100;
  if (mod10 == 1 && mod100 != 11) return 'день';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'дня';
  }
  return 'дней';
}
