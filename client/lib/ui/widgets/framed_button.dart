import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Текстовая кнопка: заливка цветом фона приложения, лавандовая рамка, чёрный текст.
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
    this.fontSize = 14,
    this.iconSize = 20,
    this.gamepadAction,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool danger;
  final EdgeInsetsGeometry? padding;
  final double minHeight;
  final double fontSize;
  final double iconSize;
  final GamepadAction? gamepadAction;

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
                      Icon(icon, size: iconSize, color: fg),
                      SizedBox(width: iconSize < 18 ? 4 : 8),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fg,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                          ),
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

    final hinted = gamepadAction == null
        ? button
        : GamepadHinted(action: gamepadAction!, child: button);
    return expanded ? SizedBox(width: double.infinity, child: hinted) : hinted;
  }
}
