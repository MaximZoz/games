import 'package:multigames_client/core/sfx.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';
import 'package:multigames_client/ui/widgets/game_fly_overlay.dart';

/// Звуки нард — категория «игры» (часы и «ваш ход» остаются общими).
abstract final class NardySfx {
  /// Кубики упали на доску.
  static void roll() => _play(SfxId.chip);

  /// Шашка встала на пункт.
  static void move() => _play(SfxId.place);

  /// Шашку соперника сбили на бар.
  static void hit() => _play(SfxId.hit);

  static void _play(SfxId id) {
    // С чужой вкладки стол не должен звучать — как в остальных играх.
    if (!GameFlyOverlay.shouldPlayGameSfx()) return;
    Sfx.play(id);
  }
}

/// Что озвучить при переходе состояния партии.
enum NardySfxCue { roll, move, hit }

/// Сравнивает два снимка партии и говорит, какие звуки сыграть.
///
/// Считаем по состоянию, а не по нажатиям: ходы соперника и бота приходят
/// снимком, и озвучивать их надо так же, как свои.
List<NardySfxCue> nardySfxCues(NardyGameView? previous, NardyGameView next) {
  if (previous == null || previous.id != next.id) return const [];
  final cues = <NardySfxCue>[];
  if (!_sameRoll(previous, next)) cues.add(NardySfxCue.roll);
  final movedChecker = !_sameBoard(previous.board, next.board) ||
      _total(previous.off) != _total(next.off);
  if (movedChecker) cues.add(NardySfxCue.move);
  if (_total(next.bar) > _total(previous.bar)) cues.add(NardySfxCue.hit);
  return cues;
}

bool _sameRoll(NardyGameView a, NardyGameView b) {
  if (a.rolled.length != b.rolled.length) return false;
  for (var i = 0; i < a.rolled.length; i++) {
    if (a.rolled[i] != b.rolled[i]) return false;
  }
  // Один и тот же набор граней в новом ходу — это всё-таки новый бросок.
  return a.turnNo == b.turnNo;
}

bool _sameBoard(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _total(List<int> values) =>
    values.fold<int>(0, (sum, value) => sum + value);
