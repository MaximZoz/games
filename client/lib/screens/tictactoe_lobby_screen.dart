import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/invite_link.dart';
import 'package:multigames_client/games/lobby_game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/relative_time.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';

class TicTacToeLobbyScreen extends ConsumerStatefulWidget {
  const TicTacToeLobbyScreen({
    super.key,
    required this.lobbyId,
    this.initialMode,
    this.fromMessageId,
  });

  final String lobbyId;
  final String? initialMode;

  /// Если открыли «Свою игру» из сообщения в чате — удалить его после входа.
  final String? fromMessageId;

  @override
  ConsumerState<TicTacToeLobbyScreen> createState() =>
      _TicTacToeLobbyScreenState();
}

/// Заголовок AppBar экрана лобби.
///
/// Пока деталь лобби не загружена, опираемся на [initialMode] из query
/// (`?mode=invite|matchmake`), чтобы не показывать «Лобби» для своей игры.
String tictactoeLobbyAppBarTitle({
  String? status,
  String? initialMode,
}) {
  final l10n = LocaleService.l10n;
  if (status == 'waiting_matchmake') return l10n.lobbyMatchmake;
  if (status == 'waiting_invite') return l10n.lobbyPrivateGame;
  if (initialMode == 'matchmake') return l10n.lobbyMatchmake;
  if (initialMode == 'invite') return l10n.lobbyPrivateGame;
  return '';
}

const List<IconData> _presetAvatarIcons = [
  Icons.face_rounded,
  Icons.face_2_rounded,
  Icons.face_3_rounded,
  Icons.face_4_rounded,
  Icons.face_5_rounded,
  Icons.face_6_rounded,
  Icons.man_rounded,
  Icons.woman_rounded,
  Icons.person_rounded,
];

class _TicTacToeLobbyScreenState extends ConsumerState<TicTacToeLobbyScreen> {
  final Set<String> _invitedFriendIds = {};
  final Set<String> _invitingFriendIds = {};
  bool _isLeaving = false;
  bool _isJoining = false;
  bool _linkCopied = false;
  Timer? _chatsRefreshTimer;
  Timer? _linkCopiedTimer;

