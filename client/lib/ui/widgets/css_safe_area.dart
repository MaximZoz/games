import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/safe_area_probe.dart';

/// Безопасные зоны iPhone для web-сборки.
///
/// `viewport-fit=cover` растягивает страницу под чёлку и home indicator, но
/// движок Flutter web про них не знает: `MediaQuery.padding` остаётся нулевым.
/// Забираем значения из CSS и подкладываем в `MediaQuery`, чтобы `SafeArea` и
/// вёрстка экранов работали так же, как на нативных платформах.
class CssSafeArea extends StatefulWidget {
  const CssSafeArea({super.key, required this.child});

  final Widget child;

  @override
  State<CssSafeArea> createState() => _CssSafeAreaState();
}

class _CssSafeAreaState extends State<CssSafeArea> with WidgetsBindingObserver {
  EdgeInsets? _insets;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _insets = readCssSafeAreaInsets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Поворот экрана и клавиатура меняют вырезы — перечитываем.
  @override
  void didChangeMetrics() {
    final next = readCssSafeAreaInsets();
    if (next == _insets || !mounted) return;
    setState(() => _insets = next);
  }

  @override
  Widget build(BuildContext context) {
    final insets = _insets;
    if (insets == null || insets == EdgeInsets.zero) return widget.child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: mediaWithCssSafeArea(media: media, cssInsets: insets),
      child: widget.child,
    );
  }
}

/// Догружает вырезы в метрики, не затирая то, что уже дала платформа.
MediaQueryData mediaWithCssSafeArea({
  required MediaQueryData media,
  required EdgeInsets cssInsets,
}) {
  double pick(double platform, double css) => math.max(platform, css);
  final viewPadding = EdgeInsets.only(
    top: pick(media.viewPadding.top, cssInsets.top),
    right: pick(media.viewPadding.right, cssInsets.right),
    bottom: pick(media.viewPadding.bottom, cssInsets.bottom),
    left: pick(media.viewPadding.left, cssInsets.left),
  );
  // Под клавиатурой нижний вырез не действует — так же, как на платформе.
  final padding = viewPadding.copyWith(
    bottom: media.viewInsets.bottom > 0 ? 0 : viewPadding.bottom,
  );
  return media.copyWith(viewPadding: viewPadding, padding: padding);
}
