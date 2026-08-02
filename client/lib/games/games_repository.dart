import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

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

/// Базовые ставки в бронзе (без покупки в магазине).
const List<int> freeStakeOptions = [1, 10, 50];

/// Fallback, если capabilities ещё не загружены.
const List<int> stakeOptions = freeStakeOptions;

/// Сохранённая в БД конфигурация создания игры.
class UserGameSettings {
  const UserGameSettings({
    this.gameType = 'tictactoe',
    this.turnTimeSec = 0,
    this.gridSize = 3,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.stakeBronze = 1,
  });

  final String gameType;
  final int turnTimeSec;
  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;
  final int stakeBronze;

  static const defaults = UserGameSettings();

  UserGameSettings copyWith({
    String? gameType,
    int? turnTimeSec,
    int? gridSize,
    bool? swapRule,
    bool? firstMoveRestriction,
    int? stakeBronze,
  }) {
    return UserGameSettings(
      gameType: gameType ?? this.gameType,
      turnTimeSec: turnTimeSec ?? this.turnTimeSec,
      gridSize: gridSize ?? this.gridSize,
      swapRule: swapRule ?? this.swapRule,
      firstMoveRestriction:
          firstMoveRestriction ?? this.firstMoveRestriction,
      stakeBronze: stakeBronze ?? this.stakeBronze,
    );
  }

  factory UserGameSettings.fromJson(Map<String, dynamic> json) {
    final turn = (json['turn_time_sec'] as num?)?.toInt() ?? 0;
    final grid = (json['grid_size'] as num?)?.toInt() ?? 3;
    final stake = (json['stake_bronze'] as num?)?.toInt() ?? 1;
    return UserGameSettings(
      gameType: json['game_type'] as String? ?? 'tictactoe',
      turnTimeSec: turnTimeOptions.contains(turn) ? turn : 0,
      gridSize: gridSizeOptions.contains(grid) ? grid : 3,
      swapRule: json['swap_rule'] == true,
      firstMoveRestriction: json['first_move_restriction'] == true,
      stakeBronze: stake < 1 ? 1 : stake,
    );
  }

