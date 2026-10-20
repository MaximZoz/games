import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/utils/user_error.dart';

import 'test_locale.dart';

void main() {
  setUp(setUpTestLocaleRu);

  group('formatUserError', () {
    test('null and fallback', () {
      expect(formatUserError(null), contains('ошибка'));
      expect(formatUserError(null, fallback: 'Кастом'), 'Кастом');
    });

    test('raw UNO late-call error is localized', () {
      expect(
        formatUserError(GamesException(
          400,
          'you cannot call UNO now',
          errorKey: 'you cannot call UNO now',
        )),
        contains('уже нельзя'),
      );
    });

    test('raw wrong game type is localized', () {
      expect(
        formatUserError(GamesException(
          400,
          'wrong game type',
          errorKey: 'wrong game type',
        )),
        'Неверный тип игры',
      );
    });

    test('raw UNO stack error is localized', () {
      expect(
        formatUserError(GamesException(
          400,
          'uno: only the same +2 or +4 can stack',
          errorKey: 'uno: only the same +2 or +4 can stack',
        )),
        contains('+2 на +4'),
      );
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
        contains('подключиться'),
      );
      expect(
        formatUserError(Exception('request timeout')),
        contains('ожидания'),
      );
    });

    test('load failure explains a 12 second timeout', () {
      expect(
        loadFailureDetail(
          TimeoutException('Future not completed', const Duration(seconds: 12)),
        ),
        'Сервер не ответил за 12 с. Проверьте интернет и нажмите «Повторить».',
      );
      expect(
        loadFailureDetail(TimeoutException('t')),
        contains('не ответил вовремя'),
      );
      expect(
        loadFailureDetail(http.ClientException('fail')),
        contains('Нет связи с сервером'),
      );
      expect(
        loadFailureDetail(FriendsException(503, 'temporarily unavailable')),
        contains('недоступен'),
      );
      expect(
        loadFailureDetail(StateError('x')),
        contains('Повторить'),
      );
      expect(
        loadFailureDetail(TimeoutException('Future not completed')),
        isNot(contains('Future not completed')),
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
