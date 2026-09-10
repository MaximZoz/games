import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/framework/battleship_game.dart';
import 'package:multigames_client/games/framework/checkers_game.dart';
import 'package:multigames_client/games/framework/game_descriptor.dart';
import 'package:multigames_client/games/framework/durak_game.dart';
import 'package:multigames_client/games/framework/nardy_game.dart';
import 'package:multigames_client/games/framework/poker_game.dart';
import 'package:multigames_client/games/framework/tictactoe_game.dart';
import 'package:multigames_client/games/framework/uno_game.dart';

/// Реестр игр клиента. Единственная точка «какие игры есть в приложении».
///
/// Добавление новой игры:
/// 1. Реализовать [GameDescriptor] (см. `tictactoe_game.dart` / `durak_game.dart`).
/// 2. Зарегистрировать ниже в [_builtinGames].
/// 3. На сервере — зарегистрировать модуль в `gameregistry` (см. docs).
class GameRegistry {
  GameRegistry(List<GameDescriptor> games)
      : _byId = {for (final g in games) g.id: g},
        _ordered = List<GameDescriptor>.from(games)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final Map<String, GameDescriptor> _byId;
  final List<GameDescriptor> _ordered;

  /// Все игры в порядке карточек на главной.
  List<GameDescriptor> get all => List.unmodifiable(_ordered);

  Iterable<String> get ids => _ordered.map((g) => g.id);

  GameDescriptor? operator [](String id) => _byId[id];

  GameDescriptor? find(String? id) {
    final key = normalizeId(id);
    return _byId[key];
  }

  /// Есть ли игра с таким id (без fallback на tictactoe).
  bool contains(String? id) {
    final v = (id ?? '').trim();
    return v.isNotEmpty && _byId.containsKey(v);
  }

  /// Нормализация `game_type`: неизвестное → первая зарегистрированная (ttt).
  String normalizeId(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isNotEmpty && _byId.containsKey(v)) return v;
    return _ordered.isNotEmpty ? _ordered.first.id : 'tictactoe';
  }

  String lobbyPath(String lobbyId, {String? gameType}) =>
      find(gameType)!.lobbyPath(lobbyId);

  String gamePath(String gameId, {String? gameType}) =>
      find(gameType)!.gamePath(gameId);

  String? gameIdFromPath(String? location) {
    final path = (location ?? '').split('?').first.trim();
    for (final g in _ordered) {
      final prefix = '/games/${g.id}/game/';
      if (!path.startsWith(prefix)) continue;
      final id = path.substring(prefix.length).split('/').first.trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  String? gameTypeFromPath(String? location) {
    final path = (location ?? '').split('?').first.trim();
    for (final g in _ordered) {
      if (path.startsWith('/games/${g.id}/game/') ||
          path.startsWith('/games/${g.id}/lobby/') ||
          path == '/games/${g.id}/offline') {
        return g.id;
      }
    }
    return null;
  }

  bool isGameOrLobbyPath(String path) {
    for (final g in _ordered) {
      if (path.startsWith('/games/${g.id}/')) return true;
    }
    return false;
  }

  /// Идёт партия (онлайн или офлайн) — без лобби. Экран партии сам рисует
  /// AppBar, поэтому оболочка может отдать ему свою высоту.
  bool isActiveGamePath(String path) {
    final clean = path.split('?').first;
    for (final g in _ordered) {
      if (clean.startsWith('/games/${g.id}/game/')) return true;
      if (clean == '/games/${g.id}/offline') return true;
    }
    return false;
  }
}

List<GameDescriptor> _builtinGames() => [
      TicTacToeGame(),
      DurakGame(),
      BattleshipGame(),
      UnoGame(),
      PokerGame(),
      NardyGame(),
      CheckersGame(),
    ];

/// Глобальный реестр (без зависимостей Riverpod — удобно в навигации).
final gameRegistry = GameRegistry(_builtinGames());

final gameRegistryProvider = Provider<GameRegistry>((ref) => gameRegistry);