  Map<String, dynamic> toJson() => {
        'game_type': gameType,
        'turn_time_sec': turnTimeSec,
        'grid_size': gridSize,
        'swap_rule': swapRule,
        'first_move_restriction': firstMoveRestriction,
        'stake_bronze': stakeBronze,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGameSettings &&
          gameType == other.gameType &&
          turnTimeSec == other.turnTimeSec &&
          gridSize == other.gridSize &&
          swapRule == other.swapRule &&
          firstMoveRestriction == other.firstMoveRestriction &&
          stakeBronze == other.stakeBronze;

  @override
  int get hashCode => Object.hash(
        gameType,
        turnTimeSec,
        gridSize,
        swapRule,
        firstMoveRestriction,
        stakeBronze,
      );
}

/// Подпись ставки в единицах старшего номинала.
String formatStakeAmount(int stakeBronze) {
  if (stakeBronze >= 10000 && stakeBronze % 10000 == 0) {
    return '${stakeBronze ~/ 10000}';
  }
  if (stakeBronze >= 100 && stakeBronze % 100 == 0) {
    return '${stakeBronze ~/ 100}';
  }
  return '$stakeBronze';
}

/// Тип монеты для отображения ставки.
CoinType stakeCoinType(int stakeBronze) {
  if (stakeBronze >= 10000 && stakeBronze % 10000 == 0) {
    return CoinType.gold;
  }
  if (stakeBronze >= 100 && stakeBronze % 100 == 0) {
    return CoinType.silver;
  }
  return CoinType.bronze;
}

bool stakeIsSilver(int stakeBronze) =>
    stakeCoinType(stakeBronze) == CoinType.silver;

bool stakeIsGold(int stakeBronze) =>
    stakeCoinType(stakeBronze) == CoinType.gold;

String formatTurnTime(int sec) {
  final l10n = LocaleService.l10n;
  if (sec == 0) return '∞';
  if (sec == 60) return l10n.timeOneMin;
  if (sec == 600) return l10n.timeTenMin;
  return l10n.timeSecondsShort(sec);
}

String formatGridSize(int size) => '${size}x$size';

/// Маркер иконки монеты в [buildTictactoeRulesText] (рисуется как [CoinIcon]).
const String kTictactoeRulesStakeIconMarker = '\uFFFC';

/// Общий формат правил крестиков-ноликов (игра, лобби, приглашения).
///
/// Ставка — число + [kTictactoeRulesStakeIconMarker]; для UI используйте
/// [buildTictactoeRulesTextWidget], чтобы показать иконку монеты.
String buildTictactoeRulesText({
  required int gridSize,
  required int turnTimeSec,
  required bool swapRule,
  required bool firstMoveRestriction,
  int stakeBronze = 1,
  bool includeTurnTime = true,
  bool offlineBot = false,
}) {
  final l10n = LocaleService.l10n;
  final winN = gridSize >= 6 ? 5 : gridSize;
  final parts = <String>[
    l10n.rulesIntro(formatGridSize(gridSize)),
    l10n.rulesWin(winN),
  ];
  if (includeTurnTime) {
    parts.add(
      turnTimeSec == 0
          ? l10n.rulesNoTimeLimit
          : l10n.rulesTurnTime(formatTurnTime(turnTimeSec)),
    );
  }
  // 0 — офлайн / без ставок: строку про ставку не показываем.
  // Формат: «1￼» → «1» + иконка монеты (не «1 бр»).
  if (stakeBronze > 0) {
    parts.add(
      l10n.rulesStake(
        '${formatStakeAmount(stakeBronze)}$kTictactoeRulesStakeIconMarker',
      ),
    );
  }
  if (swapRule) {
    parts.add(offlineBot ? l10n.rulesAlternateStarts : l10n.rulesSwap);
  }
  if (firstMoveRestriction) {
    parts.add(l10n.rulesNoCenter);
  }
  return parts.join('\n\n');
}

/// Правила с иконкой монеты в строке ставки.
Widget buildTictactoeRulesTextWidget({
  required int gridSize,
  required int turnTimeSec,
  required bool swapRule,
  required bool firstMoveRestriction,
  int stakeBronze = 1,
  bool includeTurnTime = true,
  bool offlineBot = false,
  TextStyle? style,
  TextAlign textAlign = TextAlign.start,
}) {
  final text = buildTictactoeRulesText(
    gridSize: gridSize,
    turnTimeSec: turnTimeSec,
    swapRule: swapRule,
    firstMoveRestriction: firstMoveRestriction,
    stakeBronze: stakeBronze,
    includeTurnTime: includeTurnTime,
    offlineBot: offlineBot,
  );
  final baseStyle = style ??
      const TextStyle(
        fontSize: 13,
        height: 1.4,
        color: AppColors.textSecondary,
      );
  const marker = kTictactoeRulesStakeIconMarker;
  final idx = text.indexOf(marker);
  if (idx < 0 || stakeBronze <= 0) {
    return Text(text, style: baseStyle, textAlign: textAlign);
  }
  final coinSize = (baseStyle.fontSize ?? 13) + 1;
  return Text.rich(
    TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: text.substring(0, idx)),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 1, right: 1),
            child: CoinIcon(
              coinType: stakeCoinType(stakeBronze),
              size: coinSize,
            ),
          ),
        ),
        TextSpan(text: text.substring(idx + marker.length)),
      ],
    ),
    textAlign: textAlign,
  );
}

