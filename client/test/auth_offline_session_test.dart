// Сессия без связи с сервером: вход не слетает, вкладки не ждут сеть.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/server_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _jwt({required bool expired}) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final exp = expired ? now - 3600 : now + 3600;
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'exp': exp})}.sig';
}

const _user = {'id': 'u-1', 'email': 'user@test.com', 'display_name': 'User'};

Future<AuthRepository> _repo({String? access, String? refresh}) async {
  SharedPreferences.setMockInitialValues({
    if (access != null) 'access_token': access,
    if (refresh != null) 'refresh_token': refresh,
    'user': jsonEncode(_user),
  });
  final prefs = await SharedPreferences.getInstance();
  return AuthRepository(prefs: prefs);
}

/// Клиент считает только запросы на обновление токена.
MockClient _client({
  required Future<http.Response> Function() onRefresh,
  required void Function() countRefresh,
}) {
  return MockClient((request) async {
    if (request.url.path.endsWith('/api/auth/refresh')) {
      countRefresh();
      return onRefresh();
    }
    return http.Response('{}', 200);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ServerLink.instance.reset);
  tearDown(ServerLink.instance.reset);

  test('сервер недоступен: одна попытка refresh, сессия остаётся', () async {
    final expired = _jwt(expired: true);
    final repo = await _repo(access: expired, refresh: 'r-1');
    var invalidated = 0;
    repo.onSessionInvalidated = () => invalidated++;
    var refreshCalls = 0;

    final watch = Stopwatch()..start();
    final token = await http.runWithClient(
      repo.getAccessToken,
      () => _client(
        countRefresh: () => refreshCalls++,
        onRefresh: () async => throw http.ClientException('no route'),
      ),
    );

    // Раньше было три попытки с паузами 400 и 800 мс на каждый переход.
    expect(refreshCalls, 1);
    expect(watch.elapsedMilliseconds, lessThan(400));
    expect(token, expired);
    expect(invalidated, 0);
    expect((await repo.peekStoredUser())?.id, 'u-1');
  });

  test('офлайн режим: токен отдаётся сразу, сеть не трогаем', () async {
    final expired = _jwt(expired: true);
    final repo = await _repo(access: expired, refresh: 'r-1');
    ServerLink.instance.offline = true;
    var refreshCalls = 0;

    final token = await http.runWithClient(
      repo.getAccessToken,
      () => _client(
        countRefresh: () => refreshCalls++,
        onRefresh: () async => http.Response('{}', 401),
      ),
    );

    expect(refreshCalls, 0);
    expect(token, expired);
    expect((await repo.peekStoredUser())?.id, 'u-1');
  });

  test('нет access-токена и нет сети: 503, а не «сессия истекла»', () async {
    final repo = await _repo(refresh: 'r-1');
    var invalidated = 0;
    repo.onSessionInvalidated = () => invalidated++;

    Object? error;
    await http.runWithClient(
      () async {
        try {
          await repo.sendAuthorized(
            (token) => http.get(Uri.parse('http://h/api/me')),
          );
        } catch (e) {
          error = e;
        }
      },
      () => _client(
        countRefresh: () {},
        onRefresh: () async => throw http.ClientException('no route'),
      ),
    );

    // 401 здесь заставлял экраны чатов и друзей вызывать logout.
    expect(error, isA<AuthException>());
    expect((error! as AuthException).statusCode, 503);
    expect(invalidated, 0);
    expect((await repo.peekStoredUser())?.id, 'u-1');
  });

  test('сервер ответил 401 на refresh: сессия снимается как раньше', () async {
    final repo = await _repo(access: _jwt(expired: true), refresh: 'r-1');
    var invalidated = 0;
    repo.onSessionInvalidated = () => invalidated++;

    final token = await http.runWithClient(
      repo.getAccessToken,
      () => _client(
        countRefresh: () {},
        onRefresh: () async => http.Response('{"error":"expired"}', 401),
      ),
    );

    expect(token, isNull);
    expect(invalidated, 1);
    expect(await repo.peekStoredUser(), isNull);
  });
}
