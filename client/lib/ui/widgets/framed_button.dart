import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Текстовая кнопка: пилюля, иконка слева, градиентная рамка.
///
/// Единый вид для действий в играх и общем интерфейсе — как «Редактировать»
/// в профиле, но с градиентным контуром вместо сплошной линии.
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

  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final borderRadius = BorderRadius.circular(999);
    final innerRadius = BorderRadius.circular(999);
    final contentColor = danger ? Colors.red.shade800 : AppColors.accentStart;
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
                    color: contentColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: contentColor),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: danger ? null : AppGradients.buttonBorder,
          color: danger ? Colors.red.shade300 : null,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_borderWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: innerRadius,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                borderRadius: innerRadius,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
