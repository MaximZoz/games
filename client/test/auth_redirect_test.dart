import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_redirect.dart';

void main() {
  group('safeAuthRedirect', () {
    test('accepts internal lobby path with query', () {
      expect(
        safeAuthRedirect('/games/tictactoe/lobby/abc?mode=invite'),
        '/games/tictactoe/lobby/abc?mode=invite',
      );
    });

    test('rejects absolute and protocol-relative urls', () {
      expect(safeAuthRedirect('https://evil.example/phish'), isNull);
      expect(safeAuthRedirect('//evil.example/phish'), isNull);
    });

    test('rejects login/register loops', () {
      expect(safeAuthRedirect('/login'), isNull);
      expect(safeAuthRedirect('/login?redirect=/games'), isNull);
      expect(safeAuthRedirect('/register'), isNull);
    });
  });

  group('appendRedirectQuery', () {
    test('adds redirect query for safe path', () {
      expect(
        appendRedirectQuery('/login', '/games/tictactoe/lobby/1?mode=invite'),
        '/login?redirect=%2Fgames%2Ftictactoe%2Flobby%2F1%3Fmode%3Dinvite',
      );
    });

    test('keeps path when redirect is unsafe', () {
      expect(appendRedirectQuery('/login', 'https://evil'), '/login');
    });
  });

  test('locationFromUri keeps path and query', () {
    expect(
      locationFromUri(Uri.parse('https://app.test/games/x?mode=invite')),
      '/games/x?mode=invite',
    );
  });
}
