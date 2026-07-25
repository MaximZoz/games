import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class GamesException implements Exception {
  GamesException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'GamesException($statusCode): $message';
}

/// Допустимые значения времени на ход (сек): 0=без лимита, 10, 30, 60, 600
const List<int> turnTimeOptions = [10, 30, 60, 600, 0];

/// Размеры сетки: 3x3, 4x4, 5x5, 6x6, 7x7, 8x8
const List<int> gridSizeOptions = [3, 4, 5, 6, 7, 8];

/// Ставки в бронзовых: 1, 10, 50, 100
const List<int> stakeOptions = [1, 10, 50, 100];

String formatTurnTime(int sec) {
  if (sec == 0) return '∞';
  if (sec == 10 || sec == 30) return '$sec с';
  if (sec == 60) return '1 мин';
  if (sec == 600) return '10 мин';
  return '$sec с';
}

String formatGridSize(int size) => '${size}x$size';

/// Общий формат правил крестиков-ноликов (игра, лобби, приглашения).
String buildTictactoeRulesText({
  required int gridSize,
  required int turnTimeSec,
  required bool swapRule,
  required bool firstMoveRestriction,
  int stakeBronze = 1,
}) {
  final stake = stakeBronze < 1 ? 1 : stakeBronze;
  final parts = <String>[
    'Крестики-нолики на поле ${formatGridSize(gridSize)}. Ходят по очереди, X начинает.',
    'Победа: нужно выстроить ${gridSize >= 6 ? 5 : gridSize} в ряд по горизонтали, вертикали или диагонали.',
    turnTimeSec == 0
        ? 'Без ограничения по времени на ход.'
        : 'Время на ход: ${formatTurnTime(turnTimeSec)}.',
    'Ставка: ${formatBalance(stake)}. На столько монет идёт игра.',
  ];
  if (swapRule) {
    parts.add(
        'Смена сторон: O может поменяться местами с X после первого хода X.');
  }
  if (firstMoveRestriction) {
    parts.add('Запрет центра: X не может ходить в центр первым ходом.');
  }
  return parts.join('\n\n');
}

/// 100 бронзы=1 серебро, 100 серебра=1 золото, 100 золота=1 бриллиант.
String formatBalance(int bronze) {
  if (bronze < 100) return '$bronze бр';
  final silver = bronze ~/ 100;
  final b = bronze % 100;
  if (silver < 100) return b > 0 ? '$silver с. $b бр' : '$silver с';
  final gold = silver ~/ 100;
  final s = silver % 100;
  if (gold < 100) return s > 0 || b > 0 ? '$gold з. $s с. $b бр' : '$gold з';
  final diamond = gold ~/ 100;
  final g = gold % 100;
  return g > 0 || s > 0 || b > 0 ? '$diamond ◆ $g з. $s с' : '$diamond ◆';
}

class LobbyItem {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? opponentId;
  final String status;
  final String? gameId;
  final String createdAt;
  final int turnTimeSec;
  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;
  final int stakeBronze;

  LobbyItem({
    required this.id,
    required this.creatorId,
    this.creatorName = 'Игрок',
    this.opponentId,
    required this.status,
    this.gameId,
    required this.createdAt,
    this.turnTimeSec = 0,
    this.gridSize = 3,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.stakeBronze = 1,
  });

  factory LobbyItem.fromJson(Map<String, dynamic> json) {
    return LobbyItem(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      creatorName: json['creator_name'] as String? ?? 'Игрок',
      opponentId: json['opponent_id'] as String?,
      status: json['status'] as String? ?? '',
      gameId: json['game_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      gridSize: (json['grid_size'] as num?)?.toInt() ?? 3,
      swapRule: json['swap_rule'] == true,
      firstMoveRestriction: json['first_move_restriction'] == true,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 1,
    );
  }
}

class GameStateItem {
  final String id;
  final List<String> board;
  final String turn;
  final String? winner;
  final String status;
  final bool forfeit;
  final bool timeout;
  final int turnTimeSec;
  final int? turnDeadline;
  final int gridSize;
  final String xUserId;
  final String oUserId;
  final bool swapRule;
  final bool firstMoveRestriction;
  final bool canSwap;
  final int stakeBronze;
  final String? xDisplayName;
  final String? oDisplayName;
  final String xAvatarKind;
  final String? xAvatarValue;
  final String oAvatarKind;
  final String? oAvatarValue;
  final List<int>? winningCells;

