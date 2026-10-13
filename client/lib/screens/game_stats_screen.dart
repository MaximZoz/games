import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/games/stats_modes.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/game_type_icon.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/ui/widgets/shimmer_animation_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_back_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Полный экран статистики игрока: победы/ничьи/поражения, win-rate,
/// время в игре, топ соперников (больше всего выиграл / проиграл).
///
/// [userId] — чью статистику показать. null/пусто — своя.
class GameStatsScreen extends ConsumerWidget {
  const GameStatsScreen({super.key, this.userId, this.displayName});

  final String? userId;
  final String? displayName;

  bool get _isOwn => userId == null || userId!.isEmpty;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = _isOwn
        ? l10n.statsTitle
        : (displayName?.trim().isNotEmpty == true
            ? displayName!
            : l10n.commonPlayer);
    return SwipeBackScope(
      onBack: () => _goBack(context),
      child: Scaffold(
        backgroundColor: AppColors.surfaceUnified,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceUnified,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: GamepadBackButton(
            tooltip: l10n.commonBack,
            onPressed: () => _goBack(context),
          ),
          title: Text(
            _isOwn ? l10n.statsTitle : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: GameStatsBody(userId: userId),
      ),
    );
  }
}

/// Содержимое статистики.
class GameStatsBody extends ConsumerWidget {
  const GameStatsBody({
    super.key,
    this.userId,
    this.padding,
  });

  final String? userId;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(gameStatsProvider(userId));
    final narrow = MediaQuery.sizeOf(context).shortestSide < 700;
    final contentPadding = padding ??
        EdgeInsets.fromLTRB(
          narrow ? 12 : 24,
          4,
          narrow ? 12 : 24,
          32,
        );
    return statsAsync.when(
      loading: () => Padding(
        padding: contentPadding,
        child: const _StatsSkeleton(),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.statsLoadFailed,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (stats) => stats.isEmpty && stats.recent.isEmpty
          ? const _EmptyStats()
          : GamepadScope(
              onAction: (action) {
                if (action.isDirection || action.isScroll) {
                  final back = action == GamepadAction.up ||
                      action == GamepadAction.left ||
                      action == GamepadAction.scrollUp ||
                      action == GamepadAction.scrollLeft;
                  scrollGamepadByPage(back ? -1 : 1, context: context);
                  return true;
                }
                return false;
              },
              child: _StatsDeck(
                stats: stats,
                narrow: narrow,
                padding: contentPadding,
              ),
            ),
    );
  }
}

double _winRate(int wins, int draws, int losses) {
  final total = wins + draws + losses;
  if (total <= 0) return 0;
  return wins / total;
}

class _Slice {
  const _Slice({
    required this.title,
    required this.icon,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.duration,
    required this.topWon,
    required this.topDrawn,
    required this.topLost,
  });

  final String title;
  final Object icon;
  final int wins;
  final int draws;
  final int losses;
  final int duration;
  final List<OpponentStat> topWon;
  final List<OpponentStat> topDrawn;
  final List<OpponentStat> topLost;
}

/// Два переключателя — игра и режим — и одна карточка счёта.
class _StatsDeck extends StatefulWidget {
  const _StatsDeck({
    required this.stats,
    required this.narrow,
    required this.padding,
  });

  final GameStats stats;
  final bool narrow;
  final EdgeInsetsGeometry padding;

  @override
  State<_StatsDeck> createState() => _StatsDeckState();
}

class _StatsDeckState extends State<_StatsDeck> {
  String _game = '';
  String _mode = '';

