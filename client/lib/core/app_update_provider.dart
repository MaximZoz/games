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
    this.whatsNew = '',
    this.updateAvailable = false,
    this.deferredUntilGameEnd = false,
    this.dialogShown = false,
    this.bannerDismissed = false,
  });

  final String? latestBuild;

  /// Текст «что нового» с сервера (WHAT_NEW.md).
  final String whatsNew;

  final bool updateAvailable;

  /// Есть обновление, но пользователь в активной партии — только баннер.
  final bool deferredUntilGameEnd;

  /// Диалог уже показали (не спамить).
  final bool dialogShown;

  /// Баннер «после партии» закрыли крестиком.
  final bool bannerDismissed;

  AppUpdateState copyWith({
    String? latestBuild,
    String? whatsNew,
    bool? updateAvailable,
    bool? deferredUntilGameEnd,
    bool? dialogShown,
    bool? bannerDismissed,
  }) {
    return AppUpdateState(
      latestBuild: latestBuild ?? this.latestBuild,
      whatsNew: whatsNew ?? this.whatsNew,
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

  /// Сравнить с сервером / WS payload.
  Future<void> check({
    String? latestBuild,
    String? whatsNew,
  }) async {
    if (_checking && latestBuild == null) return;
    _checking = true;
    try {
      var remote = latestBuild?.trim();
      var notes = whatsNew?.trim() ?? '';
      if (remote == null || remote.isEmpty || notes.isEmpty) {
        final info = await _fetchVersionInfo();
        remote ??= info?.buildId;
        if (notes.isEmpty) notes = info?.whatsNew ?? '';
      }
      if (remote == null || remote.isEmpty) return;

      final local = appBuildId.trim();
      // В локальной разработке оба часто «dev» — не надоедаем.
      if (remote == local) {
        if (state.updateAvailable || state.deferredUntilGameEnd) {
          state = const AppUpdateState();
        } else {
          state = state.copyWith(
            latestBuild: remote,
            whatsNew: notes,
            updateAvailable: false,
          );
        }
        return;
      }

      final inGame = _isInActiveGame();
      state = state.copyWith(
        latestBuild: remote,
        whatsNew: notes,
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
    final pinned = _ref.read(blockingGamePinProvider);
    if (pinned != null && pinned.gameId.trim().isNotEmpty) return true;
    // Путь игры — на случай лага GetActive.
    try {
      final path = _ref.read(currentRoutePathProvider);
      if (path.contains('/games/tictactoe/game/')) return true;
      if (path.contains('/games/durak/game/')) return true;
      if (path.contains('/games/') && path.contains('/game/')) return true;
    } catch (_) {}
    return false;
  }

  Future<({String buildId, String whatsNew})?> _fetchVersionInfo() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/version'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final latest = body['latest_build'] ?? body['build_id'];
      if (latest is! String || latest.trim().isEmpty) return null;
      final notes = body['whats_new'];
      return (
        buildId: latest.trim(),
        whatsNew: notes is String ? notes.trim() : '',
      );
    } catch (_) {}
    return null;
  }
}
