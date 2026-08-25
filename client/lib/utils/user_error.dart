import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_repository.dart';

bool _looksTemporarilyUnavailable(String text) {
  final s = text.toLowerCase();
  return s.contains('temporarily unavailable') ||
      s.contains('временно недоступно') ||
      s.contains('service unavailable');
}

/// Преобразует исключение в понятное пользователю сообщение (текущая локаль).
String formatUserError(Object? error, {String? fallback}) {
  final l10n = LocaleService.l10n;
  if (error == null) return fallback ?? l10n.commonGenericError;
  if (error is GamesException) {
    if (error.statusCode == 502 ||
        error.statusCode == 503 ||
        _looksTemporarilyUnavailable(error.errorKey) ||
        _looksTemporarilyUnavailable(error.message)) {
      return l10n.commonTryLater;
    }
    return _friendlyGameMessage(error.errorKey, error.message, l10n) ??
        _localizedServerKey(error.errorKey, error.message, l10n) ??
        error.message;
  }
  if (error is AuthException) {
    if (error.statusCode == 502 ||
        error.statusCode == 503 ||
        _looksTemporarilyUnavailable(error.message)) {
      return l10n.commonTryLater;
    }
    return _localizedServerKey('', error.message, l10n) ?? error.message;
  }
  if (error is ChatException) {
    return _localizedServerKey('', error.message, l10n) ?? error.message;
  }
  if (error is FriendsException) {
    return _localizedServerKey('', error.message, l10n) ?? error.message;
  }
  if (error is AdminException) {
    return _localizedServerKey('', error.message, l10n) ?? error.message;
  }

  if (error is http.ClientException) {
    return l10n.connectionError;
  }
  if (error is TimeoutException) {
    return l10n.errTimeout;
  }

  final str = error.toString().toLowerCase();
  if (str.contains('socket') ||
      str.contains('connection') ||
      str.contains('network')) {
    return l10n.errNoInternet;
  }
  if (str.contains('timeout')) {
    return l10n.errTimeout;
  }
  if (str.contains('failed host lookup') || str.contains('name resolution')) {
    return l10n.connectionError;
  }

  return fallback ?? l10n.commonGenericError;
}

String? _friendlyGameMessage(
  String errorKey,
  String message,
  dynamic l10n,
) {
  final blob = '$errorKey\n$message'.toLowerCase();
  if (blob.contains('only the same') ||
      blob.contains('+2 cannot be stacked') ||
      blob.contains('play +2 on +2') ||
      blob.contains('только +2') ||
      (blob.contains('uno:') && blob.contains('stack'))) {
    return l10n.unoErrStackSameOnly;
  }
  if (blob.contains('they can still say uno') ||
      blob.contains('wait a second') ||
      blob.contains('ещё могут сказать') ||
      blob.contains('подождите секунду')) {
    return l10n.unoErrCatchTooEarly;
  }
  if (blob.contains('cannot call uno') ||
      blob.contains('no longer say uno') ||
      blob.contains('уже нельзя') ||
      blob.contains('уже сходил')) {
    return l10n.unoErrCallTooLate;
  }
  if (blob.startsWith('uno:') ||
      blob.contains('\nuno:') ||
      blob.startsWith('poker:') ||
      blob.contains('\npoker:')) {
    return l10n.commonGenericError;
  }
  return _localizedServerKey(errorKey, message, l10n);
}

String? _localizedServerKey(String errorKey, String message, dynamic l10n) {
  final keys = <String>{
    errorKey.trim().toLowerCase(),
    message.trim().toLowerCase(),
  };
  for (final key in keys) {
    final mapped = _serverKeyMessage(key, l10n);
    if (mapped != null) return mapped;
  }
  return null;
}

String? _serverKeyMessage(String key, dynamic l10n) {
  switch (key) {
    case 'wrong game type':
      return l10n.apiErrWrongGameType;
    case 'wrong game type or state':
      return l10n.apiErrWrongGameTypeOrState;
    case 'lobby full':
    case 'lobby is full':
      return l10n.apiErrLobbyFull;
    case 'bad state':
      return l10n.apiErrBadState;
    case 'illegal move':
      return l10n.apiErrIllegalMove;
    case 'unknown move type':
      return l10n.apiErrUnknownMoveType;
    case 'no opponents':
      return l10n.apiErrNoOpponents;
    case 'no opponents to rematch':
      return l10n.apiErrNoOpponentsRematch;
    case 'user already in lobby':
    case 'already in lobby':
      return l10n.apiErrAlreadyInLobby;
    case 'game is not active':
    case 'game not active':
      return l10n.apiErrGameNotActive;
    case 'not in battle':
      return l10n.apiErrNotInBattle;
    case 'not in setup phase':
      return l10n.apiErrNotInSetup;
    case 'already ready':
      return l10n.apiErrAlreadyReady;
    case 'already forfeited':
      return l10n.apiErrAlreadyForfeited;
    case 'you have forfeited':
      return l10n.apiErrYouHaveForfeited;
    case 'no draw offer':
      return l10n.apiErrNoDrawOffer;
    case 'draw only in pvp':
      return l10n.apiErrDrawOnlyPvp;
    case 'draw only in 1v1':
      return l10n.apiErrDrawOnly1v1;
    case 'draw not available vs bot':
      return l10n.apiErrDrawVsBot;
    case 'draw not available in multiplayer':
      return l10n.apiErrDrawMultiplayer;
    case 'deck 24 supports only 2 players':
      return l10n.apiErrDeck24TwoPlayers;
    case 'deck 52 requires 3 or 4 players':
      return l10n.apiErrDeck52ThreeOrFour;
    case 'account frozen':
      return l10n.apiErrAccountFrozen;
    case 'turn_time_sec must be 0, 20, 60 or 600':
      return l10n.apiErrTurnTimeInvalid;
    default:
      return null;
  }
}
