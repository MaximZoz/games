import 'package:flutter/material.dart';
import '../app_theme.dart';

enum BannerType { error, success }

/// Баннер сообщения (ошибка/успех) с плавной анимацией появления.
class MessageBanner extends StatefulWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
    this.icon,
  });

  final String message;
  final BannerType type;
  final IconData? icon;

  @override
  State<MessageBanner> createState() => _MessageBannerState();
}

class _MessageBannerState extends State<MessageBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.type == BannerType.error;
    final bgColor = isError ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isError ? Colors.red.shade200 : Colors.green.shade200;
    final textColor = isError ? Colors.red.shade800 : Colors.green.shade800;
    final iconColor = isError ? Colors.red.shade700 : Colors.green.shade700;
    final icon = widget.icon ??
        (isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.red : Colors.green)
                    .withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
