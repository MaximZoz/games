import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyPendingPurchases = 'pending_shop_purchases';

class PendingPurchase {
  const PendingPurchase({
    required this.code,
    required this.queuedAtMs,
  });

  final String code;
  final int queuedAtMs;

  Map<String, dynamic> toJson() => {
        'code': code,
        'queued_at_ms': queuedAtMs,
      };

  factory PendingPurchase.fromJson(Map<String, dynamic> json) {
    return PendingPurchase(
      code: (json['code'] as String?) ?? '',
      queuedAtMs: (json['queued_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

final pendingPurchasesProvider =
    StateNotifierProvider<PendingPurchasesNotifier, List<PendingPurchase>>(
        (ref) {
  return PendingPurchasesNotifier(ref);
});

class PendingPurchasesNotifier extends StateNotifier<List<PendingPurchase>> {
  PendingPurchasesNotifier(this._ref) : super(const []) {
    _load();
    _ref.listen<OfflineModeState>(offlineModeProvider, (prev, next) {
      final wasOffline = prev?.isOffline ?? true;
      if (wasOffline && !next.isOffline) {
        flush();
      }
    });
  }

  final Ref _ref;
  bool _flushing = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingPurchases);
    if (raw == null || raw.isEmpty) {
      state = const [];
      return;
    }
    try {
      final list = jsonDecode(raw);
      if (list is! List) {
        state = const [];
        return;
      }
      state = list
          .whereType<Map>()
          .map((e) => PendingPurchase.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.code.isNotEmpty)
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPendingPurchases,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  /// Поставить покупку в очередь (офлайн) или купить сразу (онлайн).
  Future<ShopBuyResult> buyOrQueue(String code) async {
    final offline = _ref.read(isOfflineProvider);
    final repo = _ref.read(shopRepositoryProvider);
    if (!offline) {
      final result = await repo.buy(code);
      await _ref
          .read(authStateProvider.notifier)
          .applyBalance(result.balanceBronze);
      _ref.invalidate(shopCatalogProvider);
      _ref.invalidate(inventoryListProvider);
      return result;
    }

    // Ставки в офлайне недоступны — не ставим в очередь.
    final catalog = _ref.read(shopCatalogProvider).valueOrNull;
    ShopItem? item;
    if (catalog != null) {
      for (final e in catalog) {
        if (e.code == code) {
          item = e;
          break;
        }
      }
    }
    if (item?.kind == 'stake_unlock') {
      throw AuthException(400, LocaleService.l10n.shopStakes);
    }

    // Оптимистично: отмечаем owned в каталоге после очереди — UI вызывает setState.
    final next = [
      ...state.where((e) => e.code != code),
      PendingPurchase(
        code: code,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    state = next;
    await _persist();
    // Локальный «успех»: баланс не меняем — сервер применит при flush.
    final balance =
        _ref.read(authStateProvider).valueOrNull?.balanceBronze ?? 0;
    return ShopBuyResult(balanceBronze: balance, quantity: 1);
  }

  bool isQueued(String code) => state.any((e) => e.code == code);

  /// Синхронизация с сервером: валидные покупки применяются, ошибочные снимаются.
  Future<void> flush() async {
    if (_flushing) return;
    if (_ref.read(isOfflineProvider)) return;
    if (state.isEmpty) return;
    _flushing = true;
    try {
      final repo = _ref.read(shopRepositoryProvider);
      final remaining = <PendingPurchase>[];
      for (final item in List<PendingPurchase>.from(state)) {
        try {
          final result = await repo.buy(item.code);
          await _ref
              .read(authStateProvider.notifier)
              .applyBalance(result.balanceBronze);
        } on AuthException catch (e) {
          // Явная ошибка сервера — отменяем покупку.
          if (e.statusCode == 401 || e.statusCode >= 500) {
            remaining.add(item);
          }
        } catch (_) {
          // Сеть/таймаут — оставить в очереди.
          remaining.add(item);
        }
      }
      state = remaining;
      await _persist();
      _ref.invalidate(shopCatalogProvider);
      _ref.invalidate(inventoryListProvider);
    } finally {
      _flushing = false;
    }
  }
}
