import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/referral_link.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Хаб «Монеты»: две группы, как карточки на главной.
class CoinsScreen extends ConsumerWidget {
  const CoinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rewardAvailable =
        ref.watch(dailyRewardAvailableProvider).valueOrNull == true;
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
            tooltip: l10n.commonBack,
          ),
          title: Text(
            l10n.homeCoins,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeActionCard(
                      icon: Icons.calendar_today_rounded,
                      title: l10n.coinsLoginReward,
                      subtitle: rewardAvailable
                          ? l10n.coinsLoginAvailableToday
                          : l10n.coinsLoginStreak,
                      badgeCount: rewardAvailable ? 1 : 0,
                      onTap: () => context.push('/coins/login'),
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.person_add_alt_1_rounded,
                      title: l10n.coinsFriendReward,
                      subtitle: l10n.coinsFriendRewardHint(
                        formatRewardBronze(referralBonusBronze),
                      ),
                      onTap: () => context.push('/coins/friend'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
