import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/pending_purchases.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuietAuth extends AuthRepository {
  @override
  Future<AuthUser?> getStoredUser() async => null;

  @override
  Future<AuthUser?> fetchCurrentUser() async => null;
}

class _FakeShop extends ShopRepository {
  _FakeShop() : super(AuthRepository());

  int buys = 0;

  @override
  Future<ShopBuyResult> buy(String code) async {
    buys++;
    return const ShopBuyResult(balanceBronze: 7, quantity: 2);
  }

  @override
  Future<List<ShopItem>> listShop() async => const [];
}

class _HangingShop extends ShopRepository {
  _HangingShop() : super(AuthRepository());

  @override
  Future<ShopBuyResult> buy(String code) => Completer<ShopBuyResult>().future;
}

class _HangSaveAuth extends _QuietAuth {
  @override
  Future<void> updateStoredUser(AuthUser user) => Completer<void>().future;
}

class _SeedAuth extends AuthStateNotifier {
  _SeedAuth(Ref ref) : super(ref);

  void seed(AuthUser user) {
    state = AsyncValue.data(user);
  }
}

void main() {
  test('PendingPurchase сериализуется с title', () {
    final item = PendingPurchase(
      code: 'emoji_smile',
      title: 'Улыбка',
      queuedAtMs: 123,
    );
    final restored = PendingPurchase.fromJson(item.toJson());
    expect(restored.code, 'emoji_smile');
    expect(restored.title, 'Улыбка');
    expect(restored.queuedAtMs, 123);
  });

  test('PendingPurchase.fromJson без title не падает', () {
    final restored = PendingPurchase.fromJson({
      'code': 'hat_1',
      'queued_at_ms': 1,
    });
    expect(restored.code, 'hat_1');
    expect(restored.title, '');
  });

  test('покупка не зависает, если в очереди уже есть позиция', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'pending_shop_purchases': jsonEncode([
        {
          'code': 'elixir_stuck',
          'title': 'Stuck',
          'queued_at_ms': 1,
        },
      ]),
    });
    final shop = _FakeShop();
    final container = ProviderContainer(
      overrides: [
        offlineModeProvider.overrideWith(
          (ref) => OfflineModeNotifier(autostart: false),
        ),
        authRepositoryProvider.overrideWithValue(_QuietAuth()),
        shopRepositoryProvider.overrideWithValue(shop),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(pendingPurchasesProvider.notifier)
        .buyOrQueue('elixir_new')
        .timeout(const Duration(seconds: 2));

    expect(result.balanceBronze, 7);
    expect(result.quantity, 2);
    for (var i = 0;
        i < 40 && container.read(pendingPurchasesProvider).isNotEmpty;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(container.read(pendingPurchasesProvider), isEmpty);
    expect(shop.buys, 2);
  });

  test('онлайн-покупка не висит, если сервер не отвечает', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final previous = PendingPurchasesNotifier.onlineBuyTimeout;
    PendingPurchasesNotifier.onlineBuyTimeout =
        const Duration(milliseconds: 40);
    addTearDown(() {
      PendingPurchasesNotifier.onlineBuyTimeout = previous;
    });
    final container = ProviderContainer(
      overrides: [
        offlineModeProvider.overrideWith(
          (ref) => OfflineModeNotifier(autostart: false),
        ),
        authRepositoryProvider.overrideWithValue(_QuietAuth()),
        shopRepositoryProvider.overrideWithValue(_HangingShop()),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(pendingPurchasesProvider.notifier)
          .buyOrQueue('elixir_hang'),
      throwsA(isA<AuthException>()),
    );
  });

  test('баланс в тулбаре не ждёт запись на диск', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        offlineModeProvider.overrideWith(
          (ref) => OfflineModeNotifier(autostart: false),
        ),
        authRepositoryProvider.overrideWithValue(_HangSaveAuth()),
        authStateProvider.overrideWith((ref) => _SeedAuth(ref)),
      ],
    );
    addTearDown(container.dispose);

    final auth = container.read(authStateProvider.notifier) as _SeedAuth;
    for (var i = 0; i < 50; i++) {
      if (!container.read(authStateProvider).isLoading) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    auth.seed(AuthUser(id: 'u', email: 'a@b.c', balanceBronze: 100));

    await auth.applyBalance(40).timeout(const Duration(milliseconds: 300));
    expect(
      container.read(authStateProvider).valueOrNull?.balanceBronze,
      40,
    );
  });

  test('PendingPurchaseFlushNotice.isEmpty', () {
    expect(
      const PendingPurchaseFlushNotice(applied: [], failed: []).isEmpty,
      isTrue,
    );
    expect(
      const PendingPurchaseFlushNotice(
        applied: [
          PendingPurchaseFlushItem(code: 'a', title: 'A'),
        ],
        failed: [],
      ).isEmpty,
      isFalse,
    );
  });
}
