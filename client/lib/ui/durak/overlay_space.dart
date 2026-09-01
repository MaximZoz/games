import 'package:flutter/widgets.dart';

/// Размер корневого overlay — в тех же координатах, что [localToGlobal].
///
/// `MediaQuery.size` в партии в альбоме — коробка вкладки (без рейла и
/// вырезов). Полёты карт рисуются в root overlay на весь экран. Если
/// подставить размер вкладки как global-точку, карта садится мимо слота
/// и остаётся поверх прошлого кадра.
Size overlaySpaceSize(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay != null) {
    final box = overlay.context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      return box.size;
    }
  }
  final view = View.maybeOf(context);
  if (view != null) {
    final logical = view.physicalSize / view.devicePixelRatio;
    if (logical.width > 0 && logical.height > 0) return logical;
  }
  return MediaQuery.sizeOf(context);
}

/// Поворот или сильное изменение окна — старые global-rect полётов неверны.
bool overlaySpaceChangedEnough({
  required Size? previous,
  required Size next,
  double minDelta = 32,
}) {
  if (previous == null) return false;
  if (!previous.isFinite || !next.isFinite) return false;
  if (next.width <= 0 || next.height <= 0) return false;
  final dw = (previous.width - next.width).abs();
  final dh = (previous.height - next.height).abs();
  if (dw < minDelta && dh < minDelta) return false;
  final rotated = (previous.width - next.height).abs() < 48 &&
      (previous.height - next.width).abs() < 48;
  return rotated || dw >= 64 || dh >= 64;
}
