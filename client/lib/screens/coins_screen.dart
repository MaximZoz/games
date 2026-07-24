import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class CoinsScreen extends ConsumerStatefulWidget {
  const CoinsScreen({super.key});

  @override
  ConsumerState<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends ConsumerState<CoinsScreen> {
  bool _isClaiming = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final dailyRewardAsync = ref.watch(dailyRewardAvailableProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Назад в профиль',
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
                      data: (available) => _DailyRewardCard(
                        available: available,
                        isClaiming: _isClaiming,
                        onClaim: () async {
                          if (_isClaiming) return;
                          setState(() => _isClaiming = true);
                          await ref.read(authStateProvider.notifier).claimDailyReward();
                          if (mounted) setState(() => _isClaiming = false);
                        },
                      ),
                      loading: () => _DailyRewardCard(
                        available: false,
                        isClaiming: false,
                        onClaim: () async {},
                      ),
                      error: (err, _) => _DailyRewardCard(
                        available: false,
                        isClaiming: false,
                        onClaim: () async {},
                        errorMessage: 'Не удалось проверить. Нажмите «Обновить».',
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({
    required this.available,
    required this.onClaim,
    this.isClaiming = false,
    this.errorMessage,
  });

  final bool available;
  final Future<void> Function() onClaim;
  final bool isClaiming;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final canClaim = available && !isClaiming;
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
                      coinType: CoinType.bronze,
                      size: 40,
                      animate: available,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ежедневная награда',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            errorMessage ??
                                (available
                                    ? '20 бронзовых монет'
                                    : 'Уже получено сегодня'),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canClaim ? () { onClaim(); } : null,
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
                      disabledBackgroundColor: AppColors.accentStart.withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