  GameStateItem({
    required this.id,
    required this.board,
    required this.turn,
    this.winner,
    required this.status,
    this.forfeit = false,
    this.timeout = false,
    this.turnTimeSec = 0,
    this.turnDeadline,
    this.gridSize = 3,
    required this.xUserId,
    required this.oUserId,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.canSwap = false,
    this.stakeBronze = 1,
    this.xDisplayName,
    this.oDisplayName,
    this.xAvatarKind = 'letter',
    this.xAvatarValue,
    this.oAvatarKind = 'letter',
    this.oAvatarValue,
    this.winningCells,
  });

  bool isTurnOf(String? userId) {
    if (userId == null || status != 'active') return false;
    return (turn == 'x' && xUserId == userId) ||
        (turn == 'o' && oUserId == userId);
  }

  bool get isActivePvp =>
      status == 'active' &&
      !xUserId.startsWith('bot:') &&
      !oUserId.startsWith('bot:');

  factory GameStateItem.fromJson(Map<String, dynamic> json) {
    final gridSize = (json['grid_size'] as num?)?.toInt() ?? 3;
    final n = gridSize * gridSize;
    final boardRaw = json['board'];
    List<String> board = List.filled(n, '');
    if (boardRaw is List) {
      for (var i = 0; i < boardRaw.length && i < n; i++) {
        board[i] = (boardRaw[i] as String? ?? '').toString();
      }
    }
    final turnDeadlineRaw = json['turn_deadline'];
    int? turnDeadline;
    if (turnDeadlineRaw != null) {
      turnDeadline = (turnDeadlineRaw is int)
          ? turnDeadlineRaw
          : (turnDeadlineRaw is num ? turnDeadlineRaw.toInt() : null);
    }
    return GameStateItem(
      id: json['id'] as String? ?? json['game_id'] as String? ?? '',
      board: board,
      turn: json['turn'] as String? ?? 'x',
      winner: json['winner'] as String?,
      status: json['status'] as String? ?? 'active',
      forfeit: json['forfeit'] == true,
      timeout: json['timeout'] == true,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: turnDeadline,
      gridSize: (json['grid_size'] as num?)?.toInt() ?? 3,
      xUserId: json['x_user_id'] as String? ?? '',
      oUserId: json['o_user_id'] as String? ?? '',
      swapRule: json['swap_rule'] == true,
      firstMoveRestriction: json['first_move_restriction'] == true,
      canSwap: json['can_swap'] == true,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 1,
      xDisplayName: json['x_display_name'] as String?,
      oDisplayName: json['o_display_name'] as String?,
      xAvatarKind: json['x_avatar_kind'] as String? ?? 'letter',
      xAvatarValue: json['x_avatar_value'] as String?,
      oAvatarKind: json['o_avatar_kind'] as String? ?? 'letter',
      oAvatarValue: json['o_avatar_value'] as String?,
      winningCells: _parseWinningCells(json['winning_cells']),
    );
  }

  static List<int>? _parseWinningCells(dynamic raw) {
    if (raw is! List || raw.length < 3 || raw.length > 8) return null;
    final list = <int>[];
    for (final e in raw) {
      final n = (e is num) ? e.toInt() : null;
      if (n == null || n < 0) return null;
      list.add(n);
    }
    return list;
  }

  /// Победная линия: из winningCells или вычисленная по доске.
  List<int>? get effectiveWinningCells {
    final winLen = GameStateItem.winLength(gridSize);
    if (winningCells != null && winningCells!.length == winLen) {
      return winningCells;
    }
    final mark = winner;
    if (mark == null || mark.isEmpty) return null;
    if (status != 'x_won' && status != 'o_won') return null;
    return _computeWinningCells(board, mark, gridSize);
  }

  /// Для 3–5: N в ряд. Для 6–8: 5 в ряд (гомоку).
  static int winLength(int gridSize) => gridSize >= 6 ? 5 : gridSize;

