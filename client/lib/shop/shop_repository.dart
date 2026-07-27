import 'dart:convert';

import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class ShopItem {
  const ShopItem({
    required this.code,
    required this.kind,
    required this.title,
    required this.description,
    required this.priceBronze,
    required this.owned,
    this.stockRemaining,
    this.payload = const {},
    this.sortOrder = 0,
  });

  final String code;
  final String kind; // emoji | stake_unlock | frame
  final String title;
  final String description;
  final int priceBronze;
  final bool owned;
  final int? stockRemaining;
  final Map<String, dynamic> payload;
  final int sortOrder;

  bool get isOutOfStock =>
      stockRemaining != null && stockRemaining! <= 0 && !owned;

  int? get stakeBronze => (payload['stake_bronze'] as num?)?.toInt();
  int? get stakeSilver => (payload['stake_silver'] as num?)?.toInt();
  String? get emoji => payload['emoji'] as String?;
  String? get frameColor => payload['color'] as String?;
  String? get animatedName => payload['animated_name'] as String?;
  String? get group => payload['group'] as String?;
  int get usesEach => (payload['uses_each'] as num?)?.toInt() ?? 10;
  List<String> get packEmojiCodes {
    final raw = payload['emojis'];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is String && e.isNotEmpty) e,
    ];
  }

  ShopItem copyWith({
    bool? owned,
  }) {
    return ShopItem(
      code: code,
      kind: kind,
      title: title,
      description: description,
      priceBronze: priceBronze,
      owned: owned ?? this.owned,
      stockRemaining: stockRemaining,
      payload: payload,
      sortOrder: sortOrder,
    );
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return ShopItem(
      code: json['code'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceBronze: (json['price_bronze'] as num?)?.toInt() ?? 0,
      owned: json['owned'] == true,
      stockRemaining: (json['stock_remaining'] as num?)?.toInt(),
      payload: rawPayload is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawPayload)
          : const {},
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.code,
    required this.kind,
    required this.title,
    required this.description,
    this.payload = const {},
    this.acquiredAt,
    this.quantity = 1,
  });

  final String code;
  final String kind;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final String? acquiredAt;
  final int quantity;

  String? get emoji => payload['emoji'] as String?;
  String? get frameColor => payload['color'] as String?;
  String? get animatedName => payload['animated_name'] as String?;
  String? get group => payload['group'] as String?;
  int? get stakeBronze => (payload['stake_bronze'] as num?)?.toInt();
  int? get stakeSilver => (payload['stake_silver'] as num?)?.toInt();

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return InventoryItem(
      code: json['code'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      payload: rawPayload is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawPayload)
          : const {},
      acquiredAt: json['acquired_at'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class InventoryCapabilities {
  const InventoryCapabilities({
    required this.allowedStakeBronze,
    this.frameColor,
  });

  final List<int> allowedStakeBronze;
  final String? frameColor;

  factory InventoryCapabilities.fromJson(Map<String, dynamic> json) {
    final raw = json['allowed_stake_bronze'];
    final stakes = <int>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is num) stakes.add(v.toInt());
      }
    }
    if (stakes.isEmpty) {
      stakes.addAll(const [1, 10, 50]);
    }
    return InventoryCapabilities(
      allowedStakeBronze: stakes,
      frameColor: json['frame_color'] as String?,
    );
  }
}

class ShopBuyResult {
  const ShopBuyResult({
    required this.balanceBronze,
    this.quantity = 1,
  });

  final int balanceBronze;
  final int quantity;
}

class ShopRepository {
  ShopRepository(this._auth);

  final AuthRepository _auth;

  Future<List<ShopItem>> listShop() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/shop?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ShopRepository.listShop',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : 'Не удалось загрузить магазин',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ShopItem.fromJson)
        .toList();
  }

  Future<ShopBuyResult> buy(String code) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/shop/buy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
        operation: 'ShopRepository.buy',
      ),
    );
    if (response.statusCode == 402) {
      throw AuthException(402, 'Недостаточно монет');
    }
    if (response.statusCode == 409) {
      throw AuthException(409, 'Уже куплено или нет в наличии');
    }
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401 ? 'Сессия истекла' : 'Не удалось купить',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ShopBuyResult(
      balanceBronze: (body['balance_bronze'] as num?)?.toInt() ?? 0,
      quantity: (body['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Future<int> consumeEmoji(String code) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/inventory/consume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
        operation: 'ShopRepository.consumeEmoji',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : response.statusCode == 409
                ? 'Смайлик недоступен'
                : 'Не удалось использовать смайлик',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['quantity'] as num?)?.toInt() ?? 0;
  }

  Future<List<InventoryItem>> listInventory() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/inventory?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ShopRepository.listInventory',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : 'Не удалось загрузить предметы',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InventoryItem.fromJson)
        .toList();
  }

  Future<InventoryCapabilities> capabilities() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/inventory/capabilities?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ShopRepository.capabilities',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : 'Не удалось загрузить возможности',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return InventoryCapabilities.fromJson(body);
  }
}
