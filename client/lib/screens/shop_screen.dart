import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Хаб магазина — три раздела, как на экране монет.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            'Магазин',
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
                      icon: Icons.emoji_emotions_outlined,
                      title: 'Смайлики',
                      subtitle: 'Анимированные эмодзи для чата',
                      onTap: () => context.push('/shop/emojis'),
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Коллекции',
                      subtitle: 'Витрина профиля, подарки и доход',
                      onTap: () => context.push('/shop/collections'),
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.crop_square_rounded,
                      title: 'Рамки',
                      subtitle: 'Оформление аватара в профиле',
                      onTap: () => context.push('/shop/frames'),
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.casino_outlined,
                      title: 'Ставки',
                      subtitle: 'Разблокировка серебряных ставок',
                      onTap: () => context.push('/shop/stakes'),
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
