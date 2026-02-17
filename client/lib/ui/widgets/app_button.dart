import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Кнопка с белым фоном, чёрным текстом и анимированной цветной рамкой.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.padding,
    this.style = AppButtonStyle.normal,
    this.isLoading = false,
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final EdgeInsetsGeometry? padding;
  final AppButtonStyle style;
  final bool isLoading;
  /// true — кнопка тянется на всю ширину (форма входа/регистрации).
  final bool expanded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonStyle { normal, danger }

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final isDanger = widget.style == AppButtonStyle.danger;
    final enabled = widget.onPressed != null && !widget.isLoading;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final gradient = AppGradients.borderAt(_animation.value);
        final borderColor = isDanger ? Colors.red : null;
        return Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            decoration: BoxDecoration(
              gradient: borderColor == null ? gradient : null,
              color: borderColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.button - 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(AppRadius.button - 2),
                  child: Padding(
                    padding: padding,
                    child: widget.expanded
                        ? Center(
                            child: widget.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textPrimary,
                                    ),
                                  )
                                : Text(
                                    widget.label,
                                    style: TextStyle(
                                      color: isDanger
                                          ? Colors.red.shade800
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          )
                        : widget.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Text(
                                widget.label,
                                style: TextStyle(
                                  color: isDanger
                                      ? Colors.red.shade800
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
