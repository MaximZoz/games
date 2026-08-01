import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/profile_extra.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/head_to_head_section.dart';
import 'package:multigames_client/screens/game_stats_screen.dart';
import 'package:multigames_client/screens/pick_image_web.dart';
import 'package:multigames_client/screens/profile_avatar_storage.dart';
import 'package:multigames_client/shop/collection_widgets.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/latin_login_input_formatter.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/ui/responsive.dart';
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

const int _avatarMaxSidePx = 96;
const int _avatarStorageLimitBytes = 45 * 1024;

Future<Uint8List?> _compactAvatarBytes(Uint8List source) async {
  ui.Codec? probeCodec;
  ui.Image? probeImage;
  try {
    probeCodec = await ui.instantiateImageCodec(source);
    final probeFrame = await probeCodec.getNextFrame();
    probeImage = probeFrame.image;

    final width = probeImage.width;
    final height = probeImage.height;
    final longestSide = math.max(width, height);
    final scale =
        longestSide > _avatarMaxSidePx ? _avatarMaxSidePx / longestSide : 1.0;

    final targetWidth = math.max(1, (width * scale).round());
    final targetHeight = math.max(1, (height * scale).round());

    final codec = await ui.instantiateImageCodec(
      source,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();

    if (bytes == null) return null;
    return bytes.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    probeImage?.dispose();
    probeCodec?.dispose();
  }
}

Future<String?> _buildCompactAvatarValue(Uint8List source) async {
  final compact = await _compactAvatarBytes(source);
  final bytes = compact ?? source;
  if (bytes.lengthInBytes > _avatarStorageLimitBytes) {
    return null;
  }
  return 'base64,${base64Encode(bytes)}';
}

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

  void _startEditing(String currentName, ProfileExtra? extra) {
    _displayNameController.text = currentName;
    _displayNameController.selection =
        TextSelection.collapsed(offset: currentName.length);
    setState(() => _isEditing = true);
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

    Widget scrollableBody(Widget child) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: child,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      // iOS Safari/Flutter Web: resize от клавиатуры сбрасывает фокус TextField.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
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
                    // SwipeBack снаружи формы — край не перекрывают TextField/ListView.
                    return SwipeBackScope(
                      onBack: _cancelEditing,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        child: SizedBox.expand(
                          child: _ProfileEditForm(
                            key: const ValueKey('mobile_edit_form'),
                            user: user,
                            profileExtra: extra,
                            displayNameController: _displayNameController,
                            focusNode: _displayNameFocus,
                            onCancel: _cancelEditing,
                            onSave: _saveProfile,
                            compact: true,
                          ),
                        ),
                      ),
                    );
                  }

                  Widget content = _ProfileContent(
                    key: ValueKey(user.id),
                    cardKey: _cardKey,
                    user: user,
                    profileExtra: extra,
                    isEditing: _isEditing,
                    isClosing: _isClosing,
                    displayNameController: _displayNameController,
                    displayNameFocus: _displayNameFocus,
                    onStartEdit: () => _startEditing(
                      user.displayName ?? user.email,
                      extra,
                    ),
                    onCancelEdit: _cancelEditing,
                    onSave: _saveProfile,
                  );
                  if (_isEditing) {
                    content = Listener(
                      onPointerDown: _onTapOutsideCard,
                      child: content,
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
  final TextEditingController displayNameController;
  final FocusNode displayNameFocus;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;
  final Future<void> Function(String displayName, ProfileExtra extra) onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBorderBox(
          key: cardKey,
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: MediaQuery.sizeOf(context).height < 700 ? 16 : 22,
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
                    ),
                  )
                : _ProfileView(
                    key: const ValueKey('view'),
                    user: user,
                    profileExtra: profileExtra,
                  ),
          ),
        ),
        // Счёт, коллекции и «Редактировать» — за рамкой блока с инфо о пользователе.
        if (!isEditing)
          _ProfileBelowFrame(
            onEdit: onStartEdit,
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
  });

  final AuthUser user;
  final ProfileExtra profileExtra;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasFrame)
          FramedAvatar(
            size: 80,
            borderWidth: 4.5,
            frameCode: caps?.frameCode,
            frameColor: caps?.frameColor,
            child: _buildAvatar(),
          )
        else
          Container(
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
        if (profileExtra.about != null &&
            profileExtra.about!.trim().isNotEmpty) ...[
          SizedBox(height: gapSection),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 96),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Text(
                profileExtra.about!.trim(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Счёт, коллекции и кнопка редактирования — снаружи рамки инфо-блока.
class _ProfileBelowFrame extends ConsumerWidget {
  const _ProfileBelowFrame({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortScreen = MediaQuery.sizeOf(context).height < 700;
    final inv =
        ref.watch(inventoryListProvider).valueOrNull ?? const <InventoryItem>[];
    final collections = inv.where((e) => e.kind == 'collection').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OwnScoreSection(),
          if (collections.isNotEmpty) ...[
            const SizedBox(height: 14),
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
          SizedBox(height: shortScreen ? 16 : 20),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              context.l10n.profileEdit,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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
          ),
        ],
      ),
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

class _ProfileEditForm extends StatefulWidget {
  const _ProfileEditForm({
    super.key,
    required this.user,
    required this.profileExtra,
    required this.displayNameController,
    required this.focusNode,
    required this.onCancel,
    required this.onSave,
    this.compact = false,
  });

  final AuthUser user;
  final ProfileExtra profileExtra;
  final TextEditingController displayNameController;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final Future<void> Function(String displayName, ProfileExtra extra) onSave;
  final bool compact;

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

/// Только цифры, макс. 3 (возраст 1–111).
final _ageFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(3),
];

/// Без управляющих символов и обратного слэша, макс. 100 (о себе).
final _aboutFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[^\x00-\x1f\\]')),
  LengthLimitingTextInputFormatter(100),
];

class _ProfileEditFormState extends State<_ProfileEditForm> {
  bool _isSaving = false;
  bool _isAvatarProcessing = false;
  bool _aboutTypingActive = false;
  String? _ageError;
  String? _saveError;
  DateTime? _lastLatinOnlyToastAt;
  late String _lastAboutText;
  late TextEditingController _ageController;
  late TextEditingController _aboutController;
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
    _ageController = TextEditingController(
      text: widget.profileExtra.age?.toString() ?? '',
    );
    _aboutController = TextEditingController(
      text: widget.profileExtra.about ?? '',
    );
    _lastAboutText = _aboutController.text;
    _aboutFocus = FocusNode();
    _aboutFocus.addListener(_onAboutFocusChanged);
    _ageController.addListener(_onFieldsChanged);
    _aboutController.addListener(_onAboutTextChanged);
    _gender = widget.profileExtra.gender;
    _avatarKind = widget.profileExtra.avatarKind;
    _avatarValue = widget.profileExtra.avatarValue;
    _showStatsToOthers = widget.profileExtra.showStatsToOthers;
  }

  void _onAboutFocusChanged() {
    if (!mounted) return;
    final focused = _aboutFocus.hasFocus;
    // Поднимаем сразу по фокусу (когда выезжает клавиатура); дерево стабильное
    // через Visibility — setState здесь не пересоздаёт TextField.
    if (focused == _aboutTypingActive) return;
    setState(() => _aboutTypingActive = focused);
  }

  void _onAboutTextChanged() {
    final text = _aboutController.text;
    // Игнор смены selection (повторный тап) — только реальный текст.
    if (text == _lastAboutText) return;
    _lastAboutText = text;
    if ((_ageError != null || _saveError != null) && mounted) {
      setState(() {
        _ageError = null;
        _saveError = null;
      });
    }
  }

  ProfileExtra get _effectiveInitialExtra =>
      _initialExtra ?? widget.profileExtra;

  void _onFieldsChanged() => setState(() {
        _ageError = null;
        _saveError = null;
      });

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
    return false;
  }

  @override
  void dispose() {
    widget.displayNameController.removeListener(_onFieldsChanged);
    _ageController.removeListener(_onFieldsChanged);
    _aboutController.removeListener(_onAboutTextChanged);
    _aboutFocus.removeListener(_onAboutFocusChanged);
    _aboutFocus.dispose();
    _ageController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  bool get _hasPhoto =>
      _avatarKind == AvatarKind.file &&
      _avatarValue != null &&
      _avatarValue!.isNotEmpty;

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
          maxWidth: 256,
          maxHeight: 256,
          imageQuality: 70,
        );
        if (xFile == null || !mounted) return;
        rawBytes = await xFile.readAsBytes();
      }

      if (!mounted) return;
      final editedBytes = await _openAvatarEditor(rawBytes);
      if (!mounted || editedBytes == null || editedBytes.isEmpty) return;

      final compactAvatarValue = await _buildCompactAvatarValue(editedBytes);
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
    } finally {
      if (mounted) {
        setState(() => _isAvatarProcessing = false);
      }
    }
  }

  Future<Uint8List?> _openAvatarEditor(Uint8List sourceBytes) async {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AvatarCropDialog(sourceBytes: sourceBytes),
    );
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
            onPressed: _isSaving ? null : widget.onCancel,
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

  Widget _buildCompactAboutField({required bool expands}) {
    return TextFormField(
      key: const ValueKey('compact_about'),
      controller: _aboutController,
      focusNode: _aboutFocus,
      inputFormatters: _aboutFormatters,
      textAlignVertical: TextAlignVertical.top,
      expands: expands,
      maxLines: expands ? null : 4,
      minLines: expands ? null : 3,
      maxLength: 100,
      textCapitalization: TextCapitalization.sentences,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      decoration: InputDecoration(
        labelText: context.l10n.commonAboutMe,
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.surfaceCard,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Icon(Icons.info_outline_rounded),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        counterText: '',
      ),
    );
  }

  Widget _buildCompactSaveButton() {
    return AppButton(
      onPressed: (_isSaving || !_hasChanges) ? null : _submit,
      label: context.l10n.commonSave,
      isLoading: _isSaving,
      expanded: true,
    );
  }

  Widget _buildCompactNameAgeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('compact_display_name'),
          controller: widget.displayNameController,
          focusNode: widget.focusNode,
          inputFormatters: _displayNameFormatters,
          decoration: InputDecoration(
            labelText: context.l10n.registerNameLabel,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('compact_age'),
                controller: _ageController,
                inputFormatters: _ageFormatters,
                decoration: InputDecoration(
                  labelText: context.l10n.profileAge,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  errorText: _ageError,
                ),
                keyboardType: TextInputType.number,
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
    // Поднимаем «О себе» сразу при фокусе (клавиатура открыта).
    final aboutTypingMode = _aboutTypingActive && _aboutFocus.hasFocus;

    // Одно стабильное дерево: прячем блоки через Visibility(maintainState),
    // а не if/else — иначе TextFormField пересоздаётся и iOS закрывает клавиатуру.
    // SwipeBackScope — снаружи (ProfileScreen), здесь только форма.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompactHeader(context),
          SizedBox(height: aboutTypingMode ? 10 : 16),
          Visibility(
            visible: !aboutTypingMode,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 82,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: Center(child: _buildCurrentAvatar()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetAvatarIcons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 5),
                          itemBuilder: (context, index) {
                            final selected =
                                _avatarKind == AvatarKind.preset &&
                                    _avatarValue == index.toString();
                            return GestureDetector(
                              onTap: () => setState(() {
                                _avatarKind = AvatarKind.preset;
                                _avatarValue = index.toString();
                              }),
                              child: AnimatedContainer(
                                duration: AppDurations.short,
                                width: 48,
                                height: 48,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 15),
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
                                  size: 25,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCompactNameAgeRow(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = aboutTypingMode
                    ? math.min(168.0, constraints.maxHeight)
                    : constraints.maxHeight;
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: height,
                    child: _buildCompactAboutField(expands: true),
                  ),
                );
              },
            ),
          ),
          Visibility(
            visible: !aboutTypingMode,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _buildShowStatsCheckbox(),
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
                      : const Icon(Icons.photo_library_outlined, size: 19),
                  label: Text(_hasPhoto ? context.l10n.profileChangePhoto : context.l10n.profileUploadPhoto),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 12),
                  MessageBanner(
                    message: _saveError!,
                    type: BannerType.error,
                  ),
                ],
                const SizedBox(height: 16),
                _buildCompactSaveButton(),
              ],
            ),
          ),
        ],
    );
  }

  Widget _buildShowStatsCheckbox() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _showStatsToOthers = !_showStatsToOthers),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _showStatsToOthers,
                onChanged: (v) =>
                    setState(() => _showStatsToOthers = v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Показывать статистику другим игрокам',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactEditor(context);
    }
    return Stack(
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
                TextFormField(
                  controller: _aboutController,
                  inputFormatters: _aboutFormatters,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: context.l10n.commonAboutMe,
                    hintText: context.l10n.profileAboutHint,
                    prefixIcon: Icon(Icons.info_outline_rounded),
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                  maxLines: 3,
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                _buildShowStatsCheckbox(),
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
                OutlinedButton.icon(
                  onPressed:
                      (_isSaving || _isAvatarProcessing) ? null : _pickImage,
                  icon: _isAvatarProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _hasPhoto
                              ? Icons.change_circle_outlined
                              : Icons.photo_library_outlined,
                          size: 20,
                        ),
                  label: Text(
                    _isAvatarProcessing
                        ? context.l10n.profileProcessingPhoto
                        : (_hasPhoto ? context.l10n.profileChangePhoto : context.l10n.profileUploadPhoto),
                  ),
                ),
                if (_saveError != null) ...[
                  MessageBanner(message: _saveError!, type: BannerType.error),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 24),
                AppButton(
                  onPressed: (_isSaving || !_hasChanges) ? null : _submit,
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
    );
  }
}

