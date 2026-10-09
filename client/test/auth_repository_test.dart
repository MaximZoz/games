// Unit-тесты для AuthUser, AuthException и логики репозитория.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:multigames_client/auth/auth_repository.dart';

void main() {
  group('AuthUser', () {
    test('fromJson parses full user', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'user@test.com',
        'display_name': 'Test User',
        'is_admin': true,
      };
      final user = AuthUser.fromJson(json);
      expect(user.id, json['id']);
      expect(user.email, json['email']);
      expect(user.displayName, 'Test User');
      expect(user.isAdmin, true);
    });

    test('fromJson parses user without display_name', () {
      final json = {
        'id': 'id-1',
        'email': 'a@b.c',
      };
      final user = AuthUser.fromJson(json);
      expect(user.id, 'id-1');
      expect(user.email, 'a@b.c');
      expect(user.displayName, isNull);
    });
  });

  group('authRefreshIsDeadSession', () {
    test('401 и 403 — мёртвая сессия, 503 — временный сбой', () {
      expect(authRefreshIsDeadSession(401), isTrue);
      expect(authRefreshIsDeadSession(403), isTrue);
      expect(authRefreshIsDeadSession(503), isFalse);
      expect(authRefreshIsDeadSession(200), isFalse);
    });
  });

  group('AuthException', () {
    test('toString returns message', () {
      final e = AuthException(401, 'invalid credentials');
      expect(e.toString(), 'invalid credentials');
    });
  });

  group('AuthRepository.oauthStartUrl', () {
    test('google start URL goes to OAuth redirect, not GIS overlay', () {
      final repo = AuthRepository();
      final url = repo.oauthStartUrl(
        provider: 'google',
        poll: true,
        navigate: true,
      );
      expect(url, contains('/api/auth/oauth/google/start'));
      expect(url, contains('mode=poll'));
      expect(url, contains('navigate=1'));
      expect(url, isNot(contains('pwa=1')));
    });

    test('PWA start URL marks pwa=1 so oauth_done stays out of Safari', () {
      final repo = AuthRepository();
      final url = repo.oauthStartUrl(
        provider: 'google',
        poll: true,
        pwa: true,
      );
      expect(url, contains('mode=poll'));
      expect(url, contains('pwa=1'));
      expect(url, isNot(contains('navigate=1')));
    });
  });

  group('AuthRepository (storage)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getStoredUser returns null when empty', () async {
      final repo = AuthRepository();
      await repo.init();
      final user = await repo.getStoredUser();
      expect(user, isNull);
    });

    test('peekStoredUser не требует access token', () async {
      final repo = AuthRepository();
      await repo.init();
      repo.prefs.setString('user', '{"id":"1","email":"a@b.c"}');
      final user = await repo.peekStoredUser();
      expect(user, isNotNull);
      expect(user!.email, 'a@b.c');
      final stored = await repo.getStoredUser();
      expect(stored?.id, '1');
    });

    test('logout clears storage', () async {
      final repo = AuthRepository();
      await repo.init();
      repo.prefs.setString('access_token', 'at');
      repo.prefs.setString('user', '{"id":"1","email":"a@b.c"}');
      await repo.logout();
      expect(repo.prefs.getString('access_token'), isNull);
      expect(repo.prefs.getString('user'), isNull);
    });
  });
}
