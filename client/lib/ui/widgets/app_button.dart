import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Текстовая кнопка: светлый фон, лавандовая рамка, чёрный текст.
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonStyle { normal, danger }

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    final padding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final isDanger = widget.style == AppButtonStyle.danger;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final fg = isDanger ? Colors.red.shade800 : AppColors.textPrimary;
    final border = isDanger ? Colors.red.shade400 : AppColors.buttonBorder;

    final label = widget.isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Text(
            widget.label,
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
          onTap: enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Padding(
            padding: padding,
            child: widget.expanded ? Center(child: label) : label,
          ),
        ),
      ),
    );
  }
}
