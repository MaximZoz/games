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
    return error.message;
  }
  if (error is AuthException) {
    if (error.statusCode == 502 ||
        error.statusCode == 503 ||
        _looksTemporarilyUnavailable(error.message)) {
      return l10n.commonTryLater;
    }
    return error.message;
  }
  if (error is ChatException) return error.message;
  if (error is FriendsException) return error.message;
  if (error is AdminException) return error.message;

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
