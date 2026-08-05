import 'package:flutter/material.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatStakeAmount, stakeCoinType;
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

/// Общие виджеты лобби (крестики / дурак).
/// См. также `games/shared_lobby.dart` — общая сессия и leave/creator.
///
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

/// Оценка высоты карточки друзей — общая эвристика для обеих игр,
/// чтобы карточка не растягивалась на весь экран при паре друзей.
double estimateLobbyFriendsCardHeight(int friendCount) {
  if (friendCount <= 0) return 88;
  return 24 + friendCount * 56.0;
}

/// Баннер «Поиск соперника…» — общий для matchmake-лобби всех игр.
class LobbySearchBanner extends StatelessWidget {
  const LobbySearchBanner({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentStart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка «Игроки N/M» для своей игры на 3–4 игрока.
///
/// Общий вид для крестиков и дурака: заголовок, опциональный подзаголовок
/// (режим · колода / вариант · поле) и ставка справа.
class LobbyMultiPlayersCard extends StatelessWidget {
  const LobbyMultiPlayersCard({
    super.key,
    required this.playersCount,
    required this.maxPlayers,
    this.subtitle,
    this.stakeBronze = 0,
  });

  final int playersCount;
  final int maxPlayers;

  /// Например «Подкидной · 36 карт» или «Классика · 3×3».
  final String? subtitle;

  final int stakeBronze;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle?.trim();
    return GradientCard(
      animate: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Игроки $playersCount/$maxPlayers',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (sub != null && sub.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (stakeBronze > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatStakeAmount(stakeBronze),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                CoinIcon(
                  coinType: stakeCoinType(stakeBronze),
                  size: 20,
                  showBorder: true,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Диалог подтверждения выхода из лобби — общий для всех игр.
/// Возвращает true, если пользователь подтвердил.
Future<bool> confirmLeaveLobbyDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String leaveLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accentStart),
          child: Text(leaveLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Скелет экрана «Своя игра» в состоянии ожидания игроков.
///
/// Для 2 игроков — чип ставки сверху (как в крестиках-ноликах);
/// для 3–4 — карточка «Игроки N/M» ([multiPlayersCard]).
/// Дальше идут ссылка-приглашение и панель друзей: она занимает высоту
/// по контенту, пока помещается, и растягивается только когда друзей много.
class GameLobbyWaitingLayout extends StatelessWidget {
  const GameLobbyWaitingLayout({
    super.key,
    required this.maxPlayers,
    required this.stakeBronze,
    required this.stakeLabel,
    required this.shareLinkCard,
    required this.friendsCardBuilder,
    required this.friendsCount,
    this.multiPlayersCard,
    this.searchBanner,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 480,
  });

  final int maxPlayers;
  final int stakeBronze;
  final String stakeLabel;

  /// Карточка «Игроки N/M» — показывается только при maxPlayers > 2.
  final Widget? multiPlayersCard;

  /// Баннер «Поиск соперника…» для matchmake — сверху, если задан.
  final Widget? searchBanner;

  final Widget shareLinkCard;

  /// [expand]=true — карточка занимает остаток экрана и скроллит список.
  final Widget Function(bool expand) friendsCardBuilder;

  /// Количество друзей — для оценки нужной высоты.
  final int friendsCount;

  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isMulti = maxPlayers > 2;
    final head = <Widget>[
      if (searchBanner != null) ...[searchBanner!, const SizedBox(height: 12)],
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final estimated =
                          estimateLobbyFriendsCardHeight(friendsCount);
                      final expand = estimated >= constraints.maxHeight;
                      final card = friendsCardBuilder(expand);
                      if (expand) return card;
                      // Мало друзей — высота по контенту, карточка сверху.
                      return Align(
                        alignment: Alignment.topCenter,
                        child: card,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
