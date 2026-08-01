import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/screens/game_stats_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Секция head-to-head: счёт между текущим игроком и соперником в попапе профиля.
///
/// Заголовок «Ваш счёт» над карточкой (как «Коллекции»).
/// В карточке: иконка игры, справа — зелёная сверху, красная снизу,
/// жёлтая справа от красной. После блока счёта — кнопка статистики
/// (тап → всплывашка со статистикой игрока).
class HeadToHeadSection extends ConsumerWidget {
  const HeadToHeadSection({
    super.key,
    required this.opponentId,
    this.opponentName,
    this.padding = const EdgeInsets.only(top: 12),
  });

  /// ID соперника (для запроса head-to-head и статистики).
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
        data: (h2h) => h2h.isEmpty
            ? const SizedBox.shrink()
            : _HeadToHeadBody(
                won: h2h.won,
                drawn: h2h.drawn,
                lost: h2h.lost,
                onTapStats: () => showGameStatsDialog(
                  context,
                  userId: opponentId,
                  displayName: opponentName,
                ),
              ),
      ),
    );
  }
}

class _HeadToHeadBody extends StatelessWidget {
  const _HeadToHeadBody({
    required this.won,
    required this.drawn,
    required this.lost,
    required this.onTapStats,
  });

  final int won;
  final int drawn;
  final int lost;
  final VoidCallback onTapStats;

  @override
  Widget build(BuildContext context) {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Иконка игры (крестики-нолики).
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentStart, AppColors.accentEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tag_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              // Зелёная сверху; снизу красная, жёлтая справа от красной.
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreRow(
                    icon: Icons.check_rounded,
                    value: won,
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreRow(
                        icon: Icons.close_rounded,
                        value: lost,
                        color: const Color(0xFFC62828),
                      ),
                      const SizedBox(width: 10),
                      _ScoreRow(
                        icon: Icons.remove_rounded,
                        value: drawn,
                        color: const Color(0xFFF9A825),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Статистика — отдельный блок после счёта.
        _StatsRowButton(onTap: onTapStats),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Кнопка «Статистика» после блока счёта — открывает всплывашку.
class _StatsRowButton extends StatelessWidget {
  const _StatsRowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentStart.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentStart.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppColors.accentStart,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Статистика',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ],
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
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}
