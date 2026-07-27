import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryListProvider);
    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }

    final items = async.valueOrNull ?? const <InventoryItem>[];
    final emojis = items.where((e) => e.kind == 'emoji').toList();
    final stakes = items.where((e) => e.kind == 'stake_unlock').toList();
    final frames = items.where((e) => e.kind == 'frame').toList();

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
            'Предметы',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: async.hasError && items.isEmpty
              ? const Center(
                  child: Text(
                    'Не удалось загрузить предметы',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : items.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока ничего нет — загляните в магазин',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _Section(
                          title: 'Смайлики',
                          empty: 'Нет смайликов',
                          children: [
                            for (final it in emojis)
                              _InvTile(
                                leading: Text(
                                  it.emoji ?? '🙂',
                                  style: const TextStyle(fontSize: 26),
                                ),
                                title: it.title,
                                subtitle: it.description,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Ставки',
                          empty: 'Нет купленных ставок',
                          children: [
                            for (final it in stakes)
                              _InvTile(
                                leading: const CoinIcon(
                                  coinType: CoinType.silver,
                                  size: 26,
                                ),
                                title: it.title,
                                subtitle:
                                    'Можно ставить ${it.stakeSilver ?? (it.stakeBronze ?? 0) ~/ 100} серебра',
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Рамки',
                          empty: 'Нет рамок',
                          children: [
                            for (final it in frames)
                              _InvTile(
                                leading: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _parseColor(it.frameColor) ??
                                          AppColors.accentStart,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                title: it.title,
                                subtitle: it.description,
                              ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(
            empty,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          ...[
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
      ],
    );
  }
}

class _InvTile extends StatelessWidget {
  const _InvTile({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(v);
}
