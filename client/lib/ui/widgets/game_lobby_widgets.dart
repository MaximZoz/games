import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/games_repository.dart'
    show LobbyPlayer, formatStakeAmount, stakeCoinType; // stake — LobbyStakeChip
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

const List<IconData> kLobbyPresetAvatarIcons = [
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

/// Общие виджеты лобби (крестики / дурак / покер / морской бой / уно).
/// См. также `games/shared_lobby.dart` — общая сессия и leave/creator.
///
/// Чип «Ставки N 🥉» — общий для лобби всех игр (2 игрока).
class LobbyStakeChip extends StatelessWidget {
  const LobbyStakeChip({
    super.key,
    required this.stakeBronze,
    required this.label,
  });

  final int stakeBronze;

  /// Локализованная подпись слева, например «Ставки».
  final String label;

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
              label,
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

/// Карточка «Отправить ссылку на игру» — общий вид для всех игр.
class LobbyShareLinkCard extends StatelessWidget {
  const LobbyShareLinkCard({
    super.key,
    required this.title,
    required this.hint,
    required this.copied,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.link_rounded,
                      color: AppColors.accentStart),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  color: AppColors.accentStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Оценка высоты карточки друзей — общая эвристика для обеих игр,
/// чтобы карточка не растягивалась на весь экран при паре друзей.
double estimateLobbyFriendsCardHeight(int friendCount) {
  if (friendCount <= 0) return 88;
  return 24 + friendCount * 64.0;
}

/// Баннер «Поиск соперника…» — общий для matchmake-лобби всех игр.
class LobbySearchBanner extends StatelessWidget {
  const LobbySearchBanner({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка «Игроки N/M» для своей игры на 3–4 — слоты с аватарами + чат.
///
/// Общий вид крестиков и дурака: участники, пустые места, чат группы
/// и «добавить в друзья». Тап по игроку открывает полную карточку профиля.
class LobbyMultiPlayersCard extends ConsumerWidget {
  const LobbyMultiPlayersCard({
    super.key,
    required this.players,
    required this.maxPlayers,
    this.playersCount,
    this.currentUserId,
    this.chatUnread = 0,
    this.canOpenChat = false,
    this.canAddFriend = false,
    this.onOpenChat,
    this.onAddFriend,
    this.onPlayerTap,
    this.profileReturnPath,
  });

  final List<LobbyPlayer> players;
  final int maxPlayers;
  final int? playersCount;
  final String? currentUserId;
  final int chatUnread;
  final bool canOpenChat;
  final bool canAddFriend;
  final VoidCallback? onOpenChat;
  final VoidCallback? onAddFriend;
  final ValueChanged<LobbyPlayer>? onPlayerTap;
  final String? profileReturnPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = playersCount ?? players.length;
    final seats = maxPlayers.clamp(2, 6);
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.lobbyPlayersCount(count, maxPlayers),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final player in players)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openPlayerProfile(
                            context,
                            ref,
                            player,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LobbyPlayerAvatar(player: player),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 96),
                                  child: Text(
                                    player.displayName.trim().isNotEmpty
                                        ? player.displayName
                                        : context.l10n.commonUser,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.accentStart,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    for (var i = players.length; i < seats; i++)
                      const LobbyEmptySeatAvatar(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: context.l10n.chatGroupTooltip,
            onPressed: canOpenChat ? onOpenChat : null,
            icon: Badge(
              isLabelVisible: chatUnread > 0,
              label: Text(
                chatUnread > 99 ? '99+' : '$chatUnread',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.forum_rounded),
            ),
            color: AppColors.accentStart,
          ),
          if (canAddFriend)
            IconButton(
              tooltip: context.l10n.friendsAdd,
              onPressed: onAddFriend,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              color: AppColors.accentStart,
            ),
        ],
      ),
    );
  }

  void _openPlayerProfile(
    BuildContext context,
    WidgetRef ref,
    LobbyPlayer player,
  ) {
    if (onPlayerTap != null) {
      onPlayerTap!(player);
      return;
    }
    unawaited(
      showUserProfileDialog(
        context: context,
        ref: ref,
        userId: player.id,
        displayName: player.displayName,
        avatarKind: player.avatarKind,
        avatarValue: player.avatarValue,
        frameCode: player.frameCode,
        frameColor: player.frameColor,
        messageFrom: 'games',
        messageReturnPath: profileReturnPath,
      ),
    );
  }
}

/// Аватар участника лобби (общий для крестиков и дурака).
class LobbyPlayerAvatar extends StatelessWidget {
  const LobbyPlayerAvatar({super.key, required this.player});

  final LobbyPlayer player;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    const radius = size / 2;
    Widget avatar;
    if (player.avatarKind == 'file' &&
        player.avatarValue != null &&
        player.avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(player.avatarValue!);
      avatar = img == null
          ? _letterAvatar(radius)
          : CircleAvatar(radius: radius, backgroundImage: img);
    } else if (player.avatarKind == 'preset' && player.avatarValue != null) {
      final idx = int.tryParse(player.avatarValue!);
      avatar = idx != null &&
              idx >= 0 &&
              idx < kLobbyPresetAvatarIcons.length
          ? CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.accentSoft,
              child: Icon(
                kLobbyPresetAvatarIcons[idx],
                color: AppColors.accentStart,
                size: radius,
              ),
            )
          : _letterAvatar(radius);
    } else {
      avatar = _letterAvatar(radius);
    }
    return FramedAvatar(
      size: size,
      borderWidth: 2.6,
      frameCode: player.frameCode,
      frameColor: player.frameColor,
      animate: false,
      child: avatar,
    );
  }

  Widget _letterAvatar(double radius) {
    final name = player.displayName.trim();
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.accentStart,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Пустое место в multi-лобби.
class LobbyEmptySeatAvatar extends StatelessWidget {
  const LobbyEmptySeatAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceCard,
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.9),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

/// Диалог подтверждения выхода из лобби — общий для всех игр.
/// Возвращает true, если пользователь подтвердил.
Future<bool> confirmLeaveLobbyDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String leaveLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accentStart),
          child: Text(leaveLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Скелет экрана «Своя игра» в состоянии ожидания игроков.
///
/// Для 2 игроков — чип ставки сверху (как в крестиках-ноликах);
/// для 3–4 — карточка «Игроки N/M» ([multiPlayersCard]).
/// Дальше идут ссылка-приглашение и панель друзей: она занимает высоту
/// по контенту, пока помещается, и растягивается только когда друзей много.
class GameLobbyWaitingLayout extends StatelessWidget {
  const GameLobbyWaitingLayout({
    super.key,
    required this.maxPlayers,
    required this.stakeBronze,
    required this.stakeLabel,
    required this.shareLinkCard,
    required this.friendsCardBuilder,
    required this.friendsCount,
    this.multiPlayersCard,
    this.searchBanner,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 480,
  });

  final int maxPlayers;
  final int stakeBronze;
  final String stakeLabel;

  /// Карточка «Игроки N/M» — показывается только при maxPlayers > 2.
  final Widget? multiPlayersCard;

  /// Баннер «Поиск соперника…» для matchmake — сверху, если задан.
  final Widget? searchBanner;

  final Widget shareLinkCard;

  /// [expand]=true — карточка занимает остаток экрана и скроллит список.
  final Widget Function(bool expand) friendsCardBuilder;

  /// Количество друзей — для оценки нужной высоты.
  final int friendsCount;

  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isMulti = maxPlayers > 2;
    final head = <Widget>[
      if (searchBanner != null) ...[searchBanner!, const SizedBox(height: 12)],
      if (isMulti && multiPlayersCard != null) ...[
        multiPlayersCard!,
        const SizedBox(height: 12),
      ] else if (!isMulti && stakeBronze > 0) ...[
        LobbyStakeChip(stakeBronze: stakeBronze, label: stakeLabel),
        const SizedBox(height: 16),
      ],
      shareLinkCard,
      const SizedBox(height: 12),
    ];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...head,
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final estimated =
                          estimateLobbyFriendsCardHeight(friendsCount);
                      final expand = estimated >= constraints.maxHeight;
                      final card = friendsCardBuilder(expand);
                      if (expand) return card;
                      // Мало друзей — высота по контенту, карточка сверху.
                      return Align(
                        alignment: Alignment.topCenter,
                        child: card,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Список друзей в лобби «Своя игра» — один вид для всех игр.
///
/// Сортирует по presence, показывает «Онлайн» / «был в сети» и зелёную точку.
class LobbyFriendsInviteCard extends ConsumerWidget {
  const LobbyFriendsInviteCard({
    super.key,
    required this.friendsAsync,
    required this.excludeUserIds,
    required this.invitedIds,
    required this.invitingIds,
    required this.cancellingIds,
    required this.listStorageKey,
    required this.expand,
    required this.onInvite,
    required this.onCancel,
    this.declinedIds = const {},
    this.onFriendTap,
    this.profileReturnPath,
  });

  final AsyncValue<FriendsSnapshot> friendsAsync;
  final Set<String> excludeUserIds;
  final Set<String> invitedIds;
  final Set<String> invitingIds;
  final Set<String> cancellingIds;
  final Set<String> declinedIds;
  final String listStorageKey;
  final bool expand;
  final ValueChanged<String> onInvite;
  final ValueChanged<String> onCancel;
  final ValueChanged<FriendItem>? onFriendTap;
  final String? profileReturnPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: friendsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (snapshot) {
          final presence =
              ref.watch(presenceMapProvider).valueOrNull ?? const {};
          final list = snapshot.friends
              .where((friend) => !excludeUserIds.contains(friend.user.id))
              .toList();
          sortByPresenceOnlineFirst(list, (friend) => friend.user.id, presence);
          if (list.isEmpty) {
            final empty = Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.friendsEmpty,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
            return expand ? Center(child: empty) : empty;
          }
          return ListView.builder(
            key: PageStorageKey(listStorageKey),
            padding: const EdgeInsets.only(bottom: 8),
            shrinkWrap: !expand,
            physics: expand
                ? const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final friend = list[index];
              final id = friend.user.id;
              final invited = invitedIds.contains(id);
              final declined = declinedIds.contains(id);
              final working =
                  invitingIds.contains(id) || cancellingIds.contains(id);
              final entry = presence[id];
              final statusText = formatPresenceStatus(entry);
              final name = (friend.user.displayName ?? '').trim();
              final avatar = LobbyFriendPresenceAvatar(
                user: friend.user,
                isOnline: entry?.online == true,
              );
              return Padding(
                key: ValueKey('lobby-invite-$id'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: context.l10n.userInfoTitle,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _openFriendProfile(
                              context,
                              ref,
                              friend,
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                avatar,
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isEmpty
                                            ? context.l10n.commonPlayer
                                            : name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (statusText.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            statusText,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LobbyInviteActionButton(
                      label: declined
                          ? context.l10n.lobbyInviteSentShort
                          : invited
                              ? context.l10n.commonCancel
                              : context.l10n.lobbyInvite,
                      busy: working,
                      enabled: !declined,
                      onPressed: working || declined
                          ? null
                          : invited
                              ? () => onCancel(id)
                              : () => onInvite(id),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            formatUserError(
              error,
              fallback: context.l10n.friendsLoadFailed,
            ),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _openFriendProfile(
    BuildContext context,
    WidgetRef ref,
    FriendItem friend,
  ) {
    if (onFriendTap != null) {
      onFriendTap!(friend);
      return;
    }
    final user = friend.user;
    unawaited(
      showUserProfileDialog(
        context: context,
        ref: ref,
        userId: user.id,
        displayName: user.displayName,
        avatarKind: user.avatarKind,
        avatarValue: user.avatarValue,
        frameCode: user.frameCode,
        frameColor: user.frameColor,
        age: user.age,
        gender: user.gender,
        about: user.about,
        messageFrom: 'games',
        messageReturnPath: profileReturnPath,
      ),
    );
  }
}

/// Аватар друга в списке приглашений: буква / файл / пресет + точка онлайн.
class LobbyFriendPresenceAvatar extends StatelessWidget {
  const LobbyFriendPresenceAvatar({
    super.key,
    required this.user,
    required this.isOnline,
    this.radius = 20,
  });

  final FriendUserItem user;
  final bool isOnline;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName?.trim() ?? '';
    final letter = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    Widget avatar;
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(user.avatarValue!);
      avatar = img == null
          ? _letterAvatar(letter)
          : CircleAvatar(radius: radius, backgroundImage: img);
    } else if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final idx = int.tryParse(user.avatarValue!);
      avatar = idx != null &&
              idx >= 0 &&
              idx < kLobbyPresetAvatarIcons.length
          ? CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.accentSoft,
              child: Icon(
                kLobbyPresetAvatarIcons[idx],
                color: AppColors.accentStart,
                size: radius,
              ),
            )
          : _letterAvatar(letter);
    } else {
      avatar = _letterAvatar(letter);
    }
    if (!isOnline) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
      ],
    );
  }

  Widget _letterAvatar(String letter) {
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
}

/// Компактная кнопка «Пригласить» / «Отмена» в списке друзей лобби.
class LobbyInviteActionButton extends StatelessWidget {
  const LobbyInviteActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null && !busy;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.accentStart.withValues(alpha: active ? 0.7 : 0.35),
        ),
      ),
      child: InkWell(
        onTap: active ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentStart,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: AppColors.accentStart.withValues(
                      alpha: enabled ? 1 : 0.45,
                    ),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }
}
