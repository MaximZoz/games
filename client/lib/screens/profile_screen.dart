import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/auth/profile_extra.dart';
import 'package:multigames_client/screens/pick_image_web.dart';
import 'package:multigames_client/screens/profile_avatar_storage.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// Готовый набор аватаров (иконки).
const List<IconData> _presetAvatarIcons = [
  Icons.face_rounded,           // лицо нейтральное
  Icons.face_2_rounded,         // длинные волосы (ж)
  Icons.face_3_rounded,         // вариант (м)
  Icons.face_4_rounded,         // с усами (м)
  Icons.face_5_rounded,         // с очками
  Icons.face_6_rounded,         // вариант (ж)
  Icons.man_rounded,            // мужчина
  Icons.woman_rounded,          // женщина
  Icons.elderly_rounded,        // пожилой м
  Icons.elderly_woman_rounded,  // пожилая ж
  Icons.person_rounded,         // нейтральный силуэт
  Icons.child_care_rounded,     // ребёнок
];

/// Декодирование base64 в отдельном isolate, чтобы не блокировать UI.
Uint8List _decodeBase64Isolate(String s) => base64Decode(s);

/// Склонение: «год» / «года» / «лет» для возраста.
String _ageYearsWord(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'год';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'года';
  return 'лет';
}

