import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
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
    final offlineMode = ref.watch(offlineModeProvider);
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

    final effective = effectiveAppLocale(localeChoice);
    final currentLang = appLanguageByCode(effective.languageCode);
    final languageLabel = localeChoice == null
        ? '${l10n.settingsLanguageSystem}'
            '${currentLang != null ? ' · ${currentLang.nativeName}' : ''}'
        : (currentLang?.nativeName ?? effective.languageCode);

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
                  _SettingsCard(
                    child: InkWell(
                      onTap: () => _openLanguagePicker(
                        context,
                        ref,
                        selected: localeChoice,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            if (currentLang != null) ...[
                              _FlagThumb(iso: currentLang.flagIso),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.settingsLanguage,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    languageLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.settingsOfflineModeTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.settingsOfflineModeSubtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<OfflinePreference>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.settingsModeOnline),
                          value: OfflinePreference.online,
                          groupValue: offlineMode.preference,
                          activeColor: AppColors.accentStart,
                          onChanged: (v) {
                            if (v == null) return;
                            ref
                                .read(offlineModeProvider.notifier)
                                .setPreference(v);
                          },
                        ),
                        RadioListTile<OfflinePreference>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.settingsModeOffline),
                          value: OfflinePreference.offline,
                          groupValue: offlineMode.preference,
                          activeColor: AppColors.accentStart,
                          onChanged: (v) {
                            if (v == null) return;
                            ref
                                .read(offlineModeProvider.notifier)
                                .setPreference(v);
                          },
                        ),
                      ],
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

  Future<void> _openLanguagePicker(
    BuildContext context,
    WidgetRef ref, {
    required Locale? selected,
  }) async {
    final l10n = context.l10n;
    final chosen = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final height = MediaQuery.sizeOf(ctx).height * 0.75;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.settingsLanguage,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.accentSoft),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_iphone_rounded),
                        title: Text(l10n.settingsLanguageSystem),
                        trailing: selected == null
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.accentStart)
                            : null,
                        onTap: () => Navigator.pop(ctx, 'system'),
                      ),
                      const Divider(height: 1, color: AppColors.accentSoft),
                      for (final lang in appLanguages)
                        ListTile(
                          leading: _FlagThumb(iso: lang.flagIso),
                          title: Text(lang.nativeName),
                          subtitle: Text(
                            lang.englishName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: selected?.languageCode == lang.code
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.accentStart)
                              : null,
                          onTap: () => Navigator.pop(ctx, lang.code),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen == null || !context.mounted) return;
    if (chosen == 'system') {
      await ref.read(appLocaleProvider.notifier).setLocale(null);
    } else if (chosen is String) {
      await ref.read(appLocaleProvider.notifier).setLocale(Locale(chosen));
    }
  }
}

class _FlagThumb extends StatelessWidget {
  const _FlagThumb({required this.iso});

  final String iso;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/flags/$iso.png',
        width: 28,
        height: 20,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 28,
          height: 20,
          child: Icon(Icons.flag_outlined, size: 18),
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
