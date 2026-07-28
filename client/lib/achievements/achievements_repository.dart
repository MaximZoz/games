import 'dart:convert';

import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';

class AchievementItem {
  const AchievementItem({
    required this.code,
    required this.title,
    required this.description,
    required this.rewardBronze,
    required this.progress,
    required this.target,
    required this.status,
    this.rewardItemCode,
  });

  final String code;
  final String title;
  final String description;
  final int rewardBronze;
  final String? rewardItemCode;
  final int progress;
  final int target;
  final String status; // locked | unlocked | claimed

  bool get isLocked => status == 'locked';
  bool get isUnlocked => status == 'unlocked';
  bool get isClaimed => status == 'claimed';
  bool get hasFrameReward =>
      rewardItemCode != null && rewardItemCode!.startsWith('frame_');

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rewardBronze: (json['reward_bronze'] as num?)?.toInt() ?? 0,
      rewardItemCode: json['reward_item_code'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'locked',
    );
  }
}

class AchievementClaimResult {
  const AchievementClaimResult({
    required this.balanceBronze,
    required this.rewardBronze,
    required this.code,
  });

  final int balanceBronze;
  final int rewardBronze;
  final String code;
}

class AchievementsRepository {
  AchievementsRepository(this._auth);

  final AuthRepository _auth;

  Future<List<AchievementItem>> list() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/achievements?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AchievementsRepository.list',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? 'Сессия истекла'
            : 'Не удалось загрузить достижения',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['achievements'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AchievementItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<int> unclaimedCount() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse(
            '$apiBaseUrl/api/achievements/unclaimed-count?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AchievementsRepository.unclaimedCount',
      ),
    );
    if (response.statusCode != 200) return 0;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<AchievementClaimResult> claim(String code) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/achievements/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
        operation: 'AchievementsRepository.claim',
      ),
    );
    if (response.statusCode == 409) {
      throw AuthException(409, 'Награда уже получена или ещё недоступна');
    }
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        'Не удалось забрать награду',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AchievementClaimResult(
      balanceBronze: (body['balance_bronze'] as num?)?.toInt() ?? 0,
      rewardBronze: (body['reward_bronze'] as num?)?.toInt() ?? 0,
      code: body['code'] as String? ?? code,
    );
  }
}
