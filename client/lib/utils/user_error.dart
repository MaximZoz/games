import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:multigames_client/admin/admin_repository.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_repository.dart';

/// Преобразует исключение в понятное пользователю сообщение на русском.
String formatUserError(Object? error, {String? fallback}) {
  if (error == null) return fallback ?? 'Произошла ошибка. Попробуйте ещё раз.';
  if (error is GamesException) return error.message;
  if (error is AuthException) return error.message;
  if (error is ChatException) return error.message;
  if (error is FriendsException) return error.message;
  if (error is AdminException) return error.message;

  if (error is http.ClientException) {
    return 'Не удалось подключиться к серверу. Проверьте интернет-соединение.';
  }
  if (error is TimeoutException) {
    return 'Превышено время ожидания. Попробуйте ещё раз.';
  }

  final str = error.toString().toLowerCase();
  if (str.contains('socket') || str.contains('connection') || str.contains('network')) {
    return 'Нет подключения к интернету.';
  }
  if (str.contains('timeout')) {
    return 'Превышено время ожидания. Попробуйте ещё раз.';
  }
  if (str.contains('failed host lookup') || str.contains('name resolution')) {
    return 'Не удалось найти сервер. Проверьте подключение к интернету.';
  }

  return fallback ?? 'Произошла ошибка. Попробуйте ещё раз.';
}