final Map<int, Uint8List> _base64AvatarCache = {};

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
      compute<String, Uint8List>(_decodeBase64Isolate, v.substring(7)).then((bytes) {
        if (!mounted) return;
        _base64AvatarCache[key] = bytes;
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
    final letter = widget.letter.isEmpty ? '?' : widget.letter.substring(0, 1).toUpperCase();
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

  void _onTapOutsideCard(PointerDownEvent e) {
    if (!_isEditing || _isClosing) return;
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final bounds = Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height);
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
    _displayNameController.selection = TextSelection.collapsed(offset: currentName.length);
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
    _startClosing();
  }

  Future<void> _saveProfile(String displayName, ProfileExtra extra) async {
    await ref.read(authStateProvider.notifier).updateProfile(
          displayName: displayName,
          extra: extra,
        );
    if (mounted) _startClosing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ref.watch(authStateProvider).when(
                  data: (user) {
                    if (user == null) {
                      return _ProfileEmptyState(
                        key: const ValueKey('empty'),
                        onLogin: () => context.push('/login'),
                      );
                    }
                    final extraAsync = ref.watch(profileExtraProvider);
                    final profileExtra = extraAsync.valueOrNull ?? _lastProfileExtra ?? const ProfileExtra();
                    Widget content = extraAsync.when(
                      data: (extra) {
                        return _ProfileContent(
                          key: ValueKey(user.id),
                          cardKey: _cardKey,
                          user: user,
                          profileExtra: extra ?? const ProfileExtra(),
                          isEditing: _isEditing,
                          isClosing: _isClosing,
                          displayNameController: _displayNameController,
                          displayNameFocus: _displayNameFocus,
                          onStartEdit: () => _startEditing(
                            user.displayName ?? user.email,
                            extra ?? const ProfileExtra(),
                          ),
                          onCancelEdit: _cancelEditing,
                          onSave: _saveProfile,
                        );
                      },
                      loading: () => _ProfileContent(
                        key: ValueKey(user.id),
                        cardKey: _cardKey,
                        user: user,
                        profileExtra: profileExtra,
                        isEditing: _isEditing,
                        isClosing: _isClosing,
                        displayNameController: _displayNameController,
                        displayNameFocus: _displayNameFocus,
                        onStartEdit: () => _startEditing(
                          user.displayName ?? user.email,
                          profileExtra,
                        ),
                        onCancelEdit: _cancelEditing,
                        onSave: _saveProfile,
                      ),
                      error: (_, __) => _ProfileContent(
                        key: ValueKey(user.id),
                        cardKey: _cardKey,
                        user: user,
                        profileExtra: const ProfileExtra(),
                        isEditing: _isEditing,
                        isClosing: _isClosing,
                        displayNameController: _displayNameController,
                        displayNameFocus: _displayNameFocus,
                        onStartEdit: () => _startEditing(
                          user.displayName ?? user.email,
                          const ProfileExtra(),
                        ),
                        onCancelEdit: _cancelEditing,
                        onSave: _saveProfile,
                      ),
                    );
                    if (_isEditing) {
                      content = Listener(
                        onPointerDown: _onTapOutsideCard,
                        child: content,
                      );
                    }
                    return content;
                  },
                  loading: () => const _ProfileLoadingState(key: ValueKey('loading')),
                  error: (err, _) => _ProfileErrorState(
                    key: const ValueKey('error'),
                    message: err is AuthException ? err.message : err.toString(),
                    onRetry: () => ref.read(authStateProvider.notifier).refresh(),
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
            label: 'Повторить',
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({super.key, required this.onLogin});

  final VoidCallback onLogin;

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
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Войдите в аккаунт',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Чтобы видеть профиль и достижения',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: onLogin,
              label: 'Войти',
              expanded: true,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    onEdit: onStartEdit,
                  ),
          ),
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: child,
          ),
          child: Column(
            children: [
              _ProfileLink(
                icon: Icons.emoji_events,
                label: 'Достижения',
                onTap: () => context.push('/achievements'),
              ),
              const SizedBox(height: 12),
              _ProfileLink(
                icon: Icons.monetization_on,
                label: 'Монеты',
                onTap: () => context.push('/coins'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    super.key,
    required this.user,
    required this.profileExtra,
    required this.onEdit,
  });

  final AuthUser user;
  final ProfileExtra profileExtra;
  final VoidCallback onEdit;

  String get _displayTitle => user.displayName?.trim().isNotEmpty == true
      ? user.displayName!
      : user.email;

  String get _avatarLetter {
    if (user.displayName?.trim().isNotEmpty == true) {
      return user.displayName!.trim().substring(0, 1).toUpperCase();
    }
    return user.email.trim().isEmpty ? '?' : user.email.substring(0, 1).toUpperCase();
  }

  Widget _buildAvatar() {
    return _AsyncAvatarImage(
      avatarKind: profileExtra.avatarKind,
      avatarValue: profileExtra.avatarValue,
      letter: _avatarLetter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar(),
        const SizedBox(height: 16),
        Text(
          _displayTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        if (user.displayName?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
        if (profileExtra.age != null ||
            (profileExtra.gender != null && profileExtra.gender!.isNotEmpty) ||
            (profileExtra.about != null && profileExtra.about!.trim().isNotEmpty)) ...[
          const SizedBox(height: 12),
          if (profileExtra.age != null || (profileExtra.gender != null && profileExtra.gender!.isNotEmpty))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profileExtra.age != null) ...[
                  Text(
                    '${profileExtra.age} ${_ageYearsWord(profileExtra.age!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (profileExtra.gender != null && profileExtra.gender!.isNotEmpty) const SizedBox(width: 8),
                ],
                if (profileExtra.gender != null && profileExtra.gender!.isNotEmpty)
                  Icon(
                    profileExtra.gender == 'Женский' ? Icons.female : Icons.male,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          if (profileExtra.about != null && profileExtra.about!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profileExtra.about!.trim(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentStart),
          label: const Text(
            'Редактировать',
            style: TextStyle(
              color: AppColors.accentStart,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
  });

  final AuthUser user;
  final ProfileExtra profileExtra;
  final TextEditingController displayNameController;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final Future<void> Function(String displayName, ProfileExtra extra) onSave;

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

/// Только латиница, макс. 10 символов (логин).
final _displayNameFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
  LengthLimitingTextInputFormatter(10),
];

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
  String? _ageError;
  String? _saveError;
  late TextEditingController _ageController;
  late TextEditingController _aboutController;
  late String? _gender;
  late AvatarKind _avatarKind;
  late String? _avatarValue;
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
    _ageController.addListener(_onFieldsChanged);
    _aboutController.addListener(_onFieldsChanged);
    _gender = widget.profileExtra.gender;
    _avatarKind = widget.profileExtra.avatarKind;
    _avatarValue = widget.profileExtra.avatarValue;
  }

  ProfileExtra get _effectiveInitialExtra => _initialExtra ?? widget.profileExtra;

  void _onFieldsChanged() => setState(() { _ageError = null; _saveError = null; });

  bool get _hasChanges {
    final name = widget.displayNameController.text.trim();
    if (name != _initialDisplayName.trim()) return true;
    final initial = _effectiveInitialExtra;
    final ageStr = _ageController.text.trim();
    final initialAge = initial.age;
    if ((initialAge == null && ageStr.isNotEmpty) ||
        (initialAge != null && ageStr != initialAge.toString())) return true;
    if (_gender != initial.gender) return true;
    final about = _aboutController.text.trim();
    final initialAbout = initial.about ?? '';
    if (about != initialAbout) return true;
    if (_avatarKind != initial.avatarKind) return true;
    if ((_avatarValue ?? '') != (initial.avatarValue ?? '')) return true;
    return false;
  }

  @override
  void dispose() {
    widget.displayNameController.removeListener(_onFieldsChanged);
    _ageController.removeListener(_onFieldsChanged);
    _aboutController.removeListener(_onFieldsChanged);
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
    if (_avatarKind == AvatarKind.file && _avatarValue != null && _avatarValue!.isNotEmpty) {
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
    final letter = displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();
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
    List<int> bytes;
    if (kIsWeb) {
      final webBytes = await pickImageBytesWeb();
      if (webBytes == null || !mounted) return;
      bytes = webBytes;
    } else {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (xFile == null || !mounted) return;
      bytes = await xFile.readAsBytes();
    }
    if (!mounted) return;
    if (kIsWeb) {
      setState(() {
        _avatarKind = AvatarKind.file;
        _avatarValue = 'base64,${base64Encode(bytes)}';
      });
    } else {
      final path = await savePickedImagePath(widget.user.id, bytes);
      if (path != null && mounted) {
        setState(() {
          _avatarKind = AvatarKind.file;
          _avatarValue = path;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = widget.displayNameController.text.trim();
    final ageRaw = _ageController.text.trim();
    final age = ageRaw.isEmpty ? null : int.tryParse(ageRaw);
    if (age != null && (age < 1 || age > 111)) {
      setState(() => _ageError = 'Введите возраст от 1 до 111');
      return;
    }
    final extra = ProfileExtra(
      age: age,
      gender: _gender,
      about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
      avatarKind: _avatarKind,
      avatarValue: _avatarValue,
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
          _saveError = e is AuthException
              ? e.message
              : e is http.ClientException
                  ? 'Не удалось подключиться к серверу. Проверьте, что сервер запущен.'
                  : 'Не удалось сохранить профиль';
        });
      }
    }
  }

  static const List<String> _genderOptions = ['Мужской', 'Женский'];

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
                return InkWell(
                  onTap: () {
                    setState(() => _gender = value);
                    Navigator.of(ctx).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

  @override
  Widget build(BuildContext context) {
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
              decoration: const InputDecoration(
                labelText: 'Имя (логин)',
                hintText: 'Латиница, цифры, _ до 10 символов',
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
                labelText: 'Возраст',
                hintText: 'От 1 до 111',
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
                decoration: const InputDecoration(
                  labelText: 'Пол',
                  prefixIcon: Icon(Icons.wc_rounded),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_gender ?? 'Не указан'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutController,
              inputFormatters: _aboutFormatters,
              decoration: const InputDecoration(
                labelText: 'О себе',
                hintText: 'До 100 символов (по желанию)',
                prefixIcon: Icon(Icons.info_outline_rounded),
                alignLabelWithHint: true,
                counterText: '',
              ),
              maxLines: 3,
              maxLength: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'Аватар',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Center(child: _buildCurrentAvatar()),
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
                          color: selected ? AppColors.accentStart : Colors.transparent,
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
              onPressed: _isSaving ? null : _pickImage,
              icon: Icon(
                _hasPhoto ? Icons.change_circle_outlined : Icons.photo_library_outlined,
                size: 20,
              ),
              label: Text(_hasPhoto ? 'Поменять фото' : 'Загрузить фото'),
            ),
            if (_saveError != null) ...[
              MessageBanner(message: _saveError!, type: BannerType.error),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            AppButton(
              onPressed: (_isSaving || !_hasChanges) ? null : _submit,
              label: 'Сохранить',
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

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBorderBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentStart, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
