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

class AuthRepository {
  AuthRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  bool _prefsUnavailable = false;
  String? _memoryAccessToken;
  AuthUser? _memoryUser;

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
  }) async {
    await init();
    final uri = Uri.parse('$apiBaseUrl/api/auth/register');
    final response = await ApiClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        if (displayName.isNotEmpty) 'display_name': displayName,
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

  Future<AuthResult> _handleAuthResponse(http.Response response) async {
    if (response.statusCode != 200) {
      String msg = response.body;
      try {
        final body = jsonDecode(response.body);
        if (body is Map) msg = (body['message'] ?? body['error'] ?? msg).toString();
      } catch (_) {}
      throw AuthException(response.statusCode, msg);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['access_token'] as String;
    final refreshToken = body['refresh_token'] as String? ?? '';
    final expiresIn = body['expires_in'] as int? ?? 900;
    final user = AuthUser.fromJson(Map<String, dynamic>.from(body['user'] as Map));

    _memoryAccessToken = accessToken;
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
    if (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) {
      if (_isJwtExpired(_memoryAccessToken!)) {
        await logout();
        return null;
      }
      return _memoryAccessToken;
    }

    await init();
    String? token;
    if (_prefs != null) {
      try {
        token = _prefs!.getString(_keyAccessToken);
      } catch (_) {
        token = null;
      }
    }

    if (token != null && token.isNotEmpty) {
      if (_isJwtExpired(token)) {
        await logout();
        return null;
      }
      _memoryAccessToken = token;
    }
    return token;
  }

  Future<AuthUser?> getStoredUser() async {
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
    _memoryUser = null;

    await init();
    if (_prefs == null) return;
    try {
      await _prefs!.remove(_keyAccessToken);
      await _prefs!.remove(_keyRefreshToken);
      await _prefs!.remove(_keyUser);
    } catch (_) {}
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
    final token = await getAccessToken();
    if (token == null) throw AuthException(401, 'Не авторизован');

    final name = displayName?.trim().isEmpty == true ? null : displayName?.trim();

    final uri = Uri.parse('$apiBaseUrl/api/profile');
    final response = await ApiClient.put(
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
    );

    if (response.statusCode != 200) {
      String msg = response.body;
      try {
        final body = jsonDecode(response.body);
        if (body is Map) msg = (body['message'] ?? body['error'] ?? msg).toString();
      } catch (_) {}
      throw AuthException(response.statusCode, msg);
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
