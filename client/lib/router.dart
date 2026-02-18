import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