  @override
  void initState() {
    super.initState();
    // Не инвалидируем lobbyDetail здесь: invalidate → loading без данных →
    // мигание всего экрана при каждом remount (таб «Игры», query без mode).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Deep-link / push: пользователь уже открыл лобби — убрать карточку
      // «Вас пригласили» и бейдж в табе «Игры».
      ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
      ref.invalidate(openLobbiesProvider);
      refreshChatsList(ref, force: true).catchError((_) {});
    });
    _chatsRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) refreshChatsList(ref, force: true);
    });
  }

  @override
  void dispose() {
    _chatsRefreshTimer?.cancel();
    _linkCopiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobbyAsync = ref.watch(lobbyDetailProvider(widget.lobbyId));
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return LobbyGameNavigationWatcher(
      lobbyId: widget.lobbyId,
      onRealtimeEvent: (event) {
        final type = event['type']?.toString();
        if (type == 'chat_message' || type == 'chat_list_changed') {
          refreshChatsList(ref, force: true).catchError((_) {});
        }
      },
      child: SwipeBackScope(
        enabled: !_isLeaving,
        onBack: () => _leaveLobby(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              tooltip: context.l10n.commonBack,
              onPressed: _isLeaving ? null : () => _leaveLobby(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              tictactoeLobbyAppBarTitle(
                status: lobbyAsync.valueOrNull?.status,
                initialMode: widget.initialMode,
              ),
            ),
          ),
          body: lobbyAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (lobby) {
            final isCreator = currentUser?.id == lobby.creatorId;
            final isInviteMode = lobby.status == 'waiting_invite';
            final isMatchmakeMode = lobby.status == 'waiting_matchmake';
            if (lobby.gameId != null) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentStart,
                ),
              );
            }

            final isDesktop = isWide(context);
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 480 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lobby.stakeBronze > 0) ...[
                          _LobbyStakeChip(stakeBronze: lobby.stakeBronze),
                          const SizedBox(height: 16),
                        ],
                        if (isInviteMode && isCreator) ...[
                          _buildShareInviteLinkCard(context),
                          const SizedBox(height: 16),
                          GradientCard(
                            padding: const EdgeInsets.all(24),
                            child: friendsAsync.when(
                              data: (snapshot) {
                                final friends = snapshot.friends;
                                final presence = ref
                                        .watch(presenceMapProvider)
                                        .valueOrNull ??
                                    const {};
                                final onlineFriends = friends
                                    .where((f) {
                                      final entry = presence[f.user.id];
                                      return entry != null && entry.online;
                                    })
                                    .where((f) => !_invitedFriendIds
                                        .contains(f.user.id))
                                    .toList();
                                if (onlineFriends.isEmpty) {
                                  final onlineInvitedCount = friends
                                      .where((f) =>
                                          (presence[f.user.id]?.online ??
                                              false) &&
                                          _invitedFriendIds
                                              .contains(f.user.id))
                                      .length;
                                  return Text(
                                    friends.isEmpty
                                        ? context.l10n.lobbyNoFriendsOnline
                                        : onlineInvitedCount > 0
                                            ? context.l10n.lobbyInvitesSentWaiting
                                            : context.l10n.lobbyNoFriendsOnline,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ...onlineFriends.map((f) {
                                      final friendId = f.user.id;
                                      final isInvited =
                                          _invitedFriendIds.contains(friendId);
                                      final isInviting = _invitingFriendIds
                                          .contains(friendId);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Tooltip(
                                              message:
                                                  context.l10n.userInfoTitle,
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () => _showFriendInfo(
                                                      context, f),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  child: _buildFriendAvatar(
                                                      f.user, 20),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                f.user.displayName
                                                            ?.trim()
                                                            .isNotEmpty ==
                                                        true
                                                    ? f.user.displayName!
                                                    : context.l10n.commonUser,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: isInviting || isInvited
                                                  ? null
                                                  : () => _inviteFriend(
                                                      context, friendId),
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.accentStart,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text(
                                                isInvited
                                                    ? context
                                                        .l10n.lobbyInviteSentShort
                                                    : context.l10n.lobbyInvite,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentStart,
                                ),
                              ),
                              error: (e, _) => Text(
                                '${context.l10n.friendsLoadFailed}. ${formatUserError(e, fallback: context.l10n.commonTryLater)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ] else
                          GradientCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                if (isMatchmakeMode) ...[
                                  const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accentStart,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.l10n.lobbySearchingOpponent,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.l10n.lobbyWaitingJoin,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ] else if (isInviteMode && !isCreator) ...[
                                  Text(
                                    context.l10n.lobbyInviteTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    lobby.creatorName.trim().isNotEmpty
                                        ? context.l10n
                                            .lobbyCreatorInvites(lobby.creatorName)
                                        : context.l10n.lobbyInvitedToPlay,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    buildTictactoeRulesText(
                                      gridSize: lobby.gridSize,
                                      turnTimeSec: lobby.turnTimeSec,
                                      swapRule: lobby.swapRule,
                                      firstMoveRestriction:
                                          lobby.firstMoveRestriction,
                                      stakeBronze: lobby.stakeBronze,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    onPressed: _isJoining
                                        ? null
                                        : () => _joinViaLink(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.accentStart,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: _isJoining
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(context.l10n.lobbyEnterGame),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
          error: (_, __) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildShareInviteLinkCard(BuildContext context) {
    return GradientCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copyInviteLink,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Левая «скрепка»/link — всегда без изменений.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: AppColors.accentStart,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _linkCopied
                            ? context.l10n.lobbyLinkCopied
                            : context.l10n.lobbyCopyLink,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _linkCopied
                            ? context.l10n.lobbyLinkCopiedHint
                            : context.l10n.lobbyCopyLinkHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
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
      ),
    );
  }

  Future<void> _copyInviteLink() async {
    final url = buildInviteLobbyShareUrl(
      lobbyId: widget.lobbyId,
      baseUri: Uri.base,
    );
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _linkCopied = true);
    _linkCopiedTimer?.cancel();
    _linkCopiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  Future<void> _joinViaLink(BuildContext context) async {
    setState(() => _isJoining = true);
    try {
      final repo = ref.read(gamesRepositoryProvider);
      final result = await repo.joinLobby(widget.lobbyId);
      if (!context.mounted) return;
      if (result.joined && result.gameId != null) {
        ref.read(gameInvitesProvider.notifier).resolveJoined(widget.lobbyId);
        ref.invalidate(lobbyDetailProvider(widget.lobbyId));
        ref.invalidate(activeGameProvider);

        final messageId = widget.fromMessageId?.trim();
        if (messageId != null && messageId.isNotEmpty) {
          try {
            await ref.read(chatsRepositoryProvider).deleteMessage(messageId);
            await refreshChatsList(ref, force: true);
          } catch (_) {
            // Вход в игру важнее удаления сообщения.
          }
        }

        if (!context.mounted) return;
        // Закрыть «Свою игру» и сразу открыть матч (go затирает лобби в истории).
        context.go('/games/tictactoe/game/${result.gameId}');
        return;
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: formatUserError(e),
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _inviteFriend(BuildContext context, String friendUserId) async {
    setState(() => _invitingFriendIds.add(friendUserId));
    try {
      final repo = ref.read(gamesRepositoryProvider);
      await repo.inviteToLobby(widget.lobbyId, friendUserId);
      if (context.mounted) {
        setState(() {
          _invitedFriendIds.add(friendUserId);
          _invitingFriendIds.remove(friendUserId);
        });
        showAppSnackBar(
          context,
          message: context.l10n.lobbyInviteSent,
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      if (context.mounted) context.go('/games');
    } finally {
      if (mounted) {
        setState(() => _invitingFriendIds.remove(friendUserId));
      }
    }
  }

  void _leaveLobby(BuildContext context) {
    if (_isLeaving) return;
    _isLeaving = true;

    final lobbyId = widget.lobbyId;
    final repo = ref.read(gamesRepositoryProvider);
    final fromChat = widget.fromMessageId?.trim().isNotEmpty == true;

    // Сразу уходим с экрана — не ждём сеть и не трогаем lobbyDetail
    // (invalidate после leave давал AsyncError → спиннер → мигание карточек).
    ref.read(activeGameProvider.notifier).clearLocal();
    ref.invalidate(openLobbiesProvider);
    // Из сообщения чата — обратно к списку чатов, иначе к играм.
    context.go(fromChat ? '/chats' : '/games');

    unawaited(
      repo.leaveLobby(lobbyId).catchError((_) {}),
    );
  }

  Widget _buildFriendAvatar(FriendUserItem user, double radius) {
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(user.avatarValue!);
      if (img != null) {
        return CircleAvatar(radius: radius, backgroundImage: img);
      }
    }
    if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final idx = int.tryParse(user.avatarValue!);
      if (idx != null && idx >= 0 && idx < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[idx], color: AppColors.accentStart),
        );
      }
    }
    final displayName = user.displayName?.trim() ?? '';
    final letter = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.accentStart,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFriendInfo(BuildContext context, FriendItem friend) {
    final user = friend.user;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Consumer(
              builder: (context, ref, _) {
                final presence =
                    ref.watch(presenceMapProvider).valueOrNull ?? const {};
                final presenceEntry = presence[user.id];
                final statusText = presenceEntry == null
                    ? null
                    : (presenceEntry.online
                        ? context.l10n.commonOnlineCap
                        : formatLastSeen(presenceEntry.lastSeenAt));
                final about = user.about?.trim();
                final genderIcon = _genderIcon(user.gender);
                final female = _isFemaleGender(user.gender);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFriendAvatar(user, 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.displayName?.trim().isNotEmpty == true
                                      ? user.displayName!
                                      : context.l10n.commonUser,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (statusText != null && statusText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.commonClose,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      if ((user.age != null && user.age! > 0) ||
                          genderIcon != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (user.age != null && user.age! > 0)
                              _buildInfoPill(
                                text: context.l10n.profileAgeYears(user.age!),
                                minWidth: 72,
                              ),
                            if (genderIcon != null)
                              _buildInfoPill(
                                icon: genderIcon,
                                minWidth: 46,
                                backgroundColor: female
                                    ? const Color(0xFFFCE7F3)
                                    : AppColors.accentSoft,
                                foregroundColor: female
                                    ? const Color(0xFFBE185D)
                                    : AppColors.textPrimary,
                              ),
                          ],
                        ),
                      ],
                      if (about != null && about.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.commonAboutMe,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          about,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      PeerCollectionsSection(userId: user.id),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData? _genderIcon(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    switch (normalized) {
      case 'male':
      case 'm':
      case 'man':
      case 'м':
      case 'муж':
      case 'мужской':
        return Icons.male_rounded;
      case 'female':
      case 'f':
      case 'woman':
      case 'ж':
      case 'жен':
      case 'женский':
        return Icons.female_rounded;
      default:
        return null;
    }
  }

  bool _isFemaleGender(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'female' ||
        normalized == 'f' ||
        normalized == 'woman' ||
        normalized == 'ж' ||
        normalized == 'жен' ||
        normalized == 'женский';
  }

  Widget _buildInfoPill({
    String? text,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? minWidth,
  }) {
    final bg = backgroundColor ?? AppColors.accentSoft;
    final fg = foregroundColor ?? AppColors.textPrimary;
    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: icon != null
          ? Icon(icon, size: 16, color: fg)
          : Text(
              text ?? '',
              style: TextStyle(fontSize: 13, color: fg),
            ),
    );
  }
}

/// Ставка лобби: сумма + иконка монеты (как на карточке игры).
class _LobbyStakeChip extends StatelessWidget {
  const _LobbyStakeChip({required this.stakeBronze});

  final int stakeBronze;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.accentSoft.withValues(alpha: 0.9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.shopStakes,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatStakeAmount(stakeBronze),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            CoinIcon(
              coinType: stakeCoinType(stakeBronze),
              size: 22,
              showBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}
