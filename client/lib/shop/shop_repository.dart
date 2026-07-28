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

  int? get stakeBronze => _payloadInt('stake_bronze');
  int? get stakeSilver {
    final explicit = _payloadInt('stake_silver');
    if (explicit != null) return explicit;
    final b = stakeBronze;
    if (b != null && b >= 100 && b < 10000 && b % 100 == 0) {
      return b ~/ 100;
    }
    return null;
  }

  int? get stakeGold {
    final explicit = _payloadInt('stake_gold');
    if (explicit != null) return explicit;
    final b = stakeBronze;
    if (b != null && b >= 10000 && b % 10000 == 0) {
      return b ~/ 10000;
    }
    return null;
  }

  int? _payloadInt(String key) {
    final v = payload[key];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  String? get emoji => payload['emoji'] as String?;
  String? get frameColor => payload['color'] as String?;
  String? get animatedName => payload['animated_name'] as String?;
  String? get group => payload['group'] as String?;
  String? get collectionSet => payload['set'] as String?;
  int get dailyBronze =>
      (payload['daily_bronze'] as num?)?.toInt() ??
      (payload['weekly_bronze'] as num?)?.toInt() ??
      0;
  @Deprecated('Use dailyBronze')
  int get weeklyBronze => dailyBronze;
  int get sellRefundBronze => (priceBronze * 80) ~/ 100;

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
    final Map<String, dynamic> payload;
    if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    } else {
      payload = const {};
    }
    return ShopItem(
      code: json['code'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceBronze: (json['price_bronze'] as num?)?.toInt() ?? 0,
      owned: json['owned'] == true,
      stockRemaining: (json['stock_remaining'] as num?)?.toInt(),
      payload: payload,
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
  String? get collectionSet => payload['set'] as String?;
  int get dailyBronze =>
      (payload['daily_bronze'] as num?)?.toInt() ??
      (payload['weekly_bronze'] as num?)?.toInt() ??
      0;
  @Deprecated('Use dailyBronze')
  int get weeklyBronze => dailyBronze;
  int? get stakeBronze => _payloadInt('stake_bronze');
  int? get stakeSilver {
    final explicit = _payloadInt('stake_silver');
    if (explicit != null) return explicit;
    final b = stakeBronze;
    if (b != null && b >= 100 && b < 10000 && b % 100 == 0) {
      return b ~/ 100;
    }
    return null;
  }

  int? get stakeGold {
    final explicit = _payloadInt('stake_gold');
    if (explicit != null) return explicit;
    final b = stakeBronze;
    if (b != null && b >= 10000 && b % 10000 == 0) {
      return b ~/ 10000;
    }
    return null;
  }

  int? _payloadInt(String key) {
    final v = payload[key];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

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

  Future<List<InventoryItem>> listCollectionsShowcase(String userId) async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse(
          '$apiBaseUrl/api/inventory/collections?user_id=$userId&_=$cacheBuster',
        ),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ShopRepository.listCollectionsShowcase',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : 'Не удалось загрузить коллекции',
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

  Future<ShopBuyResult> sellCollection(String code) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/inventory/sell'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
        operation: 'ShopRepository.sellCollection',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401 ? 'Сессия истекла' : 'Не удалось продать',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ShopBuyResult(
      balanceBronze: (body['balance_bronze'] as num?)?.toInt() ?? 0,
      quantity: (body['refund_bronze'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> giftCollection(String code, String toUserId) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/inventory/gift'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code, 'to_user_id': toUserId}),
        operation: 'ShopRepository.giftCollection',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : response.statusCode == 409
                ? 'Нельзя подарить (уже есть у друга или предмет недоступен)'
                : 'Не удалось подарить',
      );
    }
  }

  Future<CollectionIncomeInfo> collectionIncome() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/inventory/collection-income?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ShopRepository.collectionIncome',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : 'Не удалось загрузить доход',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return CollectionIncomeInfo.fromJson(body);
  }

  Future<ShopBuyResult> claimCollectionIncome() async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/inventory/claim-collection-income'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{}',
        operation: 'ShopRepository.claimCollectionIncome',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : response.statusCode == 409
                ? 'Доход пока недоступен'
                : 'Не удалось забрать доход',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ShopBuyResult(
      balanceBronze: (body['balance_bronze'] as num?)?.toInt() ?? 0,
      quantity: (body['amount_bronze'] as num?)?.toInt() ?? 0,
    );
  }
}

class CollectionIncomeInfo {
  const CollectionIncomeInfo({
    required this.available,
    required this.amountBronze,
    required this.ownedCount,
    this.itemsBronze = 0,
    this.setBonusBronze = 0,
    this.completedSets = 0,
    this.nextClaimAt,
  });

  final bool available;
  final int amountBronze;
  final int ownedCount;
  final int itemsBronze;
  final int setBonusBronze;
  final int completedSets;
  final String? nextClaimAt;

  factory CollectionIncomeInfo.fromJson(Map<String, dynamic> json) {
    return CollectionIncomeInfo(
      available: json['available'] == true,
      amountBronze: (json['amount_bronze'] as num?)?.toInt() ?? 0,
      ownedCount: (json['owned_count'] as num?)?.toInt() ?? 0,
      itemsBronze: (json['items_bronze'] as num?)?.toInt() ?? 0,
      setBonusBronze: (json['set_bonus_bronze'] as num?)?.toInt() ?? 0,
      completedSets: (json['completed_sets'] as num?)?.toInt() ?? 0,
      nextClaimAt: json['next_claim_at'] as String?,
    );
  }
}
