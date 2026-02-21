import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepository(authRepository: ref.watch(authRepositoryProvider));
});

final chatsUnreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<int>.value(0);
  }

  final controller = StreamController<int>();
  Timer? timer;

  Future<void> load() async {
    try {
      final chats = await ref.read(chatsRepositoryProvider).listChats(limit: 100, offset: 0);
      final unread = chats.fold<int>(0, (sum, item) => sum + item.unreadCount);
      if (!controller.isClosed) controller.add(unread);
    } catch (_) {
      if (!controller.isClosed) controller.add(0);
    }
  }

  load();
  timer = Timer.periodic(const Duration(seconds: 20), (_) => load());

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
