import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class CoinsScreen extends ConsumerStatefulWidget {
  const CoinsScreen({super.key});

  @override
  ConsumerState<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends ConsumerState<CoinsScreen> {
  bool _isClaiming = false;
  String? _lastClaimMessage;

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
            'Монеты',
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
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                shrinkWrap: true,
                children: [
                  authState.when(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      return dailyRewardAsync.when(
                        data: (status) => _DailyRewardCard(
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
                        loading: () => _DailyRewardCard(
                          status: const DailyRewardStatus(
                            available: false,
                            streak: 0,
                            nextStreak: 1,
                            nextRewardBronze: 10,
                          ),
                          isClaiming: false,
                          onClaim: () async {},
                        ),
                        error: (err, _) => _DailyRewardCard(
                          status: const DailyRewardStatus(
                            available: false,
                            streak: 0,
                            nextStreak: 1,
                            nextRewardBronze: 10,
                          ),
                          isClaiming: false,
                          onClaim: () async {},
                          errorMessage:
                              'Не удалось проверить. Нажмите «Обновить».',
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({
    required this.status,
    required this.onClaim,
    this.isClaiming = false,
    this.errorMessage,
    this.lastClaimMessage,
  });

  final DailyRewardStatus status;
  final Future<void> Function() onClaim;
  final bool isClaiming;
  final String? errorMessage;
  final String? lastClaimMessage;

  static const _milestoneOrder = [1, 3, 7, 30];

  @override
  Widget build(BuildContext context) {
    final available = status.available;
    final canClaim = available && !isClaiming;
    final rewardType = rewardCoinType(status.nextRewardBronze);
    final subtitle = errorMessage ??
        lastClaimMessage ??
        (available
            ? '${formatRewardBronze(status.nextRewardBronze)} · день ${status.nextStreak}'
            : 'Уже получено сегодня · серия ${status.streak} дн.');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBorderBox(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CoinIcon(
                      coinType: rewardType,
                      size: 40,
                      animate: available,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Награда за вход',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Серия дней подряд',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._milestoneOrder.map((day) {
                  final bronze =
                      status.milestonesBronze[day] ?? (day == 1 ? 10 : 0);
                  final reached = status.streak >= day;
                  final isNext = available && status.nextStreak == day;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          reached
                              ? Icons.check_circle
                              : (isNext
                                  ? Icons.radio_button_checked
                                  : Icons.circle_outlined),
                          size: 18,
                          color: reached || isNext
                              ? AppColors.accentStart
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        CoinIcon(
                          coinType: rewardCoinType(bronze),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            day == 1
                                ? 'Каждый день: ${formatRewardBronze(bronze)}'
                                : '$day дней: ${formatRewardBronze(bronze)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isNext ? FontWeight.w700 : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canClaim
                        ? () {
                            onClaim();
                          }
                        : null,
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
                    label: Text(isClaiming ? '...' : 'Забрать'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentStart,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.accentStart.withValues(alpha: 0.5),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (available)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
