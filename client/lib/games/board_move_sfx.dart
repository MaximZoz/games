import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

/// Проигрывает звук хода при каждом изменении позиции на доске — свой ход,
/// ход соперника или бота озвучиваются одинаково (как в крестиках-ноликах).
///
/// Общий для настольных игр (шахматы, шашки): достаточно передать [signature]
/// текущей живой позиции (например, доска + `seq`). Со скрытой вкладки стол не
/// звучит — как в остальных играх.
class BoardChangeSfx extends StatefulWidget {
  const BoardChangeSfx({
    super.key,
    required this.signature,
    required this.child,
  });

  /// Сигнатура живой позиции. Меняется — значит был ход, играем звук.
  final String signature;
  final Widget child;

  @override
  State<BoardChangeSfx> createState() => _BoardChangeSfxState();
}

class _BoardChangeSfxState extends State<BoardChangeSfx> {
  @override
  void didUpdateWidget(covariant BoardChangeSfx oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.signature;
    final after = widget.signature;
    if (before == after || before.isEmpty || after.isEmpty) return;
    if (!GameFlyOverlay.shouldPlayGameSfx()) return;
    Sfx.play(SfxId.place);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
