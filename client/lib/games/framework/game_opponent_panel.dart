import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/framework/game_screen_scaffold.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';

/// Соперник, каким его знает партия.
class GameOpponent {
  const GameOpponent({
    required this.userId,
    this.displayName,
    this.avatarKind = 'letter',
    this.avatarValue,
    this.frameCode,
    this.frameColor,
    this.isBot = false,
  });

  final String userId;
  final String? displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;
  final bool isBot;

  /// Бот по флагу или по id (`bot:…`, локальный соперник офлайна).
  bool get isBotLike {
    final id = userId.trim();
    return isBot || id.isEmpty || id.startsWith('bot:');
  }
}

/// Вид карточки соперника.
enum GameOpponentLayout {
  /// Широкая карточка 1×1: аватар, имя, чат и «в друзья».
  card,

  /// Место за столом на 3+ игроков: аватар и имя столбиком.
  seat,
}

/// Открыть профиль соперника поверх партии — общий сценарий для всех игр.
///
/// Из профиля можно написать сообщение; назад чат вернёт на стол партии.
void openGameOpponentProfile({
  required BuildContext context,
  required WidgetRef ref,
  required GameOpponent opponent,
  required String gameType,
  required String gameId,
  String? displayName,
}) {
  if (opponent.isBotLike) return;
  unawaited(showUserProfileDialog(
    context: context,
    ref: ref,
    userId: opponent.userId.trim(),
    displayName: displayName ?? opponent.displayName,
    avatarKind: opponent.avatarKind,
    avatarValue: opponent.avatarValue,
    frameCode: opponent.frameCode,
    frameColor: opponent.frameColor,
    messageFrom: 'games',
    messageReturnPath: gamePathFor(gameId, gameType: gameType),
  ));
}

/// Карточка соперника — одна на все игры.
///
/// Фиолетовая скруглённая рамка с аватаром, именем и чатом. В ход соперника
/// рамка превращается в его таймер: зелёная → оранжевая → красная линия
/// убывает по периметру. Тап по аватару открывает профиль, иконка — чат,
/// «+» — заявку в друзья: игра это не подключает, достаточно передать
/// [opponent] и id партии.
class GameOpponentPanel extends ConsumerWidget {
  const GameOpponentPanel({
    super.key,
    required this.opponent,
    required this.gameType,
    required this.gameId,
    this.isTheirTurn = false,
    this.turnDeadline = 0,
    this.turnTimeSec = 0,
    this.onTurnExpired,
    this.trailing = const <Widget>[],
    this.maxWidth = 320,
    this.compact,
    this.align,
    this.reserveRail = true,
    this.layout = GameOpponentLayout.card,
  });

  final GameOpponent opponent;

  /// `game_type` и id партии — путь возврата из чата и профиля.
  final String gameType;
  final String gameId;

  /// Сейчас ход этого соперника: рамка показывает его время.
  final bool isTheirTurn;
  final int turnDeadline;
  final int turnTimeSec;
  final VoidCallback? onTurnExpired;

  /// Свои значки игры справа от имени (счёт, фишка, число карт).
  final List<Widget> trailing;
  final double maxWidth;

  /// null — компактно на узком экране и в альбоме телефона.
  final bool? compact;
  final Alignment? align;

  /// Оставить справа место под столбик «сдаться / ничья» общего хрома.
  final bool reserveRail;
  final GameOpponentLayout layout;

  static const double _frameWidth = 2.5;
  static const double _frameRadius = 22;

  String get _returnPath => gamePathFor(gameId, gameType: gameType);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = opponent.userId.trim();
    final bot = opponent.isBotLike;
    final rawName = opponent.displayName?.trim() ?? '';
    final name = rawName.isNotEmpty
        ? rawName
        : (bot ? l10n.gameBot : l10n.gameOpponent);

    void openProfile() => openGameOpponentProfile(
          context: context,
          ref: ref,
          opponent: opponent,
          gameType: gameType,
          gameId: gameId,
          displayName: name,
        );

    if (layout == GameOpponentLayout.seat) {
      return _seat(context, name: name, bot: bot, onTap: openProfile);
    }

    var unread = 0;
    var isFriend = false;
    String? incomingRequestId;
    var requestSent = false;
    if (!bot) {
      final chats = ref.watch(chatsListProvider).valueOrNull;
      if (chats != null) {
        for (final chat in chats) {
          if (chat.user.id == id) unread += chat.unreadCount;
        }
      }
      final friends = ref.watch(friendsSnapshotProvider).valueOrNull;
      isFriend = friends?.friends.any((f) => f.user.id == id) == true;
      requestSent = friends?.outgoing.any((r) => r.user.id == id) == true;
      final incoming = friends?.incoming.where((r) => r.user.id == id);
      if (incoming != null && incoming.isNotEmpty) {
        incomingRequestId = incoming.first.requestId;
      }
    }