  _Slice _slice(AppLocalizations l10n) {
    if (_game.isEmpty) {
      return _Slice(
        title: l10n.statsAllGames,
        icon: Icons.sports_esports_rounded,
        wins: widget.stats.wins,
        draws: widget.stats.draws,
        losses: widget.stats.losses,
        duration: widget.stats.totalDurationSec,
        topWon: widget.stats.topWon,
        topDrawn: widget.stats.topDrawn,
        topLost: widget.stats.topLost,
      );
    }
    GameTypeScore? game;
    for (final item in widget.stats.games) {
      if (item.gameType == _game) {
        game = item;
        break;
      }
    }
    if (_mode.isEmpty) {
      return _Slice(
        title: localizedGameTypeName(_game, l10n),
        icon: GameTypeIcon(gameType: _game, size: 20, color: Colors.white),
        wins: game?.won ?? 0,
        draws: game?.drawn ?? 0,
        losses: game?.lost ?? 0,
        duration: game?.totalDurationSec ?? 0,
        topWon: game?.topWon ?? const [],
        topDrawn: game?.topDrawn ?? const [],
        topLost: game?.topLost ?? const [],
      );
    }
    GameModeScore? mode;
    for (final item in widget.stats.modes) {
      if (item.gameType == _game && item.mode == _mode) {
        mode = item;
        break;
      }
    }
    return _Slice(
      title: localizedGameTypeName(_game, l10n),
      icon: GameTypeIcon(gameType: _game, size: 20, color: Colors.white),
      wins: mode?.won ?? 0,
      draws: mode?.drawn ?? 0,
      losses: mode?.lost ?? 0,
      duration: mode?.totalDurationSec ?? 0,
      topWon: mode?.topWon ?? const [],
      topDrawn: mode?.topDrawn ?? const [],
      topLost: mode?.topLost ?? const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = statsGameTypes([
      for (final g in widget.stats.games) g.gameType,
      for (final r in widget.stats.recent) r.gameType,
    ]);
    final modes = _game.isEmpty
        ? const <String>[]
        : statsModeOptions(
            _game,
            widget.stats.modes
                .where((m) => m.gameType == _game)
                .map((m) => m.mode),
          );
    final mode = modes.contains(_mode) ? _mode : '';
    final slice = _slice(l10n);
    final recent = statsRecentSlice(
      widget.stats.recent,
      game: _game,
      mode: mode,
    );
    final gameValue = _game.isEmpty
        ? l10n.statsAllGames
        : localizedGameTypeName(_game, l10n);
    final modeValue =
        mode.isEmpty ? l10n.statsAllModes : statsModeLabel(_game, mode, l10n);
    return ListView(
      padding: widget.padding,
      children: [
        _StatsSelect(
          selectKey: const Key('stats-game-select'),
          caption: l10n.statsSelectGame,
          value: gameValue,
          icon: _game.isEmpty
              ? const Icon(
                  Icons.sports_esports_rounded,
                  size: 20,
                  color: AppColors.accentStart,
                )
              : GameTypeIcon(
                  gameType: _game,
                  size: 20,
                  color: AppColors.accentStart,
                ),
          options: [
            _StatsOption(
              id: '',
              label: l10n.statsAllGames,
              icon: const Icon(
                Icons.sports_esports_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
            for (final id in types)
              _StatsOption(
                id: id,
                label: localizedGameTypeName(id, l10n),
                icon: GameTypeIcon(
                  gameType: id,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
          selectedId: _game,
          onSelected: (id) => setState(() {
            _game = id;
            _mode = '';
          }),
        ),
        const SizedBox(height: 8),
        _StatsSelect(
          selectKey: const Key('stats-mode-select'),
          caption: l10n.statsSelectMode,
          value: modeValue,
          enabled: modes.isNotEmpty,
          icon: const Icon(
            Icons.tune_rounded,
            size: 20,
            color: AppColors.accentStart,
          ),
          options: [
            _StatsOption(id: '', label: l10n.statsAllModes),
            for (final item in modes)
              _StatsOption(
                id: item,
                label: statsModeLabel(_game, item, l10n),
              ),
          ],
          selectedId: mode,
          onSelected: (id) => setState(() => _mode = id),
        ),
        const SizedBox(height: 12),
        _GameStatsBlock(
          title: slice.title,
          icon: slice.icon,
          wins: slice.wins,
          draws: slice.draws,
          losses: slice.losses,
          winRate: _winRate(slice.wins, slice.draws, slice.losses),
          totalDurationSec: slice.duration,
          topWon: slice.topWon,
          topDrawn: slice.topDrawn,
          topLost: slice.topLost,
          recent: recent,
          narrow: widget.narrow,
        ),
      ],
    );
  }
}

class _StatsOption {
  const _StatsOption({required this.id, required this.label, this.icon});

  final String id;
  final String label;
  final Widget? icon;
}

/// Белая полоска-переключатель: подпись и текущее значение, по нажатию список.
class _StatsSelect extends StatelessWidget {
  const _StatsSelect({
    required this.selectKey,
    required this.caption,
    required this.value,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.icon,
    this.enabled = true,
  });

  final Key selectKey;
  final String caption;
  final String value;
  final Widget? icon;
  final bool enabled;
  final List<_StatsOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _StatsSelectBar(
        barKey: selectKey,
        caption: caption,
        value: value,
        icon: icon,
        enabled: false,
        onTap: null,
      );
    }
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(8),
        maximumSize: WidgetStatePropertyAll(Size(360, 320)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            onPressed: () => onSelected(option.id),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                option.id == selectedId
                    ? AppColors.accentSoft
                    : Colors.transparent,
              ),
            ),
            leadingIcon: option.icon,
            child: Text(
              option.label,
              style: TextStyle(
                fontWeight: option.id == selectedId
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: option.id == selectedId
                    ? AppColors.accentStart
                    : AppColors.textPrimary,
              ),
            ),
          ),
      ],
      builder: (context, controller, _) {
        return _StatsSelectBar(
          barKey: selectKey,
          caption: caption,
          value: value,
          icon: icon,
          enabled: true,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}

class _StatsSelectBar extends StatelessWidget {
  const _StatsSelectBar({
    required this.barKey,
    required this.caption,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.icon,
  });

  final Key barKey;
  final String caption;
  final String value;
  final Widget? icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: barKey,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.game});

  final RecentGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = _outcomeTone(game.outcome);
    final label = switch (game.outcome) {
      'win' => l10n.statsOutcomeWin,
      'loss' => l10n.statsOutcomeLoss,
      _ => l10n.statsOutcomeDraw,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GameTypeIcon(gameType: game.gameType, size: 18, color: tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _recentNames(game, l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

_StatColor _outcomeTone(String outcome) {
  switch (outcome) {
    case 'win':
      return const _StatColor._(Color(0xFF2E7D32), Color(0xFFE8F5E9));
    case 'loss':
      return const _StatColor._(Color(0xFFC62828), Color(0xFFFFEBEE));
    default:
      return const _StatColor._(Color(0xFFF9A825), Color(0xFFFFF8E1));
  }
}

String _recentNames(RecentGame game, AppLocalizations l10n) {
  if (game.opponents.isEmpty) return l10n.gameBot;
  return game.opponents.map((o) {
    if (o.bot) return l10n.gameBot;
    final name = o.displayName.trim();
    return name.isEmpty ? l10n.commonPlayer : name;
  }).join(', ');
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.grid_3x3_rounded,
                size: 34,
                color: AppColors.accentStart,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.statsEmptyTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.statsEmptyHint,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Блок статистики одной игры / «Все игры»: W/D/L, время, топ соперников.
class _GameStatsBlock extends StatelessWidget {
  const _GameStatsBlock({
    required this.title,
    required this.icon,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.winRate,
    required this.totalDurationSec,
    required this.topWon,
    required this.topDrawn,
    required this.topLost,
    required this.recent,
    required this.narrow,
  });

  final String title;
  final Object icon; // IconData («все игры») или Widget (Дурак и т.п.)
  final int wins;
  final int draws;
  final int losses;
  final double winRate;
  final int totalDurationSec;
  final List<OpponentStat> topWon;
  final List<OpponentStat> topDrawn;
  final List<OpponentStat> topLost;
  final List<RecentGame> recent;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GradientCard(
      animate: false,
      padding: EdgeInsets.all(narrow ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentStart, AppColors.accentEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: icon is Widget
                    ? icon as Widget
                    : Icon(
                        icon as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: l10n.statsWins,
                  value: wins,
                  color: _StatColor.win,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: l10n.statsDraws,
                  value: draws,
                  color: _StatColor.draw,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: l10n.statsLosses,
                  value: losses,
                  color: _StatColor.loss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.statsWinRate,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(winRate * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentStart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: winRate.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.accentSoft,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentStart),
            ),
          ),
          const SizedBox(height: 14),
          _InlineTimeRow(totalDurationSec: totalDurationSec),
          if (topWon.isNotEmpty) ...[
            const SizedBox(height: 14),
            _OpponentsSection(
              title: l10n.statsTopWon,
              accent: _StatColor.win,
              opponents: topWon,
              metric: _Metric.won,
              nested: true,
            ),
          ],
          if (topDrawn.isNotEmpty) ...[
            const SizedBox(height: 14),
            _OpponentsSection(
              title: l10n.statsTopDrawn,
              accent: _StatColor.draw,
              opponents: topDrawn,
              metric: _Metric.drawn,
              nested: true,
            ),
          ],
          if (topLost.isNotEmpty) ...[
            const SizedBox(height: 14),
            _OpponentsSection(
              title: l10n.statsTopLost,
              accent: _StatColor.loss,
              opponents: topLost,
              metric: _Metric.lost,
              nested: true,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l10n.statsRecentTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Text(
              l10n.statsRecentEmpty,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _RecentRow(game: recent[i]),
            ],
        ],
      ),
    );
  }
}

class _InlineTimeRow extends StatelessWidget {
  const _InlineTimeRow({required this.totalDurationSec});

  final int totalDurationSec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.timer_outlined,
            color: AppColors.accentStart,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.statsTimePlayed,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatDuration(context.l10n, totalDurationSec),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final _StatColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.foreground.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Metric { won, drawn, lost }

/// Список топа соперников.
class _OpponentsSection extends StatelessWidget {
  const _OpponentsSection({
    required this.title,
    required this.accent,
    required this.opponents,
    required this.metric,
    this.nested = false,
  });

  final String title;
  final _StatColor accent;
  final List<OpponentStat> opponents;
  final _Metric metric;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final list = Column(
      children: [
        for (final o in opponents) _OpponentTile(stat: o, metric: metric),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: nested ? 0 : 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: nested ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (nested)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: list,
          )
        else
          GradientCard(
            animate: false,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: list,
          ),
      ],
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile({required this.stat, required this.metric});

  final OpponentStat stat;
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final name = stat.displayName.trim().isNotEmpty
        ? stat.displayName.trim()
        : context.l10n.commonPlayer;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          FramedAvatar(
            size: 36,
            borderWidth: 2.4,
            child: CircleAvatar(
              backgroundColor: AppColors.accentSoft,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accentStart,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MiniScore(stat: stat, highlight: metric),
        ],
      ),
    );
  }
}

/// Компактный счёт W-D-L справа в плитке соперника.
class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.stat, required this.highlight});

  final OpponentStat stat;
  final _Metric highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _scoreChip('${stat.won}', _StatColor.win, highlight == _Metric.won),
        const SizedBox(width: 6),
        _scoreChip(
            '${stat.drawn}', _StatColor.draw, highlight == _Metric.drawn),
        const SizedBox(width: 6),
        _scoreChip('${stat.lost}', _StatColor.loss, highlight == _Metric.lost),
      ],
    );
  }

  Widget _scoreChip(String value, _StatColor color, bool emphasize) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: emphasize ? color.foreground.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          color: emphasize ? color.foreground : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Цветовая схема для W/D/L (переиспользуется в попапе).
class _StatColor {
  final Color foreground;
  final Color background;
  const _StatColor._(this.foreground, this.background);

  static const win = _StatColor._(Color(0xFF2E7D32), Color(0xFFE8F5E9));
  static const draw = _StatColor._(
    AppColors.textSecondary,
    Color(0xFFECEFF1),
  );
  static const loss = _StatColor._(Color(0xFFC62828), Color(0xFFFFEBEE));
}

String _formatDuration(AppLocalizations l10n, int totalSec) {
  if (totalSec <= 0) return l10n.statsDurationZeroMinutes;
  final hours = totalSec ~/ 3600;
  final minutes = (totalSec % 3600) ~/ 60;
  if (hours >= 1) {
    final remMin = minutes;
    return remMin == 0
        ? l10n.statsDurationHours(hours)
        : l10n.statsDurationHoursMinutes(hours, remMin);
  }
  if (minutes >= 1) return l10n.statsDurationMinutes(minutes);
  final seconds = totalSec % 60;
  return l10n.timeSecondsShort(seconds);
}

/// Переливающийся плейсхолдер на время загрузки.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerAnimationScope(
      child: Column(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ],
      ),
    );
  }
}
