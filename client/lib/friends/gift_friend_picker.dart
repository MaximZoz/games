import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/utils/relative_time.dart';

/// Диалог выбора друга для подарка.
/// Список как во вкладке «Друзья»: аватар (клик → карточка), статус,
/// «Дружите с», тот же порядок, поиск и подгрузка при скролле.
Future<String?> showGiftFriendPicker(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const GiftFriendPickerDialog(),
  );
}

class GiftFriendPickerDialog extends ConsumerStatefulWidget {
  const GiftFriendPickerDialog({super.key});

  @override
  ConsumerState<GiftFriendPickerDialog> createState() =>
      _GiftFriendPickerDialogState();
}

class _GiftFriendPickerDialogState
    extends ConsumerState<GiftFriendPickerDialog> {
  static const int _pageSize = 10;
  static const List<IconData> _presetAvatarIcons = [
    Icons.face_rounded,
    Icons.face_2_rounded,
    Icons.face_3_rounded,
    Icons.face_4_rounded,
    Icons.face_5_rounded,
    Icons.face_6_rounded,
    Icons.man_rounded,
    Icons.woman_rounded,
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _visibleCount = _pageSize);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.extentAfter > 120) return;
    final total = _filteredSorted().length;
    if (_visibleCount >= total) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
    });
  }

  String _displayName(FriendUserItem user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return LocaleService.l10n.commonUser;
  }

  bool _matchesSearch(FriendUserItem user, String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase();
    return _displayName(user).toLowerCase().contains(q);
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  List<FriendItem> _filteredSorted() {
    final friends =
        ref.read(friendsSnapshotProvider).valueOrNull?.friends ?? const [];
    final presence =
        ref.read(presenceMapProvider).valueOrNull ?? const <String, PresenceEntry>{};
    final query = _searchController.text.trim();
    final list =
        friends.where((f) => _matchesSearch(f.user, query)).toList();
    list.sort((a, b) {
      final pa = presence[a.user.id];
      final pb = presence[b.user.id];
      final aOnline = pa?.online ?? false;
      final bOnline = pb?.online ?? false;
      if (aOnline != bOnline) return bOnline ? 1 : -1;
      if (aOnline) return 0;
      final aTime = pa?.lastSeenAt;
      final bTime = pb?.lastSeenAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final da = DateTime.tryParse(aTime);
      final db = DateTime.tryParse(bTime);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return list;
  }

  Future<void> _showUserInfo(
    FriendUserItem user,
    PresenceEntry? presence,
  ) async {
    final name = _displayName(user);
    final about = user.about?.trim();
    final statusText = presence == null
        ? null
        : (presence.online ? LocaleService.l10n.commonOnlineCap : formatLastSeen(presence.lastSeenAt));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 380;
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
            ),
            child: GradientCard(
              animate: false,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(user, isOnline: presence?.online),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        tooltip: dialogContext.l10n.commonClose,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  if (about != null && about.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogContext.l10n.commonAboutMe,
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
                  HeadToHeadSection(
                    opponentId: user.id,
                    opponentName: user.displayName,
                  ),
                  PeerCollectionsSection(userId: user.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(
    FriendUserItem user, {
    bool? isOnline,
    VoidCallback? onTap,
  }) {
    Widget avatar;
    if (user.avatarKind == 'file' &&
        user.avatarValue != null &&
        user.avatarValue!.isNotEmpty) {
      final memoryImage = AvatarMemoryCache.fromAvatarValue(user.avatarValue);
      if (memoryImage != null) {
        avatar = CircleAvatar(
          radius: 20,
          backgroundImage: memoryImage,
        );
      } else {
        avatar = _letterAvatar(user);
      }
    } else if (user.avatarKind == 'preset' && user.avatarValue != null) {
      final index = int.tryParse(user.avatarValue!);
      if (index != null && index >= 0 && index < _presetAvatarIcons.length) {
        avatar = CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentSoft,
          child: Icon(_presetAvatarIcons[index], color: AppColors.accentStart),
        );
      } else {
        avatar = _letterAvatar(user);
      }
    } else {
      avatar = _letterAvatar(user);
    }
    avatar = FramedAvatar(
      size: 40,
      borderWidth: 2.8,
      frameCode: user.frameCode,
      frameColor: user.frameColor,
      child: avatar,
    );
    if (isOnline == true) {
      avatar = Stack(
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
    if (onTap == null) return avatar;
    return Tooltip(
      message: LocaleService.l10n.userInfoTitle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: avatar,
        ),
      ),
    );
  }

  Widget _letterAvatar(FriendUserItem user) {
    final first = _displayName(user).trim();
    final letter = first.isEmpty ? '?' : first.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _friendTile(FriendItem item, PresenceEntry? presence) {
    final statusText = presence == null
        ? null
        : (presence.online ? LocaleService.l10n.commonOnlineCap : formatLastSeen(presence.lastSeenAt));
    return GradientCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      animate: false,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(item.user.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildAvatar(
                  item.user,
                  isOnline: presence?.online,
                  onTap: () => _showUserInfo(item.user, presence),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(item.user),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: LocaleService.l10n.inventoryGift,
                  onPressed: () => Navigator.of(context).pop(item.user.id),
                  icon: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.accentStart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              LocaleService.l10n.friendsSince(_formatDateTime(item.createdAt)),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(friendsSnapshotProvider);
    ref.watch(presenceMapProvider);
    final presence =
        ref.watch(presenceMapProvider).valueOrNull ??
            const <String, PresenceEntry>{};
    final items = _filteredSorted();
    final visibleCount =
        _visibleCount > items.length ? items.length : _visibleCount;
    final visible = items.take(visibleCount).toList();
    final hasMore = visibleCount < items.length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: GradientCard(
          animate: false,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.giftFriendTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.friendsSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.commonClear,
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.chatsFriendsNotFound,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: visible.length + (hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= visible.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final item = visible[index];
                          return _friendTile(
                            item,
                            presence[item.user.id],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
