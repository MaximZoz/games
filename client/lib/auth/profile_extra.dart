import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Расширенные данные профиля (возраст, пол, о себе, аватар). Хранятся локально по userId.
class ProfileExtra {
  const ProfileExtra({
    this.age,
    this.gender,
    this.about,
    this.avatarKind = AvatarKind.letter,
    this.avatarValue,
  });

  final int? age;
  final String? gender;
  final String? about;
  final AvatarKind avatarKind;
  /// Для [AvatarKind.preset] — индекс 0..N, для [AvatarKind.file] — путь к файлу.
  final String? avatarValue;

  ProfileExtra copyWith({
    int? age,
    String? gender,
    String? about,
    AvatarKind? avatarKind,
    String? avatarValue,
  }) {
    return ProfileExtra(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      about: about ?? this.about,
      avatarKind: avatarKind ?? this.avatarKind,
      avatarValue: avatarValue ?? this.avatarValue,
    );
  }

  static const String _keyPrefix = 'profile_extra_';

  static String _key(String userId) => '$_keyPrefix$userId';

  static Future<ProfileExtra?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key(userId));
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ProfileExtra(
        age: map['age'] as int?,
        gender: map['gender'] as String?,
        about: map['about'] as String?,
        avatarKind: AvatarKind.values.firstWhere(
          (e) => e.name == map['avatar_kind'],
          orElse: () => AvatarKind.letter,
        ),
        avatarValue: map['avatar_value'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String userId, ProfileExtra extra) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode({
      'age': extra.age,
      'gender': extra.gender,
      'about': extra.about,
      'avatar_kind': extra.avatarKind.name,
      'avatar_value': extra.avatarValue,
    }));
  }
}

enum AvatarKind {
  letter,
  preset,
  file,
}
