import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/screens/achievements_screen.dart';
import 'package:multigames_client/screens/admin_screen.dart';
import 'package:multigames_client/screens/coins_screen.dart';
import 'package:multigames_client/screens/chat_room_screen.dart';
import 'package:multigames_client/screens/chats_screen.dart';
import 'package:multigames_client/screens/friends_screen.dart';
import 'package:multigames_client/screens/games_screen.dart';
import 'package:multigames_client/screens/home_screen.dart';
import 'package:multigames_client/screens/inventory_screen.dart';
import 'package:multigames_client/screens/login_screen.dart';
import 'package:multigames_client/screens/profile_screen.dart';
import 'package:multigames_client/screens/register_screen.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:multigames_client/screens/tournaments_screen.dart';
import 'package:multigames_client/widgets/app_shell.dart';

const _publicPaths = <String>{'/login', '/register'};
const _authRequiredPaths = <String>{
  '/friends',
  '/chats',
  '/tournaments',
  '/games',
  '/inventory',
  '/achievements',
  '/settings',
  '/coins',
  '/admin',
};

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

NoTransitionPage<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  final refreshListenable = _AuthRefreshListenable(authNotifier.stream);
  ref.onDispose(refreshListenable.dispose);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final path = state.uri.path;
      final isPublic = _publicPaths.contains(path);
      final needsAuth = _authRequiredPaths.contains(path) || path.startsWith('/chats/');
      final isAdminRoute = path == '/admin';

      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      var user = authState.valueOrNull;
      if (needsAuth) {
        final repo = ref.read(authRepositoryProvider);
        final token = await repo.getAccessToken();
        if (token == null || token.isEmpty) {
          if (authState.valueOrNull != null) {
            await ref.read(authStateProvider.notifier).logout();
          }
          return '/profile';
        }
        user ??= await repo.getStoredUser();
      }

      if (isPublic && user != null) return '/';
      if (needsAuth && user == null) return '/profile';
      if (isAdminRoute && user != null && !user.isAdmin) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) => _noTransitionPage(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, state) => _noTransitionPage(state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/friends',
            pageBuilder: (_, state) => _noTransitionPage(state, const FriendsScreen()),
          ),
          GoRoute(
            path: '/chats',
            pageBuilder: (_, state) => _noTransitionPage(state, const ChatsScreen()),
          ),
          GoRoute(
            path: '/chats/:chatId',
            pageBuilder: (_, state) => _noTransitionPage(
              state,
              ChatRoomScreen(
                chatID: state.pathParameters['chatId'] ?? '',
                peerName: state.uri.queryParameters['name'],
              ),
            ),
          ),
          GoRoute(
            path: '/tournaments',
            pageBuilder: (_, state) => _noTransitionPage(state, const TournamentsScreen()),
          ),
          GoRoute(
            path: '/games',
            pageBuilder: (_, state) => _noTransitionPage(state, const GamesScreen()),
          ),
          GoRoute(
            path: '/inventory',
            pageBuilder: (_, state) => _noTransitionPage(state, const InventoryScreen()),
          ),
          GoRoute(
            path: '/achievements',
            pageBuilder: (_, state) => _noTransitionPage(state, const AchievementsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, state) => _noTransitionPage(state, const SettingsScreen()),
          ),
          GoRoute(
            path: '/coins',
            pageBuilder: (_, state) => _noTransitionPage(state, const CoinsScreen()),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (_, state) => _noTransitionPage(state, const LoginScreen()),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (_, state) => _noTransitionPage(state, const RegisterScreen()),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (_, state) => _noTransitionPage(state, const AdminScreen()),
          ),
        ],
      ),
    ],
  );
});