  static List<int>? _computeWinningCells(
      List<String> board, String mark, int gridSize) {
    final n = gridSize * gridSize;
    if (board.length < n) return null;
    final winLen = GameStateItem.winLength(gridSize);
    if (winLen > gridSize) return null;
    // Горизонтали
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col <= gridSize - winLen; col++) {
        var allMatch = true;
        final line = <int>[];
        for (var k = 0; k < winLen; k++) {
          final idx = row * gridSize + col + k;
          line.add(idx);
          if (board[idx] != mark) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) return line;
      }
    }
    // Вертикали
    for (var col = 0; col < gridSize; col++) {
      for (var row = 0; row <= gridSize - winLen; row++) {
        var allMatch = true;
        final line = <int>[];
        for (var k = 0; k < winLen; k++) {
          final idx = (row + k) * gridSize + col;
          line.add(idx);
          if (board[idx] != mark) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) return line;
      }
    }
    // Диагональ \
    for (var row = 0; row <= gridSize - winLen; row++) {
      for (var col = 0; col <= gridSize - winLen; col++) {
        var allMatch = true;
        final line = <int>[];
        for (var k = 0; k < winLen; k++) {
          final idx = (row + k) * gridSize + col + k;
          line.add(idx);
          if (board[idx] != mark) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) return line;
      }
    }
    // Диагональ /
    for (var row = 0; row <= gridSize - winLen; row++) {
      for (var col = winLen - 1; col < gridSize; col++) {
        var allMatch = true;
        final line = <int>[];
        for (var k = 0; k < winLen; k++) {
          final idx = (row + k) * gridSize + (col - k);
          line.add(idx);
          if (board[idx] != mark) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) return line;
      }
    }
    return null;
  }
}

/// Результат GET /api/games/tictactoe/active
class ActiveGameItem {
  final String type; // "game" | "lobby"
  final String? gameId;
  final String? lobbyId;
  final bool isMyTurn;

  ActiveGameItem({
    required this.type,
    this.gameId,
    this.lobbyId,
    this.isMyTurn = false,
  });

  factory ActiveGameItem.fromJson(Map<String, dynamic> json) {
    return ActiveGameItem(
      type: json['type'] as String? ?? 'lobby',
      gameId: json['game_id'] as String?,
      lobbyId: json['lobby_id'] as String?,
      isMyTurn: json['is_my_turn'] as bool? ?? false,
    );
  }
}

class CreateLobbyResult {
  final String lobbyId;
  final String? gameId;
  final bool matched;
  final String status;
  final String createdAt;
  final String creatorId;

  CreateLobbyResult({
    required this.lobbyId,
    this.gameId,
    this.matched = false,
    required this.status,
    required this.createdAt,
    required this.creatorId,
  });

  factory CreateLobbyResult.fromJson(Map<String, dynamic> json) {
    return CreateLobbyResult(
      lobbyId: json['lobby_id'] as String? ?? '',
      gameId: json['game_id'] as String?,
      matched: json['matched'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
    );
  }
}

class RematchResult {
  final String lobbyId;
  final String status;
  final bool matched;
  final String? gameId;

  RematchResult({
    required this.lobbyId,
    required this.status,
    this.matched = false,
    this.gameId,
  });

  factory RematchResult.fromJson(Map<String, dynamic> json) {
    return RematchResult(
      lobbyId: json['lobby_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      matched: json['matched'] as bool? ?? false,
      gameId: json['game_id'] as String?,
    );
  }
}

class JoinLobbyResult {
  final bool joined;
  final String? gameId;
  final String? status;

  JoinLobbyResult({
    required this.joined,
    this.gameId,
    this.status,
  });

  factory JoinLobbyResult.fromJson(Map<String, dynamic> json) {
    return JoinLobbyResult(
      joined: json['joined'] as bool? ?? false,
      gameId: json['game_id'] as String?,
      status: json['status'] as String?,
    );
  }
}

class GamesRepository {
  GamesRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    try {
      return await _auth.sendAuthorized(request);
    } on AuthException catch (e) {
      throw GamesException(
        e.statusCode,
        e.statusCode == 401 ? 'Сессия истекла. Войдите заново.' : e.message,
      );
    }
  }

  static String _translateMessage(String msg) {
    final m = msg.toLowerCase().trim();
    const Map<String, String> map = {
      'lobby not found': 'Лобби не найдено',
      'game not found': 'Игра не найдена',
      'not found': 'Не найдено',
      'you are not invited': 'Вас не приглашали в эту игру',
      'cannot invite yourself': 'Нельзя пригласить самого себя',
      'user is not your friend': 'Этот пользователь не в списке друзей',
      'lobby not in invite mode': 'Лобби не в режиме приглашений',
      'lobby not joinable': 'В это лобби уже нельзя войти',
      'cannot join own lobby': 'Нельзя присоединиться к своему лобби',
      'game is not over': 'Игра ещё не закончена',
      'game already started': 'Игра уже началась',
      'game is over': 'Игра уже завершена',
      'not your turn': 'Сейчас не ваш ход',
      'cell already taken': 'Эта клетка уже занята',
      'cell must be 0-8': 'Неверный ход',
      'first move cannot be in center': 'Первый ход нельзя делать в центр',
      'swap not allowed in this game': 'Смена сторон недоступна в этой игре',
      'only O can swap': 'Сменить стороны может только игрок O',
      'can only swap on your turn after X\'s first move':
          'Сменить стороны можно только после первого хода X',
      'can only swap after X\'s first move':
          'Сменить стороны можно только после первого хода X',
      'lobby invite expired': 'Приглашение в лобби истекло',
      'insufficient balance': 'Недостаточно монет',
      'creator has insufficient balance': 'У создателя недостаточно монет',
      'forbidden': 'Недостаточно прав',
      'games service unavailable (redis required)': 'Игры временно недоступны',
      'server error': 'Ошибка сервера. Попробуйте позже.',
    };
    return map[m] ?? (map[msg.trim()] ?? msg);
  }

