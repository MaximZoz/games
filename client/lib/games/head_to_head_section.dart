import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Секция head-to-head: счёт между текущим игроком и соперником в попапе профиля.
/// Иконка игры (крестики-нолики) + три блока с фиолетовыми иконками
/// (выиграл / ничья / проиграл) и цифрами.
class HeadToHeadSection extends ConsumerWidget {
  const HeadToHeadSection({
    super.key,
    required this.opponentId,
    this.padding = const EdgeInsets.only(top: 14),
  });

  /// ID соперника (для запроса head-to-head с сервера).
  final String opponentId;
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
            : _HeadToHeadBody(won: h2h.won, drawn: h2h.drawn, lost: h2h.lost),
      ),
    );
  }
}

class _HeadToHeadBody extends StatelessWidget {
  const _HeadToHeadBody({
    required this.won,
    required this.drawn,
    required this.lost,
  });

  final int won;
  final int drawn;
  final int lost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grid_3x3_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ваш счёт',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _ScoreItem(
            icon: Icons.check_circle_rounded,
            value: won,
            color: AppColors.accentStart,
          ),
          const SizedBox(width: 10),
          _ScoreItem(
            icon: Icons.remove_circle_rounded,
            value: drawn,
            color: AppColors.accentEnd,
          ),
          const SizedBox(width: 10),
          _ScoreItem(
            icon: Icons.cancel_rounded,
            value: lost,
            color: const Color(0xFFB39DDB),
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({
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
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HeadToHeadSkeleton extends StatelessWidget {
  const _HeadToHeadSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
