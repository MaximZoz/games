import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/referral_link.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Хаб «Монеты»: две группы, как карточки на главной.
class CoinsScreen extends ConsumerWidget {
  const CoinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Выберите награду',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Монеты за вход и за приглашение друзей',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    HomeActionCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Монеты за вход',
                      subtitle: rewardAvailable
                          ? 'Доступна награда за сегодня'
                          : 'Ежедневная серия входов',
                      badgeCount: rewardAvailable ? 1 : 0,
                      onTap: () => context.push('/coins/login'),
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Монеты за друга',
                      subtitle:
                          '+${formatRewardBronze(referralBonusBronze)} за регистрацию по ссылке',
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
