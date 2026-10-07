import 'package:flutter/widgets.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Метаданные и точки подключения одной игры в общий каркас.
///
/// Новая игра = реализация [GameDescriptor] + регистрация в [GameRegistry].
/// Движок, стол/поле и payload хода остаются в пакете игры; лобби, поиск,
/// флажки/сдача/ничья UI, ставки, статистика и навигация — общие.
abstract class GameDescriptor {
  /// Стабильный id (`tictactoe`, `durak`, …) — совпадает с `game_type` API.
  String get id;

  /// Локализованное имя — то же, что на карточке игры.
  ///
  /// Используется в статистике, списке лобби, инвайтах и чате через
  /// [localizedGameTypeName]. Новая игра обязана вернуть ключ из `.arb`,
  /// а не сырой `id`.
  String localizedName(AppLocalizations l10n);

  /// Подпись режима на карточке лобби/инвайта.
  ///
  /// Пусто — режима нет, чип не показывать. Не подставлять «Классика»
  /// только потому, что так у крестиков-ноликов: у Уно/покера и будущих
  /// игр без вариантов чип должен отсутствовать.
  String visibleModeLabel({
    required AppLocalizations l10n,
    String variant = '',
    String gameMode = '',
    int deckSize = 36,
  }) =>
      '';

  /// Порядок карточек на экране «Игры» (меньше — выше).
  int get sortOrder;

  /// Есть оффлайн-режим против бота.
  bool get supportsOffline;

  /// Карточка и правила есть, партии ещё нет — инвайты и создание выключены.
  bool get comingSoon => false;

  /// Предложить/принять ничью (обычно только 1×1).
  bool supportsDrawOffer(int playerCount) => playerCount == 2;

  /// API-префикс без хвоста: `/api/games/<id>`.
  String get apiPathPrefix => '/api/games/$id';

  /// Путь лобби: `/games/<id>/lobby/<lobbyId>`.
  String lobbyPath(String lobbyId) =>
      '/games/$id/lobby/${lobbyId.trim()}';

  /// Путь партии: `/games/<id>/game/<gameId>`.
  String gamePath(String gameId) => '/games/$id/game/${gameId.trim()}';

  /// Путь оффлайна, если [supportsOffline].
  String? get offlinePath =>
      supportsOffline ? '/games/$id/offline' : null;

  /// Экран лобби (ожидание игроков / инвайты).
  Widget buildLobbyScreen({
    required String lobbyId,
    String? initialMode,
    String? fromMessageId,
  });

  /// Экран партии (онлайн).
  Widget buildGameScreen({required String gameId});

  /// Экран оффлайна; null если не поддерживается.
  /// [query] — query-параметры роута (`deck`, `variant`, …).
  Widget? buildOfflineScreen({Map<String, String> query = const {}}) => null;
}

/// Возможности сессии, общие для всех игр (UI-хром).
///
/// Игровой экран подключает [GameActionsOverlay], [handleGameScreenClose],
/// [GameRematchSection], таймеры хода из `game_screen_widgets.dart`.
class GameSessionCapabilities {
  const GameSessionCapabilities({
    required this.canForfeit,
    required this.canOfferDraw,
    required this.canLeaveFreely,
    required this.isMyTurn,
    this.turnDeadline,
  });

  /// Показать флаг «сдаться».
  final bool canForfeit;

  /// Показать рукопожатие «ничья».
  final bool canOfferDraw;

  /// Вышел «в ноль» / выбыл — крестик уходит без сдачи.
  final bool canLeaveFreely;

  final bool isMyTurn;
  final DateTime? turnDeadline;
}
