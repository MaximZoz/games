import 'package:flutter/material.dart';
import 'package:multigames_client/games/games_repository.dart'
    show LobbyPlayer, formatStakeAmount, stakeCoinType; // stake — LobbyStakeChip
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

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

/// Общие виджеты лобби (крестики / дурак).
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
  return 24 + friendCount * 56.0;
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
/// и «добавить в друзья».
class LobbyMultiPlayersCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final count = playersCount ?? players.length;
    final seats = maxPlayers.clamp(2, 4);
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
                          onTap: onPlayerTap == null
                              ? null
                              : () => onPlayerTap!(player),
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
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.accentStart,
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
            tooltip: 'Чат группы',
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
