import 'dart:async';

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
  bool _claimInFlight = false;
  /// Локальный статус после клейма — без спиннера на время invalidate.
  DailyRewardStatus? _optimisticStatus;

  Future<void> _claim(DailyRewardStatus status) async {
    if (_claimInFlight || !status.available) return;
    _claimInFlight = true;

    final previous = _optimisticStatus;
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
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimisticStatus = previous);
    } finally {
      _claimInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: status != null
                  ? _LoginRewardsBody(
                      status: status,
                      onClaim: () => unawaited(_claim(status)),
                    )
                  : dailyRewardAsync.hasError
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Не удалось загрузить награды',
                            style: TextStyle(color: AppColors.textSecondary),
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
    required this.onClaim,
  });

  final DailyRewardStatus status;
  final VoidCallback onClaim;

  static const _milestones = [1, 3, 7, 30];

  @override
  Widget build(BuildContext context) {
    final canClaim = status.available;

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
              onPressed: canClaim ? onClaim : null,
              icon: const Icon(Icons.card_giftcard, size: 18),
              label: Text(
                status.available ? 'Забрать награду' : 'Уже получено',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentStart,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.accentStart.withValues(alpha: 0.45),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    final title = '$targetDays ${_daysWord(targetDays)}';

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
              BalanceDisplay(
                bronze: rewardBronze,
                coinSize: 18,
                fontSize: 13,
                spacing: 4,
                prefix: '+',
                animate: isTodaysTarget || pendingToday,
              ),
              const SizedBox(width: 8),
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