  Never _throwForErrorResponse(http.Response response) {
    var message = response.body.trim();
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        message = (body['message'] ?? body['error'] ?? message).toString();
      }
    } catch (_) {}

    if (response.statusCode == 401) {
      throw GamesException(401, 'Сессия истекла. Войдите заново.');
    }
    if (response.statusCode == 402) {
      throw GamesException(402, 'Недостаточно монет для этой ставки.');
    }
    if (response.statusCode == 403 && message.isEmpty) {
      throw GamesException(403, 'Недостаточно прав для этого действия.');
    }
    if (response.statusCode == 404 && message.isEmpty) {
      throw GamesException(404, 'Лобби или игра не найдена.');
    }
    if (response.statusCode == 503 && message.isEmpty) {
      throw GamesException(503, 'Игры временно недоступны.');
    }
    final translated =
        message.isEmpty ? 'Ошибка сервера' : _translateMessage(message);
    throw GamesException(response.statusCode, translated);
  }

  Future<RematchResult> rematch(String gameId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/rematch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'game_id': gameId}),
        operation: 'GamesRepository.rematch',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return RematchResult.fromJson(body);
  }

  Future<CreateLobbyResult> createLobby({
    required String mode,
    int turnTimeSec = 0,
    int gridSize = 3,
    bool swapRule = false,
    bool firstMoveRestriction = false,
    int stakeBronze = 1,
    bool addBotsAfter30s = false,
  }) async {
    final body = <String, dynamic>{
      'mode': mode,
      'stake_bronze': stakeBronze.clamp(1, 999999),
      'turn_time_sec': turnTimeSec,
      'grid_size': gridSize,
      'swap_rule': swapRule,
      'first_move_restriction': firstMoveRestriction,
    };
    if (mode == 'matchmake') {
      body['add_bots_after_30s'] = addBotsAfter30s;
    }
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
        operation: 'GamesRepository.createLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateLobbyResult.fromJson(data);
  }

  Future<List<LobbyItem>> listLobbies() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobbies'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.listLobbies',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['lobbies'] as List<dynamic>? ?? [];
    return list
        .map((e) => LobbyItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<LobbyItem> getLobby(String lobbyId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby/$lobbyId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return LobbyItem.fromJson(body);
  }

  Future<void> inviteToLobby(String lobbyId, String friendUserId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby/$lobbyId/invite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'friend_user_id': friendUserId}),
        operation: 'GamesRepository.inviteToLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
  }

  Future<JoinLobbyResult> joinLobby(String lobbyId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby/$lobbyId/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{}',
        operation: 'GamesRepository.joinLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return JoinLobbyResult.fromJson(body);
  }

  Future<void> declineLobby(String lobbyId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby/$lobbyId/decline'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.declineLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
  }

  Future<void> leaveLobby(String lobbyId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby/$lobbyId/leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{}',
        operation: 'GamesRepository.leaveLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
  }

  Future<GameStateItem> getGame(String gameId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/game/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getGame',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GameStateItem.fromJson(body);
  }

  Future<ActiveGameItem?> getActive() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/active'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getActive',
      ),
    );
    if (response.statusCode == 204 || response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ActiveGameItem.fromJson(body);
  }

  Future<void> forfeitGame(String gameId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/game/$gameId/forfeit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{}',
        operation: 'GamesRepository.forfeitGame',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
  }

  Future<GameStateItem> swapSides(String gameId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/game/$gameId/swap'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{}',
        operation: 'GamesRepository.swapSides',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GameStateItem.fromJson(body);
  }

  Future<GameStateItem> makeMove(String gameId, int cell) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/game/$gameId/move'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cell': cell}),
        operation: 'GamesRepository.makeMove',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GameStateItem.fromJson(body);
  }
}
