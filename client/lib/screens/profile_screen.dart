import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/profile_extra.dart';
import 'package:multigames_client/profile/profile_gallery_widgets.dart';
import 'package:multigames_client/profile/profile_photos.dart';
import 'package:multigames_client/screens/pick_image_web.dart';
import 'package:multigames_client/screens/profile_avatar_storage.dart';
import 'package:multigames_client/screens/profile_about_line.dart';
import 'package:multigames_client/screens/profile_age_input.dart';
import 'package:multigames_client/screens/profile_avatar_button.dart';
import 'package:multigames_client/screens/profile_edit_back.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/latin_login_input_formatter.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/avatar_crop_dialog.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// Готовый набор аватаров (иконки).
const List<IconData> _presetAvatarIcons = [
  Icons.face_rounded, // лицо нейтральное
  Icons.face_2_rounded, // длинные волосы (ж)
  Icons.face_3_rounded, // вариант (м)
  Icons.face_4_rounded, // с усами (м)
  Icons.face_5_rounded, // с очками
  Icons.face_6_rounded, // вариант (ж)
  Icons.man_rounded, // мужчина
  Icons.woman_rounded, // женщина
  Icons.elderly_rounded, // пожилой м
  Icons.elderly_woman_rounded, // пожилая ж
  Icons.person_rounded, // нейтральный силуэт
  Icons.child_care_rounded, // ребёнок
];

/// Декодирование base64 в отдельном isolate, чтобы не блокировать UI.
Uint8List _decodeBase64Isolate(String s) => base64Decode(s);

final Map<int, Uint8List> _base64AvatarCache = {};


void _putAvatarCache(int key, Uint8List bytes) {
  _base64AvatarCache.remove(key);
  _base64AvatarCache[key] = bytes;
  const maxEntries = 120;
  if (_base64AvatarCache.length > maxEntries) {
    _base64AvatarCache.remove(_base64AvatarCache.keys.first);
  }
}

/// Аватар с отложенной подгрузкой base64 (без подвисания при открытии/закрытии формы).
class _AsyncAvatarImage extends StatefulWidget {
  const _AsyncAvatarImage({
    required this.avatarKind,
    required this.avatarValue,
    required this.letter,
  });

  final AvatarKind avatarKind;
  final String? avatarValue;
  final String letter;

  @override
  State<_AsyncAvatarImage> createState() => _AsyncAvatarImageState();
}

