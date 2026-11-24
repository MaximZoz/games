// Включили офлайн на экране, который живёт только на API, — роутер уводит.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/core/server_link.dart';
import 'package:multigames_client/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Offline extends OfflineModeNotifier {
  _Offline() : super(autostart: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(ServerLink.instance.reset);
  tearDown(ServerLink.instance.reset);

  test('сетевые экраны в офлайне уводят на доступные', () {
    expect(offlineRedirectFor('/friends'), '/games');
    expect(offlineRedirectFor('/chats'), '/games');
    expect(offlineRedirectFor('/chats/room-1'), '/games');
    expect(offlineRedirectFor('/games/durak/lobby/abc'), '/games');
    expect(offlineRedirectFor('/games/durak/game/abc'), '/games');
    expect(offlineRedirectFor('/shop/stakes'), '/shop');
    expect(offlineRedirectFor('/stats'), '/');
    expect(offlineRedirectFor('/admin'), '/games');
  });

  test('экраны, которые работают без сервера, остаются', () {
    expect(offlineRedirectFor('/'), isNull);
    expect(offlineRedirectFor('/games'), isNull);
    expect(offlineRedirectFor('/profile'), isNull);
    expect(offlineRedirectFor('/settings'), isNull);
    expect(offlineRedirectFor('/games/durak/offline'), isNull);
    expect(
      offlineRedirectFor('/games/durak/game/offline%3Aabc'),
      isNull,
    );
  });

  test('редирект видит офлайн уже в слушателе смены режима',
      () async {
    SharedPreferences.setMockInitialValues({});
    final offline = _Offline();
    final container = ProviderContainer(
      overrides: [offlineModeProvider.overrideWith((ref) => offline)],
    );
    addTearDown(container.dispose);

    // Как в роутере: режим читается прямо в слушателе offlineModeProvider.
    bool? seenInListener;
    final watcher = Provider<void>((ref) {
      ref.listen<OfflineModeState>(offlineModeProvider, (_, __) {
        seenInListener = routerSeesOffline(ref);
      });
    });
    container.read(watcher);
    // В приложении производный провайдер уже посчитан и на него подписаны.
    container.listen<bool>(isOfflineProvider, (_, __) {});

    await offline.setPreference(OfflinePreference.offline);

    expect(seenInListener, isTrue);
  });
}
