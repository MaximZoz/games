import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/app_update_provider.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_scroll_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
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
    final padding = isPhoneLandscape(context) ? 12.0 : (narrow ? 16.0 : 24.0);

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

    Future<void> toggleSound(bool v) async {
      await ref.read(soundEnabledProvider.notifier).set(v);
      Sfx.setEnabled(v);
    }

    Future<void> toggleHaptics(bool v) async {
      await ref.read(hapticsEnabledProvider.notifier).set(v);
      Haptics.setEnabled(v);
      if (v) Haptics.play(HapticKind.notify);
    }

    Future<void> toggleGamepad(bool v) async {
      await ref.read(gamepadEnabledProvider.notifier).set(v);
    }

    Future<void> toggleOffline(bool v) async {
      final notifier = ref.read(offlineModeProvider.notifier);
      if (v) {
        await notifier.setPreference(OfflinePreference.offline);
        return;
      }
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
      if (reason == OnlineUnavailableReason.serverUnreachable) {
        showAppSnackBar(
          context,
          message: l10n.connectionError,
          kind: AppSnackKind.error,
        );
        return;
      }
      await ref.read(pendingPurchasesProvider.notifier).flush();
      await syncPreferredLanguageToServer(ref);
    }

    Future<void> toggleFriendsOnly(bool v) async {
      final err = await ref.read(messagesFriendsOnlyProvider.notifier).set(v);
      if (!context.mounted || err == null) return;
      showAppSnackBar(
        context,
        message: err,
        kind: AppSnackKind.error,
      );
    }

    void openLanguage() => _openLanguagePicker(
          context,
          ref,
          selected: localeChoice,
        );

    return Scaffold(
      backgroundColor: AppColors.surfaceUnified,
      body: SafeArea(
        child: GamepadScrollPager(
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: EdgeInsets.all(padding),
              clipBehavior: Clip.none,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PadSettingsCard(
                        group: 'settings-language',
                        debugKey: const ValueKey('settings-language-card'),
                        onActivate: openLanguage,
                        child: InkWell(
                          key: const ValueKey('settings-language'),
                          canRequestFocus: false,
                          onTap: openLanguage,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      _PadSettingsCard(
                        group: 'settings-sound',
                        debugKey: const ValueKey('settings-sound-card'),
                        onActivate: () =>
                            toggleSound(!ref.read(soundEnabledProvider)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SwitchRow(
                              title: l10n.settingsSoundTitle,
                              subtitle: l10n.settingsSoundSubtitle,
                              value: ref.watch(soundEnabledProvider),
                              controlKey:
                                  const ValueKey('settings-sound-switch'),
                              onChanged: toggleSound,
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
                                    debugKey:
                                        const ValueKey('settings-sound-games'),
                                    value: ref.watch(soundGamesEnabledProvider),
                                    onChanged: (v) async {
                                      await ref
                                          .read(soundGamesEnabledProvider
                                              .notifier)
                                          .set(v);
                                      _applySoundCategories(ref);
                                    },
                                  ),
                                  _CategoryCheck(
                                    title: l10n.settingsSoundNotifications,
                                    debugKey: const ValueKey(
                                      'settings-sound-notifications',
                                    ),
                                    value: ref.watch(
                                        soundNotificationsEnabledProvider),
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
                                    debugKey:
                                        const ValueKey('settings-sound-turn'),
                                    value: ref.watch(soundTurnEnabledProvider),
                                    onChanged: (v) async {
                                      await ref
                                          .read(
                                              soundTurnEnabledProvider.notifier)
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
                      _PadSettingsCard(
                        group: 'settings-haptics',
                        debugKey: const ValueKey('settings-haptics-card'),
                        onActivate: () =>
                            toggleHaptics(!ref.read(hapticsEnabledProvider)),
                        child: _SwitchRow(
                          title: l10n.settingsHapticsTitle,
                          subtitle: l10n.settingsHapticsSubtitle,
                          value: ref.watch(hapticsEnabledProvider),
                          controlKey: const ValueKey('settings-haptics-switch'),
                          onChanged: toggleHaptics,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PadSettingsCard(
                        group: 'settings-gamepad',
                        debugKey: const ValueKey('settings-gamepad-card'),
                        onActivate: () =>
                            toggleGamepad(!ref.read(gamepadEnabledProvider)),
                        child: ListenableBuilder(
                          listenable: Listenable.merge([
                            GamepadService.instance.devices,
                            GamepadService.instance.activityTick,
                          ]),
                          builder: (context, _) {
                            final pads = GamepadService.instance.devices.value;
                            final enabled = ref.watch(gamepadEnabledProvider);
                            final family = pads.isEmpty
                                ? GamepadFamily.xbox
                                : gamepadFamilyFromName(pads.first.name);
                            final padName = pads.isEmpty
                                ? ''
                                : (pads.first.id == GamepadService.keyPadId
                                    ? l10n.settingsGamepadGenericName
                                    : pads.first.name);
                            final connected = pads.isNotEmpty
                                ? l10n.settingsGamepadConnected(padName)
                                : l10n.settingsGamepadDisconnected;
                            final layoutName = switch (family) {
                              GamepadFamily.xbox =>
                                l10n.settingsGamepadLayoutXbox,
                              GamepadFamily.playstation =>
                                l10n.settingsGamepadLayoutPlayStation,
                              GamepadFamily.nintendo =>
                                l10n.settingsGamepadLayoutNintendo,
                            };
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SwitchRow(
                                  title: l10n.settingsGamepadTitle,
                                  subtitle: l10n.settingsGamepadSubtitle,
                                  value: enabled,
                                  controlKey:
                                      const ValueKey('settings-gamepad-switch'),
                                  onChanged: toggleGamepad,
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
                                    const SizedBox(height: 2),
                                    Text(
                                      layoutName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w700,
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
                                          text:
                                              l10n.settingsGamepadHelpNavigate,
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
                                          action2: GamepadAction.shoulderR,
                                          family: family,
                                          text: l10n.settingsGamepadHelpTabs,
                                        ),
                                        GamepadHintChip(
                                          action: GamepadAction.triggerL,
                                          family: family,
                                          text: l10n.settingsGamepadHelpBalance,
                                        ),
                                        GamepadHintChip(
                                          action: GamepadAction.triggerR,
                                          family: family,
                                          text: l10n.settingsGamepadHelpLogout,
                                        ),
                                        GamepadHintChip(
                                          action: GamepadAction.scrollDown,
                                          family: family,
                                          text: l10n.settingsGamepadHelpPage,
                                        ),
                                        GamepadHintChip(
                                          action: GamepadAction.actionY,
                                          family: family,
                                          text: l10n.settingsGamepadHelpCards,
                                        ),
                                        GamepadHintChip(
                                          action: GamepadAction.actionX,
                                          family: family,
                                          text:
                                              l10n.settingsGamepadHelpKeyboard,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n.settingsGamepadHelpPlay,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PadSettingsCard(
                        group: 'settings-offline',
                        debugKey: const ValueKey('settings-offline-card'),
                        onActivate: () => toggleOffline(!offlineMode.isOffline),
                        child: _SwitchRow(
                          title: l10n.settingsModeOffline,
                          subtitle: l10n.settingsOfflineModeSubtitle,
                          value: offlineMode.isOffline,
                          controlKey: const ValueKey('settings-offline-switch'),
                          onChanged: toggleOffline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PadSettingsCard(
                        group: 'settings-friends-only',
                        debugKey: const ValueKey('settings-friends-only-card'),
                        onActivate: () =>
                            toggleFriendsOnly(!messagesFriendsOnly),
                        child: _SwitchRow(
                          title: l10n.settingsFriendsOnlyTitle,
                          subtitle: l10n.settingsFriendsOnlySubtitle,
                          value: messagesFriendsOnly,
                          controlKey: const ValueKey(
                            'settings-friends-only-switch',
                          ),
                          onChanged: toggleFriendsOnly,
                        ),
                      ),
                      if (isPushSettingsAvailable) ...[
                        const SizedBox(height: 12),
                        _PadSettingsCard(
                          group: 'settings-push',
                          debugKey: const ValueKey('settings-push-card'),
                          onActivate: isPushSettingsAvailable
                              ? () async {
                                  final err = await ref
                                      .read(webPushEnabledProvider.notifier)
                                      .setEnabled(!webPushEnabled);
                                  if (!context.mounted || err == null) return;
                                  showAppSnackBar(
                                    context,
                                    message: err,
                                    kind: AppSnackKind.error,
                                  );
                                }
                              : () {},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SwitchRow(
                                title: l10n.settingsNotifications,
                                value: webPushEnabled,
                                controlKey: const ValueKey(
                                  'settings-push-switch',
                                ),
                                onChanged: isPushSettingsAvailable
                                    ? (v) async {
                                        final err = await ref
                                            .read(
                                              webPushEnabledProvider.notifier,
                                            )
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
                                const Divider(
                                    height: 1, color: AppColors.accentSoft),
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
                                            .read(webPushCategoriesProvider
                                                .notifier)
                                            .setCategory(chat: v),
                                      ),
                                    ),
                                    _CategoryCheck(
                                      title: l10n.settingsPushFriends,
                                      value: pushCategories.friends,
                                      onChanged: (v) => setCategory(
                                        () => ref
                                            .read(webPushCategoriesProvider
                                                .notifier)
                                            .setCategory(friends: v),
                                      ),
                                    ),
                                    _CategoryCheck(
                                      title: l10n.settingsPushGames,
                                      value: pushCategories.games,
                                      onChanged: (v) => setCategory(
                                        () => ref
                                            .read(webPushCategoriesProvider
                                                .notifier)
                                            .setCategory(games: v),
                                      ),
                                    ),
                                    _CategoryCheck(
                                      title: l10n.settingsPushRewards,
                                      value: pushCategories.rewards,
                                      onChanged: (v) => setCategory(
                                        () => ref
                                            .read(webPushCategoriesProvider
                                                .notifier)
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
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.72),
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                      ),
                      if (appUpdate.updateAvailable) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: GamepadFocusBlock(
                            radius: AppRadius.button,
                            onActivate: () => ref
                                .read(appUpdateProvider.notifier)
                                .applyUpdate(),
                            child: FilledButton.icon(
                              onPressed: () => ref
                                  .read(appUpdateProvider.notifier)
                                  .applyUpdate(),
                              icon: const Icon(
                                Icons.system_update_alt_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.appUpdateOk),
                              style: AppButtonStyles.of(),
                            ),
                          ),
                        ),
                        if (appUpdate.whatsNew.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            appUpdate.whatsNew,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.8),
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _openLanguagePicker(
    BuildContext context,
    WidgetRef ref, {
    required Locale? selected,
  }) async {
    // Прогрев флагов не блокирует открытие — геймпад должен сразу видеть список.
    unawaited(
      Future.wait(appLanguages.map((l) => FlagAssetCache.loadIso(l.flagIso))),
    );
    if (!context.mounted) return;
    final future = showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguagePickerSheet(selected: selected),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusFirstVisibleGamepadTarget();
    });
    final chosen = await future;
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

class _PadSettingsCard extends StatelessWidget {
  const _PadSettingsCard({
    required this.group,
    required this.onActivate,
    required this.child,
    this.debugKey,
  });

  final String group;
  final VoidCallback onActivate;
  final Widget child;
  final Key? debugKey;

  @override
  Widget build(BuildContext context) {
    return GamepadNavGroup(
      name: group,
      child: GamepadFocusBlock(
        key: debugKey,
        radius: AppRadius.card,
        descendantsFocusable: true,
        onActivate: onActivate,
        child: _SettingsCard(child: child),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.selected});

  final Locale? selected;

  void _close(BuildContext context, [Object? value]) {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop(value);
  }

  Widget _langTile({
    required Key key,
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    required bool checked,
    required VoidCallback onSelect,
  }) {
    return GamepadFocusBlock(
      key: key,
      radius: 12,
      onActivate: onSelect,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: checked
            ? const Icon(Icons.check_rounded, color: AppColors.accentStart)
            : null,
        onTap: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return GamepadScope(
      exclusive: true,
      onAction: (action) {
        if (action == GamepadAction.cancel) {
          _close(context);
          return true;
        }
        if (action == GamepadAction.confirm || action.isDirection) {
          return handleGamepadUiAction(context, action);
        }
        if (action.isScroll) {
          return scrollGamepadByPage(
            action == GamepadAction.scrollUp ||
                    action == GamepadAction.scrollLeft
                ? -1
                : 1,
            context: context,
          );
        }
        return true;
      },
      child: GamepadNavGroup(
        name: 'settings-language-picker',
        exclusive: true,
        child: SafeArea(
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ),
                      GamepadFocusBlock(
                        radius: 20,
                        shape: GamepadHighlightShape.circle,
                        includeInEdgeFocus: false,
                        onActivate: () => _close(context),
                        child: IconButton(
                          key: const ValueKey('settings-language-close'),
                          tooltip: l10n.commonClose,
                          onPressed: () => _close(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.accentSoft),
                Expanded(
                  child: GamepadScrollPager(
                    builder: (context, controller) {
                      return ListView(
                        controller: controller,
                        clipBehavior: Clip.none,
                        children: [
                          _langTile(
                            key: const ValueKey('lang-system'),
                            leading: const Icon(Icons.phone_iphone_rounded),
                            title: Text(l10n.settingsLanguageSystem),
                            checked: selected == null,
                            onSelect: () => _close(context, 'system'),
                          ),
                          const Divider(height: 1, color: AppColors.accentSoft),
                          for (final lang in appLanguages)
                            _langTile(
                              key: ValueKey('lang-${lang.code}'),
                              leading: _FlagThumb(iso: lang.flagIso),
                              title: Text(lang.nativeName),
                              subtitle: Text(
                                lang.englishName,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              checked: selected?.languageCode == lang.code,
                              onSelect: () => _close(context, lang.code),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            border: Border.all(
              color: GamepadFocusBlock.frameColor(
                context,
                AppColors.accentSoft,
              ),
            ),
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
    this.controlKey,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return InkWell(
      canRequestFocus: false,
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
            GamepadFocusBlock(
              key: controlKey,
              includeInEdgeFocus: false,
              radius: 18,
              onActivate: onChanged == null ? null : () => onChanged!(!value),
              child: ExcludeFocus(
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.accentStart,
                ),
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
    this.debugKey,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? debugKey;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      key: debugKey,
      includeInEdgeFocus: false,
      radius: 10,
      onActivate: () => onChanged(!value),
      child: InkWell(
        canRequestFocus: false,
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
      ),
    );
  }
}
