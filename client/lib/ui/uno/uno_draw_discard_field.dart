import 'package:flutter/material.dart';
import 'package:multigames_client/games/uno/uno_center_table_style.dart';

/// Зелёный овал колоды и сброса. В альбоме родитель жмёт его через [FittedBox].
class UnoDrawDiscardField extends StatelessWidget {
  const UnoDrawDiscardField({
    super.key,
    required this.style,
    required this.drawPile,
    required this.discardPile,
    required this.drawLabel,
    required this.discardLabel,
    required this.currentColor,
    this.pendingDrawLabel,
  });

  final UnoCenterTableStyle style;
  final Widget drawPile;
  final Widget discardPile;
  final String drawLabel;
  final String discardLabel;
  final Color currentColor;
  final String? pendingDrawLabel;

  @override
  Widget build(BuildContext context) {
    final pending = pendingDrawLabel?.trim() ?? '';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF125D42).withValues(alpha: 0.92),
            const Color(0xFF0A3E3A).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: style.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              drawPile,
              SizedBox(height: style.labelGap),
              Text(
                drawLabel,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: style.labelFontSize,
                ),
              ),
            ],
          ),
          SizedBox(width: style.gap),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              discardPile,
              SizedBox(height: style.labelGap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    discardLabel,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: style.labelFontSize,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (pending.isNotEmpty) ...[
            SizedBox(width: style.pendingGap),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pending,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
