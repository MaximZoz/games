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
  @override
  Widget build(BuildContext context) {
    final sidebarCollapsed = ref.watch(chatsSidebarCollapsedProvider);
    final showChatList = !widget.fromFriends && !widget.fromGames;
    final panelWidth = sidebarCollapsed ? _sidebarCollapsedWidth : _sidebarExpandedWidth;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showChatList)
              SizedBox(
                width: panelWidth + 32,
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
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            right: BorderSide(
                              color: AppColors.accentSoft.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ClipRect(
                          child: ChatsScreen(
                            inSplitView: true,
                            sidebarCompact: sidebarCollapsed,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: panelWidth - 14,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: AppColors.accentSoft.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          elevation: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => ref.read(chatsSidebarCollapsedProvider.notifier).state = !sidebarCollapsed,
                            child: Tooltip(
                              message: sidebarCollapsed ? context.l10n.chatsExpandPanel : context.l10n.chatsCollapsePanel,
                              child: Container(
                                width: 20,
                                height: 36,
                                alignment: Alignment.center,
                                child: Icon(
                                  sidebarCollapsed
                                    ? Icons.chevron_right_rounded
                                    : Icons.chevron_left_rounded,
                                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                                  size: 18,
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
                        inSplitView: (widget.fromFriends || widget.fromGames) ? false : true,
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
