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

ViewportMetrics readViewportMetrics() => const ViewportMetrics();
