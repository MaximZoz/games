import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/profile_extra.dart';
import 'package:multigames_client/chats/chat_image_pick.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/profile/profile_photo_cache.dart';
import 'package:multigames_client/profile/profile_photos.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/avatar_crop_dialog.dart';
import 'package:multigames_client/utils/user_error.dart';

Future<void> showProfilePhotosGallery({
  required BuildContext context,
  required String userId,
  required bool canManage,
  required String avatarKind,
  String? avatarValue,
  required String letter,
}) {
  if (userId.trim().isEmpty) return Future<void>.value();
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => ProfilePhotoViewerPage(
        userId: userId,
        canManage: canManage,
        avatarKind: avatarKind,
        avatarValue: avatarValue,
        letter: letter,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class ProfilePhotoViewerPage extends ConsumerStatefulWidget {
  const ProfilePhotoViewerPage({
    super.key,
    required this.userId,
    required this.canManage,
    required this.avatarKind,
    this.avatarValue,
    required this.letter,
  });

  final String userId;
  final bool canManage;
  final String avatarKind;
  final String? avatarValue;
  final String letter;

  @override
  ConsumerState<ProfilePhotoViewerPage> createState() =>
      _ProfilePhotoViewerPageState();
}

class _ProfilePhotoViewerPageState extends ConsumerState<ProfilePhotoViewerPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profilePhotosProvider(widget.userId));
    if (async.isLoading && !async.hasValue) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    final photos = async.valueOrNull ?? const <ProfilePhotoMeta>[];
    final me = ref.watch(authStateProvider).valueOrNull;
    final liveSelf = me != null && me.id == widget.userId;
    final avatarKind = liveSelf ? me.avatarKind : widget.avatarKind;
    final avatarValue = liveSelf ? me.avatarValue : widget.avatarValue;
    return ProfilePhotoViewerBody(
      photos: photos,
      selectedIndex: _selectedIndex,
      canManage: widget.canManage,
      fallbackPhoto: ProfileAvatarHeroImage(
        avatarKind: avatarKind,
        avatarValue: avatarValue,
        letter: widget.letter,
      ),
      imageBuilder: (photo, {BoxFit fit = BoxFit.cover}) =>
          ProfilePhotoImage(photoId: photo.id, fit: fit),
      onSelectIndex: (index) => setState(() => _selectedIndex = index),
      onMakePrimary: widget.canManage
          ? (photo) => setProfilePhotoAsPrimary(
                context: context,
                ref: ref,
                photo: photo,
              )
          : null,
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

class ProfileAvatarHeroImage extends StatelessWidget {
  const ProfileAvatarHeroImage({
    super.key,
    required this.avatarKind,
    this.avatarValue,
    required this.letter,
    this.fit = BoxFit.contain,
  });

  final String avatarKind;
  final String? avatarValue;
  final String letter;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (avatarKind == 'file' || avatarKind == AvatarKind.file.name) {
      final img = AvatarMemoryCache.fromAvatarValue(avatarValue);
      if (img != null) {
        return Image(
          image: img,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          alignment: Alignment.center,
        );
      }
    }
    final glyph = letter.trim().isEmpty ? '?' : letter.trim()[0].toUpperCase();
    return AspectRatio(
      aspectRatio: 1,
      child: ColoredBox(
        color: AppColors.accentSoft,
        child: Center(
          child: Text(
            glyph,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: AppColors.accentStart,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePhotoViewerBody extends StatefulWidget {
  const ProfilePhotoViewerBody({
    super.key,
    required this.photos,
    required this.selectedIndex,
    required this.canManage,
    required this.fallbackPhoto,
    required this.imageBuilder,
    required this.onSelectIndex,
    required this.onClose,
    this.onMakePrimary,
  });

  final List<ProfilePhotoMeta> photos;
  final int selectedIndex;
  final bool canManage;
  final Widget fallbackPhoto;
  final Widget Function(ProfilePhotoMeta photo, {BoxFit fit}) imageBuilder;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onClose;
  final ValueChanged<ProfilePhotoMeta>? onMakePrimary;

  @override
  State<ProfilePhotoViewerBody> createState() => _ProfilePhotoViewerBodyState();
}

class _ProfilePhotoViewerBodyState extends State<ProfilePhotoViewerBody> {
  late final PageController _pageController;

  bool get _hasOriginals => widget.photos.isNotEmpty;

  int get _pageCount => _hasOriginals ? widget.photos.length : 1;

  int get _safeIndex {
    if (_pageCount <= 1) return 0;
    return widget.selectedIndex.clamp(0, _pageCount - 1);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _safeIndex);
  }

  @override
  void didUpdateWidget(covariant ProfilePhotoViewerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _safeIndex;
    if (oldWidget.selectedIndex == widget.selectedIndex &&
        oldWidget.photos.length == widget.photos.length) {
      return;
    }
    if (!_pageController.hasClients) return;
    if (_pageController.page?.round() == next) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ProfilePhotoMeta? get _selectedGalleryPhoto {
    if (!_hasOriginals) return null;
    final index = _safeIndex;
    if (index < 0 || index >= widget.photos.length) return null;
    return widget.photos[index];
  }

  Widget _pageAt(int index) {
    if (!_hasOriginals) return widget.fallbackPhoto;
    return widget.imageBuilder(
      widget.photos[index],
      fit: BoxFit.contain,
    );
  }

  Widget _thumbAt(int index) {
    final photo = widget.photos[index];
    return KeyedSubtree(
      key: ValueKey('profile-photo-thumb-${photo.id}'),
      child: widget.imageBuilder(photo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = _selectedGalleryPhoto;
    final topPad = MediaQuery.viewPaddingOf(context).top;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: widget.onSelectIndex,
                  itemBuilder: (context, i) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: KeyedSubtree(
                          key: i == _safeIndex
                              ? const ValueKey('profile-viewer-main')
                              : ValueKey('profile-viewer-page-$i'),
                          child: _pageAt(i),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: topPad + 4,
                  right: 8,
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedPhoto != null &&
              widget.canManage &&
              widget.onMakePrimary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: ValueKey('profile-make-primary-${selectedPhoto.id}'),
                  onPressed: () => widget.onMakePrimary!(selectedPhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(context.l10n.profileMakePrimary),
                ),
              ),
            ),
          if (_hasOriginals)
            ColoredBox(
              key: const ValueKey('profile-viewer-strip'),
              color: const Color(0xE6000000),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPad),
                child: SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = i == _safeIndex;
                      return GestureDetector(
                        onTap: () => widget.onSelectIndex(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: selected ? 2.4 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _thumbAt(i),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfilePhotosGalleryPanel extends ConsumerWidget {
  const ProfilePhotosGalleryPanel({
    super.key,
    required this.userId,
    required this.canManage,
  });

  final String userId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profilePhotosProvider(userId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          context.l10n.profilePhotosEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (photos) => ProfilePhotosGalleryBody(
        photos: photos,
        canManage: canManage,
        imageBuilder: (photo, {BoxFit fit = BoxFit.cover}) =>
            ProfilePhotoImage(photoId: photo.id, fit: fit),
        onOpenPhoto: (index) {
          ProfilePhotoFullscreenViewer.open(
            context,
            photos: photos,
            initialIndex: index,
          );
        },
        onMakePrimary: canManage
            ? (photo) => setProfilePhotoAsPrimary(
                  context: context,
                  ref: ref,
                  photo: photo,
                )
            : null,
      ),
    );
  }
}

class ProfilePhotosGalleryBody extends StatelessWidget {
  const ProfilePhotosGalleryBody({
    super.key,
    required this.photos,
    required this.canManage,
    required this.imageBuilder,
    required this.onOpenPhoto,
    this.onMakePrimary,
  });

  final List<ProfilePhotoMeta> photos;
  final bool canManage;
  final Widget Function(ProfilePhotoMeta photo, {BoxFit fit}) imageBuilder;
  final ValueChanged<int> onOpenPhoto;
  final ValueChanged<ProfilePhotoMeta>? onMakePrimary;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Text(
          context.l10n.profilePhotosEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
      );
    }
    final narrow = MediaQuery.sizeOf(context).width < 380;
    final cardW = narrow ? 96.0 : 118.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 12,
      children: [
        for (var i = 0; i < photos.length; i++)
          SizedBox(
            width: cardW,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('profile-photo-thumb-${photos[i].id}'),
                    onTap: () => onOpenPhoto(i),
                    child: SizedBox(
                      width: cardW,
                      height: cardW,
                      child: imageBuilder(photos[i]),
                    ),
                  ),
                ),
                if (canManage && onMakePrimary != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: ValueKey('profile-make-primary-${photos[i].id}'),
                      onPressed: () => onMakePrimary!(photos[i]),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentStart,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: AppColors.accentStart.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        context.l10n.profileMakePrimary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class ProfileGalleryEditSlots extends ConsumerStatefulWidget {
  const ProfileGalleryEditSlots({
    super.key,
    required this.userId,
    this.enabled = true,
    this.compact = false,
    this.onPhotosChanged,
    this.onMutated,
  });

  final String userId;
  final bool enabled;
  final bool compact;
  final ValueChanged<List<ProfilePhotoMeta>>? onPhotosChanged;
  final VoidCallback? onMutated;

  @override
  ConsumerState<ProfileGalleryEditSlots> createState() =>
      _ProfileGalleryEditSlotsState();
}

class _ProfileGalleryEditSlotsState
    extends ConsumerState<ProfileGalleryEditSlots> {
  int? _busySlot;
  String? _lastNotifiedSignature;

  void _notifyPhotosIfNeeded(List<ProfilePhotoMeta> photos) {
    if (widget.onPhotosChanged == null) return;
    final signature = profilePhotosSignature(photos);
    if (_lastNotifiedSignature == signature) return;
    _lastNotifiedSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPhotosChanged!(photos);
    });
  }

  Future<void> _pickForSlot(int slot) async {
    if (!widget.enabled || _busySlot != null) return;
    setState(() => _busySlot = slot);
    try {
      final raw = await pickChatImageRawBytes(ImageSource.gallery);
      if (raw == null || !mounted) return;
      final picked = await compressRawChatImageAsync(raw);
      if (!mounted) return;
      if (picked == null) {
        _toast(context.l10n.profilePhotoTooLarge);
        return;
      }
      await ref.read(profilePhotosRepositoryProvider).uploadPhoto(
            slot: slot,
            imageBase64: picked.base64,
            imageMime: picked.mime,
          );
      ref.read(profilePhotoBytesCacheProvider.notifier).state = {};
      ref.invalidate(profilePhotosProvider(widget.userId));
      widget.onMutated?.call();
    } catch (e) {
      if (!mounted) return;
      _toast(formatUserError(e, fallback: context.l10n.profilePhotoUploadFailed));
    } finally {
      if (mounted) setState(() => _busySlot = null);
    }
  }

  Future<void> _delete(ProfilePhotoMeta photo) async {
    if (!widget.enabled || _busySlot != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.profilePhotoDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busySlot = photo.slot);
    try {
      await ref.read(profilePhotosRepositoryProvider).deletePhoto(photo.id);
      removeProfilePhotoFromCache(ref, photo.id);
      ref.invalidate(profilePhotosProvider(widget.userId));
      widget.onMutated?.call();
    } catch (e) {
      if (!mounted) return;
      _toast(formatUserError(e, fallback: context.l10n.profilePhotoDeleteFailed));
    } finally {
      if (mounted) setState(() => _busySlot = null);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profilePhotosProvider(widget.userId));
    final photos = async.valueOrNull ?? const <ProfilePhotoMeta>[];
    if (async.hasValue) {
      _notifyPhotosIfNeeded(photos);
    }
    final slots = profilePhotoSlots(photos);
    final phoneLand = isPhoneLandscape(context);
    final size = widget.compact
        ? (phoneLand ? 52.0 : 64.0)
        : (isNarrow(context) ? 68.0 : 76.0);

    return ProfileGallerySlotRow(
      slots: slots,
      slotSize: size,
      busySlot: _busySlot,
      enabled: widget.enabled && _busySlot == null,
      imageBuilder: (photo) => ProfilePhotoImage(photoId: photo.id),
      onAddSlot: _pickForSlot,
      onReplaceSlot: _pickForSlot,
      onDelete: _delete,
    );
  }
}

class ProfileGallerySlotRow extends StatelessWidget {
  const ProfileGallerySlotRow({
    super.key,
    required this.slots,
    required this.slotSize,
    required this.imageBuilder,
    required this.onAddSlot,
    required this.onReplaceSlot,
    required this.onDelete,
    this.busySlot,
    this.enabled = true,
  });

  final List<ProfilePhotoMeta?> slots;
  final double slotSize;
  final int? busySlot;
  final bool enabled;
  final Widget Function(ProfilePhotoMeta photo) imageBuilder;
  final ValueChanged<int> onAddSlot;
  final ValueChanged<int> onReplaceSlot;
  final ValueChanged<ProfilePhotoMeta> onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < maxProfilePhotos; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _EditSlotCard(
              slot: i,
              photo: i < slots.length ? slots[i] : null,
              size: slotSize,
              busy: busySlot == i,
              enabled: enabled,
              imageBuilder: imageBuilder,
              onAdd: () => onAddSlot(i),
              onReplace: () => onReplaceSlot(i),
              onDelete: i < slots.length && slots[i] != null
                  ? () => onDelete(slots[i]!)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _EditSlotCard extends StatelessWidget {
  const _EditSlotCard({
    required this.slot,
    required this.photo,
    required this.size,
    required this.busy,
    required this.enabled,
    required this.imageBuilder,
    required this.onAdd,
    required this.onReplace,
    required this.onDelete,
  });

  final int slot;
  final ProfilePhotoMeta? photo;
  final double size;
  final bool busy;
  final bool enabled;
  final Widget Function(ProfilePhotoMeta photo) imageBuilder;
  final VoidCallback onAdd;
  final VoidCallback onReplace;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final filled = photo != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          child: Material(
            key: ValueKey('profile-gallery-slot-$slot'),
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: !enabled || busy
                  ? null
                  : (filled ? onReplace : onAdd),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.accentStart.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (filled) imageBuilder(photo!) else const SizedBox.shrink(),
                    if (!filled)
                      Tooltip(
                        message: context.l10n.profileGalleryAdd,
                        child: Icon(
                          Icons.add_rounded,
                          key: ValueKey('profile-gallery-slot-add-$slot'),
                          color: AppColors.accentStart,
                          size: size * 0.42,
                        ),
                      ),
                    if (busy)
                      const ColoredBox(
                        color: Color(0x66FFFFFF),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    if (filled && onDelete != null && !busy)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: enabled ? onDelete : null,
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfilePhotoImage extends ConsumerStatefulWidget {
  const ProfilePhotoImage({
    super.key,
    required this.photoId,
    this.fit = BoxFit.cover,
  });

  final String photoId;
  final BoxFit fit;

  @override
  ConsumerState<ProfilePhotoImage> createState() => _ProfilePhotoImageState();
}

class _ProfilePhotoImageState extends ConsumerState<ProfilePhotoImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfilePhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoId != widget.photoId) {
      _load();
    }
  }

  Future<void> _load() async {
    final cached = ref.read(profilePhotoBytesCacheProvider)[widget.photoId];
    if (cached != null) {
      setState(() {
        _bytes = cached;
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final bytes = await ref
          .read(profilePhotosRepositoryProvider)
          .fetchPhotoBytes(widget.photoId);
      ref.read(profilePhotoBytesCacheProvider.notifier).update((m) {
        final next = Map<String, Uint8List>.from(m);
        next[widget.photoId] = bytes;
        return next;
      });
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_failed || _bytes == null) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
      );
    }
    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
    );
  }
}

class ProfilePhotoFullscreenViewer extends StatefulWidget {
  const ProfilePhotoFullscreenViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  final List<ProfilePhotoMeta> photos;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<ProfilePhotoMeta> photos,
    required int initialIndex,
  }) {
    if (photos.isEmpty) return Future<void>.value();
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ProfilePhotoFullscreenViewer(
          photos: photos,
          initialIndex: initialIndex.clamp(0, photos.length - 1),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ProfilePhotoFullscreenViewer> createState() =>
      _ProfilePhotoFullscreenViewerState();
}

class _ProfilePhotoFullscreenViewerState
    extends State<ProfilePhotoFullscreenViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _jumpTo(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: Center(
                          child: ProfilePhotoImage(
                            photoId: widget.photos[i].id,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: MediaQuery.viewPaddingOf(context).top + 4,
                    right: 8,
                    child: IconButton(
                      onPressed: _close,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: const Color(0xE6000000),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPad),
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = i == _index;
                      return GestureDetector(
                        onTap: () => _jumpTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.white24,
                              width: selected ? 2.4 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProfilePhotoImage(photoId: widget.photos[i].id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> saveOriginalPhotoToGallery({
  required WidgetRef ref,
  required String userId,
  required Uint8List rawBytes,
}) async {
  final picked = await compressRawChatImageAsync(rawBytes);
  if (picked == null) return false;
  final photos = ref.read(profilePhotosProvider(userId)).valueOrNull ??
      const <ProfilePhotoMeta>[];
  final slot = profilePhotoSlots(photos).indexWhere((e) => e == null);
  if (slot < 0) return false;
  await ref.read(profilePhotosRepositoryProvider).uploadPhoto(
        slot: slot,
        imageBase64: picked.base64,
        imageMime: picked.mime,
      );
  ref.read(profilePhotoBytesCacheProvider.notifier).state = {};
  ref.invalidate(profilePhotosProvider(userId));
  return true;
}

Future<void> setProfilePhotoAsPrimary({
  required BuildContext context,
  required WidgetRef ref,
  required ProfilePhotoMeta photo,
}) async {
  final l10n = context.l10n;
  try {
    var bytes = ref.read(profilePhotoBytesCacheProvider)[photo.id];
    bytes ??= await ref
        .read(profilePhotosRepositoryProvider)
        .fetchPhotoBytes(photo.id);
    if (!context.mounted) return;
    final cropped = await showAvatarCropDialog(
      context: context,
      sourceBytes: bytes,
    );
    if (!context.mounted || cropped == null || cropped.isEmpty) return;
    final compact = await buildCompactAvatarValue(cropped);
    if (!context.mounted) return;
    if (compact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePhotoTooLarge)),
      );
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(authStateProvider.notifier).updateProfile(
          extra: ProfileExtra(
            age: user.age,
            gender: user.gender,
            about: user.about,
            avatarKind: AvatarKind.file,
            avatarValue: compact,
            showStatsToOthers: user.showStatsToOthers,
          ),
        );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          formatUserError(e, fallback: l10n.profileSetPrimaryFailed),
        ),
      ),
    );
  }
}

class TappableProfileAvatar extends ConsumerWidget {
  const TappableProfileAvatar({
    super.key,
    required this.userId,
    required this.canManage,
    required this.avatarKind,
    this.avatarValue,
    required this.letter,
    required this.child,
  });

  final String userId;
  final bool canManage;
  final String avatarKind;
  final String? avatarValue;
  final String letter;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(profilePhotosProvider(userId)).valueOrNull?.length ?? 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showProfilePhotosGallery(
          context: context,
          userId: userId,
          canManage: canManage,
          avatarKind: avatarKind,
          avatarValue: avatarValue,
          letter: letter,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentStart.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    size: 13,
                    color: AppColors.accentStart,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
