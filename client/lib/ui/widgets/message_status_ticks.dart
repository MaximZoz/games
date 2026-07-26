import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Галочки статуса исходящего сообщения (как в Telegram):
/// одна — отправлено, две серые — доставлено, две синие — прочитано.
class MessageStatusTicks extends StatelessWidget {
  const MessageStatusTicks({
    super.key,
    required this.deliveredAt,
    required this.readAt,
    this.size = 14,
  });

  final String? deliveredAt;
  final String? readAt;
  final double size;

  /// Цвет «прочитано» (близко к Telegram).
  static const Color readColor = Color(0xFF34B7F1);

  bool get _isRead => readAt != null && readAt!.isNotEmpty;
  bool get _isDelivered => deliveredAt != null && deliveredAt!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final icon = (_isDelivered || _isRead) ? Icons.done_all : Icons.done;
    final color = _isRead
        ? readColor
        : AppColors.textSecondary.withValues(alpha: 0.65);
    return Icon(icon, size: size, color: color);
  }
}
