import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ModalRoute, RouteObserver;
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/screens/achievements_screen.dart';
import 'package:multigames_client/screens/admin_screen.dart';
import 'package:multigames_client/screens/coins_friend_screen.dart';
import 'package:multigames_client/screens/coins_login_screen.dart';
import 'package:multigames_client/screens/coins_screen.dart';
import 'package:multigames_client/screens/chats_layout_screen.dart';
import 'package:multigames_client/screens/friends_screen.dart';
import 'package:multigames_client/screens/games_screen.dart';
import 'package:multigames_client/screens/tictactoe_game_screen.dart';
import 'package:multigames_client/screens/tictactoe_lobby_screen.dart';
import 'package:multigames_client/screens/home_screen.dart';
import 'package:multigames_client/screens/inventory_screen.dart';
import 'package:multigames_client/screens/login_screen.dart';
import 'package:multigames_client/screens/profile_screen.dart';
import 'package:multigames_client/screens/register_screen.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:multigames_client/screens/shop_emojis_screen.dart';
import 'package:multigames_client/screens/shop_screen.dart';
import 'package:multigames_client/screens/shop_section_screen.dart';
import 'package:multigames_client/screens/tournaments_screen.dart';
import 'package:multigames_client/widgets/app_shell.dart';

const _publicPaths = <String>{'/login', '/register'};
const _authRequiredPaths = <String>{
  '/',
  '/friends',
  '/chats',
  '/tournaments',
  '/games',
  '/inventory',
  '/achievements',
  '/shop',
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

/// Обсервер для уведомления экранов о смене маршрута (например, при возврате назад).
final chatsRouteObserver = RouteObserver<ModalRoute<void>>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  final refreshListenable = _AuthRefreshListenable(authNotifier.stream);
  ref.onDispose(refreshListenable.dispose);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    observers: [chatsRouteObserver],
    redirect: (context, state) async {
      final path = state.uri.path;
      final isPublic = _publicPaths.contains(path);
      final needsAuth = _authRequiredPaths.contains(path) ||
          path.startsWith('/chats/') ||
          path.startsWith('/coins/') ||
          path.startsWith('/shop/') ||
          path.startsWith('/games');
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
          return appendRedirectQuery('/login', locationFromUri(state.uri));
        }
        user ??= await repo.getStoredUser();
      }

      if (isPublic && user != null) {
        return safeAuthRedirect(state.uri.queryParameters['redirect']) ?? '/';
      }
      if (needsAuth && user == null) {
        return appendRedirectQuery('/login', locationFromUri(state.uri));
      }
      if (isAdminRoute && user != null && !user.isAdmin) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              // Достижения/монеты — дочерние у `/`, чтобы тап «Главная»
              // (go('/') / initialLocation) всегда показывал карточки.
              GoRoute(
                path: '/',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'achievements',
                    pageBuilder: (_, state) =>
                        _noTransitionPage(state, const AchievementsScreen()),
                  ),
                  GoRoute(
                    path: 'shop',
                    pageBuilder: (_, state) =>
                        _noTransitionPage(state, const ShopScreen()),
                    routes: [
                      GoRoute(
                        path: 'emojis',
                        pageBuilder: (_, state) =>
                            _noTransitionPage(state, const ShopEmojisScreen()),
                      ),
                      GoRoute(
                        path: 'frames',
                        pageBuilder: (_, state) => _noTransitionPage(
                          state,
                          const ShopSectionScreen(
                            title: 'Рамки',
                            kind: 'frame',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'stakes',
                        pageBuilder: (_, state) => _noTransitionPage(
                          state,
                          const ShopSectionScreen(
                            title: 'Ставки',
                            kind: 'stake_unlock',
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'inventory',
                    pageBuilder: (_, state) =>
                        _noTransitionPage(state, const InventoryScreen()),
                  ),
                  GoRoute(
                    path: 'coins',
                    pageBuilder: (_, state) =>
                        _noTransitionPage(state, const CoinsScreen()),
                    routes: [
                      GoRoute(
                        path: 'login',
                        pageBuilder: (_, state) =>
                            _noTransitionPage(state, const CoinsLoginScreen()),
                      ),
                      GoRoute(
                        path: 'friend',
                        pageBuilder: (_, state) =>
                            _noTransitionPage(state, const CoinsFriendScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const ProfileScreen()),
              ),
              GoRoute(
                path: '/login',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const LoginScreen()),
              ),
              GoRoute(
                path: '/register',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const RegisterScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/friends',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const FriendsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                pageBuilder: (_, state) => _noTransitionPage(
                  state,
                  const ChatsLayoutScreen(),
                ),
              ),
              GoRoute(
                path: '/chats/:chatId',
                pageBuilder: (_, state) => _noTransitionPage(
                  state,
                  ChatsLayoutScreen(
                    chatId: state.pathParameters['chatId'],
                    peerName: state.uri.queryParameters['name'],
                    fromFriends: state.uri.queryParameters['from'] == 'friends',
                    fromGames: state.uri.queryParameters['from'] == 'games',
                    gameReturnPath: state.uri.queryParameters['game'],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const GamesScreen()),
              ),
              GoRoute(
                path: '/games/tictactoe/lobby/:lobbyId',
                pageBuilder: (_, state) => _noTransitionPage(
                  state,
                  TicTacToeLobbyScreen(
                    lobbyId: state.pathParameters['lobbyId'] ?? '',
                    initialMode: state.uri.queryParameters['mode'],
                  ),
                ),
              ),
              GoRoute(
                path: '/games/tictactoe/game/:gameId',
                pageBuilder: (_, state) => _noTransitionPage(
                  state,
                  TicTacToeGameScreen(
                    gameId: state.pathParameters['gameId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: '/tournaments',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const TournamentsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const SettingsScreen()),
              ),
              GoRoute(
                path: '/admin',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const AdminScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
