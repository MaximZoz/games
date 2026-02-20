import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/screens/achievements_screen.dart';
import 'package:multigames_client/screens/admin_screen.dart';
import 'package:multigames_client/screens/coins_screen.dart';
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
  '/profile',
  '/friends',
  '/tournaments',
  '/games',
  '/inventory',
  '/achievements',
  '/settings',
  '/coins',
  '/admin',
};

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) async {
      final path = state.uri.path;
      final isPublic = _publicPaths.contains(path);
      final needsAuth = _authRequiredPaths.contains(path);
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
          return '/login';
        }
        user ??= await repo.getStoredUser();
      }

      if (isPublic && user != null) return '/';
      if (needsAuth && user == null) return '/login';
      if (isAdminRoute && user != null && !user.isAdmin) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
          GoRoute(path: '/tournaments', builder: (_, __) => const TournamentsScreen()),
          GoRoute(path: '/games', builder: (_, __) => const GamesScreen()),
          GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/coins', builder: (_, __) => const CoinsScreen()),
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        ],
      ),
    ],
  );
});
