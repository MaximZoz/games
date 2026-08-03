import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

/// Верхний блок карточки игры: иконка + заголовок + ставка (кликабельная) +
/// иконка-инфо с правилами. Используется в «Крестики-нолики», «Дурак» и т.д.
class GameCardHeader extends StatelessWidget {
  const GameCardHeader({
    super.key,
    required this.title,
    required this.icon,
    this.stakeBronze,
    this.stakeLabel,
    this.stakeCoinType = CoinType.bronze,
    this.onStakeTap,
    this.onInfoTap,
    this.busy = false,
    this.isDesktop = false,
    this.isMedium = false,
  });

  final String title;
  final IconData icon;

  /// Отображаемая ставка (например, `1`, `10`). null → блок ставки скрыт.
  final int? stakeBronze;

  /// Кастомный подписант, если нужно текст вместо числа. Пустая строка → ничего.
  final String? stakeLabel;
  final CoinType stakeCoinType;
  final VoidCallback? onStakeTap;
  final VoidCallback? onInfoTap;
  final bool busy;
  final bool isDesktop;
  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isDesktop ? 52 : 44,
          height: isDesktop ? 52 : 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accentStart, AppColors.accentEnd],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        SizedBox(width: isDesktop ? 20 : 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: isMedium ? 18 : (isDesktop ? 20 : 18),
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: isMedium ? 2 : 1,
                ),
              ),
              if (stakeBronze != null && stakeBronze! > 0) ...[
                SizedBox(width: isMedium ? 8 : (isDesktop ? 16 : 12)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: busy ? null : onStakeTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stakeLabel ?? '$stakeBronze',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          CoinIcon(
                            coinType: stakeCoinType,
                            size: 20,
                            showBorder: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (onInfoTap != null)
                IconButton(
                  onPressed: busy ? null : onInfoTap,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Кликабельный chip с иконкой и текстом. Активное состояние — фиолетовое.
class GameCardChip extends StatelessWidget {
  const GameCardChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = true,
    this.compact = false,
    this.isDesktop = false,
    this.isMedium = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;
  final bool isDesktop;
  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.accentStart : AppColors.textSecondary;
    final padV = compact ? 4.0 : 6.0;
    final padH = compact ? 6.0 : 10.0;
    final iconSz = compact ? 14.0 : (isDesktop ? 18.0 : 16.0);
    final fontSz =
        compact ? 11.0 : (isMedium ? 13.0 : (isDesktop ? 14.0 : 13.0));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.accentStart.withValues(alpha: 0.2),
        highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentSoft.withValues(alpha: 0.6)
                : AppColors.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.accentStart.withValues(alpha: 0.3)
                  : AppColors.textSecondary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSz, color: color),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSz,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ряд кнопок «Создать игру» / «Найти игру» / «Играть с ботом».
/// Первая — заполненная (accent), остальные — outlined. Loading внутри кнопки
/// заменяет иконку. Кнопка «Оффлайн» отображается только если [showOffline].
class GameCardActionsRow extends StatelessWidget {
  const GameCardActionsRow({
    super.key,
    required this.createLabel,
    required this.onCreate,
    required this.findLabel,
    required this.onFind,
    this.offlineLabel,
    this.onOffline,
    this.showOffline = false,
    this.isCreating = false,
    this.isFinding = false,
    this.isDesktop = false,
  });

  final String createLabel;
  final VoidCallback? onCreate;
  final String findLabel;
  final VoidCallback? onFind;

  final String? offlineLabel;
  final VoidCallback? onOffline;
  final bool showOffline;

  final bool isCreating;
  final bool isFinding;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final gap = isDesktop ? 12.0 : 8.0;
    final btnPadV = isDesktop ? 14.0 : 12.0;
    final children = <Widget>[
      Expanded(
        child: FilledButton.icon(
          onPressed:
              isCreating || isFinding ? null : onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            disabledBackgroundColor:
                AppColors.accentStart.withValues(alpha: 0.5),
            padding: EdgeInsets.symmetric(vertical: btnPadV),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isCreating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_rounded),
          label: Text(createLabel,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
      SizedBox(width: gap),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: isCreating || isFinding ? null : onFind,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentStart,
            padding: EdgeInsets.symmetric(vertical: btnPadV),
            side: BorderSide(
              color: AppColors.accentStart.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isFinding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentStart,
                  ),
                )
              : const Icon(Icons.search_rounded),
          label: Text(findLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ];
    if (showOffline && onOffline != null && offlineLabel != null) {
      children.addAll([
        SizedBox(width: gap),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isCreating || isFinding ? null : onOffline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentStart,
              padding: EdgeInsets.symmetric(vertical: btnPadV),
              side: BorderSide(
                color: AppColors.accentStart.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.smart_toy_rounded),
            label: Text(offlineLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]);
    }
    return Row(children: children);
  }
}

/// Общий «скелет» карточки игры: заголовок + чипы + кнопки, единый стиль.
class GameCardShell extends StatelessWidget {
  const GameCardShell({
    super.key,
    required this.header,
    required this.chips,
    required this.actions,
    this.isDesktop = false,
    this.isMedium = false,
  });

  final GameCardHeader header;

  /// Ряды чипов (используется Wrap внутри).
  final List<Widget> chips;
  final Widget actions;
  final bool isDesktop;
  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      animate: false,
      padding: EdgeInsets.symmetric(
        horizontal: isMedium ? 18 : (isDesktop ? 24 : 20),
        vertical: isMedium ? 16 : (isDesktop ? 22 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          SizedBox(height: isDesktop ? 18 : 14),
          Wrap(
            spacing: isDesktop ? 10 : 8,
            runSpacing: 8,
            children: chips,
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          actions,
        ],
      ),
    );
  }
}
