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
                  onClaim: () async {
                    if (_isClaiming) return;
                    setState(() => _isClaiming = true);
                    await ref.read(authStateProvider.notifier).claimDailyReward();
                    if (!mounted) return;
                    setState(() => _isClaiming = false);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(16),
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
  });

  final DailyRewardStatus status;
  final Future<void> Function() onClaim;
  final bool isClaiming;

  static const _milestones = [1, 3, 7, 30];

  @override
  Widget build(BuildContext context) {
    final canClaim = status.available && !isClaiming;

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
                  Expanded(
                    child: _CompactMilestoneCard(
                      targetDays: _milestones[i],
                      rewardBronze: status.milestonesBronze[_milestones[i]] ??
                          (_milestones[i] == 1 ? 10 : 0),
                      streak: status.streak,
                      nextStreak: status.nextStreak,
                      availableToday: status.available,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                    : (status.available ? 'Забрать награду' : 'Уже получено'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentStart,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.accentStart.withValues(alpha: 0.45),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
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
        : '$targetDays ${_daysWord(targetDays)}';

    final progressLabel = completed
        ? '$targetDays/$targetDays'
        : pendingToday
            ? '$doneDays/$targetDays · сегодня'
            : remaining == 1
                ? '$doneDays/$targetDays · ещё 1 день'
                : '$doneDays/$targetDays · ещё $remaining';

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
              CoinIcon(
                coinType: rewardCoinType(rewardBronze),
                size: 22,
                animate: isTodaysTarget || pendingToday,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title · ${formatRewardBronze(rewardBronze)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MiniChip(
                completed: completed,
                pendingToday: pendingToday,
                remaining: remaining,
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.accentSoft.withValues(alpha: 0.55),
              color: completed ? const Color(0xFF34B7F1) : AppColors.accentStart,
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
