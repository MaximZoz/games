import 'package:multigames_client/games/nardy/nardy_engine.dart';
import 'package:multigames_client/games/nardy/nardy_repository.dart';

/// Место шашки на доске: пункт дорожки и номер в стопке.
class NardyCheckerSpot {
  const NardyCheckerSpot({
    required this.id,
    required this.track,
    required this.index,
    required this.stackSize,
  });

  /// Стабильный номер шашки внутри своего цвета.
  final int id;

  /// Пункт дорожки, [nardyBarTrack] для бара или [nardyPoints] для снятых.
  final int track;

  /// Номер в стопке снизу вверх.
  final int index;
  final int stackSize;

  bool get onBar => track == nardyBarTrack;
  bool get isOff => track >= nardyPoints;
}

/// Держит за каждой шашкой стабильный номер между кадрами.
///
/// Шашки обезличены: сервер шлёт только количества. Без стабильных номеров
/// `AnimatedPositioned` не понимает, какая шашка куда поехала, и вместо
/// движения получается мгновенная перерисовка стопок.
class NardyCheckerTracker {
  final Map<int, Map<int, int>> _trackById = {0: {}, 1: {}};

  /// Пересчитать расстановку для места [seat] по текущему состоянию.
  List<NardyCheckerSpot> spotsFor(NardyGameView game, int seat) {
    final spots = _rawSpots(game, seat);
    final previous = _trackById[seat] ?? <int, int>{};
    final assigned = List<int?>.filled(spots.length, null);
    final freeIds = <int>{};
    for (var i = 0; i < spots.length; i++) {
      freeIds.add(i);
    }

    // Сначала оставляем шашки на своих пунктах — тогда «поехавшей» окажется
    // ровно та, что действительно сходила.
    final byTrack = <int, List<int>>{};
    previous.forEach((id, track) {
      if (id < spots.length) byTrack.putIfAbsent(track, () => []).add(id);
    });
    for (var i = 0; i < spots.length; i++) {
      final candidates = byTrack[spots[i].$1];
      if (candidates == null || candidates.isEmpty) continue;
      final id = candidates.removeLast();
      if (!freeIds.remove(id)) continue;
      assigned[i] = id;
    }
    final leftovers = freeIds.toList()..sort();
    var next = 0;
    for (var i = 0; i < spots.length; i++) {
      if (assigned[i] != null) continue;
      assigned[i] = leftovers[next++];
    }

    final result = <NardyCheckerSpot>[];
    final nextTracks = <int, int>{};
    for (var i = 0; i < spots.length; i++) {
      final id = assigned[i]!;
      final (track, index, stackSize) = spots[i];
      nextTracks[id] = track;
      result.add(NardyCheckerSpot(
        id: id,
        track: track,
        index: index,
        stackSize: stackSize,
      ));
    }
    _trackById[seat] = nextTracks;
    return result;
  }

  /// Сбросить привязку — новая партия начинается с чистой доски.
  void reset() {
    _trackById[0] = {};
    _trackById[1] = {};
  }

  /// Все места шашек как (пункт, номер в стопке, размер стопки).
  List<(int, int, int)> _rawSpots(NardyGameView game, int seat) {
    final out = <(int, int, int)>[];
    final bar = seat < game.bar.length ? game.bar[seat] : 0;
    for (var i = 0; i < bar; i++) {
      out.add((nardyBarTrack, i, bar));
    }
    for (var track = 0; track < nardyPoints; track++) {
      final count = _countAt(game, seat, track);
      for (var i = 0; i < count; i++) {
        out.add((track, i, count));
      }
    }
    final off = seat < game.off.length ? game.off[seat] : 0;
    for (var i = 0; i < off; i++) {
      out.add((nardyPoints, i, off));
    }
    return out;
  }

  int _countAt(NardyGameView game, int seat, int track) {
    final point = nardyTrackToBoard(game.gameMode, seat, track);
    if (point < 0 || point >= game.board.length) return 0;
    final value = game.board[point];
    if (seat == 0) return value > 0 ? value : 0;
    return value < 0 ? -value : 0;
  }
}
