import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final addBotsAfter30s = ref.watch(addBotsAfter30sProvider);
    final messagesFriendsOnly = ref.watch(messagesFriendsOnlyProvider);
    final webPushEnabled = ref.watch(webPushEnabledProvider);
    final pushCategories = ref.watch(webPushCategoriesProvider);
    final localeChoice = ref.watch(appLocaleProvider);
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

    final languageValue = localeChoice == null
        ? 'system'
        : localeChoice.languageCode;

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
                    l10n.settingsTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.settingsLanguage,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: languageValue,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'system',
                              child: Text(l10n.settingsLanguageSystem),
                            ),
                            DropdownMenuItem(
                              value: 'ru',
                              child: Text(l10n.settingsLanguageRu),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.settingsLanguageEn),
                            ),
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            if (v == 'system') {
                              await ref
                                  .read(appLocaleProvider.notifier)
                                  .setLocale(null);
                            } else {
                              await ref
                                  .read(appLocaleProvider.notifier)
                                  .setLocale(Locale(v));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SwitchRow(
                      title: l10n.settingsAddBotsTitle,
                      subtitle: l10n.settingsAddBotsSubtitle,
                      value: addBotsAfter30s,
                      onChanged: (v) =>
                          ref.read(addBotsAfter30sProvider.notifier).set(v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SwitchRow(
                      title: l10n.settingsFriendsOnlyTitle,
                      subtitle: l10n.settingsFriendsOnlySubtitle,
                      value: messagesFriendsOnly,
                      onChanged: (v) async {
                        final err = await ref
                            .read(messagesFriendsOnlyProvider.notifier)
                            .set(v);
                        if (!context.mounted || err == null) return;
                        showAppSnackBar(
                          context,
                          message: err,
                          kind: AppSnackKind.error,
                        );
                      },
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SwitchRow(
                            title: l10n.settingsNotifications,
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
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                _CategoryCheck(
                                  title: l10n.settingsPushChat,
                                  value: pushCategories.chat,
                                  onChanged: (v) => setCategory(
                                    () => ref
                                        .read(webPushCategoriesProvider.notifier)
                                        .setCategory(chat: v),
                                  ),
                                ),
                                _CategoryCheck(
                                  title: l10n.settingsPushFriends,
                                  value: pushCategories.friends,
                                  onChanged: (v) => setCategory(
                                    () => ref
                                        .read(webPushCategoriesProvider.notifier)
                                        .setCategory(friends: v),
                                  ),
                                ),
                                _CategoryCheck(
                                  title: l10n.settingsPushGames,
                                  value: pushCategories.games,
                                  onChanged: (v) => setCategory(
                                    () => ref
                                        .read(webPushCategoriesProvider.notifier)
                                        .setCategory(games: v),
                                  ),
                                ),
                                _CategoryCheck(
                                  title: l10n.settingsPushRewards,
                                  value: pushCategories.rewards,
                                  onChanged: (v) => setCategory(
                                    () => ref
                                        .read(webPushCategoriesProvider.notifier)
                                        .setCategory(rewards: v),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: AppColors.accentStart,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
