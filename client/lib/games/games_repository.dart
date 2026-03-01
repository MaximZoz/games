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

class LobbyItem {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? opponentId;
  final String status;
  final String? gameId;
  final String createdAt;

  LobbyItem({
    required this.id,
    required this.creatorId,
    this.creatorName = 'Игрок',
    this.opponentId,
    required this.status,
    this.gameId,
    required this.createdAt,
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
  final String xUserId;
  final String oUserId;
  final String? xDisplayName;
  final String? oDisplayName;
  final String xAvatarKind;
  final String? xAvatarValue;
  final String oAvatarKind;
  final String? oAvatarValue;

  GameStateItem({
    required this.id,
    required this.board,
    required this.turn,
    this.winner,
    required this.status,
    this.forfeit = false,
    required this.xUserId,
    required this.oUserId,
    this.xDisplayName,
    this.oDisplayName,
    this.xAvatarKind = 'letter',
    this.xAvatarValue,
    this.oAvatarKind = 'letter',
    this.oAvatarValue,
  });

  factory GameStateItem.fromJson(Map<String, dynamic> json) {
    final boardRaw = json['board'];
    List<String> board = List.filled(9, '');
    if (boardRaw is List) {
      for (var i = 0; i < boardRaw.length && i < 9; i++) {
        board[i] = (boardRaw[i] as String? ?? '').toString();
      }
    }
    return GameStateItem(
      id: json['id'] as String? ?? '',
      board: board,
      turn: json['turn'] as String? ?? 'x',
      winner: json['winner'] as String?,
      status: json['status'] as String? ?? 'active',
      forfeit: json['forfeit'] == true,
      xUserId: json['x_user_id'] as String? ?? '',
      oUserId: json['o_user_id'] as String? ?? '',
      xDisplayName: json['x_display_name'] as String?,
      oDisplayName: json['o_display_name'] as String?,
      xAvatarKind: json['x_avatar_kind'] as String? ?? 'letter',
      xAvatarValue: json['x_avatar_value'] as String?,
      oAvatarKind: json['o_avatar_kind'] as String? ?? 'letter',
      oAvatarValue: json['o_avatar_value'] as String?,
    );
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
    if (response.statusCode == 403 && message.isEmpty) {
      throw GamesException(403, 'Недостаточно прав для этого действия.');
    }
    if (response.statusCode == 404 && message.isEmpty) {
      throw GamesException(404, 'Лобби или игра не найдена.');
    }
    if (response.statusCode == 503 && message.isEmpty) {
      throw GamesException(503, 'Игры временно недоступны.');
    }
    throw GamesException(
      response.statusCode,
      message.isEmpty ? 'Ошибка сервера' : message,
    );
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

  Future<CreateLobbyResult> createLobby({required String mode}) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/lobby'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mode': mode}),
        operation: 'GamesRepository.createLobby',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateLobbyResult.fromJson(body);
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
    if (response.statusCode == 404) return null;
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
