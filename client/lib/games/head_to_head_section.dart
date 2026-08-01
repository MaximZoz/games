import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/screens/game_stats_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Секция счёта head-to-head в попапе профиля.
///
/// Заголовок «Ваш счёт» над карточкой. В карточке — крупные иконки
/// победа/поражение/ничья и цифры сверху вниз. Сразу за карточкой —
/// иконка статистики (без текста), если соперник разрешил показ.
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
          final hasScore = !h2h.isEmpty;
          final showStats = h2h.showStatsToOthers;
          if (!hasScore && !showStats) return const SizedBox.shrink();
          return _HeadToHeadBody(
            won: h2h.won,
            drawn: h2h.drawn,
            lost: h2h.lost,
            hasScore: hasScore,
            showStats: showStats,
            onTapStats: () => showGameStatsDialog(
              context,
              userId: opponentId,
              displayName: opponentName ?? h2h.displayName,
            ),
          );
        },
      ),
    );
  }
}

class _HeadToHeadBody extends StatelessWidget {
  const _HeadToHeadBody({
    required this.won,
    required this.drawn,
    required this.lost,
    required this.hasScore,
    required this.showStats,
    required this.onTapStats,
  });

  final int won;
  final int drawn;
  final int lost;
  final bool hasScore;
  final bool showStats;
  final VoidCallback onTapStats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasScore) ...[
          const Text(
            'Ваш счёт',
            style: TextStyle(
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
              Flexible(
                child: ScoreTripletCard(
                  won: won,
                  lost: lost,
                  drawn: drawn,
                ),
              ),
            if (hasScore && showStats) const SizedBox(width: 8),
            if (showStats) StatsIconButton(onTap: onTapStats),
          ],
        ),
      ],
    );
  }
}

/// Карточка W/L/D: крупные иконки слева, цифры сверху вниз справа.
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
          // Иконки победа / поражение / ничья — высота как у трёх цифр.
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TallScoreIcon(icon: Icons.check_rounded, color: _win),
              SizedBox(height: 6),
              _TallScoreIcon(icon: Icons.close_rounded, color: _loss),
              SizedBox(height: 6),
              _TallScoreIcon(icon: Icons.remove_rounded, color: _draw),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Tooltip(
          message: 'Статистика',
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
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}
