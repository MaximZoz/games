import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/achievements/achievements_provider.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/chats/chats_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_auth.dart';
import 'package:multigames_client/core/gamepad/gamepad_confirm_dialog.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_highlight.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/core/presence_sort.dart';
import 'package:multigames_client/friends/friends_gamepad.dart';
import 'package:multigames_client/friends/friends_provider.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/avatar_memory_cache.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/mobile_toolbar_provider.dart';
import 'package:multigames_client/core/soft_keyboard.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';

/// Пустой список друзей/заявок: без запроса — «список пуст», при поиске — «ничего не найдено».
@visibleForTesting
String friendsListEmptyText({
  required String query,
  required String emptyList,
  required String nothingFound,
}) {
  return query.trim().isEmpty ? emptyList : nothingFound;
}

/// В альбоме и при клавиатуре нет места на отступ 80 — текст уезжает за край.
@visibleForTesting
EdgeInsets friendsEmptyStatusPadding({
  required bool phoneLandscape,
  required double keyboardInset,
}) {
  if (phoneLandscape || keyboardInset > 0) {
    return const EdgeInsets.fromLTRB(16, 8, 16, 8);
  }
  return const EdgeInsets.fromLTRB(16, 80, 16, 16);
}

/// Табы с бейджами съедают высоту над клавиатурой: в альбоме её почти нет,
/// в портрете без них видно больше результатов поиска.
@visibleForTesting
bool friendsHideTabsForKeyboard({
  required bool landscape,
  required double keyboardInset,
}) {
  return keyboardInset >= 80;
}

/// Цвет числа на табе: входящие — красный, поиск — зелёный, иначе акцент.
@visibleForTesting
Color friendsTabCountColor({
  required bool incoming,
  required bool findFriend,
  required int count,
}) {
  if (incoming && count > 0) return Colors.red.shade600;
  if (findFriend) return Colors.green.shade700;
  return AppColors.accentStart;
}

/// Бейдж «Найти друга»: живой опрос, иначе число из того же ответа, что друзья.
@visibleForTesting
int? friendsFindTabCount({int? live, int? snapshot}) {
  if (live != null) return live;
  return snapshot;
}

/// На широком экране вкладки не растягиваются на всю ширину.
@visibleForTesting
bool friendsUsePackedTabs({
  required double width,
  required bool phoneLandscape,
}) {
  return phoneLandscape || width >= Breakpoints.mobile;
}

@visibleForTesting
const double friendsDesktopGridGap = 12;

@visibleForTesting
const double friendsDesktopMaxContentWidth = 960;

@visibleForTesting
double friendsDesktopMaxCellWidth({
  required bool phoneLandscape,
  required bool tablet,
}) {
  if (phoneLandscape) return 220;
  if (tablet) return 260;
  return 300;
}

/// Сетка карточек друзей и «Найти друга» на широких экранах.
@visibleForTesting
({int crossAxisCount, double itemWidth, double contentWidth})
    friendsDesktopGridLayout({
  required double viewportWidth,
  required bool phoneLandscape,
  required bool tablet,
}) {
  final maxCellWidth = friendsDesktopMaxCellWidth(
    phoneLandscape: phoneLandscape,
    tablet: tablet,
  );
  final contentWidth =
      (viewportWidth - 32).clamp(0.0, friendsDesktopMaxContentWidth);
  final crossAxisCount = (contentWidth / (maxCellWidth + friendsDesktopGridGap))
      .floor()
      .clamp(1, 3);
  final itemWidth =
      (contentWidth - friendsDesktopGridGap * (crossAxisCount - 1)) /
          crossAxisCount;
  return (
    crossAxisCount: crossAxisCount,
    itemWidth: itemWidth,
    contentWidth: contentWidth,
  );
}

/// Лоадер пагинации попал в экран — грузим следующую страницу.
@visibleForTesting
bool friendsLoaderIsVisible({
  required Rect? loaderGlobalRect,
  required Size viewportSize,
}) {
  if (loaderGlobalRect == null) return false;
  if (loaderGlobalRect.width <= 0 || loaderGlobalRect.height <= 0) {
    return false;
  }
  return loaderGlobalRect.bottom > 0 &&
      loaderGlobalRect.top < viewportSize.height &&
      loaderGlobalRect.right > 0 &&
      loaderGlobalRect.left < viewportSize.width;
}

@visibleForTesting
bool friendsShouldLoadNextPage({
  required bool hasMore,
  required bool loading,
  required bool loaderVisible,
}) {
  return hasMore && !loading && loaderVisible;
}

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

