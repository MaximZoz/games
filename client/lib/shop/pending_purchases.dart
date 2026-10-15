import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/offline_disk_cache.dart';
import 'package:multigames_client/core/offline_mode_provider.dart';
import 'package:multigames_client/l10n/catalog_l10n.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyPendingPurchases = 'pending_shop_purchases';

class PendingPurchase {
  const PendingPurchase({
    required this.code,
    required this.queuedAtMs,
    this.title = '',
  });

  final String code;
  final String title;
  final int queuedAtMs;

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'queued_at_ms': queuedAtMs,
      };

  factory PendingPurchase.fromJson(Map<String, dynamic> json) {
    return PendingPurchase(
      code: (json['code'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      queuedAtMs: (json['queued_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Итог синхронизации одной отложенной покупки (для всплывашек).
class PendingPurchaseFlushItem {
  const PendingPurchaseFlushItem({
    required this.code,
    required this.title,
    this.reason,
  });

  final String code;
  final String title;
  final String? reason;
}

/// Пакет результатов flush — UI показывает тосты.
class PendingPurchaseFlushNotice {
  const PendingPurchaseFlushNotice({
    required this.applied,
    required this.failed,
  });

  final List<PendingPurchaseFlushItem> applied;
  final List<PendingPurchaseFlushItem> failed;

  bool get isEmpty => applied.isEmpty && failed.isEmpty;
}

final pendingPurchasesProvider =
    StateNotifierProvider<PendingPurchasesNotifier, List<PendingPurchase>>(
        (ref) {
  return PendingPurchasesNotifier(ref);
});

/// Последний результат применения очереди (null = нет события).
final pendingPurchaseFlushNoticeProvider =
    StateProvider<PendingPurchaseFlushNotice?>((ref) => null);

class PendingPurchasesNotifier extends StateNotifier<List<PendingPurchase>> {
  PendingPurchasesNotifier(this._ref) : super(const []) {
    _ready = _init();
    // flush() сам ждёт _ready. await flush() внутри _init зацикливает
    // инициализацию: кнопка «Купить» тогда навсегда остаётся на «…».
    unawaited(_ready.then((_) {
      if (!_ref.read(isOfflineProvider) && state.isNotEmpty) {
        unawaited(flush());
      }
    }));
  }

  final Ref _ref;
  bool _flushing = false;
  late final Future<void> _ready;

  Future<void> _init() async {
    await _load();
    _ref.listen<OfflineModeState>(offlineModeProvider, (prev, next) {
      final wasOffline = prev?.isOffline ?? true;
      if (wasOffline && !next.isOffline) {
        unawaited(flush());
      }
    });
  }

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
    if (!mounted) return;
    final payload = jsonEncode(state.map((e) => e.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await prefs.setString(_keyPendingPurchases, payload);
  }

  String _displayTitle(PendingPurchase item) {
    final l10n = LocaleService.l10n;
    return catalogTitle(
      item.code,
      fallback: item.title.isNotEmpty ? item.title : item.code,
      l10n: l10n,
    );
  }

  /// Очередь с диска не должна держать кнопку «Купить» на «…».
  Future<void> _awaitReady() async {
    try {
      await _ready.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Поставить покупку в очередь (офлайн) или купить сразу (онлайн).
  Future<ShopBuyResult> buyOrQueue(String code) async {
    await _awaitReady();
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

    final next = [
      ...state.where((e) => e.code != code),
      PendingPurchase(
        code: code,
        title: item?.title ?? code,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    state = next;
    await _persist();
    // Оптимистично обновляем дисковый кэш каталога (owned), чтобы после
    // перезапуска в офлайне предмет оставался «купленным».
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user != null && catalog != null) {
      final patched = [
        for (final e in catalog)
          if (e.code == code) e.copyWith(owned: true) else e,
      ];
      await OfflineDiskCache.saveShop(user.id, patched);
    }
    // Локальный «успех»: баланс не меняем — сервер применит при flush.
    final balance = user?.balanceBronze ?? 0;
    return ShopBuyResult(balanceBronze: balance, quantity: 1);
  }

  bool isQueued(String code) => state.any((e) => e.code == code);

  /// Синхронизация с сервером: валидные покупки применяются, ошибочные снимаются.
  Future<void> flush() async {
    await _awaitReady();
    if (!mounted || _flushing) return;
    if (_ref.read(isOfflineProvider)) return;
    if (state.isEmpty) return;
    _flushing = true;
    final applied = <PendingPurchaseFlushItem>[];
    final failed = <PendingPurchaseFlushItem>[];
    try {
      final repo = _ref.read(shopRepositoryProvider);
      final remaining = <PendingPurchase>[];
      for (final item in List<PendingPurchase>.from(state)) {
        final title = _displayTitle(item);
        try {
          final result = await repo.buy(item.code);
          await _ref
              .read(authStateProvider.notifier)
              .applyBalance(result.balanceBronze);
          applied.add(PendingPurchaseFlushItem(code: item.code, title: title));
        } on AuthException catch (e) {
          // Сессия / сервер — оставить в очереди, без тоста «отклонено».
          if (e.statusCode == 401 || e.statusCode >= 500) {
            remaining.add(item);
          } else {
            // Явная ошибка (недостаточно монет, уже куплено и т.п.) — снимаем.
            failed.add(PendingPurchaseFlushItem(
              code: item.code,
              title: title,
              reason: e.message,
            ));
          }
        } catch (_) {
          // Сеть/таймаут — оставить в очереди.
          remaining.add(item);
        }
      }
      if (!mounted) return;
      state = remaining;
      await _persist();
      if (!mounted) return;
      _ref.invalidate(shopCatalogProvider);
      _ref.invalidate(inventoryListProvider);
      if (applied.isNotEmpty || failed.isNotEmpty) {
        _ref.read(pendingPurchaseFlushNoticeProvider.notifier).state =
            PendingPurchaseFlushNotice(applied: applied, failed: failed);
      }
    } finally {
      _flushing = false;
    }
  }
}
