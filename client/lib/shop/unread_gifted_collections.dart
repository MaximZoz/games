import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/realtime_events_provider.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKeyPrefix = 'unread_gifted_collections_';

/// Коды коллекций, подаренных текущему пользователю и ещё не просмотренных
/// на экране «Предметы».
class UnreadGiftedCollections extends StateNotifier<Set<String>> {
  UnreadGiftedCollections(this._ref) : super(const {}) {
    _loadFuture = _load();
    _ref.listen(authStateProvider, (prev, next) {
      final prevId = prev?.valueOrNull?.id;
      final nextId = next.valueOrNull?.id;
      if (prevId != nextId) {
        state = const {};
        _loadFuture = _load();
      }
    });
  }

  final Ref _ref;
  Future<void> _loadFuture = Future.value();

  String? get _userId => _ref.read(authStateProvider).valueOrNull?.id;

  String? get _prefsKey {
    final id = _userId;
    if (id == null || id.isEmpty) return null;
    return '$_prefsKeyPrefix$id';
  }

  Future<void> _awaitLoad() => _loadFuture;

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
    await _awaitLoad();
    if (state.contains(c)) return;
    state = {...state, c};
    await _persist();
  }

  Future<void> addCodes(Iterable<String> codes) async {
    final next = codes.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (next.isEmpty) return;
    await _awaitLoad();
    final merged = {...state, ...next};
    if (merged.length == state.length) return;
    state = merged;
    await _persist();
  }

  Future<void> clear() async {
    await _awaitLoad();
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

/// Подарок из тела сообщения чата → код коллекции (или null).
String? giftCollectionCodeFromBody(String? body) {
  final gift = parseGiftCollectionMessage(body ?? '');
  final code = gift?.code.trim() ?? '';
  return code.isEmpty ? null : code;
}

/// Собирает коды подарков из непрочитанных чатов (last_message).
Set<String> giftCodesFromUnreadChats({
  required List<ChatPreviewItem> chats,
  required String myUserId,
}) {
  final me = myUserId.trim();
  if (me.isEmpty) return const {};
  final out = <String>{};
  for (final chat in chats) {
    if (chat.unreadCount <= 0) continue;
    final msg = chat.lastMessage;
    if (msg == null) continue;
    if (msg.senderUserID == me) continue;
    final code = giftCollectionCodeFromBody(msg.body);
    if (code != null) out.add(code);
  }
  return out;
}

void _noteGiftCodes(Ref ref, Iterable<String> codes) {
  final list = codes.where((e) => e.trim().isNotEmpty).toList(growable: false);
  if (list.isEmpty) return;
  unawaited(() async {
    await ref.read(unreadGiftedCollectionsProvider.notifier).addCodes(list);
    ref.invalidate(inventoryListProvider);
    ref.invalidate(collectionIncomeProvider);
  }());
}

/// Держит бейджи подарков в актуальном состоянии:
/// 1) live WebSocket `chat_message` / `collection_gifted`
/// 2) синхронизация из списка чатов (подарки, пришедшие офлайн)
final giftedCollectionsBadgeSyncProvider = Provider.autoDispose<void>((ref) {
  final keepAliveLink = ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    keepAliveLink.close();
    return;
  }

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    realtimeEventsProvider,
    (_, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final type = event['type']?.toString() ?? '';

      if (type == 'collection_gifted') {
        final code = event['code']?.toString().trim() ?? '';
        if (code.isNotEmpty) {
          _noteGiftCodes(ref, [code]);
        }
        return;
      }

      if (type != 'chat_message') return;
      final messageRaw = event['message'];
      if (messageRaw is! Map) return;
      final map = Map<String, dynamic>.from(messageRaw);
      final sender = map['sender_user_id']?.toString() ?? '';
      if (sender.isEmpty || sender == user.id) return;
      final code = giftCollectionCodeFromBody(map['body']?.toString());
      if (code != null) {
        _noteGiftCodes(ref, [code]);
      }
    },
  );

  ref.listen<AsyncValue<List<ChatPreviewItem>>>(
    chatsListProvider,
    (_, next) {
      final chats = next.valueOrNull;
      if (chats == null || chats.isEmpty) return;
      final codes = giftCodesFromUnreadChats(
        chats: chats,
        myUserId: user.id,
      );
      if (codes.isNotEmpty) {
        _noteGiftCodes(ref, codes);
      }
    },
  );

  // Первичный проход по уже загруженному списку.
  final cached = ref.read(chatsListProvider).valueOrNull;
  if (cached != null && cached.isNotEmpty) {
    final codes = giftCodesFromUnreadChats(
      chats: cached,
      myUserId: user.id,
    );
    if (codes.isNotEmpty) {
      _noteGiftCodes(ref, codes);
    }
  }

  ref.onDispose(keepAliveLink.close);
});
