import 'package:flutter/material.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatStakeAmount, stakeCoinType;
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

/// Чип «Ставки N 🥉» — общий для лобби всех игр (2 игрока).
class LobbyStakeChip extends StatelessWidget {
  const LobbyStakeChip({
    super.key,
    required this.stakeBronze,
    required this.label,
  });

  final int stakeBronze;

  /// Локализованная подпись слева, например «Ставки».
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.accentSoft.withValues(alpha: 0.9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatStakeAmount(stakeBronze),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            CoinIcon(
              coinType: stakeCoinType(stakeBronze),
              size: 22,
              showBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка «Отправить ссылку на игру» — общий вид для всех игр.
class LobbyShareLinkCard extends StatelessWidget {
  const LobbyShareLinkCard({
    super.key,
    required this.title,
    required this.hint,
    required this.copied,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.link_rounded,
                      color: AppColors.accentStart),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  color: AppColors.accentStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Скелет экрана «Своя игра» в состоянии ожидания игроков.
///
/// Для 2 игроков — чип ставки сверху (как в крестиках-ноликах);
/// для 3–4 — карточка «Игроки N/M» ([multiPlayersCard]).
/// Дальше идут ссылка-приглашение и панель друзей.
class GameLobbyWaitingLayout extends StatelessWidget {
  const GameLobbyWaitingLayout({
    super.key,
    required this.maxPlayers,
    required this.stakeBronze,
    required this.stakeLabel,
    required this.shareLinkCard,
    required this.friendsCard,
    this.multiPlayersCard,
    this.expandFriends = true,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 480,
  });

  final int maxPlayers;
  final int stakeBronze;
  final String stakeLabel;

  /// Карточка «Игроки N/M» — показывается только при maxPlayers > 2.
  final Widget? multiPlayersCard;
  final Widget shareLinkCard;
  final Widget friendsCard;
  final bool expandFriends;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isMulti = maxPlayers > 2;
    final head = <Widget>[
      if (isMulti && multiPlayersCard != null) ...[
        multiPlayersCard!,
        const SizedBox(height: 12),
      ] else if (!isMulti && stakeBronze > 0) ...[
        LobbyStakeChip(stakeBronze: stakeBronze, label: stakeLabel),
        const SizedBox(height: 16),
      ],
      shareLinkCard,
      const SizedBox(height: 12),
    ];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...head,
                if (expandFriends)
                  Expanded(child: friendsCard)
                else
                  Align(alignment: Alignment.topCenter, child: friendsCard),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
