import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/framework/game_session_api.dart';
import 'package:multigames_client/games/game_navigation.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

/// Карточка «Наблюдение» — общая для всех игр (лобби / список).
///
/// Показывается, пока игрок выбыл, а партия ещё идёт. Тап → экран партии.
class GameObservationCard extends ConsumerWidget {
  const GameObservationCard({
    super.key,
    required this.observation,
    this.active,
  });

  final ObservationItem observation;
  final ActiveGameItem? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obs = observation;
    if (obs.gameId.trim().isEmpty) return const SizedBox.shrink();
    if (active?.type == 'game' && active?.gameId == obs.gameId) {
      return const SizedBox.shrink();
    }
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () async {
          var gt = normalizeGameType(obs.gameType);
          final resolved =
              await ref.read(gameSessionApiProvider).resolveGameType(obs.gameId);
          if (resolved == null) return;
          gt = resolved;
          ref.read(activeGameProvider.notifier).setObservationLocal(
                ObservationItem(
                  gameId: obs.gameId,
                  lobbyId: obs.lobbyId,
                  gameType: gt,
                ),
              );
          if (!context.mounted) return;
          context.push(gamePathFor(obs.gameId, gameType: gt));
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            const Icon(
              Icons.visibility_rounded,
              size: 40,
              color: AppColors.accentStart,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.gamesObservation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    context.l10n.gamesObservationHint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
