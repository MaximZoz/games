import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/games/games_repository.dart'
    show GamesException, formatStakeAmount, stakeCoinType;
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/game_card_widgets.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

class DurakLobbyScreen extends ConsumerStatefulWidget {
  const DurakLobbyScreen({super.key, required this.lobbyId, this.initialMode});
  final String lobbyId;
  final String? initialMode;

  @override
  ConsumerState<DurakLobbyScreen> createState() => _DurakLobbyScreenState();
}

class _DurakLobbyScreenState extends ConsumerState<DurakLobbyScreen> {
  final Set<String> _invited = {};
  final Set<String> _inviting = {};
  bool _leaving = false;
  bool _linkCopied = false;
  Timer? _linkTimer;

  @override
  void dispose() {
    _linkTimer?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await ref.read(durakRepositoryProvider).leaveLobby(widget.lobbyId);
    } catch (_) {}
    if (!mounted) return;
    context.go('/games');
  }

  Future<void> _invite(String friendId) async {
    if (_inviting.contains(friendId) || _invited.contains(friendId)) return;
    setState(() => _inviting.add(friendId));
    try {
      await ref
          .read(durakRepositoryProvider)
          .inviteFriend(widget.lobbyId, friendId);
      if (!mounted) return;
      setState(() {
        _invited.add(friendId);
        _inviting.remove(friendId);
      });
    } on GamesException catch (e) {
      if (!mounted) return;
      setState(() => _inviting.remove(friendId));
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    }
  }

  Future<void> _copyLink(String lobbyId) async {
    final link = buildInviteLink(lobbyId, gameType: 'durak');
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    setState(() => _linkCopied = true);
    _linkTimer?.cancel();
    _linkTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(durakLobbyProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);

    // Автоматический переход в партию когда сервер стартовал игру.
    ref.listen(durakLobbyProvider(widget.lobbyId), (_, next) {
      final lobby = next.valueOrNull;
      if (lobby?.gameId != null && lobby!.gameId!.isNotEmpty) {
        context.go('/games/durak/game/${lobby.gameId}');
      }
    });

    final lobby = lobbyAsync.valueOrNull;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _leaving ? null : _leave,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_rounded, size: 22, color: AppColors.accentStart),
            SizedBox(width: 8),
            Text('Своя игра'),
          ],
        ),
        centerTitle: true,
        actions: [
          if (lobby != null)
            IconButton(
              tooltip: 'Правила игры',
              icon: const Icon(Icons.rule_rounded),
              onPressed: () => showGameRulesDialog(
                context: context,
                title: 'Правила игры',
                content: rulesTextLines(durakRuleLines(
                  mode: lobby.gameMode,
                  players: lobby.maxPlayers,
                  deckSize: lobby.deckSize,
                  turnTimeSec: lobby.turnTimeSec,
                  stakeBronze: lobby.stakeBronze,
                )),
              ),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: lobbyAsync.when(
            data: (lobby) => _buildBody(lobby, friendsAsync),
            loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accentStart),
            ),
            error: (e, _) => Center(
              child: Text(
                formatUserError(e, fallback: 'Лобби недоступно'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    DurakLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(lobby),
              const SizedBox(height: 12),
              _buildShareLinkCard(lobby.id),
              const SizedBox(height: 12),
              Expanded(child: _buildFriendsCard(lobby, friendsAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(DurakLobbyView lobby) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Игроки ${lobby.playerIds.length}/${lobby.maxPlayers}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${durakModeLabel(lobby.gameMode)} · '
                  '${durakDeckLabel(lobby.deckSize)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (lobby.stakeBronze > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatStakeAmount(lobby.stakeBronze),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                CoinIcon(
                  coinType: stakeCoinType(lobby.stakeBronze),
                  size: 20,
                  showBorder: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShareLinkCard(String lobbyId) {
    return GradientCard(
      animate: false,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _copyLink(lobbyId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded,
                    color: AppColors.accentStart),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Отправить ссылку на игру',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _linkCopied ? 'Ссылка скопирована' : 'Скопировать в буфер',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                _linkCopied ? Icons.check_rounded : Icons.copy_rounded,
                color: AppColors.accentStart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsCard(
    DurakLobbyView lobby,
    AsyncValue<FriendsSnapshot> friendsAsync,
  ) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.all(16),
      child: friendsAsync.when(
        data: (snapshot) {
          final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
          final memberIds = <String>{...lobby.playerIds, lobby.creatorId};
          final list =
              snapshot.friends.where((f) => !memberIds.contains(f.user.id)).toList();
          sortByPresenceOnlineFirst(list, (f) => f.user.id, presence);
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Друзей для приглашения нет',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];
              final id = f.user.id;
              final invited = _invited.contains(id);
              final inviting = _inviting.contains(id);
              final p = presence[id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _avatarSmall(f.user, isOnline: p?.online == true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (f.user.displayName?.trim().isNotEmpty ?? false)
                                ? f.user.displayName!
                                : 'Игрок',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            formatPresenceStatus(p),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: invited || inviting ? null : () => _invite(id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentStart,
                        side: BorderSide(
                            color: AppColors.accentStart.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: inviting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentStart,
                              ),
                            )
                          : Text(invited ? 'Отправлено' : 'Пригласить'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accentStart),
        ),
        error: (e, _) => Center(
          child: Text(
            formatUserError(e, fallback: 'Не удалось загрузить друзей'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _avatarSmall(FriendUserItem u, {required bool isOnline}) {
    Widget avatar;
    final displayName = u.displayName?.trim() ?? '';
    final letter = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    if (u.avatarKind == 'file' &&
        u.avatarValue != null &&
        u.avatarValue!.isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(u.avatarValue!);
      if (img != null) {
        avatar = CircleAvatar(radius: 20, backgroundImage: img);
      } else {
        avatar = CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentSoft,
          child: Text(letter,
              style: const TextStyle(
                color: AppColors.accentStart,
                fontWeight: FontWeight.bold,
              )),
        );
      }
    } else {
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.accentSoft,
        child: Text(letter,
            style: const TextStyle(
              color: AppColors.accentStart,
              fontWeight: FontWeight.bold,
            )),
      );
    }
    if (!isOnline) return avatar;
    return Stack(clipBehavior: Clip.none, children: [
      avatar,
      Positioned(
        right: -1,
        bottom: -1,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceCard, width: 1),
          ),
        ),
      ),
    ]);
  }

}
