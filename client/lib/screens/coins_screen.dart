import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/referral_link.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

enum _CoinsTab { login, friend }

class CoinsScreen extends ConsumerStatefulWidget {
  const CoinsScreen({super.key});

  @override
  ConsumerState<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends ConsumerState<CoinsScreen> {
  bool _isClaiming = false;
  String? _lastClaimMessage;
  _CoinsTab _tab = _CoinsTab.login;
  bool _linkCopied = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
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
            tooltip: 'Назад на главную',
          ),
          title: Text(
            'Награды',
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
              child: authState.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          12,
                        ),
                        child: SegmentedButton<_CoinsTab>(
                          segments: const [
                            ButtonSegment(
                              value: _CoinsTab.login,
                              label: Text('Монеты за вход'),
                              icon: Icon(Icons.calendar_today_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: _CoinsTab.friend,
                              label: Text('Монеты за друга'),
                              icon: Icon(Icons.person_add_alt_1_rounded, size: 16),
                            ),
                          ],
                          selected: {_tab},
                          onSelectionChanged: (next) {
                            setState(() {
                              _tab = next.first;
                              _linkCopied = false;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.accentSoft;
                              }
                              return AppColors.surfaceCard;
                            }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.accentStart;
                              }
                              return AppColors.textSecondary;
                            }),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _tab == _CoinsTab.login
                            ? dailyRewardAsync.when(
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
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, __) => const Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Text(
                                    'Не удалось загрузить награды',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : _FriendRewardsBody(
                                userId: user.id,
                                linkCopied: _linkCopied,
                                onCopyLink: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final url = buildReferralShareUrl(
                                    userId: user.id,
                                    baseUri: Uri.base,
                                  );
                                  await Clipboard.setData(
                                    ClipboardData(text: url),
                                  );
                                  if (!mounted) return;
                                  setState(() => _linkCopied = true);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Ссылка скопирована'),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRewardsBody extends StatelessWidget {
  const _FriendRewardsBody({
    required this.userId,
    required this.onCopyLink,
    required this.linkCopied,
  });

  final String userId;
  final VoidCallback onCopyLink;
  final bool linkCopied;

  @override
  Widget build(BuildContext context) {
    final url = buildReferralShareUrl(userId: userId, baseUri: Uri.base);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSoft.withValues(alpha: 0.7),
                    ),
                    alignment: Alignment.center,
                    child: const CoinIcon(
                      coinType: CoinType.bronze,
                      size: 30,
                      animate: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Пригласи друга',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${formatRewardBronze(referralBonusBronze)} за каждого, кто зарегистрируется по вашей ссылке',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCopyLink,
                  icon: Icon(
                    linkCopied ? Icons.check_rounded : Icons.link_rounded,
                    size: 18,
                  ),
                  label: Text(linkCopied ? 'Скопировано' : 'Скопировать ссылку'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Как это работает',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _FriendStep(
          number: '1',
          text: 'Скопируйте ссылку и отправьте другу',
        ),
        _FriendStep(
          number: '2',
          text: 'Друг регистрируется по этой ссылке',
        ),
        _FriendStep(
          number: '3',
          text: 'Вам начисляется ${formatRewardBronze(referralBonusBronze)}',
        ),
      ],
    );
  }
}

class _FriendStep extends StatelessWidget {
  const _FriendStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentStart,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
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
                  : (status.available ? 'Забрать сегодняшнюю награду' : 'Уже получено сегодня'),
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
    // Если сегодня можно забрать и это продвинет к цели — подсветим следующий слот.
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
    // Для длинных серий (30) показываем компактные сегменты группами, не 30 огромных точек.
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
              color = completed
                  ? const Color(0xFF34B7F1)
                  : AppColors.accentStart;
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
