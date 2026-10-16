import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/app_play_update.dart';
import 'package:multigames_client/core/app_reload.dart';
import 'package:multigames_client/core/app_testflight_update.dart';
import 'package:multigames_client/core/app_testflight_update_launch.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/active_game_guard.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';

/// Маркер «источник обновления = Google Play» (не серверный BUILD_ID).
const String kPlayStoreUpdateBuildMarker = 'play_store';

/// Маркер «источник обновления = TestFlight» (не серверный BUILD_ID).
const String kTestFlightUpdateBuildMarker = 'testflight';

/// Состояние проверки версии клиента vs сервера.
class AppUpdateState {
  const AppUpdateState({
    this.latestBuild,
    this.whatsNew = '',
    this.updateAvailable = false,
    this.deferredUntilGameEnd = false,
    this.dialogShown = false,
    this.bannerDismissed = false,
    this.iosAppleId = '',
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

  /// Apple ID приложения в TestFlight. Пусто — открыть TestFlight без страницы.
  final String iosAppleId;

  AppUpdateState copyWith({
    String? latestBuild,
    String? whatsNew,
    bool? updateAvailable,
    bool? deferredUntilGameEnd,
    bool? dialogShown,
    bool? bannerDismissed,
    String? iosAppleId,
  }) {
    return AppUpdateState(
      latestBuild: latestBuild ?? this.latestBuild,
      whatsNew: whatsNew ?? this.whatsNew,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      deferredUntilGameEnd: deferredUntilGameEnd ?? this.deferredUntilGameEnd,
      dialogShown: dialogShown ?? this.dialogShown,
      bannerDismissed: bannerDismissed ?? this.bannerDismissed,
      iosAppleId: iosAppleId ?? this.iosAppleId,
    );
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier(ref);
});

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(this._ref) : super(const AppUpdateState()) {
    // Периодическая сверка — если первый запрос упал/закэшировался.
    _poll = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(check());
    });
  }

  final Ref _ref;
  bool _checking = false;
  bool _didInitialCheck = false;
  DateTime? _lastHttpFetchAt;
  Timer? _poll;

  String get localBuildId => appBuildId;

  @override
  void dispose() {
    _poll?.cancel();
    _poll = null;
    super.dispose();
  }

  /// Один раз при старте shell (гость или авторизованный).
  /// Повторные вызовы из build не ходят в сеть — для этого poll / WS.
  Future<void> ensureInitialCheck() async {
    if (_didInitialCheck) return;
    _didInitialCheck = true;
    await check();
  }

  /// Сравнить с Play (Android) или с сервером / WS (web и прочие).
  Future<void> check({
    String? latestBuild,
    String? whatsNew,
  }) async {
    if (_checking && latestBuild == null) return;
    _checking = true;
    try {
      var notes = whatsNew?.trim() ?? '';

      // Android из Play: источник правды — In-App Updates API, не BUILD_ID.
      // Иначе AAB без --dart-define=BUILD_ID=… давал бы ложные диалоги.
      if (await supportsPlayInAppUpdate()) {
        if (notes.isEmpty) {
          final info = await _fetchVersionInfo();
          notes = info?.whatsNew ?? '';
        }
        final playAvailable = await isPlayStoreUpdateAvailable();
        if (playAvailable) {
          _setUpdateAvailable(
            remote: kPlayStoreUpdateBuildMarker,
            notes: notes,
          );
        } else if (state.updateAvailable &&
            state.latestBuild == kPlayStoreUpdateBuildMarker) {
          state = const AppUpdateState();
        }
        return;
      }

      // iPhone из TestFlight: только если CI записал более новую IPA.
      // Серверный BUILD_ID меняется и без сборки — из-за него диалог был ложным,
      // а кнопка ничего не ставила.
      if (await supportsTestFlightUpdate()) {
        final info = await _fetchVersionInfo();
        if (info == null) return;
        if (notes.isEmpty) notes = info.whatsNew;
        final flightAvailable = iosTestFlightUpdateAvailable(
          localBuildId: appBuildId,
          localBuildNumber: iosBuildNumber,
          remoteBuildId: info.iosBuildId,
          remoteBuildNumber: info.iosBuildNumber,
        );
        if (flightAvailable) {
          _setUpdateAvailable(
            remote: kTestFlightUpdateBuildMarker,
            notes: notes,
            iosAppleId: info.iosAppleId,
          );
        } else if (state.updateAvailable &&
            state.latestBuild == kTestFlightUpdateBuildMarker) {
          state = const AppUpdateState();
        }
        return;
      }

      var remote = latestBuild?.trim();
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
        } else if (state.latestBuild != remote ||
            (notes.isNotEmpty && state.whatsNew != notes)) {
          // Не трогаем state, если уже актуально — иначе shell пересобирается
          // и снова дергает check (спам /api/version).
          state = state.copyWith(
            latestBuild: remote,
            whatsNew: notes.isNotEmpty ? notes : state.whatsNew,
            updateAvailable: false,
          );
        }
        return;
      }

      _setUpdateAvailable(remote: remote, notes: notes);
    } finally {
      _checking = false;
    }
  }

  void _setUpdateAvailable({
    required String remote,
    required String notes,
    String iosAppleId = '',
  }) {
    final inGame = _isInActiveGame();
    final newRemote = remote != state.latestBuild;
    if (!newRemote &&
        state.updateAvailable &&
        state.deferredUntilGameEnd == inGame &&
        (notes.isEmpty || state.whatsNew == notes) &&
        (iosAppleId.isEmpty || state.iosAppleId == iosAppleId)) {
      return;
    }
    state = AppUpdateState(
      latestBuild: remote,
      whatsNew: notes.isNotEmpty ? notes : state.whatsNew,
      updateAvailable: true,
      deferredUntilGameEnd: inGame,
      // Новый build — снова показать диалог.
      dialogShown: newRemote ? false : state.dialogShown,
      bannerDismissed: newRemote ? false : state.bannerDismissed,
      iosAppleId: iosAppleId.isNotEmpty ? iosAppleId : state.iosAppleId,
    );
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
    state = state.copyWith(bannerDismissed: true);
  }

  Future<void> applyUpdate() async {
    // Android: Play In-App Update. iPhone: страница приложения в TestFlight.
    // Web: hard reload.
    if (await applyPlayStoreUpdate()) return;
    if (await applyTestFlightUpdate(state.iosAppleId)) return;
    await reloadApp();
  }

  bool _isInActiveGame() {
    final active = _ref.read(activeGameProvider).valueOrNull;
    if (hasBlockingActiveMatch(active)) return true;
    final pinned = _ref.read(blockingGamePinProvider);
    if (pinned != null && pinned.gameId.trim().isNotEmpty) return true;
    try {
      final path = _ref.read(currentRoutePathProvider);
      if (path.contains('/games/tictactoe/game/')) return true;
      if (path.contains('/games/durak/game/')) return true;
      if (path.contains('/games/') && path.contains('/game/')) return true;
    } catch (_) {}
    return false;
  }

  Future<
      ({
        String buildId,
        String whatsNew,
        String iosBuildId,
        int iosBuildNumber,
        String iosAppleId,
      })?> _fetchVersionInfo() async {
    final now = DateTime.now();
    // Не чаще раза в 15 с — защита от петли rebuild / частых WS reconnect.
    if (_lastHttpFetchAt != null &&
        now.difference(_lastHttpFetchAt!) < const Duration(seconds: 15)) {
      return null;
    }
    try {
      // cache-bust: иначе SW/прокси может отдать старый JSON.
      final uri = Uri.parse('$apiBaseUrl/api/version').replace(
        queryParameters: {
          't': now.millisecondsSinceEpoch.toString(),
        },
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept-Language': LocaleService.acceptLanguageHeader,
            },
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final latest = body['latest_build'] ?? body['build_id'];
      if (latest is! String || latest.trim().isEmpty) return null;
      final notes = body['whats_new'];
      final iosId = body['ios_build_id'];
      final iosNumber = body['ios_build_number'];
      final iosApple = body['ios_apple_id'];
      _lastHttpFetchAt = now;
      return (
        buildId: latest.trim(),
        whatsNew: notes is String ? notes.trim() : '',
        iosBuildId: iosId is String ? iosId.trim() : '',
        iosBuildNumber: iosNumber is num ? iosNumber.toInt() : 0,
        iosAppleId: iosApple is String ? iosApple.trim() : '',
      );
    } catch (_) {}
    return null;
  }
}
