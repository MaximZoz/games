import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'api_action_surface.dart';

/// Кнопка-иконка с мягкой лавандовой рамкой (как у свайп-действий в чатах).
class FramedIconButton extends StatelessWidget {
  const FramedIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor,
    this.loading = false,
    this.filled = true,
    this.borderWidth = 2,
    this.borderRadius = 12,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool loading;

  /// false — прозрачный фон (например, активный поиск).
  final bool filled;
  final double borderWidth;
  final double borderRadius;

  static const _gradientStop = 0.22;

  @override
  Widget build(BuildContext context) {
    return ApiActionSurface(
      onPressed: onPressed,
      loading: loading,
      builder: (context, showLoading, onTap) =>
          _body(showLoading: showLoading, onTap: onTap),
    );
  }

  Widget _body({required bool showLoading, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    final color = iconColor ?? AppColors.textPrimary;
    final innerRadius = (borderRadius - borderWidth).clamp(0.0, borderRadius);
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            canRequestFocus: false,
            onTap: onTap,
            splashColor: apiActionSplash,
            highlightColor: apiActionSplash,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(borderWidth),
              decoration: BoxDecoration(
                gradient: AppGradients.borderAt(_gradientStop),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: filled ? AppColors.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: Center(
                  child: showLoading
                      ? SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(icon, size: iconSize, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
