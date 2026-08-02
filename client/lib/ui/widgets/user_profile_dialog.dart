import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/relative_time.dart';

/// Стандартная карточка пользователя: аватар, о себе, счёт, коллекции,
/// у крестика — «в друзья» (если ещё не друг) и «написать».
Future<void> showUserProfileDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  String? displayName,
  String avatarKind = 'letter',
  String? avatarValue,
  String? frameCode,
  String? frameColor,
  int? age,
  String? gender,
  String? about,
  /// Куда вернуться из чата (например путь к игре).
  String? messageReturnPath,
  String messageFrom = 'games',
  /// В комнате чата «написать» не нужно — уже в переписке.
  bool showMessageButton = true,
}) async {
  final id = userId.trim();
  if (id.isEmpty || id.startsWith('bot:')) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
          ),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Consumer(
              builder: (context, ref, _) {
                final friendsSnapshot =
                    ref.watch(friendsSnapshotProvider).valueOrNull;
                final presence =
                    ref.watch(presenceMapProvider).valueOrNull ?? const {};
                final chatsList =
                    ref.watch(chatsListProvider).valueOrNull ?? const [];

                FriendUserItem? friendUser;
                String? incomingRequestId;
                var isFriend = false;
                var hasOutgoing = false;

                for (final f in friendsSnapshot?.friends ?? const []) {
                  if (f.user.id == id) {
                    friendUser = f.user;
                    isFriend = true;
                    break;
                  }
                }
                if (!isFriend) {
                  for (final r in friendsSnapshot?.incoming ?? const []) {
                    if (r.user.id == id) {
                      friendUser = r.user;
                      incomingRequestId = r.requestId;
                      break;
                    }
                  }
                }
                if (!isFriend && incomingRequestId == null) {
                  for (final r in friendsSnapshot?.outgoing ?? const []) {
                    if (r.user.id == id) {
                      friendUser = r.user;
                      hasOutgoing = true;
                      break;
                    }
                  }
                }
                if (friendUser == null) {
                  for (final chat in chatsList) {
                    if (chat.user.id == id) {
                      friendUser = FriendUserItem(
                        id: chat.user.id,
                        email: '',
                        displayName: chat.user.displayName,
                        avatarKind: chat.user.avatarKind,
                        avatarValue: chat.user.avatarValue,
                        age: chat.user.age,
                        gender: chat.user.gender,
                        about: chat.user.about,
                      );
                      break;
                    }
                    for (final m in chat.members) {
                      if (m.id != id) continue;
                      friendUser = FriendUserItem(
                        id: m.id,
                        email: '',
                        displayName: m.displayName,
                        avatarKind: m.avatarKind,
                        avatarValue: m.avatarValue,
                        age: m.age,
                        gender: m.gender,
                        about: m.about,
                      );
                      break;
                    }
                    if (friendUser != null) break;
                  }
                }

                final name = (friendUser?.displayName?.trim().isNotEmpty == true)
                    ? friendUser!.displayName!.trim()
                    : (displayName?.trim().isNotEmpty == true
                        ? displayName!.trim()
                        : context.l10n.commonUser);
                final resolvedAge = friendUser?.age ?? age;
                final resolvedGender = friendUser?.gender ?? gender;
                final resolvedAbout =
                    (friendUser?.about?.trim().isNotEmpty == true)
                        ? friendUser!.about!.trim()
                        : about?.trim();
                final presenceEntry = presence[id];
                final statusText = presenceEntry == null
                    ? null
                    : (presenceEntry.online
                        ? context.l10n.commonOnlineCap
                        : formatLastSeen(presenceEntry.lastSeenAt));
                final genderIcon = _genderIcon(resolvedGender);
                final female = _isFemaleGender(resolvedGender);
                final myId =
                    ref.watch(authStateProvider).valueOrNull?.id.trim() ?? '';
                final isSelf = myId.isNotEmpty && myId == id;
                // «В друзья» — если ещё не друг и нет исходящей заявки.
                final showAddFriend = !isSelf && !isFriend && !hasOutgoing;
                // «Написать» — везде, кроме комнаты текущего чата.
                final showMessage = showMessageButton && !isSelf;
                final resolvedFrameCode =
                    friendUser?.frameCode ?? frameCode;
                final resolvedFrameColor =
                    friendUser?.frameColor ?? frameColor;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileAvatar(
                            displayName: name,
                            avatarKind:
                                friendUser?.avatarKind ?? avatarKind,
                            avatarValue:
                                friendUser?.avatarValue ?? avatarValue,
                            frameCode: resolvedFrameCode,
                            frameColor: resolvedFrameColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (statusText != null &&
                                    statusText.isNotEmpty)
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
                          if (showAddFriend)
                            IconButton(
                              tooltip: incomingRequestId != null
                                  ? context.l10n.commonAccept
                                  : context.l10n.friendsAdd,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.accentStart,
                              ),
                              onPressed: () async {
                                try {
                                  final incoming = incomingRequestId;
                                  if (incoming != null &&
                                      incoming.isNotEmpty) {
                                    await ref
                                        .read(friendsRepositoryProvider)
                                        .acceptRequest(incoming);
                                    if (context.mounted) {
                                      showAppSnackBar(
                                        context,
                                        message: context
                                            .l10n.friendsRequestAccepted,
                                        kind: AppSnackKind.success,
                                      );
                                    }
                                  } else {
                                    await ref
                                        .read(friendsRepositoryProvider)
                                        .sendRequest(id);
                                    if (context.mounted) {
                                      showAppSnackBar(
                                        context,
                                        message: context
                                            .l10n.friendsRequestSent,
                                        kind: AppSnackKind.success,
                                      );
                                    }
                                  }
                                  await refreshFriendsSnapshot(ref);
                                } catch (_) {
                                  if (context.mounted) {
                                    showAppSnackBar(
                                      context,
                                      message: context.l10n.commonError,
                                      kind: AppSnackKind.error,
                                    );
                                  }
                                }
                              },
                            ),
                          if (showMessage)
                            IconButton(
                              tooltip: context.l10n.navChats,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.accentStart,
                              ),
                              onPressed: () async {
                                try {
                                  final chatId = await ref
                                      .read(chatsRepositoryProvider)
                                      .startChat(id);
                                  if (!dialogContext.mounted) return;
                                  Navigator.of(dialogContext).pop();
                                  if (!context.mounted || chatId.isEmpty) {
                                    return;
                                  }
                                  final params = <String, String>{
                                    'name': name,
                                    'from': messageFrom,
                                  };
                                  final ret =
                                      messageReturnPath?.trim() ?? '';
                                  if (ret.isNotEmpty) {
                                    params['game'] = ret;
                                  }
                                  context.push(
                                    Uri(
                                      path: '/chats/$chatId',
                                      queryParameters: params,
                                    ).toString(),
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    showAppSnackBar(
                                      context,
                                      message: context.l10n.commonError,
                                      kind: AppSnackKind.error,
                                    );
                                  }
                                }
                              },
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: context.l10n.commonClose,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      if ((resolvedAge != null && resolvedAge > 0) ||
                          genderIcon != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (resolvedAge != null && resolvedAge > 0)
                              _infoPill(
                                text: context.l10n
                                    .profileAgeYears(resolvedAge),
                                minWidth: 72,
                              ),
                            if (genderIcon != null)
                              _infoPill(
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
                      if (resolvedAbout != null &&
                          resolvedAbout.isNotEmpty) ...[
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
                          resolvedAbout,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      HeadToHeadSection(
                        opponentId: id,
                        opponentName: name,
                      ),
                      PeerCollectionsSection(userId: id),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.avatarKind,
    this.avatarValue,
    this.frameCode,
    this.frameColor,
  });

  final String displayName;
  final String avatarKind;
  final String? avatarValue;
  final String? frameCode;
  final String? frameColor;

  @override
  Widget build(BuildContext context) {
    const r = 22.0;
    Widget avatar;
    if (avatarKind == 'file' &&
        avatarValue != null &&
        avatarValue!.trim().isNotEmpty) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      avatar = img != null
          ? CircleAvatar(radius: r, backgroundImage: img)
          : _letter(r);
    } else {
      avatar = _letter(r);
    }
    return FramedAvatar(
      size: r * 2,
      borderWidth: 2.4,
      frameCode: frameCode,
      frameColor: frameColor,
      animate: false,
      child: avatar,
    );
  }

  Widget _letter(double r) {
    final letter =
        displayName.trim().isEmpty ? '?' : displayName[0].toUpperCase();
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

Widget _infoPill({
  String? text,
  IconData? icon,
  double minWidth = 0,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  return Container(
    constraints: BoxConstraints(minWidth: minWidth),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: backgroundColor ?? AppColors.accentSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: icon != null
        ? Icon(icon, size: 16, color: foregroundColor ?? AppColors.textPrimary)
        : Text(
            text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foregroundColor ?? AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
  );
}

IconData? _genderIcon(String? gender) {
  final g = (gender ?? '').trim().toLowerCase();
  if (g == 'male' || g == 'm' || g == 'муж' || g == 'мужской') {
    return Icons.male_rounded;
  }
  if (g == 'female' || g == 'f' || g == 'жен' || g == 'женский') {
    return Icons.female_rounded;
  }
  return null;
}

bool _isFemaleGender(String? gender) {
  final g = (gender ?? '').trim().toLowerCase();
  return g == 'female' || g == 'f' || g == 'жен' || g == 'женский';
}
