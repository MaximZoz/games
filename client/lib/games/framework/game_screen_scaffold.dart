import 'package:flutter/material.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';
import 'package:multigames_game_kit/motion/game_motion.dart';

/// Часы хода, которые партия отдаёт общему хрому.
///
/// [deadline] — unix-время (сек) конца хода, 0 — лимита нет. Хром сам решает,
/// где это показать: свой ход — таймер в шапке перед правилами, ход
/// соперника — рамка его карточки ([GameOpponentPanel]).
class GameTurnClock {
  const GameTurnClock({
    required this.isMyTurn,
    this.deadline = 0,
    this.turnTimeSec = 0,
    this.onExpired,
  });

  /// Партия не идёт или ходов по очереди нет.
  const GameTurnClock.idle()
      : isMyTurn = false,
        deadline = 0,
        turnTimeSec = 0,
        onExpired = null;

  final bool isMyTurn;
  final int deadline;
  final int turnTimeSec;

  /// Моё время вышло. Зовётся один раз за ход.
  final VoidCallback? onExpired;

  bool get hasTimer => deadline > 0;
}

/// Ничья: кто предложил и что делает кнопка.
class GameDrawOffer {
  const GameDrawOffer({
    required this.onPressed,
    this.flags = const DrawOfferFlags(),
  });

  final VoidCallback onPressed;
  final DrawOfferFlags flags;
}

/// Всё, что игра сообщает общему хрому партии.
///
/// Новая игра описывает только это — расположение, порядок и вид кнопок
/// у всех игр одни: крестик слева, название, таймер своего хода, правила;
/// под правилами столбиком «сдаться» и «ничья».
class GameChrome {
  const GameChrome({
    required this.onClose,
    required this.onShowRules,
    this.title,
    this.centerTitle,
    this.turn = const GameTurnClock.idle(),
    this.onSurrender,
    this.draw,
    this.leadingExtra,
    this.actions = const <Widget>[],
    this.closeTooltip,
  });

  /// Крестик. null — кнопка выключена (идёт запрос).
  final VoidCallback? onClose;

  /// Подсказка крестика; null — системное «Закрыть».
  final String? closeTooltip;
  final VoidCallback onShowRules;
  final Widget? title;

  /// null — как в теме приложения.
  final bool? centerTitle;
  final GameTurnClock turn;

  /// Флаг «сдаться». null — кнопки нет (партия окончена, офлайн).
  final VoidCallback? onSurrender;

  /// Рукопожатие «ничья». null — игра ничью не предлагает.
  final GameDrawOffer? draw;

  /// Кнопка рядом с крестиком (групповой чат стола).
  final Widget? leadingExtra;

  /// Свои кнопки игры в шапке — встают левее таймера.
  final List<Widget> actions;

  bool get hasRail => onSurrender != null || draw != null;

  /// Высота столбика действий от верха тела экрана; 0 — столбика нет.
  double get railHeight {
    final buttons = (onSurrender != null ? 1 : 0) + (draw != null ? 1 : 0);
    if (buttons == 0) return 0;
    return GameScreenScaffold.railTop +
        buttons * GameScreenScaffold.railButton +
        (buttons - 1) * GameScreenScaffold.railGap;
  }
}

/// Место, которое общий хром занял на экране партии.
///
/// Тело игры читает отсюда ширину столбика «сдаться / ничья», чтобы не
/// положить под него карточку соперника.
class GameChromeScope extends InheritedWidget {
  const GameChromeScope({
    super.key,
    required this.railInset,
    this.railHeight = 0,
    required super.child,
  });

  /// Ширина полосы справа под столбик действий; 0 — столбика нет.
  final double railInset;

  /// Высота этой полосы от верха тела экрана.
  final double railHeight;

  static double railHeightOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameChromeScope>()
          ?.railHeight ??
      0;

  static double railInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameChromeScope>()
          ?.railInset ??
      0;

  @override
  bool updateShouldNotify(GameChromeScope oldWidget) =>
      oldWidget.railInset != railInset || oldWidget.railHeight != railHeight;
}

/// Каркас экрана партии — общий для всех игр.
///
/// Игра передаёт [GameChrome] и своё [body]; шапка, таймер своего хода,
/// правила и столбик «сдаться / ничья» появляются сами и стоят одинаково.
class GameScreenScaffold extends StatelessWidget {
  const GameScreenScaffold({
    super.key,
    required this.chrome,
    required this.body,
    this.background = true,
  });

