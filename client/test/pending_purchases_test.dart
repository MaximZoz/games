import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/pending_purchases.dart';

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
