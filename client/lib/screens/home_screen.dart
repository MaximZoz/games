import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';

/// Контент главной страницы. Тулбар (Войти/Регистрация) в [AppShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardAvailable =
        ref.watch(dailyRewardAvailableProvider).valueOrNull == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Достижения',
                    subtitle: 'Ваши игровые результаты',
                    onTap: () => context.push('/achievements'),
                  ),
                  const SizedBox(height: 12),
                  HomeActionCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Монеты',
                    subtitle: rewardAvailable
                        ? 'Доступна награда за вход'
                        : 'Баланс и награды',
                    badgeCount: rewardAvailable ? 1 : 0,
                    onTap: () => context.push('/coins'),
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
