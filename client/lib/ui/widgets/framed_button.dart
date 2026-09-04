import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Текстовая кнопка: светлый фон, лавандовая рамка, чёрный текст.
class FramedButton extends StatelessWidget {
  const FramedButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expanded = false,
    this.danger = false,
    this.padding,
    this.minHeight = 44,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool danger;
  final EdgeInsetsGeometry? padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(AppRadius.button);
    final fg = danger ? Colors.red.shade800 : AppColors.textPrimary;
    final border = danger ? Colors.red.shade400 : AppColors.buttonBorder;
    final child = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Center(
          widthFactor: expanded ? null : 1,
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    final button = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.buttonFill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: child,
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
