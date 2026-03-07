import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyAddBotsAfter30s = 'add_bots_after_30s';

/// Настройка: если включена, в режиме «поиск игры» ждём 30 секунд,
/// и если соперник не найден — добавляем бота и начинаем игру.
final addBotsAfter30sProvider =
    StateNotifierProvider<AddBotsAfter30sNotifier, bool>((ref) {
  return AddBotsAfter30sNotifier();
});

class AddBotsAfter30sNotifier extends StateNotifier<bool> {
  AddBotsAfter30sNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyAddBotsAfter30s) ?? false;
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAddBotsAfter30s, value);
    state = value;
  }
}