class _AvatarCropDialog extends StatefulWidget {
  const _AvatarCropDialog({required this.sourceBytes});

  final Uint8List sourceBytes;

  @override
  State<_AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<_AvatarCropDialog> {
  static const double _viewportSize = 240;

  final TransformationController _transformation = TransformationController();
  final GlobalKey _captureKey = GlobalKey();

  bool _ready = false;
  bool _exporting = false;
  double _baseWidth = _viewportSize;
  double _baseHeight = _viewportSize;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(widget.sourceBytes);
      final frame = await codec.getNextFrame();
      image = frame.image;

      final width = image.width.toDouble();
      final height = image.height.toDouble();
      final aspect = (height == 0) ? 1.0 : width / height;

      double baseWidth;
      double baseHeight;
      if (aspect >= 1) {
        baseHeight = _viewportSize;
        baseWidth = _viewportSize * aspect;
      } else {
        baseWidth = _viewportSize;
        baseHeight = _viewportSize / aspect;
      }

      _baseWidth = baseWidth;
      _baseHeight = baseHeight;

      final tx = (_viewportSize - _baseWidth) / 2;
      final ty = (_viewportSize - _baseHeight) / 2;
      _transformation.value = Matrix4.identity()..translate(tx, ty);

      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = true;
          _baseWidth = _viewportSize;
          _baseHeight = _viewportSize;
          _transformation.value = Matrix4.identity();
        });
      }
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<void> _applyCrop() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    ui.Image? renderedImage;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      renderedImage = await boundary.toImage(pixelRatio: 2);
      final data =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || data == null) return;
      Navigator.of(context).pop(data.buffer.asUint8List());
    } finally {
      renderedImage?.dispose();
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.profileCropTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.profileCropHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _captureKey,
            child: ClipOval(
              child: SizedBox(
                width: _viewportSize,
                height: _viewportSize,
                child: ColoredBox(
                  color: AppColors.surfaceCard,
                  child: _ready
                      ? InteractiveViewer(
                          transformationController: _transformation,
                          minScale: 1,
                          maxScale: 4.5,
                          boundaryMargin: const EdgeInsets.all(180),
                          clipBehavior: Clip.none,
                          constrained: false,
                          child: SizedBox(
                            width: _baseWidth,
                            height: _baseHeight,
                            child: Image.memory(
                              widget.sourceBytes,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        )
                      : const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton.icon(
          onPressed: (!_ready || _exporting) ? null : _applyCrop,
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_exporting ? context.l10n.profilePreparing : context.l10n.profileApply),
        ),
      ],
    );
  }
}

/// Счёт и иконка статистики (общая по всем играм).
class _OwnScoreSection extends ConsumerWidget {
  const _OwnScoreSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gameStatsProvider(null)).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ваш счёт',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: ScoreTripletCard(
                won: stats?.wins ?? 0,
                lost: stats?.losses ?? 0,
                drawn: stats?.draws ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            StatsIconButton(
              onTap: () => showGameStatsDialog(context),
            ),
          ],
        ),
      ],
    );
  }
}
