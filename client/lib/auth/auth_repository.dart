import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyAccessToken = 'access_token';
const _keyRefreshToken = 'refresh_token';
const _keyUser = 'user';

class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;
  final int? age;
  final String? gender;
  final String? about;
  final String avatarKind;
  final String? avatarValue;
  final int balanceBronze;

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.isAdmin = false,
    this.age,
    this.gender,
    this.about,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.balanceBronze = 0,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      about: json['about'] as String?,
      avatarKind: json['avatar_kind'] as String? ?? 'letter',
      avatarValue: json['avatar_value'] as String?,
      balanceBronze: (json['balance_bronze'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'is_admin': isAdmin,
        'age': age,
        'gender': gender,
        'about': about,
        'avatar_kind': avatarKind,
        'avatar_value': avatarValue,
        'balance_bronze': balanceBronze,
      };
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
}

class DailyRewardStatus {
  const DailyRewardStatus({
    required this.available,
    required this.streak,
    required this.nextStreak,
    required this.nextRewardBronze,
    this.milestonesBronze = const {
      1: 10,
      3: 50,
      7: 1000,
      30: 3000,
    },
  });

  final bool available;
  final int streak;
  final int nextStreak;
  final int nextRewardBronze;
  final Map<int, int> milestonesBronze;

  static const empty = DailyRewardStatus(
    available: false,
    streak: 0,
    nextStreak: 1,
    nextRewardBronze: 10,
  );

  factory DailyRewardStatus.fromJson(Map<String, dynamic> json) {
    final milestonesRaw = json['milestones_bronze'];
    final milestones = <int, int>{
      1: 10,
      3: 50,
      7: 1000,
      30: 3000,
    };
    if (milestonesRaw is Map) {
      milestonesRaw.forEach((key, value) {
        final day = int.tryParse(key.toString());
        final bronze = value is num ? value.toInt() : null;
        if (day != null && bronze != null) {
          milestones[day] = bronze;
        }
      });
    }
    return DailyRewardStatus(
      available: (json['available'] as bool?) ?? false,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      nextStreak: (json['next_streak'] as num?)?.toInt() ?? 1,
      nextRewardBronze: (json['next_reward_bronze'] as num?)?.toInt() ?? 10,
      milestonesBronze: milestones,
    );
  }
}

class DailyRewardClaimResult {
  const DailyRewardClaimResult({
    required this.balanceBronze,
    required this.rewardBronze,
    required this.streak,
  });

  final int balanceBronze;
  final int rewardBronze;
  final int streak;
}

class AuthRepository {
  AuthRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  bool _prefsUnavailable = false;
  String? _memoryAccessToken;
  String? _memoryRefreshToken;
  AuthUser? _memoryUser;
  Future<String?>? _refreshInFlight;

  SharedPreferences get prefs {
    final p = _prefs;
    if (p == null) {
      throw StateError('SharedPreferences is not available');
    }
    return p;
  }

