import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/app_reload.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';

/// Состояние проверки версии клиента vs сервера.
class AppUpdateState {
  const AppUpdateState({
    this.latestBuild,
    this.updateAvailable = false,
    this.deferredUntilGameEnd = false,
    this.dialogShown = false,
    this.bannerDismissed = false,
  });

  final String? latestBuild;
  final bool updateAvailable;

  /// Есть обновление, но пользователь в активной партии — только баннер.
  final bool deferredUntilGameEnd;

  /// Диалог уже показали (не спамить).
  final bool dialogShown;

  /// Баннер «после партии» закрыли крестиком.
  final bool bannerDismissed;

  AppUpdateState copyWith({
    String? latestBuild,
    bool? updateAvailable,
    bool? deferredUntilGameEnd,
    bool? dialogShown,
    bool? bannerDismissed,
  }) {
    return AppUpdateState(
      latestBuild: latestBuild ?? this.latestBuild,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      deferredUntilGameEnd: deferredUntilGameEnd ?? this.deferredUntilGameEnd,
      dialogShown: dialogShown ?? this.dialogShown,
      bannerDismissed: bannerDismissed ?? this.bannerDismissed,
    );
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier(ref);
});

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(this._ref) : super(const AppUpdateState());

  final Ref _ref;
  bool _checking = false;
  bool _didInitialCheck = false;

  String get localBuildId => appBuildId;

  /// Один раз при старте shell (гость или авторизованный).
  Future<void> ensureInitialCheck() async {
    if (_didInitialCheck) return;
    _didInitialCheck = true;
    await check();
  }

  /// Сравнить с сервером / WS payload. [fromWs] — событие realtime.
  Future<void> check({String? latestBuild, bool fromWs = false}) async {
    if (_checking && latestBuild == null) return;
    _checking = true;
    try {
      var remote = latestBuild?.trim();
      if (remote == null || remote.isEmpty) {
        remote = await _fetchLatestBuild();
      }
      if (remote == null || remote.isEmpty) return;

      final local = appBuildId.trim();
      // В локальной разработке оба часто «dev» — не надоедаем.
      if (remote == local) {
        if (state.updateAvailable || state.deferredUntilGameEnd) {
          state = const AppUpdateState();
        } else {
          state = state.copyWith(latestBuild: remote, updateAvailable: false);
        }
        return;
      }

      final inGame = _isInActiveGame();
      state = state.copyWith(
        latestBuild: remote,
        updateAvailable: true,
        deferredUntilGameEnd: inGame,
        // Новый build_id — снова можно показать баннер.
        bannerDismissed: false,
      );
    } finally {
      _checking = false;
    }
  }

  /// Партия закончилась — если ждали обновление, показать диалог.
  void onActiveGameChanged() {
    if (!state.updateAvailable) return;
    final inGame = _isInActiveGame();
    if (inGame) {
      if (!state.deferredUntilGameEnd) {
        state = state.copyWith(deferredUntilGameEnd: true);
      }
      return;
    }
    if (state.deferredUntilGameEnd) {
      state = state.copyWith(deferredUntilGameEnd: false, dialogShown: false);
    }
  }

  void markDialogShown() {
    state = state.copyWith(dialogShown: true);
  }

  void dismissBanner() {
    // Скрыть баннер до конца партии; диалог покажем когда партия закончится.
    state = state.copyWith(bannerDismissed: true);
  }

  Future<void> applyUpdate() async {
    reloadApp();
  }

  bool _isInActiveGame() {
    final active = _ref.read(activeGameProvider).valueOrNull;
    if (hasBlockingActiveMatch(active)) return true;
    final pinned = _ref.read(blockingGamePinProvider)?.trim() ?? '';
    if (pinned.isNotEmpty) return true;
    // Путь игры — на случай лага GetActive.
    try {
      final path = _ref.read(currentRoutePathProvider);
      if (path.contains('/games/tictactoe/game/')) return true;
      if (path.contains('/games/') && path.contains('/game/')) return true;
    } catch (_) {}
    return false;
  }

  Future<String?> _fetchLatestBuild() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/version'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final latest = body['latest_build'] ?? body['build_id'];
      if (latest is String && latest.trim().isNotEmpty) return latest.trim();
    } catch (_) {}
    return null;
  }
}
