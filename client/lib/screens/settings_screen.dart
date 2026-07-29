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
    final narrow = isNarrow(context);
    final padding = narrow ? 24.0 : 32.0;

    String pushSubtitle() {
      if (!isWebPushSupported) {
        return 'В этом браузере Web Push недоступен (на iPhone установите приложение на экран «Домой» и откройте с иконки).';
      }
      if (!isWebPushStandalone) {
        return 'Откройте приложение с экрана «Домой» (PWA). В обычной вкладке Safari на iPhone пуши не работают.';
      }
      return 'Push: сообщения, заявки в друзья, приглашения. После включения придёт тест — сверните приложение. Если нет — кнопка «Тест» ниже.';
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
                  _SettingsTile(
                    title: 'Добавлять ботов через 30 с',
                    subtitle:
                        'В режиме «поиск игры»: если соперник не найден за 30 секунд, игра начинается с ботом (цена игры сбрасывается до 1-й бронзы)',
                    value: addBotsAfter30s,
                    onChanged: (v) =>
                        ref.read(addBotsAfter30sProvider.notifier).set(v),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    _SettingsTile(
                      title: 'Уведомления в браузере',
                      subtitle: pushSubtitle(),
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
                                return;
                              }
                              if (v) {
                                showAppSnackBar(
                                  context,
                                  message:
                                      'Подписка сохранена. Сверните приложение — должно прийти тестовое уведомление.',
                                  kind: AppSnackKind.success,
                                );
                              }
                            }
                          : null,
                    ),
                    if (webPushEnabled && isWebPushSupported) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final err = await ref
                              .read(webPushEnabledProvider.notifier)
                              .sendTestPush();
                          if (!context.mounted) return;
                          if (err != null) {
                            showAppSnackBar(
                              context,
                              message: err,
                              kind: AppSnackKind.error,
                            );
                            return;
                          }
                          showAppSnackBar(
                            context,
                            message:
                                'Тест отправлен. Сверните приложение на пару секунд.',
                            kind: AppSnackKind.success,
                          );
                        },
                        child: const Text('Отправить тестовое уведомление'),
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
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppRadius.card),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentSoft),
      ),
      child: Row(
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accentStart,
          ),
        ],
      ),
    );
  }
}