  Future<void> init() async {
    if (_prefs != null || _prefsUnavailable) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefsUnavailable = true;
      _prefs = null;
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    String displayName = '',
    String? ref,
  }) async {
    await init();
    final uri = Uri.parse('$apiBaseUrl/api/auth/register');
    final referral = (ref ?? '').trim();
    final response = await ApiClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        if (displayName.isNotEmpty) 'display_name': displayName,
        if (referral.isNotEmpty) 'ref': referral,
      }),
      operation: 'AuthRepository.register',
    );
    return _handleAuthResponse(response);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await init();
    final uri = Uri.parse('$apiBaseUrl/api/auth/login');
    final response = await ApiClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
      operation: 'AuthRepository.login',
    );
    return _handleAuthResponse(response);
  }

  static String _translateMessage(String msg) {
    final m = msg.toLowerCase().trim();
    const Map<String, String> map = {
      'invalid email or password': 'Неверный email или пароль',
      'email already registered': 'Такой email уже зарегистрирован',
      'invalid or expired token': 'Сессия истекла. Войдите заново.',
      'invalid token': 'Сессия истекла. Войдите заново.',
      'missing authorization header': 'Требуется авторизация',
      'invalid authorization header': 'Неверный формат авторизации',
      'user not found': 'Пользователь не найден',
      'email required, password at least 6 characters': 'Укажите email, пароль — минимум 6 символов',
      'email or login and password required': 'Укажите email и пароль',
      'refresh_token required': 'Сессия истекла. Войдите заново.',
      'server error': 'Ошибка сервера. Попробуйте позже.',
    };
    return map[m] ?? msg;
  }

  Future<AuthResult> _handleAuthResponse(http.Response response) async {
    if (response.statusCode != 200) {
      String msg = response.body;
      try {
        final body = jsonDecode(response.body);
        if (body is Map) msg = (body['message'] ?? body['error'] ?? msg).toString();
      } catch (_) {}
      throw AuthException(response.statusCode, _translateMessage(msg));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['access_token'] as String;
    final refreshToken = body['refresh_token'] as String? ?? '';
    final expiresIn = body['expires_in'] as int? ?? 900;
    final user = AuthUser.fromJson(Map<String, dynamic>.from(body['user'] as Map));

    _memoryAccessToken = accessToken;
    _memoryRefreshToken = refreshToken;
    _memoryUser = user;

    await _safePersistSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );

    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      user: user,
    );
  }

  Future<String?> getAccessToken() async {
    String? token = _memoryAccessToken;
    if (token == null || token.isEmpty) {
      await init();
      if (_prefs != null) {
        try {
          token = _prefs!.getString(_keyAccessToken);
        } catch (_) {
          token = null;
        }
      }
      if (token != null && token.isNotEmpty) {
        _memoryAccessToken = token;
      }
    }

    if (token == null || token.isEmpty) {
      return _refreshAccessToken();
    }

    if (_isJwtExpired(token)) {
      return _refreshAccessToken();
    }

    return token;
  }

  /// Загружает текущего пользователя с сервера (GET /api/me) и обновляет локальное хранилище.
  Future<AuthUser?> fetchCurrentUser() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return null;

    final response = await ApiClient.get(
      Uri.parse('$apiBaseUrl/api/me'),
      headers: {'Authorization': 'Bearer $token'},
      operation: 'AuthRepository.fetchCurrentUser',
    );
    if (response.statusCode != 200) return null;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(Map<String, dynamic>.from(body));
      _memoryUser = user;
      await _persistUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistUser(AuthUser user) async {
    await init();
    if (_prefs == null) return;
    try {
      await _prefs!.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<AuthUser?> getStoredUser() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return null;

    if (_memoryUser != null) return _memoryUser;

    await init();
    if (_prefs == null) return null;

    String? jsonStr;
    try {
      jsonStr = _prefs!.getString(_keyUser);
    } catch (_) {
      jsonStr = null;
    }
    if (jsonStr == null) return null;
    try {
      final user = AuthUser.fromJson(Map<String, dynamic>.from(jsonDecode(jsonStr) as Map));
      _memoryUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    _memoryUser = null;
    _refreshInFlight = null;

    await init();
    if (_prefs == null) return;
    try {
      await _prefs!.remove(_keyAccessToken);
      await _prefs!.remove(_keyRefreshToken);
      await _prefs!.remove(_keyUser);
    } catch (_) {}
  }

  /// GET /api/coins/daily-available → статус серии и награды
  Future<DailyRewardStatus> getDailyRewardStatus() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await sendAuthorized(
      (token) => ApiClient.get(
        Uri.parse('$apiBaseUrl/api/coins/daily-available?_=$cacheBuster'),
        headers: {'Authorization': 'Bearer $token'},
        operation: 'AuthRepository.getDailyRewardStatus',
      ),
    );
    if (response.statusCode != 200) {
      throw AuthException(
        response.statusCode,
        response.statusCode == 401 ? 'Сессия истекла' : 'Ошибка: ${response.statusCode}',
      );
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return DailyRewardStatus.fromJson(body);
    } catch (_) {
      return const DailyRewardStatus(
        available: false,
        streak: 0,
        nextStreak: 1,
        nextRewardBronze: 10,
      );
    }
  }

  /// Совместимость: только флаг available.
  Future<bool> getDailyRewardAvailable() async {
    final status = await getDailyRewardStatus();
    return status.available;
  }

  /// POST /api/coins/claim-daily → баланс / награда / серия
  Future<DailyRewardClaimResult?> claimDailyReward() async {
    final response = await sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/coins/claim-daily'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{}',
        operation: 'AuthRepository.claimDailyReward',
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 409) return null;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final balance = body['balance_bronze'];
      if (balance is! num) return null;
      return DailyRewardClaimResult(
        balanceBronze: balance.toInt(),
        rewardBronze: (body['reward_bronze'] as num?)?.toInt() ?? 0,
        streak: (body['streak'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> sendAuthorized(
    Future<http.Response> Function(String accessToken) request,
  ) async {
    var token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw AuthException(401, 'Сессия истекла. Войдите заново.');
    }

    var response = await request(token);
    if (response.statusCode != 401) return response;

    token = await _refreshAccessToken();
    if (token == null || token.isEmpty) {
      throw AuthException(401, 'Сессия истекла. Войдите заново.');
    }

    response = await request(token);
    if (response.statusCode == 401) {
      await logout();
      throw AuthException(401, 'Сессия истекла. Войдите заново.');
    }

    return response;
  }

  /// Обновляет профиль пользователя на бэкенде и сохраняет результат локально.
  Future<AuthUser> updateProfile({
    required String? displayName,
    int? age,
    String? gender,
    String? about,
    String? avatarKind,
    String? avatarValue,
  }) async {
    await init();
    final current = await getStoredUser();
    if (current == null) throw AuthException(401, 'Не авторизован');

    final name = displayName?.trim().isEmpty == true ? null : displayName?.trim();

    final uri = Uri.parse('$apiBaseUrl/api/profile');
    final response = await sendAuthorized(
      (token) => ApiClient.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'display_name': name,
          'age': age,
          'gender': gender,
          'about': about,
          'avatar_kind': avatarKind,
          'avatar_value': avatarValue,
        }),
        operation: 'AuthRepository.updateProfile',
      ),
    );

    if (response.statusCode != 200) {
      String msg = response.body;
      try {
        final body = jsonDecode(response.body);
        if (body is Map) msg = (body['message'] ?? body['error'] ?? msg).toString();
      } catch (_) {}
      throw AuthException(response.statusCode, _translateMessage(msg));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final user = body['user'] != null
        ? AuthUser.fromJson(Map<String, dynamic>.from(body['user'] as Map))
        : AuthUser(
            id: current.id,
            email: current.email,
            displayName: name,
            isAdmin: current.isAdmin,
            age: age,
            gender: gender,
            about: about,
            avatarKind: avatarKind ?? 'letter',
            avatarValue: avatarValue,
          );
    await _saveUser(user);
    return user;
  }

  /// Обновляет сохранённого пользователя (например, после claim монет).
  Future<void> updateStoredUser(AuthUser user) async {
    await _saveUser(user);
  }

  Future<void> _saveUser(AuthUser user) async {
    _memoryUser = user;
    await init();
    if (_prefs == null) return;
    try {
      await _prefs!.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _safePersistSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await init();
    if (_prefs == null) return;
    try {
      await _prefs!.setString(_keyAccessToken, accessToken);
      await _prefs!.setString(_keyRefreshToken, refreshToken);
      await _prefs!.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (_) {
      // На Web в private mode может быть QuotaExceededError.
      // Сессию оставляем в памяти, чтобы вход работал в текущей вкладке.
    }
  }

  Future<String?> _refreshAccessToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshAccessTokenImpl();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<String?> _refreshAccessTokenImpl() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return null;
    }

    final response = await ApiClient.post(
      Uri.parse('$apiBaseUrl/api/auth/refresh'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
      operation: 'AuthRepository.refresh',
    );
    if (response.statusCode != 200) {
      await logout();
      return null;
    }

    try {
      final result = await _handleAuthResponse(response);
      return result.accessToken;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<String?> _getRefreshToken() async {
    if (_memoryRefreshToken != null && _memoryRefreshToken!.isNotEmpty) {
      return _memoryRefreshToken;
    }

    await init();
    if (_prefs != null) {
      try {
        final stored = _prefs!.getString(_keyRefreshToken);
        if (stored != null && stored.isNotEmpty) {
          _memoryRefreshToken = stored;
          return stored;
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final body = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = body['exp'];
      if (exp is! num) return false;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= exp.toInt();
    } catch (_) {
      return false;
    }
  }
}

class AuthException implements Exception {
  final int statusCode;
  final String message;
  AuthException(this.statusCode, this.message);
  @override
  String toString() => message;
}
