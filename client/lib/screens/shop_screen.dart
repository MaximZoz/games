import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/desktop_tile_grid.dart';
import 'package:multigames_client/ui/widgets/home_action_card.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Хаб магазина — три раздела, как на экране монет.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOffline = ref.watch(isOfflineProvider);
    final tiles = useDesktopTiles(context);
    final dense = isPhoneLandscape(context);
    void goBack() => context.pop();

    final cards = <Widget>[
      HomeActionCard(
        icon: Icons.emoji_emotions_outlined,
        title: l10n.shopEmojis,
        subtitle: l10n.shopEmojisSubtitle,
        onTap: () => context.push('/shop/emojis'),
        dense: dense,
      ),
      HomeActionCard(
        icon: Icons.auto_awesome_outlined,
        title: l10n.shopCollections,
        subtitle: l10n.shopCollectionsSubtitle,
        onTap: () => context.push('/shop/collections'),
        dense: dense,
      ),
      if (!isOffline)
        HomeActionCard(
          icon: Icons.casino_outlined,
          title: l10n.shopStakes,
          subtitle: l10n.shopStakesSubtitle,
          onTap: () => context.push('/shop/stakes'),
          dense: dense,
        ),
    ];

    Widget mobileList(BuildContext context) {
      return Align(
        alignment: Alignment.topCenter,
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
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  cards[i],
                ],
              ],
            ),
          ),
        ),
      );
    }

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
          child: tiles
              ? DesktopTileGrid(
                  itemCount: cards.length,
                  maxCellWidth: dense ? 240 : 320,
                  maxContentWidth: 1100,
                  maxColumns: 3,
                  padding: EdgeInsets.fromLTRB(
                    dense ? 12 : 20,
                    dense ? 8 : 16,
                    dense ? 12 : 20,
                    24,
                  ),
                  itemBuilder: (_, i) => cards[i],
                  mobileBuilder: mobileList,
                )
              : mobileList(context),
        ),
      ),
    );
  }
}
