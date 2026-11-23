import 'dart:ui' show Size;

/// Подгонка игрового стола под доступную высоту.
///
/// Экраны карточных игр рисуются «под портрет»: сверху соперник, в середине
/// стол, снизу рука. На телефоне в альбоме вертикали остаётся ~300 px, и
/// фиксированные размеры карт и зон перестают помещаться — рука уезжает за
/// экран. Вместо отдельной альбомной верстки уменьшаем сам стол.
class GameTableFit {
  const GameTableFit({required this.scale, required this.compact});

  /// Множитель размеров карт и зон: 1.0 — полный размер.
  final double scale;

  /// Высоты не хватает — фиксированные слоты надо ужимать.
  final bool compact;

  Size scaled(Size size) =>
      scale == 1 ? size : Size(size.width * scale, size.height * scale);
}

/// [designHeight] — высота, на которой стол помещается в полный размер.
GameTableFit gameTableFit({
  required double availableHeight,
  required double designHeight,
  double minScale = 0.5,
}) {
  if (availableHeight <= 0 || designHeight <= 0) {
    return const GameTableFit(scale: 1, compact: false);
  }
  if (availableHeight >= designHeight) {
    return const GameTableFit(scale: 1, compact: false);
  }
  final scale = (availableHeight / designHeight).clamp(minScale, 1.0);
  return GameTableFit(scale: scale, compact: true);
}
