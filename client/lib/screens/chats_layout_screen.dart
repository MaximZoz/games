import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/chat_room_screen.dart';
import 'package:multigames_client/screens/chats_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

/// Комбинированный экран чатов: двухпанельный layout на десктопе (список слева,
/// диалог справа в стиле Telegram), штатный stack на мобиле.
class ChatsLayoutScreen extends ConsumerWidget {
  const ChatsLayoutScreen({
    super.key,
    this.chatId,
    this.peerName,
    this.fromFriends = false,
    this.fromGames = false,
    this.gameReturnPath,
  });

  final String? chatId;
  final String? peerName;
  final bool fromFriends;
  final bool fromGames;
  final String? gameReturnPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = isWide(context);

    if (!wide) {
      if (chatId != null && chatId!.isNotEmpty) {
        return ChatRoomScreen(
          chatID: chatId!,
          peerName: peerName,
          fromFriends: fromFriends,
          fromGames: fromGames,
          gameReturnPath: gameReturnPath,
        );
      }
      return const ChatsScreen();
    }

    return _DesktopChatsLayout(
      chatId: chatId,
      peerName: peerName,
      fromFriends: fromFriends,
      fromGames: fromGames,
      gameReturnPath: gameReturnPath,
    );
  }
}

const double _sidebarExpandedWidth = 360;
const double _sidebarCollapsedWidth = 72;

@visibleForTesting
const double chatsSidebarToggleWidth = 20;

@visibleForTesting
const double chatsSidebarToggleHeight = 36;

@visibleForTesting
const double chatsSidebarToggleLeftInset = 14;

@visibleForTesting
const double chatsSidebarLineWidth = 2;

@visibleForTesting
const double chatsSidebarSwipeThreshold = 48;

@visibleForTesting
Color chatsSidebarDividerColor() =>
    AppColors.accentSoft.withValues(alpha: 0.6);

/// Линия проходит через центр тогла и касается его заливки.
@visibleForTesting
double chatsSidebarLineLeft(double panelWidth) {
  final toggleCenter =
      panelWidth - chatsSidebarToggleLeftInset + chatsSidebarToggleWidth / 2;
  return toggleCenter - chatsSidebarLineWidth / 2;
}

@visibleForTesting
bool chatsSidebarSwipeShouldToggle({
  required bool collapsed,
  required double dx,
  double threshold = chatsSidebarSwipeThreshold,
}) {
  if (dx.abs() < threshold) return false;
  return collapsed ? dx > 0 : dx < 0;
}

class _DesktopChatsLayout extends ConsumerStatefulWidget {
  const _DesktopChatsLayout({
    this.chatId,
    this.peerName,
    this.fromFriends = false,
    this.fromGames = false,
    this.gameReturnPath,
  });

  final String? chatId;
  final String? peerName;
  final bool fromFriends;
  final bool fromGames;
  final String? gameReturnPath;

  @override
  ConsumerState<_DesktopChatsLayout> createState() => _DesktopChatsLayoutState();
}

class _DesktopChatsLayoutState extends ConsumerState<_DesktopChatsLayout> {
  double _swipeDx = 0;
  bool _swipeTriggered = false;

  void _resetSwipe() {
    _swipeDx = 0;
    _swipeTriggered = false;
  }

  void _toggleSidebar() {
    final collapsed = ref.read(chatsSidebarCollapsedProvider);
    ref.read(chatsSidebarCollapsedProvider.notifier).state = !collapsed;
  }

  void _onSwipeStart(DragStartDetails _) => _resetSwipe();

  void _onSwipeUpdate(DragUpdateDetails details) {
    if (_swipeTriggered) return;
    _swipeDx += details.delta.dx;
    final collapsed = ref.read(chatsSidebarCollapsedProvider);
    if (chatsSidebarSwipeShouldToggle(collapsed: collapsed, dx: _swipeDx)) {
      _swipeTriggered = true;
      _toggleSidebar();
    }
  }

  void _onSwipeEnd(DragEndDetails _) => _resetSwipe();

  @override
  Widget build(BuildContext context) {
    final sidebarCollapsed = ref.watch(chatsSidebarCollapsedProvider);
    final showChatList = !widget.fromFriends && !widget.fromGames;
    final panelWidth =
        sidebarCollapsed ? _sidebarCollapsedWidth : _sidebarExpandedWidth;
    final dividerColor = chatsSidebarDividerColor();
    final lineLeft = chatsSidebarLineLeft(panelWidth);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showChatList)
              SizedBox(
                width: panelWidth + 32,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: _onSwipeStart,
                  onHorizontalDragUpdate: _onSwipeUpdate,
                  onHorizontalDragEnd: _onSwipeEnd,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: panelWidth,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: panelWidth,
                          color: Colors.transparent,
                          child: ClipRect(
                            child: ChatsScreen(
                              inSplitView: true,
                              sidebarCompact: sidebarCollapsed,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: lineLeft,
                        top: 0,
                        bottom: 0,
                        width: chatsSidebarLineWidth,
                        child: ColoredBox(color: dividerColor),
                      ),
                      Positioned(
                        left: panelWidth - chatsSidebarToggleLeftInset,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: dividerColor,
                            borderRadius: BorderRadius.circular(10),
                            elevation: 1,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _toggleSidebar,
                              child: Tooltip(
                                message: sidebarCollapsed
                                    ? context.l10n.chatsExpandPanel
                                    : context.l10n.chatsCollapsePanel,
                                child: SizedBox(
                                  width: chatsSidebarToggleWidth,
                                  height: chatsSidebarToggleHeight,
                                  child: Center(
                                    child: Icon(
                                      sidebarCollapsed
                                          ? Icons.chevron_right_rounded
                                          : Icons.chevron_left_rounded,
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.9),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: widget.chatId != null && widget.chatId!.isNotEmpty
                  ? ClipRect(
                      child: ChatRoomScreen(
                        key: ValueKey('chat_${widget.chatId}'),
                        chatID: widget.chatId!,
                        peerName: widget.peerName,
                        fromFriends: widget.fromFriends,
                        fromGames: widget.fromGames,
                        gameReturnPath: widget.gameReturnPath,
                        inSplitView: (widget.fromFriends || widget.fromGames)
                            ? false
                            : true,
                      ),
                    )
                  : _buildEmptyState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: AppColors.surfaceUnified.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentSoft.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentStart.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.accentStart.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.chatsSelectChat,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.chatsSelectHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
