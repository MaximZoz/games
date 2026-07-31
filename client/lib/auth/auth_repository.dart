import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';
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
  final bool emailVerified;

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
    this.emailVerified = true,
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
      emailVerified: json['email_verified'] as bool? ?? true,
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
        'email_verified': emailVerified,
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
    _throwIfVerificationRequired(response);
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
    _throwIfVerificationRequired(response);
    return _handleAuthResponse(response);
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    await init();
    final response = await ApiClient.post(
      Uri.parse('$apiBaseUrl/api/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
      operation: 'AuthRepository.verifyEmail',
    );
    return _handleAuthResponse(response);
  }

  Future<void> resendVerification({required String email}) async {
    await init();
    final response = await ApiClient.post(
      Uri.parse('$apiBaseUrl/api/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
      operation: 'AuthRepository.resendVerification',
    );
    if (response.statusCode != 200) {
      throw AuthException(response.statusCode, _messageFromResponse(response));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    await init();
    final response = await ApiClient.post(
      Uri.parse('$apiBaseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
      operation: 'AuthRepository.forgotPassword',
    );
    if (response.statusCode != 200) {
      throw AuthException(response.statusCode, _messageFromResponse(response));
    }
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await init();
    final response = await ApiClient.post(
      Uri.parse('$apiBaseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'new_password': newPassword,
      }),
      operation: 'AuthRepository.resetPassword',
    );
    return _handleAuthResponse(response);
  }

  Future<AuthResult> applySessionTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await init();
    _memoryAccessToken = accessToken;
    _memoryRefreshToken = refreshToken;
    final user = await fetchCurrentUser();
    if (user == null) {
      await logout();
      throw AuthException(401, LocaleService.l10n.sessionExpired);
    }
    await _safePersistSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: 900,
      user: user,
    );
  }

  Future<List<String>> fetchOAuthProviders() async {
    final info = await fetchOAuthProvidersInfo();
    return info.providers;
  }

  Future<({List<String> providers, String? googleClientId})>
      fetchOAuthProvidersInfo() async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$apiBaseUrl/api/auth/oauth/providers'),
        operation: 'AuthRepository.fetchOAuthProvidersInfo',
      );
      if (response.statusCode != 200) {
        return (providers: const <String>[], googleClientId: null);
      }
      final body = jsonDecode(response.body);
      if (body is! Map) {
        return (providers: const <String>[], googleClientId: null);
      }
      final raw = body['providers'];
      final providers = raw is List
          ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const <String>[];
      final gid = (body['google_client_id'] ?? '').toString().trim();
      return (
        providers: providers,
        googleClientId: gid.isEmpty ? null : gid,
      );
    } catch (_) {
      return (providers: const <String>[], googleClientId: null);
    }
  }

  /// Вход через Google Identity Services (JWT credential), без redirect.
  Future<AuthResult> loginWithGoogleIdToken({
    required String credential,
    String? redirect,
    String? ref,
  }) async {
    await init();
    final payload = <String, dynamic>{
      'credential': credential,
    };
    final r = (redirect ?? '').trim();
    if (r.isNotEmpty) payload['redirect'] = r;
    final referral = (ref ?? '').trim();
    if (referral.isNotEmpty) payload['ref'] = referral;

    final response = await ApiClient.post(
      Uri.parse('$apiBaseUrl/api/auth/oauth/google/id-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
      operation: 'AuthRepository.loginWithGoogleIdToken',
    );
    return _handleAuthResponse(response);
  }

  String oauthStartUrl({
    required String provider,
    String? redirect,
    String? ref,
    bool poll = false,
    bool navigate = false,
  }) {
    final params = <String, String>{};
    if (poll) params['mode'] = 'poll';
    if (navigate) params['navigate'] = '1';
    final r = (redirect ?? '').trim();
    if (r.isNotEmpty) params['redirect'] = r;
    final referral = (ref ?? '').trim();
    if (referral.isNotEmpty) params['ref'] = referral;
    return Uri.parse('$apiBaseUrl/api/auth/oauth/$provider/start')
        .replace(queryParameters: params.isEmpty ? null : params)
        .toString();
  }

  /// Старт OAuth для PWA: JSON с authorize_url + state, дальше poll.
  Future<({String authorizeUrl, String state})> startOAuthPoll({
    required String provider,
    String? redirect,
    String? ref,
  }) async {
    await init();
    final params = <String, String>{'mode': 'poll'};
    final r = (redirect ?? '').trim();
    if (r.isNotEmpty) params['redirect'] = r;
    final referral = (ref ?? '').trim();
    if (referral.isNotEmpty) params['ref'] = referral;
    final response = await ApiClient.get(
      Uri.parse('$apiBaseUrl/api/auth/oauth/$provider/start')
          .replace(queryParameters: params),
      operation: 'AuthRepository.startOAuthPoll',
    );
    if (response.statusCode != 200) {
      throw AuthException(response.statusCode, _messageFromResponse(response));
    }
    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw AuthException(500, LocaleService.l10n.oauthError);
    }
    final url = (body['authorize_url'] ?? '').toString();
    final state = (body['state'] ?? '').toString();
    if (url.isEmpty || state.isEmpty) {
      throw AuthException(500, LocaleService.l10n.oauthError);
    }
    return (authorizeUrl: url, state: state);
  }

  /// Ждёт результат OAuth (после входа в popup/Safari).
  /// На iOS PWA JS может засыпать в фоне — при возврате опрашиваем сразу.
  Future<Map<String, String>> pollOAuthResult({
    String state = '',
    Duration timeout = const Duration(minutes: 5),
  }) async {
    await init();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final params = <String, String>{};
      final s = state.trim();
      if (s.isNotEmpty) params['state'] = s;
      final response = await ApiClient.get(
        Uri.parse('$apiBaseUrl/api/auth/oauth/poll').replace(
          queryParameters: params.isEmpty ? null : params,
        ),
        operation: 'AuthRepository.pollOAuthResult',
      );
      if (response.statusCode == 202) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        continue;
      }
      if (response.statusCode != 200) {
        throw AuthException(response.statusCode, _messageFromResponse(response));
      }
      final body = jsonDecode(response.body);
      if (body is! Map) {
        throw AuthException(500, LocaleService.l10n.oauthError);
      }
      final status = (body['status'] ?? '').toString();
      if (status == 'pending') {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        continue;
      }
      if (status == 'error') {
        final err = (body['error'] ?? LocaleService.l10n.oauthError).toString();
        throw AuthException(400, err);
      }
      return {
        'access_token': (body['access_token'] ?? '').toString(),
        'refresh_token': (body['refresh_token'] ?? '').toString(),
        'redirect': (body['redirect'] ?? '').toString(),
      };
    }
    throw AuthException(408, LocaleService.l10n.oauthError);
  }

  void _throwIfVerificationRequired(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 403) return;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['requires_verification'] == true) {
        final email = (body['email'] ?? '').toString();
        final message = (body['message'] ?? body['error'] ?? '').toString();
        throw EmailVerificationRequiredException(
          email: email,
          message: message.isEmpty ? 'email not verified' : message,
        );
      }
    } catch (e) {
      if (e is EmailVerificationRequiredException) rethrow;
    }
  }

  static String _messageFromResponse(http.Response response) {
    var msg = response.body.trim();
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        msg = (body['message'] ?? body['error'] ?? msg).toString().trim();
      }
    } catch (_) {}
    if (msg.isEmpty) return LocaleService.l10n.commonServerErrorShort;
    return msg;
  }

  Future<AuthResult> _handleAuthResponse(http.Response response) async {
    if (response.statusCode != 200) {
      throw AuthException(response.statusCode, _messageFromResponse(response));
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
      final l10n = LocaleService.l10n;
      throw AuthException(
        response.statusCode,
        response.statusCode == 401
            ? l10n.sessionExpired
            : _messageFromResponse(response),
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
      throw AuthException(401, LocaleService.l10n.sessionExpired);
    }

    var response = await request(token);
    if (response.statusCode != 401) return response;

    token = await _refreshAccessToken();
    if (token == null || token.isEmpty) {
      throw AuthException(401, LocaleService.l10n.sessionExpired);
    }

    response = await request(token);
    if (response.statusCode == 401) {
      await logout();
      throw AuthException(401, LocaleService.l10n.sessionExpired);
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
    if (current == null) {
      throw AuthException(401, LocaleService.l10n.sessionExpired);
    }

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
      throw AuthException(response.statusCode, _messageFromResponse(response));
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
            emailVerified: current.emailVerified,
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

class EmailVerificationRequiredException implements Exception {
  final String email;
  final String message;
  EmailVerificationRequiredException({
    required this.email,
    this.message = '',
  });
  @override
  String toString() => message.isEmpty ? 'email not verified' : message;
}