/// 100 бронзы=1 серебро, 100 серебра=1 золото, 100 золота=1 бриллиант.
String formatBalance(int bronze) {
  final l10n = LocaleService.l10n;
  final br = l10n.balanceAbbrBronze;
  final sil = l10n.balanceAbbrSilver;
  final gld = l10n.balanceAbbrGold;
  if (bronze < 100) return '$bronze $br';
  final silver = bronze ~/ 100;
  final b = bronze % 100;
  if (silver < 100) return b > 0 ? '$silver $sil $b $br' : '$silver $sil';
  final gold = silver ~/ 100;
  final s = silver % 100;
  if (gold < 100) {
    return s > 0 || b > 0 ? '$gold $gld $s $sil $b $br' : '$gold $gld';
  }
  final diamond = gold ~/ 100;
  final g = gold % 100;
  return g > 0 || s > 0 || b > 0
      ? '$diamond ◆ $g $gld $s $sil'
      : '$diamond ◆';
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
    String? creatorName,
    this.opponentId,
    required this.status,
    this.gameId,
    required this.createdAt,
    this.turnTimeSec = 0,
    this.gridSize = 3,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.stakeBronze = 1,
  }) : creatorName = localizeDisplayName(creatorName);

  factory LobbyItem.fromJson(Map<String, dynamic> json) {
    return LobbyItem(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      creatorName: localizeDisplayName(json['creator_name'] as String?),
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
  final String? xFrameColor;
  final String? xFrameCode;
  final String oAvatarKind;
  final String? oAvatarValue;
  final String? oFrameColor;
  final String? oFrameCode;
  final List<int>? winningCells;
  /// User id того, кто предложил ничью; null — предложения нет.
  final String? drawOfferBy;

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
    this.xFrameColor,
    this.xFrameCode,
    this.oAvatarKind = 'letter',
    this.oAvatarValue,
    this.oFrameColor,
    this.oFrameCode,
    this.winningCells,
    this.drawOfferBy,
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
      xDisplayName: () {
        final raw = json['x_display_name'] as String?;
        if (raw == null || raw.trim().isEmpty) return null;
        return localizeDisplayName(raw);
      }(),
      oDisplayName: () {
        final raw = json['o_display_name'] as String?;
        if (raw == null || raw.trim().isEmpty) return null;
        return localizeDisplayName(raw);
      }(),
      xAvatarKind: json['x_avatar_kind'] as String? ?? 'letter',
      xAvatarValue: json['x_avatar_value'] as String?,
      xFrameColor: json['x_frame_color'] as String?,
      xFrameCode: json['x_frame_code'] as String?,
      oAvatarKind: json['o_avatar_kind'] as String? ?? 'letter',
      oAvatarValue: json['o_avatar_value'] as String?,
      oFrameColor: json['o_frame_color'] as String?,
      oFrameCode: json['o_frame_code'] as String?,
      winningCells: _parseWinningCells(json['winning_cells']),
      drawOfferBy: () {
        final raw = json['draw_offer_by'] as String?;
        if (raw == null || raw.trim().isEmpty) return null;
        return raw.trim();
      }(),
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

/// Агрегированная статистика игрока (W/D/L, win-rate, время в игре).
class GameStats {
  const GameStats({
    required this.wins,
    required this.draws,
    required this.losses,
    required this.totalPlayed,
    required this.winRate,
    required this.totalDurationSec,
    required this.topWon,
    required this.topDrawn,
    required this.topLost,
    this.games = const [],
  });

  final int wins;
  final int draws;
  final int losses;
  final int totalPlayed;
  final double winRate;
  final int totalDurationSec;
  final List<OpponentStat> topWon;
  final List<OpponentStat> topDrawn;
  final List<OpponentStat> topLost;
  /// Разбивка по типам игр.
  final List<GameTypeScore> games;

  bool get isEmpty => totalPlayed == 0;

  factory GameStats.fromJson(Map<String, dynamic> json) {
    final gamesRaw = json['games'];
    final games = gamesRaw is List
        ? gamesRaw
            .whereType<Map>()
            .map((e) => GameTypeScore.fromJson(Map<String, dynamic>.from(e)))
            .where((g) => !g.isEmpty)
            .toList(growable: false)
        : const <GameTypeScore>[];
    return GameStats(
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      totalPlayed: (json['total_played'] as num?)?.toInt() ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      totalDurationSec: (json['total_duration_sec'] as num?)?.toInt() ?? 0,
      topWon: _opponentList(json['top_won']),
      topDrawn: _opponentList(json['top_drawn']),
      topLost: _opponentList(json['top_lost']),
      games: games,
    );
  }

  static List<OpponentStat> _opponentList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => OpponentStat.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}

/// Счёт против конкретного соперника (для топа и head-to-head).
class OpponentStat {
  const OpponentStat({
    required this.opponentId,
    required this.displayName,
    required this.won,
    required this.drawn,
    required this.lost,
  });

  final String opponentId;
  final String displayName;
  final int won;
  final int drawn;
  final int lost;

  int get total => won + drawn + lost;

  factory OpponentStat.fromJson(Map<String, dynamic> json) {
    return OpponentStat(
      opponentId: json['opponent_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      won: (json['won'] as num?)?.toInt() ?? 0,
      drawn: (json['drawn'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Счёт / статистика по одному типу игры.
class GameTypeScore {
  const GameTypeScore({
    required this.gameType,
    required this.won,
    required this.drawn,
    required this.lost,
    this.totalDurationSec = 0,
    this.topWon = const [],
    this.topDrawn = const [],
    this.topLost = const [],
  });

  final String gameType;
  final int won;
  final int drawn;
  final int lost;
  final int totalDurationSec;
  final List<OpponentStat> topWon;
  final List<OpponentStat> topDrawn;
  final List<OpponentStat> topLost;

  bool get isEmpty => won == 0 && drawn == 0 && lost == 0;

  factory GameTypeScore.fromJson(Map<String, dynamic> json) {
    return GameTypeScore(
      gameType: json['game_type'] as String? ?? 'tictactoe',
      won: (json['won'] as num?)?.toInt() ?? 0,
      drawn: (json['drawn'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      totalDurationSec: (json['total_duration_sec'] as num?)?.toInt() ?? 0,
      topWon: GameStats._opponentList(json['top_won']),
      topDrawn: GameStats._opponentList(json['top_drawn']),
      topLost: GameStats._opponentList(json['top_lost']),
    );
  }
}

/// Результат head-to-head: счёт между мной и соперником.
class HeadToHead {
  const HeadToHead({
    required this.opponentId,
    required this.displayName,
    required this.won,
    required this.drawn,
    required this.lost,
    this.games = const [],
    this.showStatsToOthers = false,
  });

  final String opponentId;
  final String displayName;
  final int won;
  final int drawn;
  final int lost;
  /// Счёт по каждой игре (tictactoe, …).
  final List<GameTypeScore> games;
  /// Разрешил ли соперник показывать свою статистику другим.
  final bool showStatsToOthers;

  bool get isEmpty => won == 0 && drawn == 0 && lost == 0 && games.isEmpty;

  factory HeadToHead.fromJson(Map<String, dynamic> json) {
    final gamesRaw = json['games'];
    final games = gamesRaw is List
        ? gamesRaw
            .whereType<Map>()
            .map((e) => GameTypeScore.fromJson(Map<String, dynamic>.from(e)))
            .where((g) => !g.isEmpty)
            .toList(growable: false)
        : const <GameTypeScore>[];
    // Обратная совместимость: если games нет, собираем из суммарных полей.
    final fallbackGames = games.isNotEmpty
        ? games
        : (() {
            final won = (json['won'] as num?)?.toInt() ?? 0;
            final drawn = (json['drawn'] as num?)?.toInt() ?? 0;
            final lost = (json['lost'] as num?)?.toInt() ?? 0;
            if (won == 0 && drawn == 0 && lost == 0) {
              return const <GameTypeScore>[];
            }
            return [
              GameTypeScore(
                gameType: 'tictactoe',
                won: won,
                drawn: drawn,
                lost: lost,
              ),
            ];
          })();
    return HeadToHead(
      opponentId: json['opponent_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      won: (json['won'] as num?)?.toInt() ?? 0,
      drawn: (json['drawn'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      games: fallbackGames,
      showStatsToOthers: json['show_stats_to_others'] as bool? ?? false,
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
        e.statusCode == 401
            ? LocaleService.l10n.sessionExpired
            : e.message,
      );
    }
  }

  static String _messageFromBody(String msg) {
    final trimmed = msg.trim();
    if (trimmed.isEmpty) return LocaleService.l10n.commonServerErrorShort;
    return trimmed;
  }

  Never _throwForErrorResponse(http.Response response) {
    var message = response.body.trim();
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        message = (body['message'] ?? body['error'] ?? message).toString();
      }
    } catch (_) {}

    final l10n = LocaleService.l10n;
    if (response.statusCode == 401) {
      throw GamesException(401, l10n.sessionExpired);
    }
    if (response.statusCode == 402) {
      throw GamesException(
        402,
        message.trim().isEmpty ? l10n.commonInsufficientCoins : message.trim(),
      );
    }
    if (response.statusCode == 403 && message.trim().isEmpty) {
      throw GamesException(403, l10n.commonForbidden);
    }
    if (response.statusCode == 404 && message.trim().isEmpty) {
      throw GamesException(404, l10n.commonNotFound);
    }
    if (response.statusCode == 503 && message.trim().isEmpty) {
      throw GamesException(503, l10n.errGamesUnavailable);
    }
    throw GamesException(response.statusCode, _messageFromBody(message));
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

  Future<void> offerDraw(String gameId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/game/$gameId/draw-offer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{}',
        operation: 'GamesRepository.offerDraw',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
  }

  Future<void> acceptDraw(String gameId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/game/$gameId/draw-accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{}',
        operation: 'GamesRepository.acceptDraw',
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

  Future<UserGameSettings> getGameSettings({
    String gameType = 'tictactoe',
  }) async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse(
          '$apiBaseUrl/api/games/settings?game_type=$gameType&_=$cacheBuster',
        ),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getGameSettings',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserGameSettings.fromJson(body);
  }

  Future<UserGameSettings> saveGameSettings(UserGameSettings settings) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.put(
        Uri.parse('$apiBaseUrl/api/games/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings.toJson()),
        operation: 'GamesRepository.saveGameSettings',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserGameSettings.fromJson(body);
  }

  /// GET /api/games/stats — статистика (W/D/L, win-rate, время, топ соперников).
  /// Без [userId] — своя статистика; с [userId] — статистика другого игрока.
  Future<GameStats> getStats({String? userId}) async {
    final uri = userId == null || userId.isEmpty
        ? Uri.parse('$apiBaseUrl/api/games/stats')
        : Uri.parse('$apiBaseUrl/api/games/stats?user_id=$userId');
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getStats',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GameStats.fromJson(body);
  }

  /// GET /api/games/head-to-head?user_id=... — счёт между мной и соперником.
  Future<HeadToHead> getHeadToHead(String opponentUserId) async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse(
          '$apiBaseUrl/api/games/head-to-head?user_id=$opponentUserId',
        ),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getHeadToHead',
      ),
    );
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return HeadToHead.fromJson(body);
  }
}
