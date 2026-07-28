import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKeyPrefix = 'unread_gifted_collections_';

/// Коды коллекций, подаренных текущему пользователю и ещё не просмотренных
/// на экране «Предметы».
class UnreadGiftedCollections extends StateNotifier<Set<String>> {
  UnreadGiftedCollections(this._ref) : super(const {}) {
    _load();
    _ref.listen(authStateProvider, (prev, next) {
      final prevId = prev?.valueOrNull?.id;
      final nextId = next.valueOrNull?.id;
      if (prevId != nextId) {
        state = const {};
        _load();
      }
    });
  }

  final Ref _ref;

  String? get _userId => _ref.read(authStateProvider).valueOrNull?.id;

  String? get _prefsKey {
    final id = _userId;
    if (id == null || id.isEmpty) return null;
    return '$_prefsKeyPrefix$id';
  }

  Future<void> _load() async {
    final key = _prefsKey;
    if (key == null) {
      state = const {};
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        state = const {};
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        state = const {};
        return;
      }
      state = decoded.whereType<String>().where((e) => e.isNotEmpty).toSet();
    } catch (_) {
      state = const {};
    }
  }

  Future<void> _persist() async {
    final key = _prefsKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(state.toList()));
    } catch (_) {}
  }

  Future<void> addCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) return;
    if (state.contains(c)) return;
    state = {...state, c};
    await _persist();
  }

  Future<void> clear() async {
    if (state.isEmpty) return;
    state = const {};
    await _persist();
  }
}

final unreadGiftedCollectionsProvider =
    StateNotifierProvider<UnreadGiftedCollections, Set<String>>((ref) {
  return UnreadGiftedCollections(ref);
});

final unreadGiftedCollectionsCountProvider = Provider<int>((ref) {
  return ref.watch(unreadGiftedCollectionsProvider).length;
});

final unreadGiftedCollectionsAvailableProvider = Provider<bool>((ref) {
  return ref.watch(unreadGiftedCollectionsCountProvider) > 0;
});
