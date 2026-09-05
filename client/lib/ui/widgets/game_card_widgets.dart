import 'package:flutter/material.dart';
import 'package:multigames_client/games/games_repository.dart'
    show rulesLineWithStakeIcon;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/ui/widgets/framed_button.dart';
import 'package:multigames_client/ui/widgets/gradient_card.dart';

/// Flutter считает «Крестики-нолики» одним словом и ставит «...» вместо
/// переноса. Нулевой пробел после дефиса даёт точку разрыва.
String wrapGameTitle(String title) {
  return title.replaceAllMapped(
    RegExp(r'[-–—‐‑‒―־]'),
    (m) => '${m[0]}\u200b',
  );
}

/// Название на карточке игры: перенос на новую строку, не обрезка в одну.
class GameCardTitle extends StatelessWidget {
  const GameCardTitle({
    super.key,
    required this.title,
    this.isDesktop = false,
    this.isMedium = false,
  });

  final String title;
  final bool isDesktop;
  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      wrapGameTitle(title),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: isMedium ? 18 : (isDesktop ? 20 : 18),
        letterSpacing: -0.3,
        height: 1.15,
      ),
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
    );
  }
}

/// Верхний блок карточки игры: иконка + заголовок + ставка (кликабельная) +
/// иконка-инфо с правилами. Используется в «Крестики-нолики», «Дурак» и т.д.
class GameCardHeader extends StatelessWidget {
  const GameCardHeader({
    super.key,
    required this.title,
    required this.icon,
    this.flipIcon = false,
    this.iconChild,
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

  /// Зеркалить Material-иконку по X, если нет [iconChild].
  final bool flipIcon;

  /// Кастомная иконка (например Уно); если задана — вместо [icon]/[flipIcon].
  final Widget? iconChild;

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
    final Widget leading = iconChild ??
        (flipIcon
            ? DurakGameIcon(size: 26, color: Colors.white)
            : Icon(icon, color: Colors.white, size: 26));
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
          child: leading,
        ),
        SizedBox(width: isDesktop ? 20 : 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GameCardTitle(
                  title: title,
                  isDesktop: isDesktop,
                  isMedium: isMedium,
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
                  // Не отключать при busy: IconButton с onPressed == null
                  // уходит в disabled и анимирует цвет — иконка «моргает».
                  onPressed: onInfoTap,
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
    this.flipIcon = false,
    this.iconChild,
    this.selected = true,
    this.compact = false,
    this.isDesktop = false,
    this.isMedium = false,
  });

  final String label;
  final IconData icon;

  /// Зеркалить Material-иконку по X, если нет [iconChild].
  final bool flipIcon;

  /// Кастомная иконка; если задана — вместо [icon]/[flipIcon].
  final Widget? iconChild;
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
            color: AppColors.buttonFill,
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
              iconChild ??
                  (flipIcon
                      ? DurakGameIcon(size: iconSz, color: color)
                      : Icon(icon, size: iconSz, color: color)),
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

/// Ряд кнопок «Создать игру» / «Найти игру».
///
/// Всегда одна линия: на узкой карточке уменьшаются отступ и кегль.
/// Loading заменяет иконку на spinner и текст на «Создание…» / «Поиск…».
/// В offline-режиме — одна широкая кнопка «Играть».
class GameCardActionsRow extends StatelessWidget {
  const GameCardActionsRow({
    super.key,
    required this.createLabel,
    required this.creatingLabel,
    required this.onCreate,
    required this.findLabel,
    required this.findingLabel,
    required this.onFind,
    this.offline = false,
    this.offlinePlayLabel,
    this.onOfflinePlay,
    this.inDevelopment = false,
    this.isCreating = false,
    this.isFinding = false,
    this.isDesktop = false,
    this.isMedium = false,
  });

  final String createLabel;
  final String creatingLabel;
  final VoidCallback? onCreate;

  final String findLabel;
  final String findingLabel;
  final VoidCallback? onFind;

  final bool offline;
  final String? offlinePlayLabel;
  final VoidCallback? onOfflinePlay;

  /// Одна неактивная кнопка «В разработке» вместо Создать/Найти/Играть.
  final bool inDevelopment;

  final bool isCreating;
  final bool isFinding;
  final bool isDesktop;
  final bool isMedium;

  /// Обе кнопки одной высоты — иначе ряд «прыгает» по базовой линии.
  double get _height => isDesktop ? 50 : 46;

  @override
  Widget build(BuildContext context) {
    if (inDevelopment) {
      return SizedBox(
        height: _height,
        child: FramedButton(
          onPressed: null,
          icon: Icons.construction_rounded,
          label: context.l10n.gamesInDevelopment,
          expanded: true,
          minHeight: _height,
        ),
      );
    }

    if (offline) {
      return SizedBox(
        height: _height,
        child: FramedButton(
          onPressed: onOfflinePlay,
          icon: Icons.play_arrow_rounded,
          label: offlinePlayLabel ?? context.l10n.gamesPlay,
          expanded: true,
          minHeight: _height,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final veryTight = width < 300;
        final tight = width < 360;
        final height = veryTight ? 42.0 : (tight ? 44.0 : _height);
        final padH = veryTight ? 6.0 : (tight ? 8.0 : 12.0);
        final fontSize = veryTight ? 11.5 : (tight ? 12.5 : 13.5);
        final iconSize = veryTight ? 16.0 : (tight ? 17.0 : 18.0);
        final gap = veryTight ? 6.0 : (tight ? 8.0 : 10.0);
        final padding = EdgeInsets.symmetric(horizontal: padH, vertical: 8);

        Widget action({
          required IconData icon,
          required String label,
          required VoidCallback? onPressed,
          required bool loading,
        }) {
          return Expanded(
            child: SizedBox(
              height: height,
              child: FramedButton(
                onPressed: onPressed,
                icon: icon,
                label: label,
                loading: loading,
                expanded: true,
                minHeight: height,
                padding: padding,
                fontSize: fontSize,
                iconSize: iconSize,
              ),
            ),
          );
        }

        return Row(
          children: [
            action(
              icon: Icons.add_rounded,
              label: isCreating ? creatingLabel : createLabel,
              onPressed: isCreating || isFinding ? null : onCreate,
              loading: isCreating,
            ),
            SizedBox(width: gap),
            action(
              icon: Icons.search_rounded,
              label: isFinding ? findingLabel : findLabel,
              onPressed: isCreating || isFinding ? null : onFind,
              loading: isFinding,
            ),
          ],
        );
      },
    );
  }
}

/// Открывает единый диалог правил. Заголовок всегда [gamesRulesTitle] —
/// карточки и экраны игр не задают свой.
Future<void> showGameRulesDialog({
  required BuildContext context,
  required Widget content,
  String? closeLabel,
}) {
  final resolvedClose = closeLabel ?? context.l10n.commonClose;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.gamesRulesTitle),
      content: SingleChildScrollView(child: content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(resolvedClose),
        ),
      ],
    ),
  );
}

/// Список строк правил. Ставка из [rulesStakeLine] рисует иконку монеты.
Widget rulesTextLines(List<String> lines) {
  const style = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < lines.length; i++) ...[
        rulesLineWithStakeIcon(lines[i], style: style),
        if (i != lines.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = gamesHubStackActions(constraints.maxWidth);
        return GradientCard(
      animate: false,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : (isMedium ? 18 : (isDesktop ? 24 : 20)),
        vertical: compact ? 14 : (isMedium ? 16 : (isDesktop ? 22 : 20)),
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
      },
    );
  }
}
