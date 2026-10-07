import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:multigames_client/games/games_repository.dart'
    show rulesLineWithStakeIcon;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/games/games_hub_tabs.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/durak_game_icon.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_scroll_dismiss.dart';
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: gameCardTitleMinHeight(
                      isDesktop: isDesktop,
                      isMedium: isMedium,
                    ),
                  ),
                  child: GameCardTitle(
                    title: title,
                    isDesktop: isDesktop,
                    isMedium: isMedium,
                  ),
                ),
              ),
              if (stakeBronze != null && stakeBronze! > 0) ...[
                SizedBox(width: isMedium ? 8 : (isDesktop ? 16 : 12)),
                GamepadFocusBlock(
                  radius: 12,
                  outlinePadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  onActivate: busy ? null : onStakeTap,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      canRequestFocus: false,
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
                ),
              ],
              if (onInfoTap != null)
                GamepadFocusBlock(
                  radius: 16,
                  shape: GamepadHighlightShape.circle,
                  onActivate: onInfoTap,
                  child: IconButton(
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
    final chipH = gameCardChipHeight(
      compact: compact,
      isDesktop: isDesktop,
      isMedium: isMedium,
    );
    return GamepadFocusBlock(
      radius: 10,
      onActivate: onTap,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.accentStart.withValues(alpha: 0.2),
        highlightColor: AppColors.accentStart.withValues(alpha: 0.1),
        child: Container(
          constraints: BoxConstraints(minHeight: chipH),
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
      ),
    );
  }
}

/// Ряд кнопок «Создать игру» / «Найти игру».
///
/// Всегда одна линия и одинаковый размер на любой ширине карточки.
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
        child: GamepadFocusBlock(
          radius: AppRadius.button,
          child: FramedButton(
            onPressed: null,
            icon: Icons.construction_rounded,
            label: context.l10n.gamesInDevelopment,
            expanded: true,
            minHeight: _height,
          ),
        ),
      );
    }

    if (offline) {
      return SizedBox(
        height: _height,
        child: GamepadFocusBlock(
          radius: AppRadius.button,
          pageAnchor: true,
          onActivate: onOfflinePlay,
          child: FramedButton(
            onPressed: onOfflinePlay,
            icon: Icons.play_arrow_rounded,
            label: offlinePlayLabel ?? context.l10n.gamesPlay,
            expanded: true,
            minHeight: _height,
          ),
        ),
      );
    }

    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
      required bool loading,
      bool pageAnchor = false,
    }) {
      return Expanded(
        child: SizedBox(
          height: _height,
          child: GamepadFocusBlock(
            radius: AppRadius.button,
            pageAnchor: pageAnchor,
            onActivate: loading ? null : onPressed,
            child: FramedButton(
              onPressed: onPressed,
              icon: icon,
              label: label,
              loading: loading,
              expanded: true,
              minHeight: _height,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fontSize: 13.5,
              iconSize: 18,
            ),
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
          pageAnchor: true,
        ),
        const SizedBox(width: 10),
        action(
          icon: Icons.search_rounded,
          label: isFinding ? findingLabel : findLabel,
          onPressed: isCreating || isFinding ? null : onFind,
          loading: isFinding,
        ),
      ],
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
    builder: (ctx) => wrapGamepadScrollDismissDialog(
      dialogContext: ctx,
      child: AlertDialog(
        title: Text(context.l10n.gamesRulesTitle),
        content: SingleChildScrollView(child: content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(resolvedClose),
          ),
        ],
      ),
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

/// Две строки названия — как у «Крестики-нолики», чтобы шапка совпадала с Дураком.
@visibleForTesting
double gameCardTitleMinHeight({
  required bool isDesktop,
  required bool isMedium,
}) {
  final fontSize = isMedium ? 18.0 : (isDesktop ? 20.0 : 18.0);
  return fontSize * 1.15 * 2;
}

/// Высота одного чипа режима — одинаковая для короткой и длинной подписи.
@visibleForTesting
double gameCardChipHeight({
  required bool compact,
  required bool isDesktop,
  bool isMedium = false,
}) {
  final padV = compact ? 4.0 : 6.0;
  final iconSz = compact ? 14.0 : (isDesktop ? 18.0 : 16.0);
  final fontSz =
      compact ? 11.0 : (isMedium ? 13.0 : (isDesktop ? 14.0 : 13.0));
  return (math.max(iconSz, fontSz * 1.35) + padV * 2 + 2).ceilToDouble();
}

/// Полоса чипов на три ряда: на плитке ~340px четыре чипа Дурака
/// («Переводной», «24 карты») переносятся дважды, не в два ряда.
@visibleForTesting
double gameCardChipsMinHeight({
  required bool compact,
  required bool isDesktop,
  bool isMedium = false,
}) {
  final row = gameCardChipHeight(
    compact: compact,
    isDesktop: isDesktop,
    isMedium: isMedium,
  );
  const rows = 3;
  return row * rows + 8 * (rows - 1) + 4;
}

/// Ширина плитки и растяжение по высоте ряда — без LayoutBuilder
/// (он не считается в IntrinsicHeight).
class GameCardLayout extends InheritedWidget {
  const GameCardLayout({
    super.key,
    required this.cardWidth,
    required super.child,
  });

  final double cardWidth;

  static GameCardLayout? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GameCardLayout>();
  }

  @override
  bool updateShouldNotify(GameCardLayout oldWidget) {
    return cardWidth != oldWidget.cardWidth;
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
    final layout = GameCardLayout.maybeOf(context);
    final cardWidth = layout?.cardWidth;
    final compact = gamesHubStackActions(
      cardWidth ?? MediaQuery.sizeOf(context).width,
    );
    final chipsGap = isDesktop ? 18.0 : 14.0;
    final actionsGap = isDesktop ? 20.0 : 16.0;
    return GradientCard(
      animate: false,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : (isMedium ? 18 : (isDesktop ? 24 : 20)),
        vertical: compact ? 14 : (isMedium ? 16 : (isDesktop ? 22 : 20)),
      ),
      child: _GameCardBodyColumn(
        headerGap: chipsGap,
        actionsGap: actionsGap,
        children: [
          header,
          SizedBox(
            width: double.infinity,
            height: gameCardChipsMinHeight(
              compact: false,
              isDesktop: isDesktop,
              isMedium: isMedium,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: isDesktop ? 10 : 8,
                runSpacing: 8,
                children: chips,
              ),
            ),
          ),
          actions,
        ],
      ),
    );
  }
}

