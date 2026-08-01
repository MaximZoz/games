import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
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
  final isOwn = userId == null || userId.isEmpty;
  final title = isOwn
      ? 'Статистика'
      : (displayName?.trim().isNotEmpty == true ? displayName!.trim() : 'Игрок');
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
                        tooltip: 'Закрыть',
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
    final title = _isOwn
        ? 'Статистика'
        : (displayName?.trim().isNotEmpty == true ? displayName! : 'Игрок');
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
            tooltip: 'Назад',
            onPressed: () => _goBack(context),
          ),
          title: Text(
            _isOwn ? 'Статистика' : title,
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
            'Не удалось загрузить статистику',
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
                _SummarySection(stats: stats, narrow: narrow),
                const SizedBox(height: 16),
                _TimeSection(totalDurationSec: stats.totalDurationSec),
                const SizedBox(height: 16),
                if (stats.topWon.isNotEmpty) ...[
                  _OpponentsSection(
                    title: 'Чаще всего побеждали',
                    accent: _StatColor.win,
                    opponents: stats.topWon,
                    metric: _Metric.won,
                  ),
                  const SizedBox(height: 16),
                ],
                if (stats.topLost.isNotEmpty) ...[
                  _OpponentsSection(
                    title: 'Чаще всего проигрывали',
                    accent: _StatColor.loss,
                    opponents: stats.topLost,
                    metric: _Metric.lost,
                  ),
                ],
              ],
            ),
    );
  }
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
            const Text(
              'Пока нет сыгранных партий',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Сыграйте первую игру, чтобы здесь появилась статистика.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Итоговый блок: W/D/L пилюли + win-rate прогресс-бар.
class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.stats, required this.narrow});

  final GameStats stats;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(
                  Icons.grid_3x3_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Крестики-нолики',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Победы',
                  value: stats.wins,
                  color: _StatColor.win,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Ничьи',
                  value: stats.draws,
                  color: _StatColor.draw,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Поражения',
                  value: stats.losses,
                  color: _StatColor.loss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Win-rate.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Процент побед',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(stats.winRate * 100).round()}%',
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
              value: stats.winRate.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.accentSoft,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentStart),
            ),
          ),
        ],
      ),
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

/// Карточка времени в игре.
class _TimeSection extends StatelessWidget {
  const _TimeSection({required this.totalDurationSec});

  final int totalDurationSec;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppColors.accentStart,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Время в игре',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(totalDurationSec),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Metric { won, lost }

/// Список топа соперников.
class _OpponentsSection extends StatelessWidget {
  const _OpponentsSection({
    required this.title,
    required this.accent,
    required this.opponents,
    required this.metric,
  });

  final String title;
  final _StatColor accent;
  final List<OpponentStat> opponents;
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GradientCard(
          animate: false,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final o in opponents) _OpponentTile(stat: o, metric: metric),
            ],
          ),
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
        : 'Игрок';
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
        _scoreChip('${stat.drawn}', _StatColor.draw, false),
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

String _formatDuration(int totalSec) {
  if (totalSec <= 0) return '0 мин';
  final hours = totalSec ~/ 3600;
  final minutes = (totalSec % 3600) ~/ 60;
  if (hours >= 1) {
    final remMin = minutes;
    return remMin == 0 ? '$hours ч' : '$hours ч $remMin мин';
  }
  if (minutes >= 1) return '$minutes мин';
  final seconds = totalSec % 60;
  return '$seconds с';
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
