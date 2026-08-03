import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Хаб магазина — три раздела, как на экране монет.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOffline = ref.watch(isOfflineProvider);
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
            l10n.shopTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeActionCard(
                      icon: Icons.emoji_emotions_outlined,
                      title: l10n.shopEmojis,
                      subtitle: l10n.shopEmojisSubtitle,
                      onTap: () => context.push('/shop/emojis'),
                    ),
                    const SizedBox(height: 12),
                    HomeActionCard(
                      icon: Icons.auto_awesome_outlined,
                      title: l10n.shopCollections,
                      subtitle: l10n.shopCollectionsSubtitle,
                      onTap: () => context.push('/shop/collections'),
                    ),
                    if (!isOffline) ...[
                      const SizedBox(height: 12),
                      HomeActionCard(
                        icon: Icons.casino_outlined,
                        title: l10n.shopStakes,
                        subtitle: l10n.shopStakesSubtitle,
                        onTap: () => context.push('/shop/stakes'),
                      ),
                    ],
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
