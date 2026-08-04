import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/game_engine/game_engine.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

class GamesException implements Exception {
  GamesException(this.statusCode, this.message, {this.errorKey = ''});
  final int statusCode;
  final String message;
  /// Канонический ключ с сервера (`error` в JSON), без локали.
  final String errorKey;

  @override
  String toString() => 'GamesException($statusCode): $message';
}

/// Допустимые значения времени на ход (сек): 0=∞, 20, 60=1м, 600=10м
const List<int> turnTimeOptions = [20, 60, 600, 0];

/// Размеры сетки теперь выводятся из режима; список оставлен для API-совместимости.
const List<int> gridSizeOptions = [3, 8, 9, 10, 15];

const List<String> variantOptions = allGameVariants;

String variantLabel(String variant) {
  switch (parseVariant(variant)) {
    case variantGomoku:
      return 'Гомоку';
    case variantUltimate:
      return 'Ультимейт';
    case variantMulti3:
      return 'На троих';
    case variantMulti4:
      return 'На четверых';
    case variantClassic:
    default:
      return 'Классика';
  }
}

String variantShortLabel(String variant) => variantLabel(variant);

int gridSizeForVariant(String variant) => configForVariant(variant).gridSize;

int winLengthForVariant(String variant) => configForVariant(variant).winLength;

/// Базовые ставки в бронзе (без покупки в магазине).
const List<int> freeStakeOptions = [1, 10, 50];

/// Fallback, если capabilities ещё не загружены.
const List<int> stakeOptions = freeStakeOptions;

/// Сохранённая в БД конфигурация создания игры.
class UserGameSettings {
  const UserGameSettings({
    this.gameType = 'tictactoe',
    this.turnTimeSec = 0,
    this.variant = variantClassic,
    int? gridSize,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.stakeBronze = 1,
  }) : gridSize = gridSize ??
            (variant == variantGomoku
                ? 15
                : variant == variantUltimate
                    ? 9
                    : variant == variantMulti3
                        ? 8
                        : variant == variantMulti4
                            ? 10
                            : 3);

  final String gameType;
  final int turnTimeSec;
  final String variant;
  final int gridSize;
  final bool swapRule;
  final bool firstMoveRestriction;
  final int stakeBronze;

  static const defaults = UserGameSettings();

  UserGameSettings copyWith({
    String? gameType,
    int? turnTimeSec,
    String? variant,
    int? gridSize,
    bool? swapRule,
    bool? firstMoveRestriction,
    int? stakeBronze,
  }) {
    final nextVariant = variant ?? this.variant;
    return UserGameSettings(
      gameType: gameType ?? this.gameType,
      turnTimeSec: turnTimeSec ?? this.turnTimeSec,
      variant: nextVariant,
      gridSize: gridSize ?? gridSizeForVariant(nextVariant),
      swapRule: swapRule ?? this.swapRule,
      firstMoveRestriction: firstMoveRestriction ?? this.firstMoveRestriction,
      stakeBronze: stakeBronze ?? this.stakeBronze,
    );
  }

  factory UserGameSettings.fromJson(Map<String, dynamic> json) {
    final turn = (json['turn_time_sec'] as num?)?.toInt() ?? 0;
    final grid = (json['grid_size'] as num?)?.toInt() ?? 3;
    final stake = (json['stake_bronze'] as num?)?.toInt() ?? 1;
    final rawVariant = json['variant'] as String?;
    final variant = rawVariant == null || rawVariant.isEmpty
        ? variantFromLegacyGrid(grid)
        : parseVariant(rawVariant);
    return UserGameSettings(
      gameType: json['game_type'] as String? ?? 'tictactoe',
      turnTimeSec: turnTimeOptions.contains(turn) ? turn : 0,
      variant: variant,
      swapRule: json['swap_rule'] == true,
      firstMoveRestriction: json['first_move_restriction'] == true,
      stakeBronze: stake < 1 ? 1 : stake,
    );
  }

