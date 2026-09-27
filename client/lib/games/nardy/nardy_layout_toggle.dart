import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/nardy/nardy_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Круглая кнопка: зеркалит раскладку фишек (дом слева / справа).
class NardyLayoutToggleButton extends ConsumerWidget {
  const NardyLayoutToggleButton({super.key, this.size = 26});

  /// Сторона кнопки — совпадает с высотой полосы «осталось».
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeOnRight = ref.watch(nardyHomeOnRightProvider);
    final label = context.l10n.nardyLayoutToggle;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppColors.surfaceCard.withValues(alpha: 0.72),
          shape: CircleBorder(
            side: BorderSide(
              color: AppColors.accentStart.withValues(alpha: 0.4),
            ),
          ),
          child: InkWell(
            onTap: () => unawaited(
              ref.read(nardyHomeOnRightProvider.notifier).set(!homeOnRight),
            ),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                Icons.swap_horiz_rounded,
                size: size * 0.7,
                color: homeOnRight
                    ? AppColors.accentStart
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