    final size = MediaQuery.sizeOf(context);
    final tight = compact ??
        (size.width < 420 || (size.shortestSide < 700 && size.width > size.height));
    final rail = reserveRail ? GameChromeScope.railInsetOf(context) : 0.0;

    final card = GameOpponentCard(
      userId: id,
      displayName: name,
      avatarKind: opponent.avatarKind,
      avatarValue: opponent.avatarValue,
      frameCode: opponent.frameCode,
      frameColor: opponent.frameColor,
      isBot: bot,
      messageUnread: unread,
      infoTooltip: bot ? '' : l10n.userInfoTitle,
      messageTooltip: l10n.gameWriteMessage,
      compact: tight,
      maxWidth: maxWidth,
      // Рамку рисует таймер хода — своя у карточки не нужна.
      borderWidth: 0,
      showAddFriend: !bot && !isFriend,
      addFriendEnabled: !requestSent,
      addFriendBadge: incomingRequestId != null ? 1 : 0,
      addFriendTooltip: incomingRequestId != null
          ? l10n.friendsAcceptRequest
          : (requestSent ? l10n.friendsRequestSent : l10n.friendsAdd),
      onAddFriendTap: () => unawaited(
        _addFriend(context, ref, id, requestId: incomingRequestId),
      ),
      onInfoTap: openProfile,
      onMessageTap:
          bot ? null : () => unawaited(_openChat(context, ref, id, name)),
      trailing: trailing,
    );

    final framed = TurnTimerBorder(
      key: const ValueKey('game-opponent-frame'),
      active: isTheirTurn,
      turnDeadline: turnDeadline,
      turnTimeSec: turnTimeSec,
      borderWidth: _frameWidth,
      radius: _frameRadius,
      onExpired: onTurnExpired,
      child: card,
    );

    return Padding(
      // Симметрично, чтобы карточка осталась по центру стола.
      padding: EdgeInsets.symmetric(horizontal: align == null ? rail : 0),
      child: Align(
        alignment: align ?? Alignment.center,
        widthFactor: align == null ? null : 1,
        heightFactor: 1,
        child: framed,
      ),
    );
  }

  Widget _seat(
    BuildContext context, {
    required String name,
    required bool bot,
    required VoidCallback onTap,
  }) {
    final avatar = GameActorHighlight(
      key: const ValueKey('game-opponent-frame'),
      isActing: isTheirTurn,
      turnDeadline: turnDeadline,
      turnTimeSec: turnTimeSec,
      borderWidth: _frameWidth,
      radius: 999,
      onExpired: onTurnExpired,
      child: GamePlayerAvatar(
        displayName: name,
        avatarKind: opponent.avatarKind,
        avatarValue: opponent.avatarValue,
        userId: opponent.userId,
        frameCode: opponent.frameCode,
        frameColor: opponent.frameColor,
        compact: true,
      ),
    );
    return Tooltip(
      message: bot ? '' : context.l10n.userInfoTitle,
      child: MouseRegion(
        cursor: bot ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: bot ? null : onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isTheirTurn
                        ? AppColors.accentStart
                        : AppColors.textPrimary,
                  ),
                ),
                if (trailing.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String displayName,
  ) async {
    try {
      final chatId = await ref.read(chatsRepositoryProvider).startChat(userId);
      if (!context.mounted || chatId.isEmpty) return;
      context.push(
        Uri(
          path: '/chats/$chatId',
          queryParameters: {
            'name': displayName,
            'from': 'games',
            'game': _returnPath,
          },
        ).toString(),
      );
    } catch (_) {
      if (!context.mounted) return;
      context.push(
        Uri(
          path: '/chats',
          queryParameters: {'peer': userId, 'game': _returnPath},
        ).toString(),
      );
    }
  }

  Future<void> _addFriend(
    BuildContext context,
    WidgetRef ref,
    String userId, {
    String? requestId,
  }) async {
    final repo = ref.read(friendsRepositoryProvider);
    try {
      if (requestId != null) {
        await repo.acceptRequest(requestId);
      } else {
        await repo.sendRequest(userId);
      }
      if (!context.mounted) return;
      ref.invalidate(friendsSnapshotProvider);
      showAppSnackBar(
        context,
        message: requestId != null
            ? context.l10n.friendsAcceptRequest
            : context.l10n.friendsRequestSent,
        kind: AppSnackKind.success,
      );
    } catch (_) {}
  }
}
