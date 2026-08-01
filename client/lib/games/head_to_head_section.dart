import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Секция head-to-head: счёт между текущим игроком и соперником в попапе профиля.
///
/// Компактно: иконка игры слева, справа от неё по вертикали —
/// победа (зелёный) / ничья (жёлтый) / проигрыш (красный).
/// Рядом — фиолетовая иконка статистики; тап → экран статистики этого игрока.
class HeadToHeadSection extends ConsumerWidget {
  const HeadToHeadSection({
    super.key,
    required this.opponentId,
    this.opponentName,
    this.padding = const EdgeInsets.only(top: 12),
  });

  /// ID соперника (для запроса head-to-head и перехода в его статистику).
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
                onTapStats: () => _goToStats(context),
              ),
      ),
    );
  }

  void _goToStats(BuildContext context) {
    final qs = <String>['user_id=$opponentId'];
    final name = opponentName?.trim();
    if (name != null && name.isNotEmpty) {
      qs.add('name=${Uri.encodeQueryComponent(name)}');
    }
    context.go('/profile/stats?${qs.join('&')}');
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'Ваш счёт',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
              Icons.grid_3x3_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          // W/D/L по вертикали справа от иконки.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreRow(
                icon: Icons.check_circle_rounded,
                value: won,
                color: const Color(0xFF2E7D32), // зелёный
              ),
              const SizedBox(height: 2),
              _ScoreRow(
                icon: Icons.remove_circle_rounded,
                value: drawn,
                color: const Color(0xFFF9A825), // жёлтый
              ),
              const SizedBox(height: 2),
              _ScoreRow(
                icon: Icons.cancel_rounded,
                value: lost,
                color: const Color(0xFFC62828), // красный
              ),
            ],
          ),
          const SizedBox(width: 6),
          // Фиолетовая иконка-кнопка → переход в статистику игрока.
          _StatsIconButton(onTap: onTapStats),
        ],
      ),
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
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

/// Фиолетовая иконка статистики — тап открывает экран статистики игрока.
class _StatsIconButton extends StatelessWidget {
  const _StatsIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Tooltip(
          message: 'Статистика игрока',
          child: Container(
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
        ),
      ),
    );
  }
}

class _HeadToHeadSkeleton extends StatelessWidget {
  const _HeadToHeadSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
