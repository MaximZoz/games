import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/utils/user_error.dart';

const goOfflineButtonKey = ValueKey<String>('go-offline-button');

/// «Перейти в офлайн» рядом с «Повторить» на экране ошибки загрузки.
///
/// Видна только когда загрузка упала из-за связи с сервером, пользователь
/// вошёл и ещё в онлайн режиме. В остальных случаях места не занимает.
class GoOfflineButton extends ConsumerWidget {
  const GoOfflineButton({
    super.key,
    required this.error,
    this.padding = const EdgeInsets.only(top: 8),
    this.expanded = false,
    this.compact = false,
  });

  final Object? error;
  final EdgeInsetsGeometry padding;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isNoConnectionError(error)) return const SizedBox.shrink();
    if (ref.watch(isOfflineProvider)) return const SizedBox.shrink();
    if (ref.watch(authStateProvider).valueOrNull == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: FramedButton(
        key: goOfflineButtonKey,
        label: context.l10n.serverUnreachableGoOffline,
        icon: Icons.cloud_off_rounded,
        expanded: expanded,
        minHeight: compact ? 40 : 44,
        fontSize: compact ? 13 : 14,
        iconSize: compact ? 18 : 20,
        onPressed: () => ref
            .read(offlineModeProvider.notifier)
            .setPreference(OfflinePreference.offline),
      ),
    );
  }
}
