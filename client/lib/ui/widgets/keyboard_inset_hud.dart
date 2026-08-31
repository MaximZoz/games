import 'package:flutter/material.dart';
import 'package:multigames_client/core/viewport_metrics.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';

/// Диагностика раскладки под клавиатурой: `?insets=1` в адресе.
/// Нужна, чтобы поймать завышенный `viewInsets` на iOS PWA — там ни
/// логов, ни devtools под рукой.
bool keyboardInsetHudEnabled() {
  return Uri.base.queryParameters['insets'] == '1';
}

class KeyboardInsetHud extends StatelessWidget {
  const KeyboardInsetHud({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final metrics = readViewportMetrics();
    final inset = media.viewInsets.bottom;
    final safe = sanitizeKeyboardInset(
      inset: inset,
      viewportHeight: media.size.height,
    );
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(0);
    final lines = <String>[
      'size ${fmt(media.size.width)}x${fmt(media.size.height)} dpr ${media.devicePixelRatio.toStringAsFixed(1)}',
      'viewInsets.bottom ${fmt(inset)} → clamp ${fmt(safe)}',
      'viewPadding t${fmt(media.viewPadding.top)} b${fmt(media.viewPadding.bottom)}',
      'innerHeight ${fmt(metrics.innerHeight)} visual ${fmt(metrics.visualHeight)}',
      'visualOffsetTop ${fmt(metrics.visualOffsetTop)} scrollY ${fmt(metrics.scrollY)}',
    ];
    return IgnorePointer(
      child: Container(
        color: const Color(0xCC000000),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF7CFC9B),
                  fontSize: 10,
                  height: 1.35,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
