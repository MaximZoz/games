import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/utils/user_error.dart';

void main() {
  group('formatUserError', () {
    test('null and fallback', () {
      expect(formatUserError(null), contains('ошибка'));
      expect(formatUserError(null, fallback: 'Кастом'), 'Кастом');
    });

    test('domain exceptions keep message', () {
      expect(formatUserError(GamesException(400, 'Не ваш ход')), 'Не ваш ход');
      expect(formatUserError(AuthException(401, 'Сессия')), 'Сессия');
      expect(formatUserError(ChatException(404, 'Чат')), 'Чат');
      expect(formatUserError(FriendsException(403, 'Блок')), 'Блок');
    });

    test('network and timeout', () {
      expect(
        formatUserError(http.ClientException('fail')),
        contains('подключиться'),
      );
      expect(
        formatUserError(TimeoutException('t')),
        contains('ожидания'),
      );
      expect(
        formatUserError(Exception('SocketException: connection refused')),
        contains('интернет'),
      );
      expect(
        formatUserError(Exception('failed host lookup')),
        contains('найти сервер'),
      );
      expect(
        formatUserError(Exception('request timeout')),
        contains('ожидания'),
      );
    });

    test('unknown uses fallback', () {
      expect(
        formatUserError(StateError('x'), fallback: 'Упс'),
        'Упс',
      );
    });
  });
}