class _AsyncAvatarImageState extends State<_AsyncAvatarImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decodeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _AsyncAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarValue != widget.avatarValue) _decodeIfNeeded();
  }

  void _decodeIfNeeded() {
    if (widget.avatarKind != AvatarKind.file ||
        widget.avatarValue == null ||
        !widget.avatarValue!.startsWith('base64,')) {
      if (_bytes != null) setState(() => _bytes = null);
      return;
    }
    final v = widget.avatarValue!;
    final key = Object.hash(v.hashCode, v.length);
    final cached = _base64AvatarCache[key];
    if (cached != null) {
      if (_bytes != cached) setState(() => _bytes = cached);
      return;
    }
    setState(() => _bytes = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      compute<String, Uint8List>(_decodeBase64Isolate, v.substring(7))
          .then((bytes) {
        if (!mounted) return;
        _putAvatarCache(key, bytes);
        setState(() => _bytes = bytes);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.avatarKind == AvatarKind.file &&
        widget.avatarValue != null &&
        widget.avatarValue!.isNotEmpty) {
      if (widget.avatarValue!.startsWith('base64,')) {
        if (_bytes != null) {
          return CircleAvatar(
            radius: 40,
            backgroundImage: MemoryImage(_bytes!),
          );
        }
        return _letterAvatar();
      }
      final provider = imageProviderForAvatarPath(widget.avatarValue!);
      if (provider != null) {
        return CircleAvatar(
          radius: 40,
          backgroundImage: provider,
        );
      }
    }
    if (widget.avatarKind == AvatarKind.preset && widget.avatarValue != null) {
      final index = int.tryParse(widget.avatarValue!);
      if (index != null && index >= 0 && index < _presetAvatarIcons.length) {
        return CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.accentSoft,
          child: Icon(
            _presetAvatarIcons[index],
            size: 40,
            color: AppColors.accentStart,
          ),
        );
      }
    }
    return _letterAvatar();
  }

  Widget _letterAvatar() {
    final letter = widget.letter.isEmpty
        ? '?'
        : widget.letter.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.accentStart,
        ),
      ),
    );
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isClosing = false;
  bool _focusAboutOnEdit = false;
  int _editBackTick = 0;
  ProfileExtra? _lastProfileExtra;
  final _cardKey = GlobalKey();
  final _displayNameController = TextEditingController();
  final _displayNameFocus = FocusNode();

  static const _closeDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mobileToolbarLeadingProvider.notifier).state = null;
    });
  }

  void _onTapOutsideCard(PointerDownEvent e) {
    if (!_isEditing || _isClosing) return;
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final bounds =
        Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height);
    if (!bounds.contains(e.position)) _startClosing();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayNameFocus.dispose();
    super.dispose();
  }

  void _startEditing(
    String currentName,
    ProfileExtra? extra, {
    bool focusAbout = false,
  }) {
    _displayNameController.text = currentName;
    _displayNameController.selection =
        TextSelection.collapsed(offset: currentName.length);
    setState(() {
      _focusAboutOnEdit = focusAbout;
      _isEditing = true;
    });
  }

  void _startClosing() {
    setState(() => _isClosing = true);
    Future.delayed(_closeDuration, () {
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isClosing = false;
        });
      }
    });
  }

  void _cancelEditing() {
    // На мобиле закрываем сразу — иначе свайп/назад «не срабатывает» 280мс.
    if (isNarrow(context)) {
      _exitEditingImmediate();
      return;
    }
    _startClosing();
  }

  Future<void> _saveProfile(String displayName, ProfileExtra extra) async {
    await ref.read(authStateProvider.notifier).updateProfile(
          displayName: displayName,
          extra: extra,
        );
    ref.invalidate(achievementsListProvider);
    ref.invalidate(achievementsUnclaimedCountProvider);
    if (mounted) _startClosing();
  }

  void _exitEditingImmediate() {
    if (!_isEditing && !_isClosing) return;
    setState(() {
      _isEditing = false;
      _isClosing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isNarrow(context);
    final path = ref.watch(currentRoutePathProvider);
    // Ушли с вкладки профиля — сбрасываем edit (StatefulShell сохраняет State).
    if (path != '/profile' && (_isEditing || _isClosing)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(currentRoutePathProvider) != '/profile') {
          _exitEditingImmediate();
        }
      });
    }
    // Повторный тап по табу «Профиль» внизу — тоже выход из редактирования.
    ref.listen<int>(profileExitEditTickProvider, (_, __) {
      _exitEditingImmediate();
    });

    final phoneLandscape = isPhoneLandscape(context);
    // Portrait — узкая колонка; landscape заполняет ширину экрана.
    final profileMaxWidth = phoneLandscape ? double.infinity : 400.0;

    Widget scrollableBody(Widget child) {
      final framed = Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: profileMaxWidth),
          child: child,
        ),
      );
      // Карточка по центру оставшейся площади (и по вертикали).
      if (mobile) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                phoneLandscape ? 8 : 12,
                phoneLandscape ? 4 : 6,
                phoneLandscape ? 8 : 12,
                phoneLandscape ? 8 : 16,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      (phoneLandscape ? 12 : 22),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: framed,
                ),
              ),
            );
          },
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [framed],
      );
    }

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isEditing) {
          setState(() => _editBackTick++);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // В альбоме с открытым полем щель только у верха экрана — без top inset.
        top: !(ref.watch(profileEditFieldOpenProvider) &&
            isPhoneLandscape(context)),
        // Клавиатура перекрывает home indicator — не добавляем нижний inset.
        bottom: MediaQuery.viewInsetsOf(context).bottom < 80,
        child: ref.watch(authStateProvider).when(
              data: (user) {
                if (user == null) {
                  return scrollableBody(
                    _ProfileEmptyState(
                      key: const ValueKey('empty'),
                      onLogin: () => context.go(
                        appendRedirectQuery(
                          '/login',
                          GoRouterState.of(context)
                              .uri
                              .queryParameters['redirect'],
                        ),
                      ),
                      onRegister: () => context.go(
                        appendRedirectQuery(
                          '/register',
                          GoRouterState.of(context)
                              .uri
                              .queryParameters['redirect'],
                        ),
                      ),
                    ),
                  );
                }

                final extraAsync = ref.watch(profileExtraProvider);
                final profileExtra = extraAsync.valueOrNull ??
                    _lastProfileExtra ??
                    const ProfileExtra();

                Widget buildProfile(ProfileExtra extra) {
                  if (mobile && _isEditing) {
                    // translucent edge: чекбокс у левого края остаётся кликабельным.
                    final editForm = _ProfileEditForm(
                      key: const ValueKey('mobile_edit_form'),
                      user: user,
                      profileExtra: extra,
                      displayNameController: _displayNameController,
                      focusNode: _displayNameFocus,
                      onCancel: _cancelEditing,
                      onSave: _saveProfile,
                      compact: true,
                      focusAboutOnOpen: _focusAboutOnEdit,
                      editBackTick: _editBackTick,
                    );
                    // Landscape: две колонки на всю высоту, без внешней прокрутки.
                    if (phoneLandscape) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                        child: SizedBox.expand(child: editForm),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: SizedBox.expand(child: editForm),
                    );
                  }

                  Widget content = _ProfileContent(
                    key: ValueKey(user.id),
                    cardKey: _cardKey,
                    user: user,
                    profileExtra: extra,
                    isEditing: _isEditing,
                    isClosing: _isClosing,
                    focusAboutOnOpen: _focusAboutOnEdit,
                    displayNameController: _displayNameController,
                    displayNameFocus: _displayNameFocus,
                    onStartEdit: ({bool focusAbout = false}) => _startEditing(
                      user.displayName ?? user.email,
                      extra,
                      focusAbout: focusAbout,
                    ),
                    onCancelEdit: _cancelEditing,
                    onSave: _saveProfile,
                    editBackTick: _editBackTick,
                  );
                  if (_isEditing) {
                    content = Listener(
                      onPointerDown: _onTapOutsideCard,
                      child: content,
                    );
                  }
                  // Landscape: карточка на всю оставшуюся площадь экрана.
                  if (phoneLandscape) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                      child: SizedBox.expand(child: content),
                    );
                  }
                  // Важно: при полном заполнении (о себе + коллекции + чипы)
                  // карточка выше экрана — нужен скролл, а не Center.
                  return scrollableBody(content);
                }

                return extraAsync.when(
                  data: (extra) => buildProfile(extra ?? const ProfileExtra()),
                  loading: () => buildProfile(profileExtra),
                  error: (_, __) => buildProfile(profileExtra),
                );
              },
              loading: () => scrollableBody(
                const _ProfileLoadingState(key: ValueKey('loading')),
              ),
              error: (err, _) => scrollableBody(
                _ProfileErrorState(
                  key: const ValueKey('error'),
                  message:
                      err is AuthException ? err.message : formatUserError(err),
                  onRetry: () => ref.read(authStateProvider.notifier).refresh(),
                ),
              ),
            ),
      ),
    ),
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.short,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MessageBanner(message: message, type: BannerType.error),
          const SizedBox(height: 16),
          AppButton(
            onPressed: onRetry,
            label: context.l10n.commonRetry,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: AnimatedBorderBox(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.profileSignInPrompt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.profileSignInHint,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: onLogin,
              label: context.l10n.loginSubmit,
              expanded: true,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(context.l10n.registerTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    super.key,
    required this.cardKey,
    required this.user,
    required this.profileExtra,
    required this.isEditing,
    required this.isClosing,
    this.focusAboutOnOpen = false,
    this.editBackTick = 0,
    required this.displayNameController,
    required this.displayNameFocus,
    required this.onStartEdit,
    required this.onCancelEdit,
    required this.onSave,
  });

  final Key? cardKey;
  final AuthUser user;
  final ProfileExtra profileExtra;
  final bool isEditing;
  final bool isClosing;
  final bool focusAboutOnOpen;
  final int editBackTick;
  final TextEditingController displayNameController;
  final FocusNode displayNameFocus;
  final void Function({bool focusAbout}) onStartEdit;
  final VoidCallback onCancelEdit;
  final Future<void> Function(String displayName, ProfileExtra extra) onSave;

  @override
  Widget build(BuildContext context) {
    final phoneLandscape = isPhoneLandscape(context);
    final cardMaxWidth = phoneLandscape ? double.infinity : 460.0;
    final card = AnimatedBorderBox(
              key: cardKey,
              expand: phoneLandscape,
              padding: EdgeInsets.symmetric(
                horizontal: phoneLandscape ? 14 : 18,
                vertical: phoneLandscape
                    ? 12
                    : (MediaQuery.sizeOf(context).height < 700 ? 16 : 22),
              ),
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: isEditing
                    ? AnimatedOpacity(
                        key: const ValueKey('edit'),
                        opacity: isClosing ? 0 : 1,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        child: _ProfileEditForm(
                          key: const ValueKey('edit_form'),
                          user: user,
                          profileExtra: profileExtra,
                          displayNameController: displayNameController,
                          focusNode: displayNameFocus,
                          onCancel: onCancelEdit,
                          onSave: onSave,
                          focusAboutOnOpen: focusAboutOnOpen,
                          editBackTick: editBackTick,
                        ),
                      )
                    : _ProfileView(
                        key: const ValueKey('view'),
                        user: user,
                        profileExtra: profileExtra,
                        onEdit: () => onStartEdit(),
                        onEditAbout: () => onStartEdit(focusAbout: true),
                      ),
              ),
    );
    if (phoneLandscape) {
      return SizedBox.expand(
        key: const ValueKey('profile-landscape-card'),
        child: card,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: card,
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({
    super.key,
    required this.user,
    required this.profileExtra,
    required this.onEdit,
    this.onEditAbout,
  });

  final AuthUser user;
  final ProfileExtra profileExtra;
  final VoidCallback onEdit;
  final VoidCallback? onEditAbout;

  String get _displayTitle => user.displayName?.trim().isNotEmpty == true
      ? user.displayName!
      : user.email;

  String get _avatarLetter {
    if (user.displayName?.trim().isNotEmpty == true) {
      return user.displayName!.trim().substring(0, 1).toUpperCase();
    }
    return user.email.trim().isEmpty
        ? '?'
        : user.email.substring(0, 1).toUpperCase();
  }

  Widget _buildAvatar() {
    return _AsyncAvatarImage(
      avatarKind: profileExtra.avatarKind,
      avatarValue: profileExtra.avatarValue,
      letter: _avatarLetter,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(inventoryCapabilitiesProvider).valueOrNull;
    final shortScreen = MediaQuery.sizeOf(context).height < 700;
    final gapAfterAvatar = shortScreen ? 12.0 : 16.0;
    final gapSection = shortScreen ? 12.0 : 14.0;
    final hasFrame = AvatarFrameStyle.resolve(
          code: caps?.frameCode,
          colorHex: caps?.frameColor,
        ) !=
        null;

    final avatar = hasFrame
        ? FramedAvatar(
            size: 80,
            borderWidth: 4.5,
            frameCode: caps?.frameCode,
            frameColor: caps?.frameColor,
            child: _buildAvatar(),
          )
        : Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.accentStart, AppColors.accentEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
              ),
              child: _buildAvatar(),
            ),
          );

    final phoneLandscape = isPhoneLandscape(context);
    final identity = <Widget>[
      TappableProfileAvatar(
        userId: user.id,
        canManage: true,
        avatarKind: profileExtra.avatarKind.name,
        avatarValue: profileExtra.avatarValue,
        letter: _avatarLetter,
        child: avatar,
      ),
      SizedBox(height: gapAfterAvatar),
      Text(
        _displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
        textAlign: TextAlign.center,
      ),
      if (user.displayName?.trim().isNotEmpty == true) ...[
        const SizedBox(height: 2),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
      if (profileExtra.age != null ||
          (profileExtra.gender != null &&
              profileExtra.gender!.isNotEmpty)) ...[
        SizedBox(height: gapSection),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (profileExtra.age != null)
              _ProfileInfoChip(
                icon: Icons.cake_outlined,
                label: context.l10n.profileAgeYears(profileExtra.age!),
              ),
            if (profileExtra.gender != null &&
                profileExtra.gender!.isNotEmpty)
              _ProfileInfoChip(
                icon: isFemaleGender(profileExtra.gender)
                    ? Icons.female_rounded
                    : Icons.male_rounded,
                label: localizeGender(profileExtra.gender, context.l10n),
              ),
          ],
        ),
      ],
    ];

    final hasAbout =
        profileExtra.about != null && profileExtra.about!.trim().isNotEmpty;
    final aboutBlock = hasAbout
        ? Material(
            color: AppColors.accentSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onEditAbout ?? onEdit,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: AboutOneLineText(
                  text: profileExtra.about!.trim(),
                  maxLines: 8,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          )
        : null;

    final collectionsBlock = Builder(
      builder: (context) {
        final inv = ref.watch(inventoryListProvider).valueOrNull ??
            const <InventoryItem>[];
        final collections = inv
            .where((e) =>
                e.kind == 'collection' && !isRetiredCollectionItem(e.code))
            .toList();
        if (collections.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!phoneLandscape) SizedBox(height: gapSection + 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.profileCollections,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CollectionShowcaseGrid(items: collections),
          ],
        );
      },
    );

    final editButton = OutlinedButton.icon(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(
        context.l10n.profileEdit,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentStart,
        padding: EdgeInsets.symmetric(
          horizontal: 22,
          vertical: shortScreen ? 11 : 13,
        ),
        side: BorderSide(
          color: AppColors.accentStart.withValues(alpha: 0.6),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    if (phoneLandscape) {
      return Row(
        key: const ValueKey('profile-view-landscape'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: identity,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (aboutBlock != null) ...[
                  aboutBlock,
                  SizedBox(height: gapSection),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: collectionsBlock,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: editButton,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...identity,
        if (aboutBlock != null) ...[
          SizedBox(height: gapSection),
          aboutBlock,
        ],
        collectionsBlock,
        SizedBox(height: shortScreen ? 16 : 20),
        editButton,
      ],
    );
  }

}

class _ProfileInfoChip extends StatelessWidget {
  const _ProfileInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentStart.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.accentStart),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditForm extends ConsumerStatefulWidget {
  const _ProfileEditForm({
    super.key,
    required this.user,
    required this.profileExtra,
    required this.displayNameController,
    required this.focusNode,
    required this.onCancel,
    required this.onSave,
    this.compact = false,
    this.focusAboutOnOpen = false,
    this.editBackTick = 0,
  });

  final AuthUser user;
  final ProfileExtra profileExtra;
  final TextEditingController displayNameController;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final Future<void> Function(String displayName, ProfileExtra extra) onSave;
  final bool compact;
  final bool focusAboutOnOpen;
  final int editBackTick;

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditFormState();
}

/// Только цифры, макс. 3, не больше 111.
final _ageFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(3),
  const ProfileAgeRangeFormatter(),
];

/// Без управляющих символов и обратного слэша, макс. 100 (о себе).
final _aboutFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[^\x00-\x1f\\]')),
  LengthLimitingTextInputFormatter(100),
];

class _ProfileEditFormState extends ConsumerState<_ProfileEditForm> {
  bool _isSaving = false;
  bool _isAvatarProcessing = false;
  bool _galleryDirty = false;
  String? _initialGallerySignature;
  String _gallerySignature = '';
  ProfileEditField _activeField = ProfileEditField.none;
  String? _ageError;
  String? _saveError;
  DateTime? _lastLatinOnlyToastAt;
  late String _lastAboutText;
  late TextEditingController _ageController;
  late TextEditingController _aboutController;
  late FocusNode _ageFocus;
  late FocusNode _aboutFocus;
  late String? _gender;
  late AvatarKind _avatarKind;
  late String? _avatarValue;
  late bool _showStatsToOthers;
  late String _initialDisplayName;
  ProfileExtra? _initialExtra;
  String? _avatarCacheKey;
  Widget? _cachedAvatarWidget;

  @override
  void initState() {
    super.initState();
    _initialDisplayName = widget.displayNameController.text;
    _initialExtra = widget.profileExtra;
    widget.displayNameController.addListener(_onFieldsChanged);
    widget.focusNode.addListener(_onNameFocusChanged);
    _ageController = TextEditingController(
      text: widget.profileExtra.age?.toString() ?? '',
    );
    _aboutController = TextEditingController(
      text: widget.profileExtra.about ?? '',
    );
    _lastAboutText = _aboutController.text;
    _ageFocus = FocusNode();
    _aboutFocus = FocusNode();
    _ageFocus.addListener(_onAgeFocusChanged);
    _aboutFocus.addListener(_onAboutFocusChanged);
    _ageController.addListener(_onAgeTextChanged);
    _aboutController.addListener(_onAboutTextChanged);
    _gender = widget.profileExtra.gender;
    _avatarKind = widget.profileExtra.avatarKind;
    _avatarValue = widget.profileExtra.avatarValue;
    _showStatsToOthers = widget.profileExtra.showStatsToOthers;
    if (widget.focusAboutOnOpen) {
      _activeField = ProfileEditField.about;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _aboutFocus.requestFocus();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFieldOpenProvider();
    });
  }

  @override
  void didUpdateWidget(covariant _ProfileEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editBackTick != oldWidget.editBackTick &&
        widget.editBackTick > oldWidget.editBackTick) {
      _handleEditBack();
    }
  }

  bool get _fieldIsOpen => profileEditFieldActive(_activeField);

  void _leaveActiveField() {
    widget.focusNode.unfocus();
    _ageFocus.unfocus();
    _aboutFocus.unfocus();
    if (_activeField != ProfileEditField.none && mounted) {
      setState(() => _activeField = ProfileEditField.none);
    }
    _syncFieldOpenProvider();
  }

  void _syncFieldOpenProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _fieldIsOpen;
      if (ref.read(profileEditFieldOpenProvider) != next) {
        ref.read(profileEditFieldOpenProvider.notifier).state = next;
      }
    });
  }

  void _requestFieldFocus(ProfileEditField field) {
    if (!mounted) return;
    switch (field) {
      case ProfileEditField.name:
        widget.focusNode.requestFocus();
      case ProfileEditField.age:
        _ageFocus.requestFocus();
      case ProfileEditField.about:
        _aboutFocus.requestFocus();
      case ProfileEditField.none:
        break;
    }
  }

  void _openField(ProfileEditField field) {
    if (_isSaving || field == ProfileEditField.none) return;
    if (_activeField != field) {
      setState(() => _activeField = field);
    }
    _syncFieldOpenProvider();
    // Сразу и после кадра: в альбоме IME часто не открывается с первого раза.
    _requestFieldFocus(field);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFieldFocus(field);
    });
  }

  void _openAboutField() => _openField(ProfileEditField.about);

  void _onEmptyEditorTap() {
    if (shouldUnfocusFieldOnEmptyTap(fieldFocused: _fieldIsOpen)) {
      _leaveActiveField();
    }
  }

  bool _handleEditBack() {
    final action = profileEditBackAction(fieldFocused: _fieldIsOpen);
    if (action == ProfileEditBackAction.stayInEditor) {
      _leaveActiveField();
      return true;
    }
    widget.onCancel();
    return true;
  }

  void _syncActiveField(ProfileEditField field) {
    if (!mounted || !widget.compact) return;
    if (shouldClearFieldOpenOnFocusLost()) return;
    if (_activeField != field) {
      setState(() => _activeField = field);
    }
    _syncFieldOpenProvider();
  }

  void _onNameFocusChanged() {
    if (widget.focusNode.hasFocus) _syncActiveField(ProfileEditField.name);
  }

  void _onAgeFocusChanged() {
    if (_ageFocus.hasFocus) _syncActiveField(ProfileEditField.age);
  }

  void _onAboutFocusChanged() {
    if (!mounted) return;
    // Web Back сначала снимает фокус — не закрываем поле по blur.
    if (_aboutFocus.hasFocus) {
      if (widget.compact) {
        _syncActiveField(ProfileEditField.about);
      } else if (_activeField != ProfileEditField.about) {
        setState(() => _activeField = ProfileEditField.about);
      }
    }
  }

  void _onAboutTextChanged() {
    final text = _aboutController.text;
    // Игнор смены selection (повторный тап) — только реальный текст.
    if (text == _lastAboutText) return;
    _lastAboutText = text;
    _onFieldsChanged();
  }

  ProfileExtra get _effectiveInitialExtra =>
      _initialExtra ?? widget.profileExtra;

  void _onFieldsChanged() => setState(() {
        _saveError = null;
      });

  void _onAgeTextChanged() {
    if (!mounted) return;
    setState(() {
      _ageError = profileAgeIsInvalid(_ageController.text)
          ? context.l10n.profileAgeInvalid
          : null;
      _saveError = null;
    });
  }

  /// Только латиница, макс. 10 символов (логин).
  List<TextInputFormatter> get _displayNameFormatters => [
        LatinLoginInputFormatter(onRejected: _showLatinOnlyToast),
        LengthLimitingTextInputFormatter(10),
      ];

  void _showLatinOnlyToast() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastLatinOnlyToastAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastLatinOnlyToastAt = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.profileNameLatinOnly,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool get _hasChanges {
    final name = widget.displayNameController.text.trim();
    if (name != _initialDisplayName.trim()) return true;
    final initial = _effectiveInitialExtra;
    final ageStr = _ageController.text.trim();
    final initialAge = initial.age;
    if ((initialAge == null && ageStr.isNotEmpty) ||
        (initialAge != null && ageStr != initialAge.toString())) {
      return true;
    }
    if (_gender != initial.gender) return true;
    final about = _aboutController.text.trim();
    final initialAbout = initial.about ?? '';
    if (about != initialAbout) return true;
    if (_avatarKind != initial.avatarKind) return true;
    if ((_avatarValue ?? '') != (initial.avatarValue ?? '')) return true;
    if (_showStatsToOthers != initial.showStatsToOthers) return true;
    if (_galleryDirty) return true;
    if (_initialGallerySignature != null &&
        _gallerySignature != _initialGallerySignature) {
      return true;
    }
    return false;
  }

  void _onGalleryMutated() {
    if (_galleryDirty) return;
    setState(() => _galleryDirty = true);
  }

  void _onGalleryPhotosChanged(List<ProfilePhotoMeta> photos) {
    final next = profilePhotosSignature(photos);
    if (_initialGallerySignature == null) {
      _initialGallerySignature = next;
      _gallerySignature = next;
      return;
    }
    if (next == _gallerySignature) return;
    setState(() => _gallerySignature = next);
  }

  @override
  void dispose() {
    try {
      ref.read(profileEditFieldOpenProvider.notifier).state = false;
    } catch (_) {}
    widget.displayNameController.removeListener(_onFieldsChanged);
    widget.focusNode.removeListener(_onNameFocusChanged);
    _ageController.removeListener(_onAgeTextChanged);
    _aboutController.removeListener(_onAboutTextChanged);
    _ageFocus.removeListener(_onAgeFocusChanged);
    _aboutFocus.removeListener(_onAboutFocusChanged);
    _ageFocus.dispose();
    _aboutFocus.dispose();
    _ageController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Widget _buildCurrentAvatar() {
    final name = widget.displayNameController.text.trim();
    final cacheKey = '$_avatarKind|$_avatarValue|$name';
    if (_avatarCacheKey == cacheKey && _cachedAvatarWidget != null) {
      return _cachedAvatarWidget!;
    }
    Widget avatarWidget;
    if (_avatarKind == AvatarKind.file &&
        _avatarValue != null &&
        _avatarValue!.isNotEmpty) {
      final v = _avatarValue!;
      if (v.startsWith('base64,')) {
        avatarWidget = _AsyncAvatarImage(
          avatarKind: _avatarKind,
          avatarValue: _avatarValue,
          letter: name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        );
      } else {
        final provider = imageProviderForAvatarPath(v);
        if (provider != null) {
          avatarWidget = CircleAvatar(
            radius: 40,
            backgroundImage: provider,
          );
        } else {
          avatarWidget = _buildLetterAvatar(name);
        }
      }
    } else if (_avatarKind == AvatarKind.preset && _avatarValue != null) {
      final index = int.tryParse(_avatarValue!);
      if (index != null && index >= 0 && index < _presetAvatarIcons.length) {
        avatarWidget = CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.accentSoft,
          child: Icon(
            _presetAvatarIcons[index],
            size: 40,
            color: AppColors.accentStart,
          ),
        );
      } else {
        avatarWidget = _buildLetterAvatar(name);
      }
    } else {
      avatarWidget = _buildLetterAvatar(name);
    }
    _avatarCacheKey = cacheKey;
    _cachedAvatarWidget = avatarWidget;
    return avatarWidget;
  }

  Widget _buildLetterAvatar(String name) {
    final displayName = name.isNotEmpty ? name : (widget.user.email);
    final letter =
        displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.accentSoft,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.accentStart,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_isAvatarProcessing) return;
    setState(() => _isAvatarProcessing = true);
    try {
      Uint8List rawBytes;
      if (kIsWeb) {
        final webBytes = await pickImageBytesWeb();
        if (webBytes == null || !mounted) return;
        rawBytes = webBytes;
      } else {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 88,
        );
        if (xFile == null || !mounted) return;
        rawBytes = await xFile.readAsBytes();
      }

      if (!mounted) return;
      final editedBytes = await _openAvatarEditor(rawBytes);
      if (!mounted || editedBytes == null || editedBytes.isEmpty) return;

      final compactAvatarValue = await buildCompactAvatarValue(editedBytes);
      if (!mounted) return;

      setState(() {
        if (compactAvatarValue == null) {
          // Если даже после ресайза аватар всё ещё слишком тяжёлый — используем лёгкую иконку.
          final presetIndex =
              widget.user.id.hashCode.abs() % _presetAvatarIcons.length;
          _avatarKind = AvatarKind.preset;
          _avatarValue = presetIndex.toString();
        } else {
          _avatarKind = AvatarKind.file;
          _avatarValue = compactAvatarValue;
        }
      });
      if (compactAvatarValue != null) {
        try {
          final saved = await saveOriginalPhotoToGallery(
            ref: ref,
            userId: widget.user.id,
            rawBytes: rawBytes,
          );
          if (saved && mounted) _onGalleryMutated();
        } catch (_) {
          // Круглый аватар уже выбран; оригинал в галерею — по возможности.
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAvatarProcessing = false);
      }
    }
  }

  Future<Uint8List?> _openAvatarEditor(Uint8List sourceBytes) async {
    return showAvatarCropDialog(context: context, sourceBytes: sourceBytes);
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = widget.displayNameController.text.trim();
    final ageRaw = _ageController.text.trim();
    final age = ageRaw.isEmpty ? null : int.tryParse(ageRaw);
    if (age != null && (age < 1 || age > 111)) {
      setState(() => _ageError = context.l10n.profileAgeInvalid);
      return;
    }
    final extra = ProfileExtra(
      age: age,
      gender: _gender,
      about: _aboutController.text.trim().isEmpty
          ? null
          : _aboutController.text.trim(),
      avatarKind: _avatarKind,
      avatarValue: _avatarValue,
      showStatsToOthers: _showStatsToOthers,
    );
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(name, extra);
      if (mounted) {
        _initialDisplayName = name;
        _initialExtra = extra;
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError =
              formatUserError(e, fallback: context.l10n.profileSaveFailed);
        });
      }
    }
  }

  static const List<String> _genderOptions = [
    kGenderMaleApi,
    kGenderFemaleApi,
  ];

  void _openGenderMenu() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _genderOptions.map((value) {
                final selected = _gender == value;
                final label = localizeGender(value, context.l10n);
                return InkWell(
                  onTap: () {
                    setState(() => _gender = value);
                    Navigator.of(ctx).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.commonBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: _isSaving ? null : _handleEditBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutPreview({Key? key}) {
    final text = _aboutController.text.trim();
    final empty = text.isEmpty;
    return Material(
      key: key,
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        onTap: _isSaving ? null : _openAboutField,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.accentSoft),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.commonAboutMe,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AboutOneLineText(
                      text: empty ? context.l10n.profileAboutHint : text,
                      maxLines: 8,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        color: empty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutEditorField({
    Key? key,
    bool expand = false,
    bool landscapeStrip = false,
  }) {
    final strip = landscapeStrip;
    return TextFormField(
      key: key,
      autofocus: true,
      controller: _aboutController,
      focusNode: _aboutFocus,
      inputFormatters: _aboutFormatters,
      textAlignVertical:
          strip ? TextAlignVertical.center : TextAlignVertical.top,
      expands: expand && !strip,
      maxLines: (expand && !strip) ? null : (strip ? profileEditStripMaxLines() : 5),
      minLines: (expand && !strip) ? null : 1,
      maxLength: 100,
      keyboardType: strip ? TextInputType.text : TextInputType.multiline,
      textInputAction: strip ? TextInputAction.done : TextInputAction.newline,
      enableIMEPersonalizedLearning: false,
      textCapitalization: TextCapitalization.sentences,
      scrollPadding: const EdgeInsets.only(bottom: 24),
      style: const TextStyle(
        fontSize: 16,
        height: 1.3,
      ),
      decoration: InputDecoration(
        labelText: strip ? null : context.l10n.commonAboutMe,
        hintText: context.l10n.profileAboutHint,
        alignLabelWithHint: !strip,
        isDense: strip,
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: strip
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : const EdgeInsets.fromLTRB(12, 16, 12, 16),
        prefixIcon: strip ? null : const Icon(Icons.info_outline_rounded),
        counterText: '',
      ),
      onFieldSubmitted: strip ? (_) => _leaveActiveField() : null,
    );
  }

  Widget _buildNameEditorField({
    Key? key,
    bool expand = false,
    bool landscapeStrip = false,
  }) {
    final strip = landscapeStrip;
    return TextFormField(
      key: key,
      autofocus: true,
      controller: widget.displayNameController,
      focusNode: widget.focusNode,
      inputFormatters: _displayNameFormatters,
      textAlignVertical:
          strip ? TextAlignVertical.center : TextAlignVertical.top,
      expands: expand && !strip,
      maxLines: (expand && !strip) ? null : profileEditStripMaxLines(),
      minLines: (expand && !strip) ? null : 1,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      enableIMEPersonalizedLearning: false,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      scrollPadding: const EdgeInsets.only(bottom: 24),
      style: const TextStyle(
        fontSize: 16,
        height: 1.3,
      ),
      decoration: InputDecoration(
        labelText: strip ? null : context.l10n.registerNameLabel,
        hintText: context.l10n.profileNameHint,
        alignLabelWithHint: !strip,
        isDense: strip,
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: strip
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : const EdgeInsets.fromLTRB(12, 16, 12, 16),
        prefixIcon: strip ? null : const Icon(Icons.person_outline_rounded),
      ),
      onFieldSubmitted: (_) => _leaveActiveField(),
    );
  }

  Widget _buildAgeEditorField({
    Key? key,
    bool expand = false,
    bool landscapeStrip = false,
  }) {
    final strip = landscapeStrip;
    return TextFormField(
      key: key,
      autofocus: true,
      controller: _ageController,
      focusNode: _ageFocus,
      inputFormatters: _ageFormatters,
      textAlignVertical:
          strip ? TextAlignVertical.center : TextAlignVertical.top,
      expands: expand && !strip,
      maxLines: (expand && !strip) ? null : profileEditStripMaxLines(),
      minLines: (expand && !strip) ? null : 1,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      enableIMEPersonalizedLearning: false,
      scrollPadding: const EdgeInsets.only(bottom: 24),
      style: const TextStyle(
        fontSize: 16,
        height: 1.3,
      ),
      decoration: InputDecoration(
        labelText: strip ? null : context.l10n.profileAge,
        hintText: context.l10n.profileAgeHint,
        alignLabelWithHint: !strip,
        isDense: strip,
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: strip
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : const EdgeInsets.fromLTRB(12, 16, 12, 16),
        prefixIcon: strip ? null : const Icon(Icons.cake_outlined),
        errorText: _ageError,
      ),
      onFieldSubmitted: (_) => _leaveActiveField(),
    );
  }

  Widget _buildActiveFieldEditor({
    Key? key,
    bool expand = true,
    bool landscapeStrip = false,
  }) {
    switch (_activeField) {
      case ProfileEditField.name:
        return _buildNameEditorField(
          key: key ?? const ValueKey('compact_display_name'),
          expand: expand,
          landscapeStrip: landscapeStrip,
        );
      case ProfileEditField.age:
        return _buildAgeEditorField(
          key: key ?? const ValueKey('compact_age'),
          expand: expand,
          landscapeStrip: landscapeStrip,
        );
      case ProfileEditField.about:
        return _buildAboutEditorField(
          key: key ?? const ValueKey('compact_about'),
          expand: expand,
          landscapeStrip: landscapeStrip,
        );
      case ProfileEditField.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildKeyboardInputStrip(BuildContext context, {bool compact = false}) {
    return Material(
      color: AppColors.surfaceCard,
      elevation: 6,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Padding(
        padding: EdgeInsets.fromLTRB(2, compact ? 2 : 4, 8, compact ? 2 : 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              tooltip: context.l10n.commonBack,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: compact ? 36 : 40,
                minHeight: compact ? 36 : 40,
              ),
              onPressed: _isSaving ? null : _handleEditBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
            ),
            Expanded(
              child: _buildActiveFieldEditor(
                expand: false,
                landscapeStrip: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldPreview({
    required Key key,
    required IconData icon,
    required String label,
    required String text,
    required ProfileEditField field,
    String? errorText,
  }) {
    return Material(
      key: key,
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        onTap: _isSaving ? null : () => _openField(field),
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            errorText: errorText,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSaveButton() {
    return AppButton(
      onPressed: (_isSaving || !_hasChanges || _ageError != null)
          ? null
          : _submit,
      label: context.l10n.commonSave,
      isLoading: _isSaving,
      expanded: true,
    );
  }

  Widget _buildCompactNameAgeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldPreview(
          key: const ValueKey('compact_display_name'),
          icon: Icons.person_outline_rounded,
          label: context.l10n.registerNameLabel,
          text: widget.displayNameController.text.trim(),
          field: ProfileEditField.name,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFieldPreview(
                key: const ValueKey('compact_age'),
                icon: Icons.cake_outlined,
                label: context.l10n.profileAge,
                text: _ageController.text.trim(),
                field: ProfileEditField.age,
                errorText: _ageError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _openGenderMenu,
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.l10n.profileGender,
                    prefixIcon: const Icon(Icons.wc_rounded),
                  ),
                  child: Text(
                    localizeGender(_gender, context.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactEditor(BuildContext context) {
    final fieldTyping = _fieldIsOpen;
    final phoneLand = isPhoneLandscape(context);
    final layout = profileEditCompactLayout(
      phoneLandscape: phoneLand,
      fieldTypingActive: fieldTyping,
    );
    // На web resizeToAvoidBottomInset выключен — поднимаем поле над клавиатурой.
    // На нативе Scaffold уже съел inset, здесь будет 0.
    final keyboardPad = sanitizeKeyboardInset(
      inset: MediaQuery.viewInsetsOf(context).bottom,
      viewportHeight: MediaQuery.sizeOf(context).height,
    );
    // Портрет: поле открыто, но форма остаётся на экране — иначе над полоской
    // ввода пустота и непонятно, что вообще редактируешь.
    final keepFormBehindStrip = profileEditKeepFormWithStrip(
      phoneLandscape: phoneLand,
      fieldTypingActive: fieldTyping,
    );

    final aboutField =
        _buildAboutPreview(key: const ValueKey('compact_about_preview'));

    final avatarAndMeta = Visibility(
      visible: !fieldTyping || keepFormBehindStrip,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: phoneLand ? 64 : 82,
            child: Row(
              children: [
                SizedBox(
                  width: phoneLand ? 56 : 76,
                  child: Center(child: _buildCurrentAvatar()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatarIcons.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 5),
                    itemBuilder: (context, index) {
                      final selected = _avatarKind == AvatarKind.preset &&
                          _avatarValue == index.toString();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _avatarKind = AvatarKind.preset;
                          _avatarValue = index.toString();
                        }),
                        child: AnimatedContainer(
                          duration: AppDurations.short,
                          width: phoneLand ? 40 : 48,
                          height: phoneLand ? 40 : 48,
                          margin: EdgeInsets.symmetric(
                            vertical: phoneLand ? 12 : 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.accentStart
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _presetAvatarIcons[index],
                            color: AppColors.accentStart,
                            size: phoneLand ? 22 : 25,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: phoneLand ? 10 : 16),
          _buildCompactNameAgeRow(),
          SizedBox(height: phoneLand ? 8 : 12),
          _buildShowStatsCheckbox(),
          SizedBox(height: phoneLand ? 8 : 12),
        ],
      ),
    );

    final galleryAndPhoto = Visibility(
      visible: !fieldTyping || keepFormBehindStrip,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: phoneLand ? 8 : 12),
          ProfileGalleryEditSlots(
            userId: widget.user.id,
            enabled: !_isSaving,
            compact: true,
            onPhotosChanged: _onGalleryPhotosChanged,
            onMutated: _onGalleryMutated,
          ),
          SizedBox(height: phoneLand ? 8 : 12),
          OutlinedButton.icon(
            onPressed: (_isSaving || _isAvatarProcessing) ? null : _pickImage,
            icon: _isAvatarProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined, size: 19),
            label: Text(
              profileAvatarActionLabel(
                processing: _isAvatarProcessing,
                processingLabel: context.l10n.profileProcessingPhoto,
                changeLabel: context.l10n.profileChangePhoto,
              ),
            ),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            MessageBanner(
              message: _saveError!,
              type: BannerType.error,
            ),
          ],
        ],
      ),
    );

    // Portrait: поля скроллятся, «Сохранить» внизу.
    // Landscape: две колонки. Активное поле — на весь экран (как «О себе»),
    // переключение только по тапу, не по viewInsets — иначе iPhone теряет фокус.
    final Widget form;
    switch (layout) {
      case ProfileEditCompactLayout.singleField:
        final land = phoneLand;
        if (land) {
          form = Align(
            alignment: profileEditStripAlignment(phoneLandscape: land),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.viewPaddingOf(context).top,
              ),
              child: _buildKeyboardInputStrip(context, compact: true),
            ),
          );
          break;
        }
        form = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCompactHeader(context),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    avatarAndMeta,
                    aboutField,
                    galleryAndPhoto,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(bottom: keyboardPad),
              child: _buildKeyboardInputStrip(context),
            ),
          ],
        );
      case ProfileEditCompactLayout.landscapeColumns:
        form = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 8),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompactHeader(context),
                    const SizedBox(height: 12),
                    avatarAndMeta,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 8),
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          aboutField,
                          galleryAndPhoto,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCompactSaveButton(),
                ],
              ),
            ),
          ],
        );
      case ProfileEditCompactLayout.portraitForm:
        form = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCompactHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    avatarAndMeta,
                    aboutField,
                    galleryAndPhoto,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactSaveButton(),
          ],
        );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleEditBack();
      },
      child: SwipeBackScope(
        onBack: _handleEditBack,
        opaqueEdge: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: fieldTyping ? null : _onEmptyEditorTap,
          child: form,
        ),
      ),
    );
  }

  Widget _buildShowStatsCheckbox() {
    // Кликается только квадрат (не подпись). Выровнен по левому краю как поля.
    final checked = _showStatsToOthers;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showStatsToOthers = !checked),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.accentStart : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: checked
                          ? AppColors.accentStart
                          : AppColors.textSecondary.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.profileShowStats,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactEditor(context);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleEditBack();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onEmptyEditorTap,
        child: Stack(
      clipBehavior: Clip.none,
      children: [
        SelectionArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                TextFormField(
                  controller: widget.displayNameController,
                  focusNode: widget.focusNode,
                  inputFormatters: _displayNameFormatters,
                  decoration: InputDecoration(
                    labelText: context.l10n.registerNameLabel,
                    hintText: context.l10n.profileNameHint,
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  inputFormatters: _ageFormatters,
                  decoration: InputDecoration(
                    labelText: context.l10n.profileAge,
                    hintText: context.l10n.profileAgeHint,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    errorText: _ageError,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _openGenderMenu,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.profileGender,
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(localizeGender(_gender, context.l10n)),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildShowStatsCheckbox(),
                const SizedBox(height: 12),
                _activeField == ProfileEditField.about
                    ? _buildAboutEditorField()
                    : _buildAboutPreview(),
                const SizedBox(height: 20),
                Text(
                  context.l10n.profileAvatar,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCurrentAvatar(),
                      if (_isAvatarProcessing)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: Color(0x8A000000),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...List.generate(_presetAvatarIcons.length, (index) {
                      final selected = _avatarKind == AvatarKind.preset &&
                          _avatarValue == index.toString();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _avatarKind = AvatarKind.preset;
                          _avatarValue = index.toString();
                        }),
                        child: AnimatedContainer(
                          duration: AppDurations.short,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.accentStart
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.accentSoft,
                            child: Icon(
                              _presetAvatarIcons[index],
                              color: AppColors.accentStart,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                ProfileGalleryEditSlots(
                  userId: widget.user.id,
                  enabled: !_isSaving,
                  onPhotosChanged: _onGalleryPhotosChanged,
                  onMutated: _onGalleryMutated,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      (_isSaving || _isAvatarProcessing) ? null : _pickImage,
                  icon: _isAvatarProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.change_circle_outlined, size: 20),
                  label: Text(
                    profileAvatarActionLabel(
                      processing: _isAvatarProcessing,
                      processingLabel: context.l10n.profileProcessingPhoto,
                      changeLabel: context.l10n.profileChangePhoto,
                    ),
                  ),
                ),
                if (_saveError != null) ...[
                  MessageBanner(message: _saveError!, type: BannerType.error),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 24),
                AppButton(
                  onPressed: (_isSaving || !_hasChanges || _ageError != null)
                      ? null
                      : _submit,
                  label: context.l10n.commonSave,
                  isLoading: _isSaving,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            onPressed: _isSaving ? null : widget.onCancel,
            icon: const Icon(Icons.close),
            color: Colors.red,
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
        ),
      ),
    );
  }
}

