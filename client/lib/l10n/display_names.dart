import 'package:multigames_client/core/locale_provider.dart';
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

/// Название игры по `game_type` (карточки приглашений, лобби, чат).
String localizedGameTypeName(String gameType, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (gameType.trim()) {
    case 'durak':
      return t.gamesDurak;
    case 'battleship':
      return t.gamesBattleship;
    case 'poker':
      return t.gamesPoker;
    case 'uno':
      return t.gamesUno;
    case 'tictactoe':
      return t.gamesTicTacToe;
    default:
      return t.gamesTicTacToe;
  }
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