  Map<String, dynamic> toJson() => {
        'game_type': gameType,
        'turn_time_sec': turnTimeSec,
        'variant': parseVariant(variant),
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
          variant == other.variant &&
          gridSize == other.gridSize &&
          swapRule == other.swapRule &&
          firstMoveRestriction == other.firstMoveRestriction &&
          stakeBronze == other.stakeBronze;

  @override
  int get hashCode => Object.hash(
        gameType,
        turnTimeSec,
        variant,
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
  String variant = variantClassic,
  required int gridSize,
  required int turnTimeSec,
  required bool swapRule,
  required bool firstMoveRestriction,
  int stakeBronze = 1,
  bool includeTurnTime = true,
  bool offlineBot = false,
}) {
  final l10n = LocaleService.l10n;
  final cfg = configForVariant(variant);
  final resolvedGridSize = cfg.gridSize;
  final parts = <String>[
    'Режим: ${variantLabel(cfg.variant)}',
    ..._variantRulesBody(cfg, l10n, resolvedGridSize),
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

/// Текст правил по режиму (после строки «Режим: …»).
List<String> _variantRulesBody(
  GameConfig cfg,
  AppLocalizations l10n,
  int resolvedGridSize,
) {
  switch (cfg.variant) {
    case variantUltimate:
      return const [
        'Девять малых полей 3×3 объединены в одно большое. Ходят по очереди, X начинает.',
        'Ход в клетку малого поля указывает, в какое малое поле обязан ходить соперник '
            '(по той же позиции клетки: центр → центр, угол → угол и т.д.). '
            'Если это поле уже выиграно или заполнено — соперник может выбрать любое открытое.',
        'Малое поле выигрывает тот, кто собрал в нём 3 в ряд; при заполнении без победителя поле закрывается ничьей.',
        'Победа в партии: выиграть три малых поля в ряд на большом поле '
            '(горизонталь, вертикаль или диагональ).',
      ];
    case variantGomoku:
      return [
        l10n.rulesIntro(formatGridSize(resolvedGridSize)),
        l10n.rulesWin(cfg.winLength),
      ];
    case variantMulti3:
      return [
        'Трое игроков на поле ${formatGridSize(resolvedGridSize)}. '
            'Знаки: крестик (X), нолик (O) и треугольник. Ходят по кругу, X начинает.',
        l10n.rulesWin(cfg.winLength),
      ];
    case variantMulti4:
      return [
        'Четверо игроков на поле ${formatGridSize(resolvedGridSize)}. '
            'Знаки: крестик (X), нолик (O), треугольник и квадрат. Ходят по кругу, X начинает.',
        l10n.rulesWin(cfg.winLength),
      ];
    case variantClassic:
    default:
      return [
        l10n.rulesIntro(formatGridSize(resolvedGridSize)),
        l10n.rulesWin(cfg.winLength),
      ];
  }
}

/// Правила с иконкой монеты в строке ставки.
Widget buildTictactoeRulesTextWidget({
  String variant = variantClassic,
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
    variant: variant,
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
  return g > 0 || s > 0 || b > 0 ? '$diamond ◆ $g $gld $s $sil' : '$diamond ◆';
}

class LobbyPlayer {
  final String id;
  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameColor;
  final String? frameCode;

  LobbyPlayer({
    required this.id,
    String? displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameColor,
    this.frameCode,
  }) : displayName = localizeDisplayName(displayName);

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) {
    return LobbyPlayer(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarKind: json['avatar_kind'] as String? ?? 'letter',
      avatarValue: json['avatar_value'] as String?,
      frameColor: json['frame_color'] as String?,
      frameCode: json['frame_code'] as String?,
    );
  }
}

class LobbyItem {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? opponentId;
  final String status;
  /// `matchmake` — открытый поиск («Лобби»); `invite` — «Своя игра» / реванш.
  final String mode;
  final String? gameId;
  final String createdAt;
  final int turnTimeSec;
  final String variant;
  final int gridSize;
  final int maxPlayers;
  final int playersCount;
  final List<String> playerIds;
  final List<LobbyPlayer> players;
  final String? chatId;
  final bool swapRule;
  final bool firstMoveRestriction;
  final int stakeBronze;

  /// Тип игры лобби: 'tictactoe' | 'durak'.
  final String gameType;

  /// Durak: размер колоды и режим (подкидной/переводной).
  final int deckSize;
  final String gameMode;

  bool get isDurak => gameType == 'durak';

  LobbyItem({
    required this.id,
    required this.creatorId,
    String? creatorName,
    this.opponentId,
    required this.status,
    this.mode = '',
    this.gameId,
    required this.createdAt,
    this.turnTimeSec = 0,
    this.variant = variantClassic,
    int? gridSize,
    int? maxPlayers,
    int? playersCount,
    List<String>? playerIds,
    List<LobbyPlayer>? players,
    this.chatId,
    this.swapRule = false,
    this.firstMoveRestriction = false,
    this.stakeBronze = 1,
    this.gameType = 'tictactoe',
    this.deckSize = 36,
    this.gameMode = 'podkidnoi',
  })  : gridSize = gridSize ?? gridSizeForVariant(variant),
        maxPlayers = maxPlayers ?? configForVariant(variant).maxPlayers,
        players = players ?? const [],
        playerIds = playerIds ?? const [],
        playersCount =
            playersCount ?? (players?.length ?? playerIds?.length ?? 1),
        creatorName = localizeDisplayName(creatorName);

  factory LobbyItem.fromJson(Map<String, dynamic> json) {
    final legacyGrid = (json['grid_size'] as num?)?.toInt() ?? 3;
    final rawVariant = json['variant'] as String?;
    final variant = rawVariant == null || rawVariant.isEmpty
        ? variantFromLegacyGrid(legacyGrid)
        : parseVariant(rawVariant);
    final cfg = configForVariant(variant);
    final players = _parseLobbyPlayers(json['players']);
    final playerIds = _parseStringList(json['player_ids']);
    return LobbyItem(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      creatorName: localizeDisplayName(json['creator_name'] as String?),
      opponentId: json['opponent_id'] as String?,
      status: json['status'] as String? ?? '',
      mode: (json['mode'] as String?)?.trim() ?? '',
      gameId: json['game_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      variant: variant,
      gridSize: cfg.gridSize,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? cfg.maxPlayers,
      playersCount: (json['players_count'] as num?)?.toInt() ??
          (players.isNotEmpty ? players.length : playerIds.length),
      playerIds: playerIds,
      players: players,
      chatId: json['chat_id'] as String?,
      swapRule: json['swap_rule'] == true,
      firstMoveRestriction: json['first_move_restriction'] == true,
      stakeBronze: (json['stake_bronze'] as num?)?.toInt() ?? 1,
      gameType: (json['game_type'] as String?)?.trim().isNotEmpty == true
          ? (json['game_type'] as String).trim()
          : 'tictactoe',
      deckSize: (json['deck_size'] as num?)?.toInt() ?? 36,
      gameMode: (json['game_mode'] as String?)?.trim().isNotEmpty == true
          ? (json['game_mode'] as String).trim()
          : 'podkidnoi',
    );
  }

  static List<LobbyPlayer> _parseLobbyPlayers(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => LobbyPlayer.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }
}

class GamePlayerMeta {
  const GamePlayerMeta({
    required this.mark,
    required this.userId,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameColor,
    this.frameCode,
  });

  final String mark;
  final String userId;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameColor;
  final String? frameCode;
}

class GameStateItem {
  final String id;
  final List<String> board;
  final String variant;
  final String turn;
  final String? winner;
  final String status;
  final bool forfeit;
  final bool timeout;
  final int turnTimeSec;
  final int? turnDeadline;
  final int gridSize;
  final int maxPlayers;
  final String xUserId;
  final String oUserId;
  final String tUserId;
  final String sUserId;
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
  final String? tDisplayName;
  final String? sDisplayName;
  final String tAvatarKind;
  final String? tAvatarValue;
  final String? tFrameColor;
  final String? tFrameCode;
  final String sAvatarKind;
  final String? sAvatarValue;
  final String? sFrameColor;
  final String? sFrameCode;
  final String? chatId;
  final List<String> eliminatedMarks;
  final List<int>? winningCells;
  final int? nextBoard;
  final List<String> metaBoard;

  /// User id того, кто предложил ничью; null — предложения нет.
  final String? drawOfferBy;

  GameStateItem({
    required this.id,
    required this.board,
    this.variant = variantClassic,
    required this.turn,
    this.winner,
    required this.status,
    this.forfeit = false,
    this.timeout = false,
    this.turnTimeSec = 0,
    this.turnDeadline,
    this.gridSize = 3,
    this.maxPlayers = 2,
    required this.xUserId,
    required this.oUserId,
    this.tUserId = '',
    this.sUserId = '',
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
    this.tDisplayName,
    this.sDisplayName,
    this.tAvatarKind = 'letter',
    this.tAvatarValue,
    this.tFrameColor,
    this.tFrameCode,
    this.sAvatarKind = 'letter',
    this.sAvatarValue,
    this.sFrameColor,
    this.sFrameCode,
    this.chatId,
    this.eliminatedMarks = const [],
    this.winningCells,
    this.nextBoard,
    this.metaBoard = const [],
    this.drawOfferBy,
  });

  bool isTurnOf(String? userId) {
    if (userId == null || status != 'active') return false;
    return markForUser(userId) == turn;
  }

  String? markForUser(String? userId) {
    if (userId == null) return null;
    if (xUserId == userId) return 'x';
    if (oUserId == userId) return 'o';
    if (tUserId == userId) return 't';
    if (sUserId == userId) return 's';
    return null;
  }

  List<String> get playerUserIds => [
        xUserId,
        oUserId,
        if (tUserId.isNotEmpty) tUserId,
        if (sUserId.isNotEmpty) sUserId,
      ].where((id) => id.isNotEmpty).toList(growable: false);

  List<GamePlayerMeta> get playerMetas => [
        GamePlayerMeta(
          mark: 'x',
          userId: xUserId,
          displayName: xDisplayName,
          avatarKind: xAvatarKind,
          avatarValue: xAvatarValue,
          frameColor: xFrameColor,
          frameCode: xFrameCode,
        ),
        GamePlayerMeta(
          mark: 'o',
          userId: oUserId,
          displayName: oDisplayName,
          avatarKind: oAvatarKind,
          avatarValue: oAvatarValue,
          frameColor: oFrameColor,
          frameCode: oFrameCode,
        ),
        if (tUserId.isNotEmpty)
          GamePlayerMeta(
            mark: 't',
            userId: tUserId,
            displayName: tDisplayName,
            avatarKind: tAvatarKind,
            avatarValue: tAvatarValue,
            frameColor: tFrameColor,
            frameCode: tFrameCode,
          ),
        if (sUserId.isNotEmpty)
          GamePlayerMeta(
            mark: 's',
            userId: sUserId,
            displayName: sDisplayName,
            avatarKind: sAvatarKind,
            avatarValue: sAvatarValue,
            frameColor: sFrameColor,
            frameCode: sFrameCode,
          ),
      ].where((p) => p.userId.isNotEmpty).toList(growable: false);

  /// Чужие участники партии. Без [userId] — пусто (не показываем «себя» по ошибке).
  List<GamePlayerMeta> opponentsOf(String? userId) {
    final me = userId?.trim() ?? '';
    if (me.isEmpty) return const [];
    return playerMetas
        .where((p) => p.userId.trim() != me)
        .toList(growable: false);
  }

  bool isEliminated(String mark) =>
      eliminatedMarks.contains(mark.trim().toLowerCase());

  GamePlayerMeta? playerMeta(String mark) {
    final target = mark.trim().toLowerCase();
    for (final p in playerMetas) {
      if (p.mark == target) return p;
    }
    return null;
  }

  bool get isActivePvp =>
      status == 'active' && playerUserIds.every((id) => !id.startsWith('bot:'));

  factory GameStateItem.fromJson(Map<String, dynamic> json) {
    final legacyGrid = (json['grid_size'] as num?)?.toInt() ?? 3;
    final rawVariant = json['variant'] as String?;
    final variant = rawVariant == null || rawVariant.isEmpty
        ? variantFromLegacyGrid(legacyGrid)
        : parseVariant(rawVariant);
    final cfg = configForVariant(variant);
    final gridSize = cfg.gridSize;
    final n = cfg.cellCount;
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
      variant: variant,
      turn: json['turn'] as String? ?? 'x',
      winner: json['winner'] as String?,
      status: json['status'] as String? ?? 'active',
      forfeit: json['forfeit'] == true,
      timeout: json['timeout'] == true,
      turnTimeSec: (json['turn_time_sec'] as num?)?.toInt() ?? 0,
      turnDeadline: turnDeadline,
      gridSize: gridSize,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? cfg.maxPlayers,
      xUserId: json['x_user_id'] as String? ?? '',
      oUserId: json['o_user_id'] as String? ?? '',
      tUserId: json['t_user_id'] as String? ?? '',
      sUserId: json['s_user_id'] as String? ?? '',
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
      tDisplayName: _localizedOptionalName(json['t_display_name']),
      sDisplayName: _localizedOptionalName(json['s_display_name']),
      tAvatarKind: json['t_avatar_kind'] as String? ?? 'letter',
      tAvatarValue: json['t_avatar_value'] as String?,
      tFrameColor: json['t_frame_color'] as String?,
      tFrameCode: json['t_frame_code'] as String?,
      sAvatarKind: json['s_avatar_kind'] as String? ?? 'letter',
      sAvatarValue: json['s_avatar_value'] as String?,
      sFrameColor: json['s_frame_color'] as String?,
      sFrameCode: json['s_frame_code'] as String?,
      chatId: json['chat_id'] as String?,
      eliminatedMarks: _parseStringList(json['eliminated_marks']),
      winningCells: _parseWinningCells(json['winning_cells']),
      nextBoard: () {
        final raw = json['next_board'];
        if (raw is num) return raw.toInt();
        return null;
      }(),
      metaBoard: _parseMetaBoard(json['meta_board']),
      drawOfferBy: () {
        final raw = json['draw_offer_by'] as String?;
        if (raw == null || raw.trim().isEmpty) return null;
        return raw.trim();
      }(),
    );
  }

  static List<int>? _parseWinningCells(dynamic raw) {
    if (raw is! List || raw.length < 3 || raw.length > 9) return null;
    final list = <int>[];
    for (final e in raw) {
      final n = (e is num) ? e.toInt() : null;
      if (n == null || n < 0) return null;
      list.add(n);
    }
    return list;
  }

  static List<String> _parseMetaBoard(dynamic raw) {
    if (raw is! List) return const [];
    final out = List<String>.filled(9, '');
    for (var i = 0; i < raw.length && i < 9; i++) {
      out[i] = raw[i]?.toString() ?? '';
    }
    return out;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim().toLowerCase() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static String? _localizedOptionalName(dynamic rawValue) {
    final raw = rawValue as String?;
    if (raw == null || raw.trim().isEmpty) return null;
    return localizeDisplayName(raw);
  }

  /// Победная линия: из winningCells или вычисленная по доске.
  List<int>? get effectiveWinningCells {
    final winLen = GameStateItem.winLength(gridSize, variant: variant);
    if (winningCells != null && winningCells!.length == winLen) {
      return winningCells;
    }
    final mark = winner;
    if (mark == null || mark.isEmpty) return null;
    if (!status.endsWith('_won')) return null;
    return _computeWinningCells(board, mark, gridSize, winLen);
  }

  static int winLength(int gridSize, {String? variant}) {
    if (variant != null && variant.isNotEmpty) {
      return configForVariant(variant).winLength;
    }
    if (gridSize == 15) return 5;
    if (gridSize == 8 || gridSize == 10) return 4;
    return 3;
  }

  static List<int>? _computeWinningCells(
      List<String> board, String mark, int gridSize, int winLen) {
    final n = gridSize * gridSize;
    if (board.length < n) return null;
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

/// Результат GET /api/games/tictactoe/active — живая сессия (играю / лобби).
class ActiveGameItem {
  final String type; // "game" | "lobby"
  final String? gameId;
  final String? lobbyId;
  final bool isMyTurn;

  /// Тип игры: 'tictactoe' | 'durak'. От него зависит роутинг обратно
  /// в лобби/партию. Default 'tictactoe' сохраняет обратную совместимость.
  final String gameType;

  ActiveGameItem({
    required this.type,
    this.gameId,
    this.lobbyId,
    this.isMyTurn = false,
    this.gameType = 'tictactoe',
  });

  factory ActiveGameItem.fromJson(Map<String, dynamic> json) {
    return ActiveGameItem(
      type: json['type'] as String? ?? 'lobby',
      gameId: json['game_id'] as String?,
      lobbyId: json['lobby_id'] as String?,
      isMyTurn: json['is_my_turn'] as bool? ?? false,
      gameType: (json['game_type'] as String?)?.trim().isNotEmpty == true
          ? (json['game_type'] as String).trim()
          : 'tictactoe',
    );
  }
}

/// Наблюдение за multi-партией после выбывания (пока лобби/партия жива).
class ObservationItem {
  final String gameId;
  final String? lobbyId;

  const ObservationItem({required this.gameId, this.lobbyId});

  factory ObservationItem.fromJson(Map<String, dynamic> json) {
    return ObservationItem(
      gameId: json['game_id'] as String? ?? '',
      lobbyId: json['lobby_id'] as String?,
    );
  }
}

/// Ответ GetActive: active и/или observation.
class ActiveSessionResult {
  final ActiveGameItem? active;
  final ObservationItem? observation;

  const ActiveSessionResult({this.active, this.observation});

  factory ActiveSessionResult.fromJson(Map<String, dynamic> json) {
    ObservationItem? obs;
    final rawObs = json['observation'];
    if (rawObs is Map<String, dynamic>) {
      final item = ObservationItem.fromJson(rawObs);
      if (item.gameId.trim().isNotEmpty) obs = item;
    }
    final type = json['type']?.toString();
    ActiveGameItem? active;
    if (type == 'game' || type == 'lobby') {
      active = ActiveGameItem.fromJson(json);
    }
    return ActiveSessionResult(active: active, observation: obs);
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
  final bool waitingMore;
  final String? chatId;
  final int? playersCount;
  final int? maxPlayers;

  JoinLobbyResult({
    required this.joined,
    this.gameId,
    this.status,
    this.waitingMore = false,
    this.chatId,
    this.playersCount,
    this.maxPlayers,
  });

  factory JoinLobbyResult.fromJson(Map<String, dynamic> json) {
    return JoinLobbyResult(
      joined: json['joined'] as bool? ?? false,
      gameId: json['game_id'] as String?,
      status: json['status'] as String?,
      waitingMore: json['waiting_more'] as bool? ?? false,
      chatId: json['chat_id'] as String?,
      playersCount: (json['players_count'] as num?)?.toInt(),
      maxPlayers: (json['max_players'] as num?)?.toInt(),
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
        e.statusCode == 401 ? LocaleService.l10n.sessionExpired : e.message,
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
    var errorKey = '';
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        errorKey = (body['error'] ?? body['code'] ?? '').toString().trim();
        message =
            (body['message'] ?? body['error'] ?? message).toString();
      }
    } catch (_) {}

    final l10n = LocaleService.l10n;
    if (response.statusCode == 401) {
      throw GamesException(401, l10n.sessionExpired, errorKey: errorKey);
    }
    if (response.statusCode == 402) {
      throw GamesException(
        402,
        message.trim().isEmpty ? l10n.commonInsufficientCoins : message.trim(),
        errorKey: errorKey,
      );
    }
    if (response.statusCode == 403 && message.trim().isEmpty) {
      throw GamesException(403, l10n.commonForbidden, errorKey: errorKey);
    }
    if (response.statusCode == 404 && message.trim().isEmpty) {
      throw GamesException(404, l10n.commonNotFound, errorKey: errorKey);
    }
    final keyLower = errorKey.toLowerCase();
    final msgLower = message.toLowerCase();
    if (keyLower.contains('temporarily unavailable') ||
        msgLower.contains('temporarily unavailable')) {
      throw GamesException(
        response.statusCode == 0 ? 503 : response.statusCode,
        l10n.commonTryLater,
        errorKey: errorKey.isEmpty ? 'temporarily unavailable' : errorKey,
      );
    }
    if (response.statusCode == 503 && message.trim().isEmpty) {
      throw GamesException(503, l10n.errGamesUnavailable, errorKey: errorKey);
    }
    throw GamesException(
      response.statusCode,
      _messageFromBody(message),
      errorKey: errorKey,
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

  Future<CreateLobbyResult> createLobby({
    required String mode,
    int turnTimeSec = 0,
    String variant = variantClassic,
    int gridSize = 3,
    bool swapRule = false,
    bool firstMoveRestriction = false,
    int stakeBronze = 1,
    bool addBotsAfter30s = false,
  }) async {
    final parsedVariant = parseVariant(variant);
    final body = <String, dynamic>{
      'mode': mode,
      'stake_bronze': stakeBronze.clamp(1, 999999),
      'turn_time_sec': turnTimeSec,
      'variant': parsedVariant,
      'grid_size': gridSizeForVariant(parsedVariant),
      'swap_rule': false,
      'first_move_restriction': false,
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

  Future<ActiveSessionResult> getActiveSession() async {
    final response = await _authorizedRequest(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/games/tictactoe/active'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'GamesRepository.getActive',
      ),
    );
    if (response.statusCode == 204 || response.statusCode == 404) {
      return const ActiveSessionResult();
    }
    if (response.statusCode != 200) {
      _throwForErrorResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ActiveSessionResult.fromJson(body);
  }

  /// Только active (игра/лобби). Observation — через [getActiveSession].
  Future<ActiveGameItem?> getActive() async {
    final session = await getActiveSession();
    return session.active;
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
