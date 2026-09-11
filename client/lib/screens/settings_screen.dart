import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/app_update_provider.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/haptics.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/core/web_push_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/flag_asset_cache.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/shop/pending_purchases.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

void _applySoundCategories(WidgetRef ref) {
  Sfx.instance.setCategories(
    games: ref.read(soundGamesEnabledProvider),
    notifications: ref.read(soundNotificationsEnabledProvider),
    turn: ref.read(soundTurnEnabledProvider),
  );
}

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
    final appUpdate = ref.watch(appUpdateProvider);
    final narrow = isNarrow(context);
    final padding = isPhoneLandscape(context)
        ? 12.0
        : (narrow ? 16.0 : 24.0);

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
      backgroundColor: AppColors.surfaceUnified,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          clipBehavior: Clip.hardEdge,
          child: Align(
            alignment: Alignment.topCenter,
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
                        _SwitchRow(
                          title: l10n.settingsSoundTitle,
                          subtitle: l10n.settingsSoundSubtitle,
                          value: ref.watch(soundEnabledProvider),
                          onChanged: (v) async {
                            await ref.read(soundEnabledProvider.notifier).set(v);
                            Sfx.setEnabled(v);
                          },
                        ),
                        if (ref.watch(soundEnabledProvider)) ...[
                          const SizedBox(height: 8),
                          const Divider(
                            height: 1,
                            color: AppColors.accentSoft,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _CategoryCheck(
                                title: l10n.settingsSoundGames,
                                value: ref.watch(soundGamesEnabledProvider),
                                onChanged: (v) async {
                                  await ref
                                      .read(soundGamesEnabledProvider.notifier)
                                      .set(v);
                                  _applySoundCategories(ref);
                                },
                              ),
                              _CategoryCheck(
                                title: l10n.settingsSoundNotifications,
                                value: ref
                                    .watch(soundNotificationsEnabledProvider),
                                onChanged: (v) async {
                                  await ref
                                      .read(
                                        soundNotificationsEnabledProvider
                                            .notifier,
                                      )
                                      .set(v);
                                  _applySoundCategories(ref);
                                },
                              ),
                              _CategoryCheck(
                                title: l10n.settingsSoundTurn,
                                value: ref.watch(soundTurnEnabledProvider),
                                onChanged: (v) async {
                                  await ref
                                      .read(soundTurnEnabledProvider.notifier)
                                      .set(v);
                                  _applySoundCategories(ref);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SwitchRow(
                      title: l10n.settingsHapticsTitle,
                      subtitle: l10n.settingsHapticsSubtitle,
                      value: ref.watch(hapticsEnabledProvider),
                      onChanged: (v) async {
                        await ref.read(hapticsEnabledProvider.notifier).set(v);
                        Haptics.setEnabled(v);
                        if (v) Haptics.play(HapticKind.notify);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: ValueListenableBuilder(
                      valueListenable: GamepadService.instance.devices,
                      builder: (context, pads, _) {
                        final enabled = ref.watch(gamepadEnabledProvider);
                        final family = pads.isEmpty
                            ? GamepadFamily.xbox
                            : gamepadFamilyFromName(pads.first.name);
                        final connected = pads.isNotEmpty
                            ? l10n.settingsGamepadConnected(pads.first.name)
                            : l10n.settingsGamepadDisconnected;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SwitchRow(
                              title: l10n.settingsGamepadTitle,
                              subtitle: l10n.settingsGamepadSubtitle,
                              value: enabled,
                              onChanged: (v) async {
                                await ref
                                    .read(gamepadEnabledProvider.notifier)
                                    .set(v);
                              },
                            ),
                            if (enabled) ...[
                              const SizedBox(height: 8),
                              const Divider(
                                height: 1,
                                color: AppColors.accentSoft,
                              ),
                              const SizedBox(height: 10),
                              if (pads.isEmpty)
                                Text(
                                  connected,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                )
                              else ...[
                                Text(
                                  connected,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 8,
                                  children: [
                                    GamepadHintChip(
                                      action: GamepadAction.left,
                                      family: family,
                                      text: l10n.settingsGamepadHelpNavigate,
                                    ),
                                    GamepadHintChip(
                                      action: GamepadAction.confirm,
                                      family: family,
                                      text: l10n.settingsGamepadHelpConfirm,
                                    ),
                                    GamepadHintChip(
                                      action: GamepadAction.cancel,
                                      family: family,
                                      text: l10n.settingsGamepadHelpBack,
                                    ),
                                    GamepadHintChip(
                                      action: GamepadAction.shoulderL,
                                      family: family,
                                      text: l10n.settingsGamepadHelpTabs,
                                    ),
                                    GamepadHintChip(
                                      action: GamepadAction.actionY,
                                      family: family,
                                      text: l10n.settingsGamepadHelpCards,
                                    ),
                                    GamepadHintChip(
                                      action: GamepadAction.actionX,
                                      family: family,
                                      text: l10n.settingsGamepadHelpKeyboard,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SwitchRow(
                      title: l10n.settingsModeOffline,
                      subtitle: l10n.settingsOfflineModeSubtitle,
                      // Эффективный офлайн (ручной или нет сети/сервера).
                      value: offlineMode.isOffline,
                      onChanged: (v) async {
                        final notifier =
                            ref.read(offlineModeProvider.notifier);
                        if (v) {
                          await notifier
                              .setPreference(OfflinePreference.offline);
                          return;
                        }
                        // Выход в онлайн: если сети/сервера нет — тост с причиной.
                        final reason = await notifier.tryGoOnline();
                        if (!context.mounted) return;
                        if (reason == OnlineUnavailableReason.noInternet) {
                          showAppSnackBar(
                            context,
                            message: l10n.errNoInternet,
                            kind: AppSnackKind.error,
                          );
                          return;
                        }
                        if (reason ==
                            OnlineUnavailableReason.serverUnreachable) {
                          showAppSnackBar(
                            context,
                            message: l10n.connectionError,
                            kind: AppSnackKind.error,
                          );
                          return;
                        }
                        // Явный flush при выходе из офлайна (на случай гонки слушателя).
                        await ref
                            .read(pendingPurchasesProvider.notifier)
                            .flush();
                        await syncPreferredLanguageToServer(ref);
                      },
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
                  if (isPushSettingsAvailable) ...[
                    const SizedBox(height: 12),
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SwitchRow(
                            title: l10n.settingsNotifications,
                            value: webPushEnabled,
                            onChanged: isPushSettingsAvailable
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
                  const SizedBox(height: 28),
                  Text(
                    l10n.settingsAppVersion(appVersionLabel),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.72),
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                  ),
                  if (appUpdate.updateAvailable) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.icon(
                        onPressed: () =>
                            ref.read(appUpdateProvider.notifier).applyUpdate(),
                        icon: const Icon(Icons.system_update_alt_rounded, size: 18),
                        label: Text(l10n.appUpdateOk),
                        style: AppButtonStyles.of(),
                      ),
                    ),
                    if (appUpdate.whatsNew.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        appUpdate.whatsNew,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.35,
                            ),
                      ),
                    ],
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
    // Прогрев флагов языков в memory-кэш — нужно для офлайна на Web.
    await Future.wait(
      appLanguages.map((l) => FlagAssetCache.loadIso(l.flagIso)),
    );
    if (!context.mounted) return;
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
    if (!ref.read(isOfflineProvider)) {
      await syncPreferredLanguageToServer(ref);
    }
  }
}

class _FlagThumb extends StatelessWidget {
  const _FlagThumb({required this.iso});

  final String iso;

  @override
  Widget build(BuildContext context) {
    String? unicode;
    for (final info in countryFlagsByName.values) {
      if (info.iso.toLowerCase() == iso.toLowerCase()) {
        unicode = info.unicode;
        break;
      }
    }
    // Memory-кэш FlagAssetCache — на Flutter Web в офлайне Image.asset
    // снова ходит в сеть за /assets/flags/*.png.
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 28,
        height: 20,
        child: FittedBox(
          fit: BoxFit.cover,
          child: CountryFlagImage(
            iso: iso,
            size: 28,
            fallbackUnicode: unicode,
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
    return RepaintBoundary(
      child: Material(
        color: AppColors.surfaceCard,
        elevation: 0,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(AppRadius.card),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.accentSoft),
          ),
          child: child,
        ),
      ),
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
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
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
            ExcludeFocus(
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.accentStart,
              ),
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeFocus(
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.accentStart,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