enum _FriendsTabKind { friends, incoming, outgoing, findFriend }

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with TickerProviderStateMixin {
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
    Icons.elderly_rounded,
    Icons.elderly_woman_rounded,
    Icons.person_rounded,
    Icons.child_care_rounded,
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;
  late final StateController<Widget?> _toolbarLeading;
  late final StateController<bool> _navCollapse;
  List<_FriendsTabKind> _currentTabs = const [
    _FriendsTabKind.friends,
    _FriendsTabKind.incoming,
    _FriendsTabKind.outgoing,
    _FriendsTabKind.findFriend,
  ];
  final Set<String> _actionsInProgress = <String>{};
  Timer? _searchDebounce;
  int _searchRevision = 0;

  List<FriendSearchItem> _searchResults = const [];
  bool _isSearching = false;
  bool _isSearchLoadingMore = false;
  bool _searchHasMore = false;
  bool _isSearchExpanded = false;
  int _friendsVisibleCount = _pageSize;
  int _incomingVisibleCount = _pageSize;
  int _outgoingVisibleCount = _pageSize;

  /// Deep-link `/friends?tab=incoming` (пуш / бейдж) — применить один раз.
  bool _deepLinkIncomingApplied = false;

  final GlobalKey _friendsLoaderKey = GlobalKey();
  final GlobalKey _incomingLoaderKey = GlobalKey();
  final GlobalKey _outgoingLoaderKey = GlobalKey();
  final GlobalKey _searchLoaderKey = GlobalKey();
  bool _desktopPagingScheduled = false;

  int _gamepadCardIndex = 0;
  int? _gamepadActionIndex;
  int _gamepadCardCount = 0;
  int _gamepadColumns = 1;
  final List<List<VoidCallback>> _gamepadCardActions = [];
  final List<VoidCallback> _gamepadCardOpens = [];
  final Map<int, GlobalKey> _gamepadCardKeys = {};

  @override
  void initState() {
    super.initState();
    // Кэш до dispose: в Flutter 3.27 ref уже закрыт, когда вызывается dispose.
    _toolbarLeading = ref.read(mobileToolbarLeadingProvider.notifier);
    _navCollapse = ref.read(collapseMobileBottomNavProvider.notifier);
    _tabController = TabController(length: _currentTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _applyIncomingDeepLinkIfNeeded() {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab != 'incoming') {
      _deepLinkIncomingApplied = false;
      return;
    }
    if (_deepLinkIncomingApplied) return;
    final index = _currentTabs.indexOf(_FriendsTabKind.incoming);
    if (index < 0 || index >= _tabController.length) return;
    _deepLinkIncomingApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (index < _tabController.length && _tabController.index != index) {
        _tabController.index = index;
      }
      // Убрать query, чтобы повторный build не дёргал таб.
      final uri = GoRouterState.of(context).uri;
      if (uri.path == '/friends' && uri.queryParameters['tab'] == 'incoming') {
        context.go('/friends');
      }
    });
  }

  void _onTabChanged() {
    if (_isFindFriendTab && _searchController.text.trim().isNotEmpty) {
      _scheduleSearch(immediate: true);
    }
    _resetGamepadCursor();
    if (mounted) setState(() {});
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
    _syncBottomNavCollapse();
  }

  void _syncBottomNavCollapse() {
    if (!mounted) return;
    final collapse = _isSearchExpanded && _searchFocusNode.hasFocus;
    final notifier = ref.read(collapseMobileBottomNavProvider.notifier);
    if (notifier.state != collapse) {
      notifier.state = collapse;
    }
  }

  bool _sameTabs(List<_FriendsTabKind> a, List<_FriendsTabKind> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _syncTabController(List<_FriendsTabKind> tabs) {
    if (tabs.isEmpty) return;
    if (_sameTabs(tabs, _currentTabs) && _tabController.length == tabs.length) {
      return;
    }
    final oldKind = (_tabController.index >= 0 &&
            _tabController.index < _currentTabs.length)
        ? _currentTabs[_tabController.index]
        : _FriendsTabKind.findFriend;
    final oldController = _tabController;
    oldController.removeListener(_onTabChanged);
    var index = tabs.indexOf(oldKind);
    if (index < 0) index = 0;
    _currentTabs = List<_FriendsTabKind>.of(tabs);
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: index,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
    });
  }

  @override
  void dispose() {
    final toolbarLeading = _toolbarLeading;
    final navCollapse = _navCollapse;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (toolbarLeading.mounted) toolbarLeading.state = null;
      if (navCollapse.mounted) navCollapse.state = false;
    });
    _searchDebounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isFindFriendTab {
    final i = _tabController.index;
    if (i < 0 || i >= _currentTabs.length) return false;
    return _currentTabs[i] == _FriendsTabKind.findFriend;
  }

  void _showMessage(String? error, String? success) {}

  String _displayName(FriendUserItem user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return LocaleService.l10n.commonUser;
  }

  bool _matchesSearch(FriendUserItem user, String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase();
    final name = _displayName(user).toLowerCase();
    return name.contains(q);
  }

  List<FriendItem> _sortedAndFilteredFriends(
    List<FriendItem> friends,
    Map<String, PresenceEntry> presence,
    String searchQuery,
  ) {
    final list =
        friends.where((f) => _matchesSearch(f.user, searchQuery)).toList();
    sortByPresenceOnlineFirst(list, (f) => f.user.id, presence);
    return list;
  }

  List<FriendRequestItem> _filteredRequests(
    List<FriendRequestItem> items,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return items;
    return items.where((r) => _matchesSearch(r.user, searchQuery)).toList();
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _showRequestInfoDialog({
    required FriendUserItem user,
    PresenceEntry? presence,
  }) async {
    await showUserProfileDialog(
      context: context,
      ref: ref,
      userId: user.id,
      displayName: _displayName(user),
      avatarKind: user.avatarKind,
      avatarValue: user.avatarValue,
      frameCode: user.frameCode,
      frameColor: user.frameColor,
      age: user.age,
      gender: user.gender,
      about: user.about,
      messageFrom: 'friends',
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
        avatar = _buildLetterAvatar(user);
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
        avatar = _buildLetterAvatar(user);
      }
    } else {
      avatar = _buildLetterAvatar(user);
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

  Widget _buildLetterAvatar(FriendUserItem user) {
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

  Future<void> _handleFriendsException(FriendsException e) async {
    if (e.statusCode == 401) {
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      _showMessage(LocaleService.l10n.sessionExpired, null);
      context.go('/login');
      return;
    }
    _showMessage(e.message, null);
  }

  Future<void> _handleChatException(ChatException e) async {
    if (e.statusCode == 401) {
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _openChatWithUser(
    FriendUserItem user, {
    String? actionKey,
  }) async {
    final key = actionKey ?? 'chat_${user.id}';
    if (_actionsInProgress.contains(key)) return;
    setState(() => _actionsInProgress.add(key));

    try {
      _searchFocusNode.unfocus();
      GamepadKeyboardController.instance.hide();
      final chatID = await ref.read(chatsRepositoryProvider).startChat(user.id);
      if (!mounted) return;
      if (chatID.isEmpty) return;
      final name = Uri.encodeQueryComponent(_displayName(user));
      context.push('/chats/$chatID?name=$name&from=friends');
    } catch (e) {
      if (e is ChatException) {
        await _handleChatException(e);
      }
    } finally {
      if (mounted) {
        setState(() => _actionsInProgress.remove(key));
      }
    }
  }

  void _clearSearchState({required bool collapseExpanded}) {
    _searchDebounce?.cancel();
    _searchRevision++;
    _searchController.clear();
    _searchResults = const [];
    _isSearching = false;
    _isSearchLoadingMore = false;
    _searchHasMore = false;
    if (collapseExpanded) {
      _isSearchExpanded = false;
    }
  }

  /// Тап по bottom-nav «Друзья»: свернуть/очистить поиск и открыть таб «Друзья».
  void _onFriendsNavTap() {
    if (!mounted) return;
    final friendsIndex = _currentTabs.indexOf(_FriendsTabKind.friends);
    final targetIndex = friendsIndex >= 0 ? friendsIndex : 0;
    setState(() {
      _clearSearchState(collapseExpanded: true);
      if (_tabController.index != targetIndex &&
          targetIndex < _tabController.length) {
        _tabController.index = targetIndex;
      }
    });
    _searchFocusNode.unfocus();
    _syncBottomNavCollapse();
  }

  void _resetGamepadCursor() {
    _gamepadCardIndex = 0;
    _gamepadActionIndex = null;
  }

  _FriendsTabKind? _gamepadCollectTab;

  bool _isTabActive(_FriendsTabKind tab) {
    return _currentTabs.isNotEmpty &&
        _tabController.index >= 0 &&
        _tabController.index < _currentTabs.length &&
        _currentTabs[_tabController.index] == tab;
  }

  void _beginGamepadCards({
    required int count,
    required int columns,
    required _FriendsTabKind tab,
  }) {
    if (!_isTabActive(tab)) return;
    _gamepadCollectTab = tab;
    _gamepadCardCount = count;
    _gamepadColumns = columns < 1 ? 1 : columns;
    _gamepadCardActions.clear();
    _gamepadCardOpens.clear();
    if (count <= 0) {
      _gamepadCardIndex = 0;
      _gamepadActionIndex = null;
      return;
    }
    if (_gamepadCardIndex >= count) {
      _gamepadCardIndex = count - 1;
    }
  }

  void _registerGamepadActions(
    List<VoidCallback> actions, {
    required VoidCallback onOpen,
  }) {
    if (_gamepadCollectTab == null || !_isTabActive(_gamepadCollectTab!)) {
      return;
    }
    _gamepadCardActions.add(actions);
    _gamepadCardOpens.add(onOpen);
  }

  VoidCallback? _openForCurrentCard() {
    if (_gamepadCardIndex < 0 ||
        _gamepadCardIndex >= _gamepadCardOpens.length) {
      return null;
    }
    return _gamepadCardOpens[_gamepadCardIndex];
  }

  List<VoidCallback> _actionsForCurrentCard() {
    if (_gamepadCardIndex < 0 ||
        _gamepadCardIndex >= _gamepadCardActions.length) {
      return const [];
    }
    return _gamepadCardActions[_gamepadCardIndex];
  }

  bool _cardHighlighted(int index) {
    return index == _gamepadCardIndex && _gamepadActionIndex == null;
  }

  bool _actionHighlighted(int cardIndex, int actionIndex) {
    return cardIndex == _gamepadCardIndex && _gamepadActionIndex == actionIndex;
  }

  GlobalKey _gamepadKeyFor(int index) {
    return _gamepadCardKeys.putIfAbsent(index, GlobalKey.new);
  }

  void _ensureGamepadCardVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _gamepadCardKeys[_gamepadCardIndex]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: const Duration(milliseconds: 120),
      );
    });
  }

  void _focusSearchField() {
    if (gamepadConnected()) {
      _searchFocusNode.requestFocus();
      GamepadKeyboardController.instance.show();
      return;
    }
    openSoftKeyboard(_searchFocusNode);
  }

  bool _onGamepad(GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    final keyboard = GamepadKeyboardController.instance.visible;
    if (action == GamepadAction.triggerL) {
      _toggleSearch(fromGamepad: true);
      return true;
    }
    if (keyboard) return false;
    if (action.isScroll) {
      final route = ModalRoute.of(context);
      if (!friendsGamepadAllowsTabScroll(
        popupOpen: isGamepadPopupOpen(context),
        exclusive: GamepadDispatcher.hasExclusive,
        routeCovered: route != null && !route.isCurrent,
      )) {
        return true;
      }
      if (_tabController.length <= 1) return true;
      final next = friendsTabIndexAfterScroll(
        index: _tabController.index,
        length: _tabController.length,
        action: action,
      );
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
      return true;
    }
    if (action == GamepadAction.up || action == GamepadAction.down) {
      if (_gamepadCardCount <= 0) return true;
      setState(() {
        _gamepadActionIndex = null;
        _gamepadCardIndex = friendsCardIndexAfterMove(
          index: _gamepadCardIndex,
          count: _gamepadCardCount,
          columns: _gamepadColumns,
          action: action,
        );
      });
      _ensureGamepadCardVisible();
      return true;
    }
    if (action == GamepadAction.left || action == GamepadAction.right) {
      if (_gamepadCardCount <= 0) return true;
      final actions = _actionsForCurrentCard();
      setState(() {
        _gamepadActionIndex = friendsActionIndexAfterMove(
          current: _gamepadActionIndex,
          actionCount: actions.length,
          action: action,
        );
      });
      return true;
    }
    if (action == GamepadAction.confirm) {
      if (_gamepadCardCount <= 0) return false;
      if (_gamepadActionIndex == null) {
        _openForCurrentCard()?.call();
        return true;
      }
      final actions = _actionsForCurrentCard();
      final i = _gamepadActionIndex!;
      if (i >= 0 && i < actions.length) {
        actions[i]();
      }
      return true;
    }
    if (action == GamepadAction.cancel) {
      if (_gamepadActionIndex != null) {
        setState(() => _gamepadActionIndex = null);
        return true;
      }
      if (_searchFocusNode.hasFocus ||
          GamepadKeyboardController.instance.visible) {
        _searchFocusNode.unfocus();
        dismissGamepadKeyboard();
        if (!isWide(context) && _isSearchExpanded) {
          setState(() => _isSearchExpanded = false);
          _syncBottomNavCollapse();
        }
        return true;
      }
      return false;
    }
    return false;
  }

  Widget _gamepadActionFrame({
    required int cardIndex,
    required int actionIndex,
    required Widget child,
  }) {
    return wrapGamepadCursor(
      highlighted: _actionHighlighted(cardIndex, actionIndex),
      radius: 10,
      child: child,
    );
  }

  void _toggleSearch({bool fromGamepad = false}) {
    final wide = mounted && isWide(context);
    if (wide) {
      if (_searchFocusNode.hasFocus ||
          GamepadKeyboardController.instance.visible) {
        _searchFocusNode.unfocus();
        dismissGamepadKeyboard();
        return;
      }
      _focusSearchField();
      return;
    }

    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _clearSearchState(collapseExpanded: false);
      }
    });

    if (_isSearchExpanded) {
      // Поле уже смонтировано (свёрнутая панель) — фокус тем же жестом,
      // иначе браузер не считает открытие клавиатуры пользовательским.
      _focusSearchField();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusSearchField();
      });
      if (_searchController.text.trim().isNotEmpty) {
        _scheduleSearch(immediate: true, forceRun: true);
      }
    } else {
      _searchFocusNode.unfocus();
      if (fromGamepad || gamepadConnected()) {
        dismissGamepadKeyboard();
      }
      _syncBottomNavCollapse();
    }
  }

  Future<void> _refreshSnapshot({bool refreshSearch = false}) async {
    try {
      ref.invalidate(friendsSnapshotProvider);
      // Онлайн/last seen — иначе статус друга не меняется без перезагрузки.
      refreshPresence(ref);
      await Future.wait([
        ref.read(friendsSnapshotProvider.future),
        ref.read(presenceMapProvider.future),
      ]);
      if (mounted) {
        setState(() {
          _friendsVisibleCount = _pageSize;
          _incomingVisibleCount = _pageSize;
          _outgoingVisibleCount = _pageSize;
        });
      }
      if (refreshSearch && _searchController.text.trim().isNotEmpty) {
        await _performSearch(query: _searchController.text.trim());
      }
    } catch (e) {
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    }
  }

  void _onSearchTextChanged(String _) {
    setState(() {});
    _scheduleSearch();
  }

  void _scheduleSearch({bool immediate = false, bool forceRun = false}) {
    if (!forceRun && !_isFindFriendTab) return;
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchRevision++;
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _isSearchLoadingMore = false;
        _searchHasMore = false;
      });
      return;
    }

    final requestID = ++_searchRevision;
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 220);
    _searchDebounce = Timer(delay, () {
      unawaited(_performSearch(query: query, requestID: requestID));
    });
  }

  Future<void> _performSearch({String? query, int? requestID}) async {
    final q = (query ?? _searchController.text).trim();
    final currentRequestID = requestID ?? ++_searchRevision;
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _isSearchLoadingMore = false;
        _searchHasMore = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _isSearchLoadingMore = false;
      _searchHasMore = false;
    });
    final repo = ref.read(friendsRepositoryProvider);
    try {
      final page = await repo.searchUsersPage(
        q,
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted || currentRequestID != _searchRevision) return;
      setState(() {
        _searchResults = page.users;
        _searchHasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted || currentRequestID != _searchRevision) return;
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
      if (mounted && currentRequestID == _searchRevision) {
        setState(() => _searchHasMore = false);
      }
    } finally {
      if (mounted && currentRequestID == _searchRevision) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isSearching || _isSearchLoadingMore || !_searchHasMore) return;
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final requestID = _searchRevision;
    if (!mounted) return;
    setState(() => _isSearchLoadingMore = true);

    final repo = ref.read(friendsRepositoryProvider);
    try {
      final page = await repo.searchUsersPage(
        q,
        limit: _pageSize,
        offset: _searchResults.length,
      );
      if (!mounted || requestID != _searchRevision) return;
      setState(() {
        _searchResults = [..._searchResults, ...page.users];
        _searchHasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted || requestID != _searchRevision) return;
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
      if (mounted && requestID == _searchRevision) {
        setState(() => _searchHasMore = false);
      }
    } finally {
      if (mounted && requestID == _searchRevision) {
        setState(() => _isSearchLoadingMore = false);
      }
    }
  }

  void _updateSearchRelation(
    String userID, {
    required String relationStatus,
    String? requestID,
  }) {
    if (!mounted) return;
    setState(() {
      _searchResults = _searchResults.map((entry) {
        if (entry.user.id != userID) return entry;
        return FriendSearchItem(
          user: entry.user,
          relationStatus: relationStatus,
          requestId: requestID,
        );
      }).toList();
    });
  }

  Future<bool> _confirmRemoveFriend(FriendUserItem user) async {
    final name = _displayName(user);
    final l10n = context.l10n;
    return showGamepadChoiceDialog(
      context: context,
      title: l10n.friendsRemoveTitle,
      message: l10n.friendsRemoveConfirm(name),
      confirmLabel: l10n.friendsRemoveConfirmAction,
    );
  }

  Future<void> _runSearchAction({
    required String key,
    required Future<void> Function(FriendsRepository repo) call,
    required String success,
    required String userID,
    required String nextRelationStatus,
    String? nextRequestID,
  }) async {
    if (_actionsInProgress.contains(key)) return;
    setState(() => _actionsInProgress.add(key));

    final repo = ref.read(friendsRepositoryProvider);
    try {
      await call(repo);
      _showMessage(null, success);
      _updateSearchRelation(
        userID,
        relationStatus: nextRelationStatus,
        requestID: nextRequestID,
      );
      await _refreshSnapshot(refreshSearch: false);
      _refreshRewardBadges();
    } catch (e) {
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    } finally {
      if (mounted) {
        setState(() => _actionsInProgress.remove(key));
      }
    }
  }

  void _refreshRewardBadges() {
    ref.invalidate(tasksUnclaimedCountProvider);
    ref.invalidate(achievementsUnclaimedCountProvider);
  }

  Future<void> _runAction({
    required String key,
    required Future<void> Function(FriendsRepository repo) call,
    required String success,
    bool refreshSearch = true,
  }) async {
    if (_actionsInProgress.contains(key)) return;
    setState(() => _actionsInProgress.add(key));

    final repo = ref.read(friendsRepositoryProvider);
    try {
      await call(repo);
      _showMessage(null, success);
      await _refreshSnapshot(refreshSearch: refreshSearch);
      _refreshRewardBadges();
    } catch (e) {
      if (e is FriendsException) {
        await _handleFriendsException(e);
      } else {
        _showMessage(e.toString(), null);
      }
    } finally {
      if (mounted) {
        setState(() => _actionsInProgress.remove(key));
      }
    }
  }

  bool _busy(String key) => _actionsInProgress.contains(key);

  Widget _buildUserCard({
    required BuildContext context,
    required FriendUserItem user,
    required String subtitle,
    required List<Widget> actions,
    Widget? trailing,
    bool alignActionsRight = false,
    PresenceEntry? presence,
    int? gamepadIndex,
  }) {
    final compactDesktopCard = isWide(context);
    final statusText = presence == null ? null : formatPresenceStatus(presence);
    final card = GradientCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(compactDesktopCard ? 10 : 14),
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showRequestInfoDialog(
                    user: user,
                    presence: presence,
                  ),
                  child: Row(
                    children: [
                      _buildAvatar(
                        user,
                        isOnline: presence?.online,
                        onTap: () => _showRequestInfoDialog(
                          user: user,
                          presence: presence,
                        ),
                      ),
                      SizedBox(width: compactDesktopCard ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(user),
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
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
          SizedBox(height: compactDesktopCard ? 6 : 10),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compactDesktopCard ? 11 : 12,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: alignActionsRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: actions),
            ),
          ],
        ],
      ),
    );
    final highlighted = gamepadIndex != null && _cardHighlighted(gamepadIndex);
    final framed = wrapGamepadCursor(
      highlighted: highlighted,
      radius: 22,
      child: card,
    );
    if (gamepadIndex == null) return framed;
    return KeyedSubtree(key: _gamepadKeyFor(gamepadIndex), child: framed);
  }

  GlobalKey _loaderKeyForTab(_FriendsTabKind tab) {
    return switch (tab) {
      _FriendsTabKind.friends => _friendsLoaderKey,
      _FriendsTabKind.incoming => _incomingLoaderKey,
      _FriendsTabKind.outgoing => _outgoingLoaderKey,
      _FriendsTabKind.findFriend => _searchLoaderKey,
    };
  }

  void _scheduleVisiblePaging({
    required GlobalKey loaderKey,
    required VoidCallback loadMore,
    required bool hasMore,
    required bool loading,
  }) {
    if (_desktopPagingScheduled) return;
    if (!hasMore || loading) return;
    _desktopPagingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _desktopPagingScheduled = false;
      if (!mounted) return;
      final loaderContext = loaderKey.currentContext;
      if (loaderContext == null) return;
      final box = loaderContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) return;
      final origin = box.localToGlobal(Offset.zero);
      final rect = origin & box.size;
      final viewport = MediaQuery.sizeOf(context);
      if (!friendsLoaderIsVisible(
        loaderGlobalRect: rect,
        viewportSize: viewport,
      )) {
        return;
      }
      loadMore();
    });
  }

  void _expandVisibleForTab(_FriendsTabKind tab, int totalCount) {
    if (!mounted) return;
    int current;
    switch (tab) {
      case _FriendsTabKind.friends:
        current = _friendsVisibleCount;
        break;
      case _FriendsTabKind.incoming:
        current = _incomingVisibleCount;
        break;
      case _FriendsTabKind.outgoing:
        current = _outgoingVisibleCount;
        break;
      case _FriendsTabKind.findFriend:
        return; // не используется для поиска
    }
    if (current >= totalCount) return;
    final next = current + _pageSize;
    final nextCount = next > totalCount ? totalCount : next;
    setState(() {
      switch (tab) {
        case _FriendsTabKind.friends:
          _friendsVisibleCount = nextCount;
          break;
        case _FriendsTabKind.incoming:
          _incomingVisibleCount = nextCount;
          break;
        case _FriendsTabKind.outgoing:
          _outgoingVisibleCount = nextCount;
          break;
        case _FriendsTabKind.findFriend:
          break;
      }
    });
  }

  Widget _friendsStatusPane(Widget child) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final phoneLandscape = isPhoneLandscape(context);
    final pad = friendsEmptyStatusPadding(
      phoneLandscape: phoneLandscape,
      keyboardInset: keyboardInset,
    );
    final tight = phoneLandscape || keyboardInset > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - pad.vertical).clamp(32.0, 4000.0)
            : 80.0;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics()),
          padding: pad,
          children: [
            if (tight)
              SizedBox(
                height: bodyHeight,
                child: Center(child: child),
              )
            else
              Center(child: child),
          ],
        );
      },
    );
  }

  Widget _buildAdaptiveList<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required String emptyText,
    required _FriendsTabKind tab,
  }) {
    if (items.isEmpty) {
      return _friendsStatusPane(
        Text(
          emptyText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.25,
          ),
        ),
      );
    }

    final configuredVisibleCount = switch (tab) {
      _FriendsTabKind.friends => _friendsVisibleCount,
      _FriendsTabKind.incoming => _incomingVisibleCount,
      _FriendsTabKind.outgoing => _outgoingVisibleCount,
      _FriendsTabKind.findFriend => items.length,
    };
    final visibleCount = configuredVisibleCount > items.length
        ? items.length
        : configuredVisibleCount;
    final hasMore = visibleCount < items.length;
    final totalCount = visibleCount + (hasMore ? 1 : 0);

    // Плитки на десктопе и на телефоне в landscape (portrait — список).
    final useGrid = useDesktopTiles(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (useGrid) {
          const gap = friendsDesktopGridGap;
          final layout = friendsDesktopGridLayout(
            viewportWidth: constraints.maxWidth,
            phoneLandscape: isPhoneLandscape(context),
            tablet: isTablet(context),
          );
          final itemWidth = layout.itemWidth;
          final availableWidth = layout.contentWidth;
          _beginGamepadCards(
            count: visibleCount,
            columns: layout.crossAxisCount,
            tab: tab,
          );
          final tabActive = _currentTabs.isNotEmpty &&
              _tabController.index >= 0 &&
              _tabController.index < _currentTabs.length &&
              _currentTabs[_tabController.index] == tab;
          if (hasMore && tabActive) {
            _scheduleVisiblePaging(
              loaderKey: _loaderKeyForTab(tab),
              loadMore: () => _expandVisibleForTab(tab, items.length),
              hasMore: hasMore,
              loading: false,
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if ((notification is ScrollUpdateNotification ||
                      notification is ScrollEndNotification) &&
                  hasMore &&
                  tabActive) {
                _scheduleVisiblePaging(
                  loaderKey: _loaderKeyForTab(tab),
                  loadMore: () => _expandVisibleForTab(tab, items.length),
                  hasMore: hasMore,
                  loading: false,
                );
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isPhoneLandscape(context) ? 10 : 16),
              physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics()),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: availableWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.start,
                        children: [
                          for (var i = 0; i < visibleCount; i++)
                            SizedBox(
                              width: itemWidth,
                              child: itemBuilder(items[i], i),
                            ),
                        ],
                      ),
                      if (hasMore)
                        Padding(
                          key: _loaderKeyForTab(tab),
                          padding: const EdgeInsets.only(top: 16),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        _beginGamepadCards(count: visibleCount, columns: 1, tab: tab);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics()),
          itemCount: totalCount,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= visibleCount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _expandVisibleForTab(tab, items.length);
              });
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.topCenter,
              child: itemBuilder(items[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsTab(
      FriendsSnapshot snapshot, Map<String, PresenceEntry> presence) {
    final l10n = context.l10n;
    final searchQuery = _searchController.text.trim();
    final items =
        _sortedAndFilteredFriends(snapshot.friends, presence, searchQuery);
    return _buildAdaptiveList<FriendItem>(
      items: items,
      emptyText: friendsListEmptyText(
        query: searchQuery,
        emptyList: l10n.friendsEmpty,
        nothingFound: l10n.friendsSearchNoMatches,
      ),
      tab: _FriendsTabKind.friends,
      itemBuilder: (item, index) {
        final key = 'remove_${item.user.id}';
        final chatKey = 'chat_${item.user.id}';
        Future<void> openChat() =>
            _openChatWithUser(item.user, actionKey: chatKey);
        Future<void> removeFriend() async {
          final ok = await _confirmRemoveFriend(item.user);
          if (!ok || !mounted) return;
          await _runAction(
            key: key,
            call: (repo) => repo.removeFriend(item.user.id),
            success: l10n.friendsRemoved,
          );
        }

        _registerGamepadActions(
          [openChat, removeFriend],
          onOpen: () => unawaited(
            _showRequestInfoDialog(
              user: item.user,
              presence: presence[item.user.id],
            ),
          ),
        );
        return _buildUserCard(
          context: context,
          user: item.user,
          presence: presence[item.user.id],
          subtitle: l10n.friendsSince(_formatDateTime(item.createdAt)),
          gamepadIndex: index,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 0,
                child: _buildCompactIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: l10n.gameWriteMessage,
                  loading: _busy(chatKey),
                  onPressed: _busy(chatKey) ? null : openChat,
                ),
              ),
              const SizedBox(width: 14),
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 1,
                child: _buildCompactIconButton(
                  icon: Icons.person_remove_alt_1_rounded,
                  tooltip: l10n.friendsRemove,
                  danger: true,
                  loading: _busy(key),
                  onPressed: _busy(key) ? null : removeFriend,
                ),
              ),
            ],
          ),
          actions: const [],
        );
      },
    );
  }

  Widget _buildIncomingTab(
      FriendsSnapshot snapshot, Map<String, PresenceEntry> presence) {
    final l10n = context.l10n;
    final searchQuery = _searchController.text.trim();
    final items = _filteredRequests(snapshot.incoming, searchQuery);
    return _buildAdaptiveList<FriendRequestItem>(
      items: items,
      emptyText: friendsListEmptyText(
        query: searchQuery,
        emptyList: l10n.friendsNoIncoming,
        nothingFound: l10n.friendsIncomingSearchNoMatches,
      ),
      tab: _FriendsTabKind.incoming,
      itemBuilder: (item, index) {
        final acceptKey = 'accept_${item.requestId}';
        final rejectKey = 'reject_${item.requestId}';
        final chatKey = 'chat_incoming_${item.user.id}';
        Future<void> openChat() =>
            _openChatWithUser(item.user, actionKey: chatKey);
        Future<void> accept() => _runAction(
              key: acceptKey,
              call: (repo) => repo.acceptRequest(item.requestId),
              success: l10n.friendsRequestAccepted,
            );
        Future<void> reject() => _runAction(
              key: rejectKey,
              call: (repo) => repo.rejectRequest(item.requestId),
              success: l10n.friendsRequestDeclined,
            );
        _registerGamepadActions(
          [openChat, accept, reject],
          onOpen: () => unawaited(
            _showRequestInfoDialog(
              user: item.user,
              presence: presence[item.user.id],
            ),
          ),
        );
        return _buildUserCard(
          context: context,
          user: item.user,
          presence: presence[item.user.id],
          subtitle: l10n.friendsIncomingAt(_formatDateTime(item.createdAt)),
          gamepadIndex: index,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 0,
                child: _buildCompactIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: l10n.gameWriteMessage,
                  loading: _busy(chatKey),
                  onPressed: _busy(chatKey) ? null : openChat,
                ),
              ),
              const SizedBox(width: 14),
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 1,
                child: _buildActionIcon(
                  key: acceptKey,
                  icon: Icons.check_rounded,
                  tooltip: l10n.friendsAcceptRequest,
                  call: (repo) => repo.acceptRequest(item.requestId),
                  success: l10n.friendsRequestAccepted,
                  successStyle: true,
                ),
              ),
              const SizedBox(width: 4),
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 2,
                child: _buildActionIcon(
                  key: rejectKey,
                  icon: Icons.close_rounded,
                  tooltip: l10n.friendsDeclineRequest,
                  call: (repo) => repo.rejectRequest(item.requestId),
                  success: l10n.friendsRequestDeclined,
                  danger: true,
                ),
              ),
            ],
          ),
          actions: const [],
        );
      },
    );
  }

  Widget _buildOutgoingTab(
      FriendsSnapshot snapshot, Map<String, PresenceEntry> presence) {
    final l10n = context.l10n;
    final searchQuery = _searchController.text.trim();
    final items = _filteredRequests(snapshot.outgoing, searchQuery);
    return _buildAdaptiveList<FriendRequestItem>(
      items: items,
      emptyText: friendsListEmptyText(
        query: searchQuery,
        emptyList: l10n.friendsNoOutgoing,
        nothingFound: l10n.friendsOutgoingSearchNoMatches,
      ),
      tab: _FriendsTabKind.outgoing,
      itemBuilder: (item, index) {
        final cancelKey = 'cancel_${item.requestId}';
        final chatKey = 'chat_outgoing_${item.user.id}';
        Future<void> openChat() =>
            _openChatWithUser(item.user, actionKey: chatKey);
        Future<void> cancel() => _runAction(
              key: cancelKey,
              call: (repo) => repo.cancelRequest(item.requestId),
              success: l10n.friendsRequestCancelled,
            );
        _registerGamepadActions(
          [openChat, cancel],
          onOpen: () => unawaited(
            _showRequestInfoDialog(
              user: item.user,
              presence: presence[item.user.id],
            ),
          ),
        );
        return _buildUserCard(
          context: context,
          user: item.user,
          presence: presence[item.user.id],
          subtitle: l10n.friendsOutgoingAt(_formatDateTime(item.createdAt)),
          gamepadIndex: index,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 0,
                child: _buildCompactIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: l10n.gameWriteMessage,
                  loading: _busy(chatKey),
                  onPressed: _busy(chatKey) ? null : openChat,
                ),
              ),
              const SizedBox(width: 14),
              _gamepadActionFrame(
                cardIndex: index,
                actionIndex: 1,
                child: _buildActionIcon(
                  key: cancelKey,
                  icon: Icons.close_rounded,
                  tooltip: l10n.friendsCancelRequest,
                  call: (repo) => repo.cancelRequest(item.requestId),
                  success: l10n.friendsRequestCancelled,
                  danger: true,
                ),
              ),
            ],
          ),
          actions: const [],
        );
      },
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool danger = false,
    bool success = false,
    bool loading = false,
  }) {
    return FramedIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      loading: loading,
      size: 34,
      iconSize: 18,
      borderRadius: 10,
      borderWidth: 1.5,
      iconColor: danger
          ? Colors.red.shade700
          : success
              ? const Color(0xFF16A34A)
              : AppColors.textPrimary,
    );
  }

  Widget _buildActionIcon({
    required String key,
    required IconData icon,
    required String tooltip,
    required Future<void> Function(FriendsRepository repo) call,
    required String success,
    bool danger = false,
    bool successStyle = false,
  }) {
    final busy = _busy(key);
    return _buildCompactIconButton(
      icon: icon,
      tooltip: tooltip,
      danger: danger,
      success: successStyle,
      loading: busy,
      onPressed: busy
          ? null
          : () => _runAction(
                key: key,
                call: call,
                success: success,
              ),
    );
  }

  Widget _buildGradientHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    // Та же мягкая лавандовая рамка, что у свайп-кнопок / «добавить» в чатах.
    return FramedIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      filled: !active,
      iconColor: active ? Colors.red.shade700 : AppColors.textPrimary,
    );
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    FriendSearchItem item,
    Map<String, PresenceEntry> presence, {
    required int index,
  }) {
    final l10n = context.l10n;
    final relation = item.relationStatus;
    final sendKey = 'send_${item.user.id}';
    final cancelKey = 'cancel_search_${item.requestId ?? item.user.id}';
    final acceptKey = 'accept_search_${item.requestId ?? item.user.id}';
    final rejectKey = 'reject_search_${item.requestId ?? item.user.id}';
    final removeKey = 'remove_search_${item.user.id}';
    final chatKey = 'chat_search_${item.user.id}';

    final controls = <Widget>[];
    final gamepadActions = <VoidCallback>[];
    if (relation == 'none') {
      final busy = _busy(sendKey);
      Future<void> send() => _runSearchAction(
            key: sendKey,
            call: (repo) => repo.sendRequest(item.user.id),
            success: l10n.friendsRequestSent,
            userID: item.user.id,
            nextRelationStatus: 'outgoing',
            nextRequestID: item.requestId,
          );
      gamepadActions.add(send);
      controls.add(
        _buildCompactIconButton(
          icon: Icons.person_add_alt_1_rounded,
          tooltip: l10n.friendsAdd,
          loading: busy,
          onPressed: busy ? null : send,
        ),
      );
    } else if (relation == 'outgoing' && item.requestId != null) {
      final busy = _busy(cancelKey);
      Future<void> cancel() => _runSearchAction(
            key: cancelKey,
            call: (repo) => repo.cancelRequest(item.requestId!),
            success: l10n.friendsRequestCancelled,
            userID: item.user.id,
            nextRelationStatus: 'none',
          );
      gamepadActions.add(cancel);
      controls.add(
        _buildCompactIconButton(
          icon: Icons.close_rounded,
          tooltip: l10n.friendsCancelRequest,
          danger: true,
          loading: busy,
          onPressed: busy ? null : cancel,
        ),
      );
    } else if (relation == 'incoming' && item.requestId != null) {
      final acceptBusy = _busy(acceptKey);
      final rejectBusy = _busy(rejectKey);
      Future<void> accept() => _runSearchAction(
            key: acceptKey,
            call: (repo) => repo.acceptRequest(item.requestId!),
            success: l10n.friendsRequestAccepted,
            userID: item.user.id,
            nextRelationStatus: 'friend',
          );
      Future<void> reject() => _runSearchAction(
            key: rejectKey,
            call: (repo) => repo.rejectRequest(item.requestId!),
            success: l10n.friendsRequestDeclined,
            userID: item.user.id,
            nextRelationStatus: 'none',
          );
      gamepadActions.addAll([accept, reject]);
      controls.addAll([
        _buildCompactIconButton(
          icon: Icons.check_rounded,
          tooltip: l10n.friendsAcceptRequest,
          success: true,
          loading: acceptBusy,
          onPressed: acceptBusy ? null : accept,
        ),
        _buildCompactIconButton(
          icon: Icons.close_rounded,
          tooltip: l10n.friendsDeclineRequest,
          danger: true,
          loading: rejectBusy,
          onPressed: rejectBusy ? null : reject,
        ),
      ]);
    } else if (relation == 'friend') {
      final removeBusy = _busy(removeKey);
      Future<void> openChat() =>
          _openChatWithUser(item.user, actionKey: chatKey);
      Future<void> removeFriend() async {
        final ok = await _confirmRemoveFriend(item.user);
        if (!ok || !mounted) return;
        await _runSearchAction(
          key: removeKey,
          call: (repo) => repo.removeFriend(item.user.id),
          success: l10n.friendsRemoved,
          userID: item.user.id,
          nextRelationStatus: 'none',
        );
      }

      gamepadActions.addAll([openChat, removeFriend]);
      controls.addAll([
        _buildCompactIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: l10n.gameWriteMessage,
          loading: _busy(chatKey),
          onPressed: _busy(chatKey) ? null : openChat,
        ),
        _buildCompactIconButton(
          icon: Icons.person_remove_alt_1_rounded,
          tooltip: l10n.friendsRemove,
          danger: true,
          loading: removeBusy,
          onPressed: removeBusy ? null : removeFriend,
        ),
      ]);
    }

    final relationLabel = switch (relation) {
      'friend' => l10n.friendsAlreadyFriends,
      'incoming' => l10n.friendsIncomingStatus,
      'outgoing' => l10n.friendsOutgoingStatus,
      _ => l10n.friendsNotFriends,
    };

    final controlRow = <Widget>[];
    for (var i = 0; i < controls.length; i++) {
      if (i > 0) {
        controlRow.add(const SizedBox(width: 4));
      }
      controlRow.add(
        _gamepadActionFrame(
          cardIndex: index,
          actionIndex: i,
          child: controls[i],
        ),
      );
    }
    _registerGamepadActions(
      gamepadActions,
      onOpen: () => unawaited(
        _showRequestInfoDialog(
          user: item.user,
          presence: presence[item.user.id],
        ),
      ),
    );

    return _buildUserCard(
      context: context,
      user: item.user,
      presence: presence[item.user.id],
      subtitle: relationLabel,
      gamepadIndex: index,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: controlRow),
      actions: const [],
    );
  }

  Widget _buildSearchPanel() {
    final focused = _searchFocusNode.hasFocus;
    final phoneLand = isPhoneLandscape(context);
    final tight = phoneLand || MediaQuery.viewInsetsOf(context).bottom > 0;
    final showCollapse = focused;
    final showClear = _searchController.text.isNotEmpty;
    Widget? suffix;
    if (showClear || showCollapse) {
      suffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showClear)
            IconButton(
              tooltip: context.l10n.commonClear,
              onPressed: () {
                _searchDebounce?.cancel();
                _searchRevision++;
                _searchController.clear();
                setState(() {
                  _searchResults = const [];
                  _isSearching = false;
                  _isSearchLoadingMore = false;
                  _searchHasMore = false;
                });
                _focusSearchField();
              },
              icon: Icon(Icons.close_rounded, color: Colors.red.shade600),
            ),
          if (showCollapse)
            IconButton(
              tooltip: context.l10n.friendsCollapseSearch,
              onPressed: _toggleSearch,
              icon: const Icon(Icons.search_off_rounded),
            ),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, tight ? 4 : 10),
      child: FriendsGamepadLtHint(
        expandChild: true,
        child: GamepadFieldBlock(
          inputFocus: _searchFocusNode,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(
                // В фокусе — тот же фиолет, что у рамки лупы.
                color: focused
                    ? AppColors.accentStart
                    : AppColors.accentStart.withValues(alpha: 0.45),
                width: focused ? 2 : 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              readOnly: gamepadConnected(),
              showCursor: true,
              // null = AutofillConfiguration.disabled → autocomplete=off на web.
              // Иначе дефолт [] оставляет autocomplete=on и iOS Safari
              // показывает панель Passwords / Payment / Locations над клавиатурой.
              autofillHints: null,
              enableSuggestions: false,
              autocorrect: false,
              enableIMEPersonalizedLearning: false,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: context.l10n.friendsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: suffix,
                suffixIconConstraints: suffix == null
                    ? null
                    : const BoxConstraints(minWidth: 48, minHeight: 40),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: tight ? 8 : 12,
                ),
              ),
              onChanged: _onSearchTextChanged,
              onSubmitted: (_) => _scheduleSearch(immediate: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(Map<String, PresenceEntry> presence) {
    final l10n = context.l10n;
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return _friendsStatusPane(
        Text(
          l10n.friendsSearchPrompt,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_isSearching) {
      return _friendsStatusPane(
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentStart,
          ),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return _friendsStatusPane(
        Text(
          l10n.friendsNothingFound,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.25,
          ),
        ),
      );
    }
    final showPagingLoader = _isSearchLoadingMore || _searchHasMore;
    final itemCount = _searchResults.length + (showPagingLoader ? 1 : 0);

    if (useDesktopTiles(context)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const gap = friendsDesktopGridGap;
          final layout = friendsDesktopGridLayout(
            viewportWidth: constraints.maxWidth,
            phoneLandscape: isPhoneLandscape(context),
            tablet: isTablet(context),
          );
          final itemWidth = layout.itemWidth;
          final availableWidth = layout.contentWidth;
          _beginGamepadCards(
            count: _searchResults.length,
            columns: layout.crossAxisCount,
            tab: _FriendsTabKind.findFriend,
          );
          if (_isFindFriendTab && _searchHasMore && !_isSearchLoadingMore) {
            _scheduleVisiblePaging(
              loaderKey: _searchLoaderKey,
              loadMore: () => unawaited(_loadMoreSearchResults()),
              hasMore: _searchHasMore,
              loading: _isSearchLoadingMore,
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if ((notification is ScrollUpdateNotification ||
                      notification is ScrollEndNotification) &&
                  _isFindFriendTab &&
                  _searchHasMore &&
                  !_isSearchLoadingMore) {
                _scheduleVisiblePaging(
                  loaderKey: _searchLoaderKey,
                  loadMore: () => unawaited(_loadMoreSearchResults()),
                  hasMore: _searchHasMore,
                  loading: _isSearchLoadingMore,
                );
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics()),
              padding: EdgeInsets.all(isPhoneLandscape(context) ? 10 : 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: availableWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.start,
                        children: [
                          for (var i = 0; i < _searchResults.length; i++)
                            SizedBox(
                              width: itemWidth,
                              child: _buildSearchResultCard(
                                context,
                                _searchResults[i],
                                presence,
                                index: i,
                              ),
                            ),
                        ],
                      ),
                      if (showPagingLoader)
                        Padding(
                          key: _searchLoaderKey,
                          padding: const EdgeInsets.only(top: 16),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentStart,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    _beginGamepadCards(
      count: _searchResults.length,
      columns: 1,
      tab: _FriendsTabKind.findFriend,
    );
    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          if (_searchHasMore && !_isSearchLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_loadMoreSearchResults());
            });
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentStart,
                ),
              ),
            ),
          );
        }
        return Align(
          alignment: Alignment.topCenter,
          child: _buildSearchResultCard(
            context,
            _searchResults[index],
            presence,
            index: index,
          ),
        );
      },
    );
  }

  Widget _buildWideHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const inset = 16.0;
        final width = (constraints.maxWidth - inset * 2)
            .clamp(0.0, friendsDesktopMaxContentWidth);
        return Padding(
          padding: const EdgeInsets.fromLTRB(inset, 8, inset, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: width,
              child: FriendsGamepadLtHint(
                expandChild: true,
                child: _buildInlineSearchField(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineSearchField() {
    final focused = _searchFocusNode.hasFocus;
    return GamepadFieldBlock(
      inputFocus: _searchFocusNode,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: focused
                ? AppColors.accentStart
                : AppColors.accentStart.withValues(alpha: 0.45),
            width: focused ? 2 : 1.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          readOnly: gamepadConnected(),
          showCursor: true,
          autofillHints: null,
          enableSuggestions: false,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.friendsSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.commonClose,
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchRevision++;
                      _searchController.clear();
                      setState(() {
                        _searchResults = const [];
                        _isSearching = false;
                        _isSearchLoadingMore = false;
                        _searchHasMore = false;
                      });
                      _focusSearchField();
                    },
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: Colors.red.shade600),
                  ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: _onSearchTextChanged,
          onSubmitted: (_) => _scheduleSearch(immediate: true),
        ),
      ),
    );
  }

  List<_FriendsTabKind> _visibleTabs(FriendsSnapshot? snapshot) {
    // Пока нет данных — все табы, чтобы не дёргать layout на первом кадре.
    if (snapshot == null) {
      return const [
        _FriendsTabKind.friends,
        _FriendsTabKind.incoming,
        _FriendsTabKind.outgoing,
        _FriendsTabKind.findFriend,
      ];
    }
    return [
      if (snapshot.friends.isNotEmpty) _FriendsTabKind.friends,
      if (snapshot.incoming.isNotEmpty) _FriendsTabKind.incoming,
      if (snapshot.outgoing.isNotEmpty) _FriendsTabKind.outgoing,
      _FriendsTabKind.findFriend,
    ];
  }

  String _tabTitle(AppLocalizations l10n, _FriendsTabKind tab) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return l10n.friendsTabFriends;
      case _FriendsTabKind.incoming:
        return l10n.friendsTabIncoming;
      case _FriendsTabKind.outgoing:
        return l10n.friendsTabOutgoing;
      case _FriendsTabKind.findFriend:
        return l10n.friendsFindTab;
    }
  }

  int? _tabCount(
    _FriendsTabKind tab,
    FriendsSnapshot? snapshot,
    int? totalUsersCount,
  ) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return snapshot?.friends.length;
      case _FriendsTabKind.incoming:
        return snapshot?.incoming.length;
      case _FriendsTabKind.outgoing:
        return snapshot?.outgoing.length;
      case _FriendsTabKind.findFriend:
        return totalUsersCount;
    }
  }

  Widget _countBadge(int count, TextStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count', style: style),
    );
  }

  Widget _buildTabLabel(
    _FriendsTabKind tab,
    FriendsSnapshot? snapshot,
    int? totalUsersCount, {
    required bool inline,
  }) {
    final title = _tabTitle(context.l10n, tab);
    final count = _tabCount(tab, snapshot, totalUsersCount);
    final countStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: friendsTabCountColor(
        incoming: tab == _FriendsTabKind.incoming,
        findFriend: tab == _FriendsTabKind.findFriend,
        count: count ?? 0,
      ),
    );
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: inline ? TextOverflow.clip : TextOverflow.ellipsis,
      softWrap: false,
      textAlign: TextAlign.center,
    );
    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,
          if (count != null) ...[
            const SizedBox(width: 6),
            _countBadge(count, countStyle),
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (count != null)
          _countBadge(count, countStyle)
        else
          const SizedBox(height: 18),
        const SizedBox(height: 4),
        titleWidget,
      ],
    );
  }

  Widget _buildTabBar({
    required List<_FriendsTabKind> tabs,
    required FriendsSnapshot? snapshot,
    required int? totalUsersCount,
    required bool compact,
  }) {
    final packed = friendsUsePackedTabs(
      width: MediaQuery.sizeOf(context).width,
      phoneLandscape: isPhoneLandscape(context),
    );
    final fontSize = compact ? (tabs.length <= 2 ? 14.0 : 12.0) : 15.0;
    final bar = TabBar(
      controller: _tabController,
      isScrollable: packed,
      tabAlignment: packed ? TabAlignment.start : TabAlignment.fill,
      indicatorSize:
          packed ? TabBarIndicatorSize.label : TabBarIndicatorSize.tab,
      labelPadding:
          EdgeInsets.only(right: packed ? 22 : 4, left: packed ? 0 : 4),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.accentStart, width: 2.5),
      ),
      dividerColor: AppColors.accentStart.withValues(alpha: 0.16),
      overlayColor: WidgetStatePropertyAll(
        AppColors.accentStart.withValues(alpha: 0.06),
      ),
      labelColor: AppColors.accentStart,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        for (final tab in tabs)
          Tab(
            height: packed ? 40 : 48,
            child: _buildTabLabel(
              tab,
              snapshot,
              totalUsersCount,
              inline: packed,
            ),
          ),
      ],
    );
    if (!packed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: bar,
      );
    }
    final inset = isPhoneLandscape(context) ? 10.0 : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - inset * 2)
            .clamp(0.0, friendsDesktopMaxContentWidth);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: width, child: bar),
          ),
        );
      },
    );
  }

  Widget _tabContent(_FriendsTabKind tab, FriendsSnapshot snapshot,
      Map<String, PresenceEntry> presence) {
    switch (tab) {
      case _FriendsTabKind.friends:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(),
          child: _buildFriendsTab(snapshot, presence),
        );
      case _FriendsTabKind.incoming:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(),
          child: _buildIncomingTab(snapshot, presence),
        );
      case _FriendsTabKind.outgoing:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(),
          child: _buildOutgoingTab(snapshot, presence),
        );
      case _FriendsTabKind.findFriend:
        return RefreshIndicator(
          onRefresh: () => _refreshSnapshot(refreshSearch: true),
          child: _buildSearchResults(presence),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(friendsNavTapTickProvider, (_, __) {
      _onFriendsNavTap();
    });
    final presence = ref.watch(presenceMapProvider).valueOrNull ?? const {};
    final friendsAsync = ref.watch(friendsSnapshotProvider);
    final totalUsersAsync = ref.watch(totalUsersCountProvider);
    final friendsSnapshot = friendsAsync.valueOrNull;
    // Сначала число из списка друзей — оно уже на экране. Опрос только
    // обновляет его, не прячет бейдж и не крутит счётчик с нуля.
    final liveUsersCount = totalUsersAsync.when(
      data: (v) => v,
      loading: () => totalUsersAsync.valueOrNull,
      error: (_, __) => totalUsersAsync.valueOrNull,
    );
    final totalUsersCount = friendsFindTabCount(
      live: liveUsersCount,
      snapshot: friendsSnapshot?.usersCount,
    );
    final tabs = _visibleTabs(friendsSnapshot);
    if (!_sameTabs(tabs, _currentTabs) ||
        _tabController.length != tabs.length) {
      _syncTabController(tabs);
    }
    _applyIncomingDeepLinkIfNeeded();
    final compact = MediaQuery.sizeOf(context).width < 430;
    final wide = isWide(context);
    final hideTabs = friendsHideTabsForKeyboard(
      landscape:
          MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height,
      keyboardInset: MediaQuery.viewInsetsOf(context).bottom,
    );
    final path = ref.watch(currentRoutePathProvider);
    if (!wide && path == '/friends') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted) return;
          ref.read(mobileToolbarLeadingProvider.notifier).state =
              FriendsGamepadLtHint(
            child: _buildGradientHeaderIconButton(
              icon: _isSearchExpanded
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
              tooltip: _isSearchExpanded
                  ? context.l10n.friendsCollapseSearch
                  : context.l10n.friendsExpandSearch,
              onPressed: _toggleSearch,
              active: _isSearchExpanded,
            ),
          );
        });
      });
    }
    return GamepadScope(
      onAction: _onGamepad,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Клавиатуру уже вычел AppShell — иначе поиск и список без высоты.
        resizeToAvoidBottomInset: !KeyboardInsetScope.handledOf(context),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) _buildWideHeader(),
              if (!wide)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  // Поле поиска всегда в дереве, свёрнутое — просто нулевой
                  // высоты. Иначе оно создаётся вместе с панелью, фокус уходит
                  // в новый элемент на следующем кадре и клавиатура не выезжает
                  // с первого тапа.
                  child: ClipRect(
                    child: AnimatedAlign(
                      duration: AppDurations.short,
                      alignment: Alignment.topCenter,
                      heightFactor: _isSearchExpanded ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isSearchExpanded,
                        child: _buildSearchPanel(),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: double.infinity),
                    child: Column(
                      key: const ValueKey('friends-tabs'),
                      children: [
                        if (!hideTabs)
                          Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            descendantsAreFocusable: false,
                            descendantsAreTraversable: false,
                            child: FriendsGamepadTabSticks(
                              child: _buildTabBar(
                                tabs: tabs,
                                snapshot: friendsSnapshot,
                                totalUsersCount: totalUsersCount,
                                compact: compact,
                              ),
                            ),
                          ),
                        Expanded(
                          child: friendsAsync.when(
                            data: (snapshot) {
                              return TabBarView(
                                controller: _tabController,
                                // Свайп между табами друзей; bottom-nav от
                                // history защищён через Router.neglect.
                                physics: const PageScrollPhysics(),
                                children: [
                                  for (final tab in tabs)
                                    _tabContent(tab, snapshot, presence),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentStart,
                              ),
                            ),
                            error: (err, _) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 46,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      err.toString(),
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Colors.red.shade700),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
