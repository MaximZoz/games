import 'package:flutter/services.dart';

const int kProfileAgeMin = 1;
const int kProfileAgeMax = 111;

/// Пусто — ок (возраст необязателен). Иначе только 1–111.
bool profileAgeIsInvalid(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return false;
  final age = int.tryParse(text);
  if (age == null) return true;
  return age < kProfileAgeMin || age > kProfileAgeMax;
}

/// Не даёт ввести число больше 111 (например 125).
class ProfileAgeRangeFormatter extends TextInputFormatter {
  const ProfileAgeRangeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d{1,3}$').hasMatch(text)) return oldValue;
    final age = int.tryParse(text);
    if (age == null || age > kProfileAgeMax) return oldValue;
    return newValue;
  }
}
