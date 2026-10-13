import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Канонические значения пола в API/БД (исторически на русском).
const kGenderMaleApi = 'Мужской';
const kGenderFemaleApi = 'Женский';

bool isSupportDisplayName(String? name) {
  final n = (name ?? '').trim().toLowerCase();
  return n == 'поддержка' || n == 'support';
}

/// Локализует служебные имена с сервера (бот / игрок по умолчанию).
String localizeDisplayName(String? name, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final n = (name ?? '').trim();
  if (n.isEmpty) return t.commonPlayer;
  switch (n.toLowerCase()) {
    case 'бот':
    case 'bot':
      return t.gameBot;
    case 'игрок':
    case 'player':
      return t.commonPlayer;
    case 'поддержка':
    case 'support':
      return t.supportTitle;
    default:
      return n;
  }
}

/// Название игры по `game_type` (карточки, лобби, статистика, чат).
///
/// Берёт [GameDescriptor.localizedName] из реестра — новая игра появляется
/// везде после регистрации и ключа в `.arb`. Неизвестный id не маскируется
/// под крестики-нолики.
String localizedGameTypeName(String gameType, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final id = gameType.trim();
  if (id.isEmpty) return t.gamesTicTacToe;
  final game = gameRegistry[id];
  if (game != null) return game.localizedName(t);
  return id;
}

/// Пользовательский режим лобби/инвайта. Пусто — чип не показывать.
///
/// Источник — [GameDescriptor.visibleModeLabel]. Игры без вариантов
/// (Уно, покер, будущие) не получают «Классику» по умолчанию.
String localizedGameModeLabel({
  required String gameType,
  String variant = '',
  String gameMode = '',
  int deckSize = 36,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return gameRegistry[gameType.trim()]?.visibleModeLabel(
        l10n: t,
        variant: variant,
        gameMode: gameMode,
        deckSize: deckSize,
      ) ??
      '';
}

/// Локализует заголовки групповых чатов игр (в БД исторически на русском).
String localizeChatTitle(String? title, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final n = (title ?? '').trim();
  if (n.isEmpty) return t.chatsGroupChat;
  switch (n) {
    case 'Дурак':
    case 'Durak':
      return t.gamesDurak;
    case 'Дурак на троих':
      return t.chatTitleDurak3;
    case 'Дурак на четверых':
      return t.chatTitleDurak4;
    case 'Крестики-нолики':
    case 'Tic-tac-toe':
      return t.gamesTicTacToe;
    case 'Уно':
    case 'Uno':
      return t.gamesUno;
    case 'Козёл':
    case 'Домино':
    case 'Domino':
    case 'Goat':
      return t.gamesDomino;
    case 'Нарды':
    case 'Nardy':
    case 'Backgammon':
      return t.gamesNardy;
    case 'Шашки':
    case 'Checkers':
      return t.gamesCheckers;
    case 'Шахматы':
    case 'Chess':
      return t.gamesChess;
    case 'На троих':
      return t.gamesVariantMulti3;
    case 'На четверых':
      return t.gamesVariantMulti4;
    case 'Групповой чат':
    case 'Group chat':
      return t.chatsGroupChat;
    case 'Поддержка':
    case 'Support':
      return t.supportTitle;
    case 'Игра':
    case 'Game':
      return t.gamesTitle;
    default:
      return n;
  }
}

/// Отображаемый пол: API хранит «Мужской»/«Женский», UI — через l10n.
String localizeGender(String? gender, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final g = (gender ?? '').trim();
  if (g.isEmpty) return t.profileGenderUnset;
  final lower = g.toLowerCase();
  if (lower == 'женский' ||
      lower == 'жен' ||
      lower == 'female' ||
      lower == 'f') {
    return t.profileGenderFemale;
  }
  if (lower == 'мужской' ||
      lower == 'муж' ||
      lower == 'male' ||
      lower == 'm') {
    return t.profileGenderMale;
  }
  return g;
}

bool isFemaleGender(String? gender) {
  final g = (gender ?? '').trim().toLowerCase();
  return g == 'женский' || g == 'жен' || g == 'female' || g == 'f';
}
