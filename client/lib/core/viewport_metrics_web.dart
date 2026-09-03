import 'package:web/web.dart' as web;

/// Метрики браузерного viewport — только для web-диагностики раскладки.
class ViewportMetrics {
  const ViewportMetrics({
    this.innerHeight,
    this.visualHeight,
    this.visualOffsetTop,
    this.scrollY,
  });

  final double? innerHeight;
  final double? visualHeight;
  final double? visualOffsetTop;
  final double? scrollY;
}

ViewportMetrics readViewportMetrics() {
  try {
    final vv = web.window.visualViewport;
    return ViewportMetrics(
      innerHeight: web.window.innerHeight.toDouble(),
      visualHeight: vv?.height.toDouble(),
      visualOffsetTop: vv?.offsetTop.toDouble(),
      scrollY: web.window.scrollY.toDouble(),
    );
  } catch (_) {
    return const ViewportMetrics();
  }
}
