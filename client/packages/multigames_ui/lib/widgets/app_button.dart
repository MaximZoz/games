import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'api_action_surface.dart';

/// Текстовая кнопка: заливка цветом фона приложения, лавандовая рамка, чёрный текст.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.padding,
    this.style = AppButtonStyle.normal,
    this.isLoading = false,
    this.expanded = false,
    this.animateBorder = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final EdgeInsetsGeometry? padding;
  final AppButtonStyle style;
  final bool isLoading;

  /// true — кнопка тянется на всю ширину (форма входа/регистрации).
  final bool expanded;

  /// Сохранено для совместимости: анимация рамки отключена.
  final bool animateBorder;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    return ApiActionSurface(
      onPressed: onPressed,
      loading: isLoading,
      builder: (context, showLoading, onTap) => _AppButtonBody(
        label: label,
        padding: resolvedPadding,
        style: style,
        expanded: expanded,
        showLoading: showLoading,
        onTap: onTap,
      ),
    );
  }
}

enum AppButtonStyle { normal, danger }

class _AppButtonBody extends StatelessWidget {
  const _AppButtonBody({
    required this.label,
    required this.padding,
    required this.style,
    required this.expanded,
    required this.showLoading,
    required this.onTap,
  });

  final String label;
  final EdgeInsetsGeometry padding;
  final AppButtonStyle style;
  final bool expanded;
  final bool showLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDanger = style == AppButtonStyle.danger;
    final enabled = onTap != null;
    final fg = isDanger ? Colors.red.shade800 : AppColors.textPrimary;
    final border = isDanger ? Colors.red.shade400 : AppColors.buttonBorder;
    final child = showLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          );

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: AppColors.buttonFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: apiActionSplash,
          highlightColor: apiActionSplash,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Padding(
            padding: padding,
            child: expanded ? Center(child: child) : child,
          ),
        ),
      ),
    );
  }
}
