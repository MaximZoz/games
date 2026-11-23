import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// Место одной фишки в россыпи: центр и поворот.
class ScatterSlot {
  const ScatterSlot({required this.center, required this.angle});

  final Offset center;

  /// Радианы, по часовой стрелке.
  final double angle;
}

/// Россыпь фишек по области — прикуп, «базар», сброс.
///
/// Раскладка детерминирована по [seed]: место фишки `i` не зависит от того,
/// сколько их осталось, поэтому при взятии одной остальные не прыгают.
/// Слоты перемешаны, так что уходят они вразнобой, а не по рядам.
///
/// [capacity] — сколько фишек бывает максимум; показывать нужно первые
/// `count` слотов.
List<ScatterSlot> scatterSlots({
  required int capacity,
  required Size area,
  required Size item,
  int seed = 0,
  double maxAngle = 0.55,
}) {
  if (capacity <= 0 || area.isEmpty) return const [];
  final random = math.Random(seed);
  // Повёрнутая фишка занимает круг по диагонали — от края держимся на него.
  final reach = math.sqrt(item.width * item.width + item.height * item.height) / 2;
  final usableW = math.max(0.0, area.width - reach * 2);
  final usableH = math.max(0.0, area.height - reach * 2);
  final aspect = usableH <= 0 ? capacity.toDouble() : usableW / usableH;
  var cols = math.sqrt(capacity * math.max(aspect, 0.01)).ceil();
  cols = cols.clamp(1, capacity);
  final rows = (capacity / cols).ceil();
  final cellW = cols <= 1 ? 0.0 : usableW / (cols - 1);
  final cellH = rows <= 1 ? 0.0 : usableH / (rows - 1);
  final slots = <ScatterSlot>[];
  for (var i = 0; i < capacity; i++) {
    final col = i % cols;
    final row = i ~/ cols;
    final baseX = cols <= 1 ? area.width / 2 : reach + col * cellW;
    final baseY = rows <= 1 ? area.height / 2 : reach + row * cellH;
    final jitterX = (random.nextDouble() - 0.5) * cellW * 0.45;
    final jitterY = (random.nextDouble() - 0.5) * cellH * 0.45;
    slots.add(ScatterSlot(
      center: Offset(
        (baseX + jitterX).clamp(reach, math.max(reach, area.width - reach)),
        (baseY + jitterY).clamp(reach, math.max(reach, area.height - reach)),
      ),
      angle: (random.nextDouble() - 0.5) * 2 * maxAngle,
    ));
  }
  slots.shuffle(random);
  return slots;
}
