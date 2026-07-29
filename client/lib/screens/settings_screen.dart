import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addBotsAfter30s = ref.watch(addBotsAfter30sProvider);
    final webPushEnabled = ref.watch(webPushEnabledProvider);
    final pushCategories = ref.watch(webPushCategoriesProvider);
    final narrow = isNarrow(context);
    final padding = narrow ? 24.0 : 32.0;

    Future<void> setCategory(Future<String?> Function() save) async {
      final err = await save();
      if (!context.mounted || err == null) return;
      showAppSnackBar(
        context,
        message: err,
        kind: AppSnackKind.error,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Настройки',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsCard(
                    child: _SwitchRow(
                      title: 'Добавлять ботов через 30 с',
                      subtitle:
                          'В режиме «поиск игры»: если соперник не найден за 30 секунд, игра начинается с ботом (цена игры сбрасывается до 1-й бронзы)',
                      value: addBotsAfter30s,
                      onChanged: (v) =>
                          ref.read(addBotsAfter30sProvider.notifier).set(v),
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SwitchRow(
                            title: 'Уведомления',
                            value: webPushEnabled,
                            onChanged: isWebPushSupported
                                ? (v) async {
                                    final err = await ref
                                        .read(webPushEnabledProvider.notifier)
                                        .setEnabled(v);
                                    if (!context.mounted) return;
                                    if (err != null) {
                                      showAppSnackBar(
                                        context,
                                        message: err,
                                        kind: AppSnackKind.error,
                                      );
                                    }
                                  }
                                : null,
                          ),
                          if (webPushEnabled) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: AppColors.accentSoft),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _CategoryCheck(
                                    title: 'Чат',
                                    value: pushCategories.chat,
                                    onChanged: (v) => setCategory(
                                      () => ref
                                          .read(
                                              webPushCategoriesProvider.notifier)
                                          .setCategory(chat: v),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _CategoryCheck(
                                    title: 'Друзья',
                                    value: pushCategories.friends,
                                    onChanged: (v) => setCategory(
                                      () => ref
                                          .read(
                                              webPushCategoriesProvider.notifier)
                                          .setCategory(friends: v),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _CategoryCheck(
                                    title: 'Игры',
                                    value: pushCategories.games,
                                    onChanged: (v) => setCategory(
                                      () => ref
                                          .read(
                                              webPushCategoriesProvider.notifier)
                                          .setCategory(games: v),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _CategoryCheck(
                                    title: 'Награды',
                                    value: pushCategories.rewards,
                                    onChanged: (v) => setCategory(
                                      () => ref
                                          .read(
                                              webPushCategoriesProvider.notifier)
                                          .setCategory(rewards: v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppRadius.card),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentSoft),
      ),
      child: child,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitleText != null && subtitleText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.accentStart,
        ),
      ],
    );
  }
}

class _CategoryCheck extends StatelessWidget {
  const _CategoryCheck({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.accentStart,
                side: const BorderSide(color: AppColors.accentSoft, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