/// Шапка + чипы сверху, кнопки внизу, если сетка дала общую высоту.
class _GameCardBodyColumn extends MultiChildRenderObjectWidget {
  const _GameCardBodyColumn({
    required this.headerGap,
    required this.actionsGap,
    required super.children,
  });

  final double headerGap;
  final double actionsGap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderGameCardBodyColumn(
      headerGap: headerGap,
      actionsGap: actionsGap,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderGameCardBodyColumn renderObject,
  ) {
    renderObject
      ..headerGap = headerGap
      ..actionsGap = actionsGap;
  }
}

class _GameCardBodyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderGameCardBodyColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GameCardBodyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GameCardBodyParentData> {
  _RenderGameCardBodyColumn({
    required double headerGap,
    required double actionsGap,
  })  : _headerGap = headerGap,
        _actionsGap = actionsGap;

  double _headerGap;
  double _actionsGap;

  double get headerGap => _headerGap;
  set headerGap(double value) {
    if (_headerGap == value) return;
    _headerGap = value;
    markNeedsLayout();
  }

  double get actionsGap => _actionsGap;
  set actionsGap(double value) {
    if (_actionsGap == value) return;
    _actionsGap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GameCardBodyParentData) {
      child.parentData = _GameCardBodyParentData();
    }
  }

  @override
  void performLayout() {
    final header = firstChild;
    final chips = header == null ? null : childAfter(header);
    final actions = chips == null ? null : childAfter(chips);
    if (header == null || chips == null || actions == null) {
      size = constraints.smallest;
      return;
    }

    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.constrainWidth();
    final childConstraints = BoxConstraints(
      minWidth: width,
      maxWidth: width,
    );
    header.layout(childConstraints, parentUsesSize: true);
    chips.layout(childConstraints, parentUsesSize: true);
    actions.layout(childConstraints, parentUsesSize: true);

    final contentHeight = header.size.height +
        headerGap +
        chips.size.height +
        actionsGap +
        actions.size.height;
    final height = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > contentHeight
        ? constraints.maxHeight
        : contentHeight;

    final headerData = header.parentData! as _GameCardBodyParentData;
    final chipsData = chips.parentData! as _GameCardBodyParentData;
    final actionsData = actions.parentData! as _GameCardBodyParentData;
    headerData.offset = Offset.zero;
    chipsData.offset = Offset(0, header.size.height + headerGap);
    actionsData.offset = Offset(
      0,
      height - actions.size.height,
    );
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