  final GameChrome chrome;
  final Widget body;

  /// Обернуть тело общим фоном. false — игра рисует фон сама.
  final bool background;

  /// Ширина столбика действий: кнопка с полной зоной нажатия, вплотную
  /// к правому краю — ровно под кнопкой правил.
  static const double railWidth = 48;

  /// Отступ столбика от верха тела, высота кнопки и зазор между кнопками.
  static const double railTop = 4;
  static const double railButton = 48;
  static const double railGap = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final railInset = chrome.hasRail ? railWidth : 0.0;
    final draw = chrome.draw;
    final stack = Stack(
      children: [
        Positioned.fill(child: body),
        // Без таймера о своём ходе сообщает звук — как в играх без лимита.
        if (!chrome.turn.hasTimer)
          MyTurnAlert.stackLeaf(isMyTurn: chrome.turn.isMyTurn),
        if (chrome.hasRail)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              left: false,
              bottom: false,
              minimum: const EdgeInsets.only(top: railTop),
              child: GameActionsOverlay(
                key: const ValueKey('game-chrome-rail'),
                canSurrender: chrome.onSurrender != null,
                canDraw: draw != null,
                iOfferedDraw: draw?.flags.iOffered ?? false,
                opponentOfferedDraw: draw?.flags.opponentOffered ?? false,
                onSurrender: chrome.onSurrender ?? () {},
                onDraw: draw?.onPressed ?? () {},
                surrenderTooltip: l10n.gameSurrender,
                drawTooltip: l10n.gameOfferDraw,
                acceptDrawTooltip: l10n.gameAcceptDrawTitle,
                drawOfferedTooltip: l10n.gameDrawOffered,
              ),
            ),
          ),
      ],
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: gameToolbarHeight(context),
        leadingWidth: gameAppBarLeadingWidth(
          withExtra: chrome.leadingExtra != null,
        ),
        leading: buildGameAppBarLeading(
          onClose: chrome.onClose,
          closeTooltip: chrome.closeTooltip,
          extra: chrome.leadingExtra,
        ),
        title: chrome.title,
        centerTitle: chrome.centerTitle,
        actions: [
          ...chrome.actions,
          GameMyTurnTimer(turn: chrome.turn),
          IconButton(
            key: const ValueKey('game-chrome-rules'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            iconSize: 22,
            icon: const Icon(Icons.rule_rounded),
            tooltip: l10n.gamesRulesTitle,
            onPressed: chrome.onShowRules,
          ),
        ],
      ),
      body: GameChromeScope(
        railInset: railInset,
        railHeight: chrome.railHeight,
        child: background ? GradientBackground(child: stack) : stack,
      ),
    );
  }
}

/// Таймер своего хода в шапке — сразу перед кнопкой правил.
///
/// Виден только в мой ход; ход соперника показывает рамка его карточки.
/// Виджет остаётся в дереве и в чужой ход, чтобы звук «ваш ход» и тики
/// считались непрерывно.
class GameMyTurnTimer extends StatelessWidget {
  const GameMyTurnTimer({super.key, required this.turn});

  final GameTurnClock turn;

  @override
  Widget build(BuildContext context) {
    if (!turn.hasTimer) return const SizedBox.shrink();
    final mine = turn.isMyTurn;
    final chip = TurnTimerBorder(
      active: mine && turn.turnTimeSec > 0,
      turnDeadline: turn.deadline,
      turnTimeSec: turn.turnTimeSec,
      borderWidth: 2,
      radius: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: GameTurnCountdown(
            key: ValueKey('game-chrome-clock-${turn.deadline}'),
            turnDeadline: turn.deadline,
            turnTimeSec: turn.turnTimeSec,
            isMyTurn: mine,
            onExpired: turn.onExpired ?? () {},
            labelBuilder: (s) => context.l10n.gameSecondsLeft(s),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Center(
        child: AnimatedSize(
          duration: GameMotion.fade,
          curve: GameMotion.settleCurve,
          alignment: Alignment.centerRight,
          child: AnimatedOpacity(
            key: const ValueKey('game-chrome-timer'),
            duration: GameMotion.fade,
            opacity: mine ? 1 : 0,
            child: Visibility(
              visible: mine,
              maintainState: true,
              maintainAnimation: true,
              child: chip,
            ),
          ),
        ),
      ),
    );
  }
}
