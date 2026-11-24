// Связь ApiClient с режимом сети: офлайн не ходит в сеть, сбой сети
// поднимает сигнал для диалога «нет связи с сервером».

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/server_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(ServerLink.instance.reset);
  tearDown(ServerLink.instance.reset);

  group('isServerUnreachableError', () {
    test('обрыв и таймаут — сервер недоступен', () {
      expect(isServerUnreachableError(http.ClientException('x')), isTrue);
      expect(isServerUnreachableError(TimeoutException('x')), isTrue);
    });

    test('ответ сервера и офлайн режим — не потеря связи', () {
      expect(isServerUnreachableError(AuthException(401, 'x')), isFalse);
      expect(isServerUnreachableError(AuthException(503, 'x')), isFalse);
      expect(isServerUnreachableError(OfflineModeException()), isFalse);
      expect(isServerUnreachableError(null), isFalse);
    });
  });

  group('ServerLink.blocks', () {
    test('онлайн ничего не блокирует', () {
      expect(
        ServerLink.instance.blocks(Uri.parse('http://h/api/games')),
        isFalse,
      );
    });

    test('офлайн режет API, но оставляет вход и регистрацию', () {
      ServerLink.instance.offline = true;
      final link = ServerLink.instance;
      expect(link.blocks(Uri.parse('http://h/api/games')), isTrue);
      expect(link.blocks(Uri.parse('http://h/api/me')), isTrue);
      expect(link.blocks(Uri.parse('http://h/api/auth/refresh')), isTrue);
      expect(link.blocks(Uri.parse('http://h/api/auth/login')), isFalse);
      expect(link.blocks(Uri.parse('http://h/api/auth/register')), isFalse);
    });
  });

  group('primeOfflinePreference', () {
    test('сохранённый офлайн блокирует API ещё до провайдера', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'offline_mode_preference': 'offline',
      });
      await primeOfflinePreference();
      expect(ServerLink.instance.offline, isTrue);
    });

    test('сохранённый онлайн флаг не трогает', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'offline_mode_preference': 'online',
      });
      await primeOfflinePreference();
      expect(ServerLink.instance.offline, isFalse);
    });
  });

  group('ApiClient', () {
    test('офлайн: запрос падает сразу и не уходит в сеть', () async {
      ServerLink.instance.offline = true;
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      final watch = Stopwatch()..start();
      await http.runWithClient(
        () async {
          await expectLater(
            ApiClient.get(Uri.parse('http://h/api/games')),
            throwsA(isA<OfflineModeException>()),
          );
        },
        () => client,
      );
      expect(calls, 0);
      expect(watch.elapsedMilliseconds, lessThan(500));
      expect(ServerLink.instance.failures.value, 0);
    });

    test('сбой сети поднимает сигнал, ответ с ошибкой — нет', () async {
      final down = MockClient((_) async => throw http.ClientException('down'));
      await http.runWithClient(
        () async {
          await expectLater(
            ApiClient.get(Uri.parse('http://h/api/games')),
            throwsA(isA<http.ClientException>()),
          );
        },
        () => down,
      );
      expect(ServerLink.instance.failures.value, 1);

      final broken = MockClient((_) async => http.Response('oops', 500));
      await http.runWithClient(
        () async {
          final res = await ApiClient.get(Uri.parse('http://h/api/games'));
          expect(res.statusCode, 500);
        },
        () => broken,
      );
      expect(ServerLink.instance.failures.value, 1);
    });
  });
}
