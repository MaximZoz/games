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
import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/screens/games_screen.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/screens/home_screen.dart';
import 'package:multigames_client/screens/inventory_screen.dart';
import 'package:multigames_client/screens/login_screen.dart';
import 'package:multigames_client/screens/oauth_callback_screen.dart';
import 'package:multigames_client/screens/profile_screen.dart';
import 'package:multigames_client/screens/register_screen.dart';
import 'package:multigames_client/screens/settings_screen.dart';
import 'package:multigames_client/screens/shop_collections_screen.dart';
import 'package:multigames_client/screens/shop_emojis_screen.dart';
import 'package:multigames_client/screens/shop_screen.dart';
import 'package:multigames_client/screens/shop_section_screen.dart';
import 'package:multigames_client/screens/tournaments_screen.dart';
import 'package:multigames_client/screens/forgot_password_screen.dart';
import 'package:multigames_client/screens/game_stats_screen.dart';
import 'package:multigames_client/screens/reset_password_screen.dart';
import 'package:multigames_client/screens/verify_email_screen.dart';
import 'package:multigames_client/widgets/app_shell.dart';

const _publicPaths = <String>{
  '/login',
  '/register',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
  '/oauth/callback',
};
const _authRequiredPaths = <String>{
  '/',
  '/friends',
  '/chats',
  '/tournaments',
  '/games',
  '/inventory',
  '/achievements',
  '/shop',
  '/stats',
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

  void bump() => notifyListeners();

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

/// Один раз за жизнь приложения: после обновления/перезагрузки открывать «Игры».
class _StartupGamesGate {
  bool done = false;
}

final _startupGamesGateProvider = Provider<_StartupGamesGate>((ref) {
  return _StartupGamesGate();
});

/// Deep-link / auth — не сбрасываем на /games при cold start.
bool _preserveStartupPath(String path) {
  if (path == '/login' ||
      path == '/register' ||
      path == '/verify-email' ||
      path == '/forgot-password' ||
      path == '/reset-password') {
    return true;
  }
  if (path == '/oauth/callback') return true;
  // Любая зарегистрированная игра (лобби / партия / оффлайн).
  if (gameRegistry.isGameOrLobbyPath(path)) return true;
  // Комната чата /invite из пуша или ссылки.
  if (path.startsWith('/chats/') && path.length > '/chats/'.length) {
    return true;
  }
  if (path.startsWith('/coins/')) return true;
  if (path.startsWith('/shop/')) return true;
  return false;
}

/// Маршруты лобби/партии/оффлайна из [gameRegistry] — новая игра = новый дескриптор.
List<GoRoute> _gameRoutesFromRegistry() {
  final routes = <GoRoute>[];
  for (final game in gameRegistry.all) {
    routes.add(
      GoRoute(
        path: '/games/${game.id}/lobby/:lobbyId',
        pageBuilder: (_, state) => _noTransitionPage(
          state,
          game.buildLobbyScreen(
            lobbyId: state.pathParameters['lobbyId'] ?? '',
            initialMode: state.uri.queryParameters['mode'],
            fromMessageId: state.uri.queryParameters['from_message'],
          ),
        ),
      ),
    );
    routes.add(
      GoRoute(
        path: '/games/${game.id}/game/:gameId',
        pageBuilder: (_, state) => _noTransitionPage(
          state,
          game.buildGameScreen(
            gameId: state.pathParameters['gameId'] ?? '',
          ),
        ),
      ),
    );
    if (game.supportsOffline) {
      routes.add(
        GoRoute(
          path: '/games/${game.id}/offline',
          pageBuilder: (_, state) {
            final screen = game.buildOfflineScreen(
              query: state.uri.queryParameters,
            );
            return _noTransitionPage(
              state,
              screen ?? const GamesScreen(),
            );
          },
        ),
      );
    }
  }
  return routes;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  final refreshListenable = _AuthRefreshListenable(authNotifier.stream);
  final startupGate = ref.read(_startupGamesGateProvider);
  ref.listen<OfflineModeState>(offlineModeProvider, (_, __) {
    refreshListenable.bump();
  });
  ref.onDispose(refreshListenable.dispose);
  return GoRouter(
    initialLocation: '/games',
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
          final afterLogin = (_preserveStartupPath(path) || path == '/games')
              ? locationFromUri(state.uri)
              : '/games';
          return appendRedirectQuery('/login', afterLogin);
        }
        user ??= await repo.getStoredUser();
      }

      if (isPublic && user != null) {
        return safeAuthRedirect(state.uri.queryParameters['redirect']) ??
            '/games';
      }
      if (needsAuth && user == null) {
        final afterLogin = (_preserveStartupPath(path) || path == '/games')
            ? locationFromUri(state.uri)
            : '/games';
        return appendRedirectQuery('/login', afterLogin);
      }
      if (isAdminRoute && user != null && !user.isAdmin) return '/games';

      // Офлайн: чаты/друзья/лобби/ставки недоступны.
      if (user != null && ref.read(isOfflineProvider)) {
        if (path == '/friends' ||
            path == '/chats' ||
            path.startsWith('/chats/')) {
          return '/games';
        }
        if (path.startsWith('/games/tictactoe/lobby/')) {
          return '/games';
        }
        if (path == '/shop/stakes' || path.endsWith('/shop/stakes')) {
          return '/shop';
        }
      }

      // Перезагрузка / обновление PWA: всегда вкладка «Игры» (не чаты/друзья/…).
      if (user != null && !startupGate.done) {
        startupGate.done = true;
        if (!_preserveStartupPath(path) && path != '/games') {
          return '/games';
        }
      }
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
                        routes: [
                          GoRoute(
                            path: ':group',
                            pageBuilder: (_, state) {
                              final group =
                                  state.pathParameters['group'] ?? 'emotions';
                              return _noTransitionPage(
                                state,
                                ShopEmojiGroupScreen(group: group),
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'collections',
                        pageBuilder: (_, state) => _noTransitionPage(
                          state,
                          const ShopCollectionsScreen(),
                        ),
                        routes: [
                          GoRoute(
                            path: ':set',
                            pageBuilder: (_, state) {
                              final set =
                                  state.pathParameters['set'] ?? 'legends';
                              return _noTransitionPage(
                                state,
                                ShopCollectionGroupScreen(set: set),
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'stakes',
                        pageBuilder: (_, state) => _noTransitionPage(
                          state,
                          const ShopSectionScreen(
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
                    path: 'stats',
                    pageBuilder: (_, state) {
                      final uid = state.uri.queryParameters['user_id'];
                      final name = state.uri.queryParameters['name'];
                      return _noTransitionPage(
                        state,
                        GameStatsScreen(
                          userId: (uid == null || uid.isEmpty) ? null : uid,
                          displayName: name,
                        ),
                      );
                    },
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
                routes: [
                  // Совместимость со старыми ссылками → главная статистика.
                  GoRoute(
                    path: 'stats',
                    redirect: (context, state) {
                      final q = state.uri.query;
                      return q.isEmpty ? '/stats' : '/stats?$q';
                    },
                  ),
                ],
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
              GoRoute(
                path: '/verify-email',
                pageBuilder: (_, state) {
                  final email =
                      state.uri.queryParameters['email']?.trim() ?? '';
                  return _noTransitionPage(
                    state,
                    VerifyEmailScreen(email: email),
                  );
                },
              ),
              GoRoute(
                path: '/forgot-password',
                pageBuilder: (_, state) {
                  final email =
                      state.uri.queryParameters['email']?.trim() ?? '';
                  return _noTransitionPage(
                    state,
                    ForgotPasswordScreen(initialEmail: email),
                  );
                },
              ),
              GoRoute(
                path: '/reset-password',
                pageBuilder: (_, state) {
                  final email =
                      state.uri.queryParameters['email']?.trim() ?? '';
                  return _noTransitionPage(
                    state,
                    ResetPasswordScreen(email: email),
                  );
                },
              ),
              GoRoute(
                path: '/oauth/callback',
                pageBuilder: (_, state) =>
                    _noTransitionPage(state, const OAuthCallbackScreen()),
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
              ..._gameRoutesFromRegistry(),
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
