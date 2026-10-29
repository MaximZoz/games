import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';

/// Сбой загрузки списка: что не открылось, почему и кнопка повтора.
class ScreenLoadError extends StatelessWidget {
  const ScreenLoadError({
    super.key,
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;
    final detail = loadFailureDetail(error);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24,
          vertical: compact ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: compact ? 40 : 46,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                key: const ValueKey('screen-load-error-title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                key: const ValueKey('screen-load-error-detail'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 13 : 14,
                  height: 1.35,
                ),
              ),
              SizedBox(height: compact ? 14 : 16),
              FilledButton(
                key: const ValueKey('screen-load-retry'),
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentStart,
                  foregroundColor: Colors.white,
                  minimumSize: Size(compact ? 148 : 160, compact ? 40 : 44),
                ),
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
