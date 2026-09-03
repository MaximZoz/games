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
  /// Прошлое место каждой шашки: id → (пункт, номер в стопке).
  final Map<int, Map<int, (int, int)>> _placeById = {0: {}, 1: {}};

  /// Пересчитать расстановку для места [seat] по текущему состоянию.
  List<NardyCheckerSpot> spotsFor(NardyGameView game, int seat) {
    final spots = _rawSpots(game, seat);
    final previous = _placeById[seat] ?? <int, (int, int)>{};
    final assigned = List<int?>.filled(spots.length, null);
    final freeIds = <int>{};
    for (var i = 0; i < spots.length; i++) {
      freeIds.add(i);
    }

    // Шашки, оставшиеся на своём пункте, сохраняют и пункт, и порядок в
    // стопке: иначе при уходе одной шашки «переезжает» вся стопка.
    final byTrack = <int, List<int>>{};
    previous.forEach((id, place) {
      if (id < spots.length) byTrack.putIfAbsent(place.$1, () => []).add(id);
    });
    for (final ids in byTrack.values) {
      ids.sort((a, b) => previous[a]!.$2.compareTo(previous[b]!.$2));
    }
    final taken = <int, int>{};
    for (var i = 0; i < spots.length; i++) {
      final (track, _, _) = spots[i];
      final candidates = byTrack[track];
      if (candidates == null) continue;
      final position = taken[track] ?? 0;
      if (position >= candidates.length) continue;
      final id = candidates[position];
      if (!freeIds.remove(id)) continue;
      taken[track] = position + 1;
      assigned[i] = id;
    }
    final leftovers = freeIds.toList()..sort();
    var next = 0;
    for (var i = 0; i < spots.length; i++) {
      if (assigned[i] != null) continue;
      assigned[i] = leftovers[next++];
    }

    final result = <NardyCheckerSpot>[];
    final nextPlaces = <int, (int, int)>{};
    for (var i = 0; i < spots.length; i++) {
      final id = assigned[i]!;
      final (track, index, stackSize) = spots[i];
      nextPlaces[id] = (track, index);
      result.add(NardyCheckerSpot(
        id: id,
        track: track,
        index: index,
        stackSize: stackSize,
      ));
    }
    _placeById[seat] = nextPlaces;
    return result;
  }

  /// Сбросить привязку — новая партия начинается с чистой доски.
  void reset() {
    _placeById[0] = {};
    _placeById[1] = {};
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
