import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/screens/game_stats_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';

/// Секция счёта head-to-head в попапе профиля при клике на игрока.
///
/// По каждой игре: иконка игры + цифры победа/поражение/ничья сверху вниз
/// на высоту иконки. Сразу за блоком — иконка статистики (если разрешено).
class HeadToHeadSection extends ConsumerWidget {
  const HeadToHeadSection({
    super.key,
    required this.opponentId,
    this.opponentName,
    this.padding = const EdgeInsets.only(top: 12),
  });

  final String opponentId;
  final String? opponentName;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (opponentId.isEmpty) return const SizedBox.shrink();
    final h2hAsync = ref.watch(headToHeadProvider(opponentId));

    return Padding(
      padding: padding,
      child: h2hAsync.when(
        loading: () => const _HeadToHeadSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
        data: (h2h) {
          final games = h2h.games;
          final showStats = h2h.showStatsToOthers;
          if (games.isEmpty && !showStats) return const SizedBox.shrink();
          return _HeadToHeadBody(
            games: games,
            showStats: showStats,
            onTapStats: () {
              final name = (opponentName ?? h2h.displayName).trim();
              // Из попапа профиля — статистика тоже во всплывашке.
              // С главной (/stats) остаётся полноэкранный виджет.
              showDialog<void>(
                context: context,
                builder: (ctx) {
                  final title = name.isNotEmpty
                      ? name
                      : context.l10n.statsTitle;
                  void close() {
                    final nav = Navigator.of(ctx);
                    if (nav.canPop()) nav.pop();
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    focusFirstVisibleGamepadTarget();
                  });
                  return GamepadScope(
                    exclusive: true,
                    onAction: (action) {
                      if (action == GamepadAction.cancel) {
                        close();
                        return true;
                      }
                      if (action.isScroll || action.isDirection) {
                        return handleGamepadUiAction(ctx, action);
                      }
                      return true;
                    },
                    child: GamepadNavGroup(
                      name: 'h2h-stats-popup',
                      exclusive: true,
                      child: Dialog(
                        backgroundColor: AppColors.surfaceUnified,
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 520,
                            maxHeight: 640,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GamepadFocusBlock(
                                      autofocus: true,
                                      radius: 18,
                                      onActivate: close,
                                      child: IconButton(
                                        onPressed: close,
                                        icon: const Icon(Icons.close_rounded),
                                        tooltip: context.l10n.commonClose,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: GameStatsBody(
                                  userId: opponentId,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    20,
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
            },
          );
        },
      ),
    );
  }
}

class _HeadToHeadBody extends StatelessWidget {
  const _HeadToHeadBody({
    required this.games,
    required this.showStats,
    required this.onTapStats,
  });

  final List<GameTypeScore> games;
  final bool showStats;
  final VoidCallback onTapStats;

  @override
  Widget build(BuildContext context) {
    final hasScore = games.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasScore) ...[
          Text(
            context.l10n.statsYourScore,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasScore)
              Expanded(
                child: HeadToHeadScoreStrip(games: games),
              ),
            if (hasScore && showStats) const SizedBox(width: 8),
            if (showStats) StatsIconButton(onTap: onTapStats),
          ],
        ),
      ],
    );
  }
}

/// Карточки игр со счётом в одной горизонтальной полосе.
class HeadToHeadScoreStrip extends StatefulWidget {
  const HeadToHeadScoreStrip({
    super.key,
    required this.games,
    this.controller,
  });

  final List<GameTypeScore> games;
  final ScrollController? controller;

  @override
  State<HeadToHeadScoreStrip> createState() => _HeadToHeadScoreStripState();
}

class _HeadToHeadScoreStripState extends State<HeadToHeadScoreStrip> {
  ScrollController? _owned;

  ScrollController get _controller =>
      widget.controller ?? (_owned ??= ScrollController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta = event.scrollDelta.dy != 0
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) return;
    final pos = _controller.position;
    final next =
        (_controller.offset + delta).clamp(0.0, pos.maxScrollExtent);
    if (next == _controller.offset) return;
    _controller.jumpTo(next);
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: widget.games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final g = widget.games[index];
              return Center(
                child: GameTypeScoreChip(
                  gameType: g.gameType,
                  won: g.won,
                  lost: g.lost,
                  drawn: g.drawn,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Одна игра: компактная иконка, под ней цифры W/L/D слева направо.
class GameTypeScoreChip extends StatelessWidget {
  const GameTypeScoreChip({
    super.key,
    required this.gameType,
    required this.won,
    required this.lost,
    required this.drawn,
    this.iconSize = 36,
  });

  final String gameType;
  final int won;
  final int lost;
  final int drawn;
  final double iconSize;

  static const _win = Color(0xFF2E7D32);
  static const _loss = Color(0xFFC62828);
  static const _draw = Color(0xFFF9A825);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentStart, AppColors.accentEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: GameTypeIcon(
            gameType: gameType,
            size: iconSize * 0.52,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DigitChip(value: won, color: _win),
            const SizedBox(width: 6),
            _DigitChip(value: lost, color: _loss),
            const SizedBox(width: 6),
            _DigitChip(value: drawn, color: _draw),
          ],
        ),
      ],
    );
  }
}

class _DigitChip extends StatelessWidget {
  const _DigitChip({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        height: 1,
      ),
    );
  }
}

/// Карточка суммарного W/L/D (свой профиль): цветные иконки + цифры.
class ScoreTripletCard extends StatelessWidget {
  const ScoreTripletCard({
    super.key,
    required this.won,
    required this.lost,
    required this.drawn,
    this.width = double.infinity,
  });

  final int won;
  final int lost;
  final int drawn;
  final double width;

  static const _win = Color(0xFF2E7D32);
  static const _loss = Color(0xFFC62828);
  static const _draw = Color(0xFFF9A825);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кубок — победа, большой палец вниз — поражение, рукопожатие — ничья.
              _TallScoreIcon(icon: Icons.emoji_events_rounded, color: _win),
              SizedBox(height: 6),
              _TallScoreIcon(icon: Icons.thumb_down_alt_rounded, color: _loss),
              SizedBox(height: 6),
              _TallScoreIcon(icon: Icons.handshake_rounded, color: _draw),
            ],
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreDigit(value: won, color: _win),
              const SizedBox(height: 6),
              _ScoreDigit(value: lost, color: _loss),
              const SizedBox(height: 6),
              _ScoreDigit(value: drawn, color: _draw),
            ],
          ),
        ],
      ),
    );
  }
}

class _TallScoreIcon extends StatelessWidget {
  const _TallScoreIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _ScoreDigit extends StatelessWidget {
  const _ScoreDigit({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Иконка статистики без текста — сразу за блоком счёта.
class StatsIconButton extends StatelessWidget {
  const StatsIconButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GamepadFocusBlock(
      radius: 12,
      onActivate: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Tooltip(
            message: context.l10n.statsTitle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentStart.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 22,
                color: AppColors.accentStart,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeadToHeadSkeleton extends StatelessWidget {
  const _HeadToHeadSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}
