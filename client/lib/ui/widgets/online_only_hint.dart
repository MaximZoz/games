import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Подпись на месте кнопки, которая работает только через сервер.
///
/// В офлайн режиме такие кнопки скрыты: награду, доход и прочее можно
/// забрать после возврата в онлайн.
class OnlineOnlyHint extends StatelessWidget {
  const OnlineOnlyHint({super.key, this.dense = false, this.minHeight = 44});

  final bool dense;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final size = dense ? 12.0 : 13.0;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: dense ? 32 : minHeight),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: size + 3,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.l10n.offlineOnlineOnlyHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: size,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
