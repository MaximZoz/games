import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/framed_avatar.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';
import 'package:multigames_client/ui/widgets/shimmer_animation_scope.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

/// Всплывашка со статистикой игрока (из попапа профиля).
Future<void> showGameStatsDialog(
  BuildContext context, {
  String? userId,
  String? displayName,
}) {
  final l10n = context.l10n;
  final isOwn = userId == null || userId.isEmpty;
  final title = isOwn
      ? l10n.statsTitle
      : (displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : l10n.commonPlayer);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final maxH = MediaQuery.sizeOf(dialogContext).height * 0.85;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
          child: GradientCard(
            animate: false,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: dialogContext.l10n.commonClose,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: GameStatsBody(
                    userId: userId,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

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
      context.go('/profile');
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
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

/// Содержимое статистики — для экрана и всплывашки.
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
      data: (stats) => stats.isEmpty
          ? const _EmptyStats()
          : ListView(
              padding: contentPadding,
              shrinkWrap: true,
              children: [
                _GameStatsBlock(
                  title: l10n.statsAllGames,
                  icon: Icons.sports_esports_rounded,
                  wins: stats.wins,
                  draws: stats.draws,
                  losses: stats.losses,
                  winRate: stats.winRate,
                  totalDurationSec: stats.totalDurationSec,
                  topWon: stats.topWon,
                  topDrawn: stats.topDrawn,
                  topLost: stats.topLost,
                  narrow: narrow,
                ),
                for (final g in stats.games) ...[
                  const SizedBox(height: 12),
                  _GameStatsBlock(
                    title: _gameTypeTitle(l10n, g.gameType),
                    icon: _gameTypeIcon(g.gameType),
                    wins: g.won,
                    draws: g.drawn,
                    losses: g.lost,
                    winRate: _winRate(g.won, g.drawn, g.lost),
                    totalDurationSec: g.totalDurationSec,
                    topWon: g.topWon,
                    topDrawn: g.topDrawn,
                    topLost: g.topLost,
                    narrow: narrow,
                  ),
                ],
              ],
            ),
    );
  }
}

String _gameTypeTitle(AppLocalizations l10n, String gameType) {
  switch (gameType) {
    case 'tictactoe':
      return l10n.gamesTicTacToe;
    default:
      return gameType;
  }
}

IconData _gameTypeIcon(String gameType) {
  switch (gameType) {
    case 'tictactoe':
      return Icons.grid_3x3_rounded;
    default:
      return Icons.sports_esports_rounded;
  }
}

double _winRate(int wins, int draws, int losses) {
  final total = wins + draws + losses;
  if (total <= 0) return 0;
  return wins / total;
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
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
    required this.narrow,
  });

  final String title;
  final IconData icon;
  final int wins;
  final int draws;
  final int losses;
  final double winRate;
  final int totalDurationSec;
  final List<OpponentStat> topWon;
  final List<OpponentStat> topDrawn;
  final List<OpponentStat> topLost;
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
                child: Icon(icon, color: Colors.white, size: 20),
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
        _scoreChip('${stat.drawn}', _StatColor.draw, highlight == _Metric.drawn),
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
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 72,
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
