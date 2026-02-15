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
      };
      final user = AuthUser.fromJson(json);
      expect(user.id, json['id']);
      expect(user.email, json['email']);
      expect(user.displayName, 'Test User');
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

  group('AuthException', () {
    test('toString returns message', () {
      final e = AuthException(401, 'invalid credentials');
      expect(e.toString(), 'invalid credentials');
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
