import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_condition.dart';
import 'package:multigames_client/shop/collection_condition_scale.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_buy_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';

/// Снятые с витрины предметы (логика магазина/витрины их не показывает).
bool isRetiredCollectionItem(String code) => code == 'coll_fireworks';

const collectionSetOrder = [
  'celebration',
  'nature',
  'cosmic',
  'adventure',
  'legends',
  'jewels',
];

/// Бонус полного набора. Винтажный набор — 300% обычного бонуса.
int collectionSetIncomeBronze(String set, {required bool allVintage}) {
  final base = collectionSetBonusBronze(set);
  if (!allVintage) return base;
  return base * 3;
}

bool collectionOwnedIsVintage({
  required String? acquiredAt,
  int conditionShift = 0,
  String? vintageAt,
  DateTime? now,
}) {
  final acquired = parseCollectionAcquiredAt(acquiredAt);
  if (acquired == null) return false;
  return collectionConditionEffective(
        acquired: acquired,
        now: now ?? DateTime.now(),
        shift: conditionShift,
        vintageAt: parseCollectionAcquiredAt(vintageAt),
      ) ==
      CollectionCondition.vintage;
}

/// Дневной бонус за полностью собранную группу (как на сервере).
int collectionSetBonusBronze(String set) {
  switch (set) {
    case 'celebration':
    case 'nature':
      return 50;
    case 'cosmic':
      return 100;
    case 'adventure':
      return 200;
    case 'legends':
      return 500;
    case 'jewels':
      return 5000;
    default:
      return 0;
  }
}

/// Группы коллекций: доход/день по возрастанию, затем фиксированный порядок.
int compareCollectionSetsByDaily(
  String a,
  String b,
  int Function(String set) dailyOf,
) {
  final byDaily = dailyOf(a).compareTo(dailyOf(b));
  if (byDaily != 0) return byDaily;
  final ai = collectionSetOrder.indexOf(a);
  final bi = collectionSetOrder.indexOf(b);
  return (ai < 0 ? 999 : ai).compareTo(bi < 0 ? 999 : bi);
}

/// Предметы коллекции: доход/день по возрастанию.
int compareCollectionItemsByDaily(
    int aDaily, int bDaily, int aOrder, int bOrder) {
  final byDaily = aDaily.compareTo(bDaily);
  if (byDaily != 0) return byDaily;
  return aOrder.compareTo(bOrder);
}

String collectionSetTitle(String set) {
  final l10n = LocaleService.l10n;
  switch (set) {
    case 'legends':
      return l10n.collectionSetLegends;
    case 'cosmic':
      return l10n.collectionSetSpace;
    case 'jewels':
      return l10n.collectionSetGems;
    case 'celebration':
      return l10n.collectionSetParty;
    case 'nature':
      return l10n.collectionSetNature;
    case 'adventure':
      return l10n.collectionSetAdventures;
    default:
      return set;
  }
}

String collectionItemSubtitle(int dailyBronze) =>
    LocaleService.l10n.collectionCardMeta(
      formatRewardBronzePerDay(dailyBronze),
    );

/// Доход предмета в магазине: у купленного — по текущему состоянию.
int shopCollectionDaily(ShopItem item) {
  if (!item.owned) return item.dailyBronze;
  return collectionDailyIncomeBronze(
    baseBronze: item.dailyBronze,
    acquiredAt: item.acquiredAt,
    conditionShift: item.conditionShift,
    vintageAt: item.vintageAt,
  );
}

/// Бонус набора в магазине. Утроение только если набор собран и весь винтажный.
int shopSetDaily(String set, List<ShopItem> items) {
  if (items.isEmpty || items.any((e) => !e.owned)) {
    return collectionSetBonusBronze(set);
  }
  final allVintage = items.every(
    (e) => collectionOwnedIsVintage(
      acquiredAt: e.acquiredAt,
      conditionShift: e.conditionShift,
      vintageAt: e.vintageAt,
    ),
  );
  return collectionSetIncomeBronze(set, allVintage: allVintage);
}

/// Кнопка эликсира на полноэкранной коллекции.
class CollectionElixirButton {
  const CollectionElixirButton({
    required this.effect,
    required this.label,
    required this.onPressed,
    this.quantity = 1,
  });

  final String effect;
  final String label;

  /// Сколько флаконов этого эффекта ещё есть. 0 — кнопку не показываем.
  final int quantity;

  /// null — отмена. Иначе новый возраст, срок и сколько флаконов осталось.
  final Future<
          ({
            int shift,
            DateTime? vintageAt,
            DateTime? acquiredAt,
            int quantity
          })?>
      Function() onPressed;

  CollectionElixirButton withQuantity(int quantity) {
    return CollectionElixirButton(
      effect: effect,
      label: label,
      quantity: quantity,
      onPressed: onPressed,
    );
  }
}

/// Полноэкранный просмотр: тап вне кнопок закрывает; крестика нет.
/// Если задан [acquiredAt], состояние и срок до следующего считаются сами.
Future<void> showCollectionFullscreen(
  BuildContext context, {
  required String title,
  required String animatedName,
  String? fallback,
  String? subtitle,
  ValueNotifier<String>? subtitleListenable,
  Widget? bottomAction,
  FutureOr<void> Function()? onBuy,
  String? buyLabel,
  CollectionCondition? condition,
  DateTime? acquiredAt,
  int conditionShift = 0,
  DateTime? vintageAt,
  List<CollectionElixirButton> elixirActions = const [],
  Widget? artwork,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) {
      return _CollectionFullscreen(
        title: title,
        animatedName: animatedName,
        fallback: fallback,
        subtitle: subtitle,
        subtitleListenable: subtitleListenable,
        bottomAction: bottomAction,
        onBuy: onBuy,
        buyLabel: buyLabel,
        condition: condition,
        acquiredAt: acquiredAt,
        conditionShift: conditionShift,
        vintageAt: vintageAt,
        elixirActions: elixirActions,
        artwork: artwork,
      );
    },
  );
}

class _CollectionFullscreen extends StatefulWidget {
  const _CollectionFullscreen({
    required this.title,
    required this.animatedName,
    this.fallback,
    this.subtitle,
    this.subtitleListenable,
    this.bottomAction,
    this.onBuy,
    this.buyLabel,
    this.condition,
    this.acquiredAt,
    this.conditionShift = 0,
    this.vintageAt,
    this.elixirActions = const [],
    this.artwork,
  });

  final String title;
  final String animatedName;
  final String? fallback;
  final String? subtitle;
  final ValueNotifier<String>? subtitleListenable;
  final Widget? bottomAction;
  final FutureOr<void> Function()? onBuy;
  final String? buyLabel;
  final CollectionCondition? condition;
  final DateTime? acquiredAt;
  final int conditionShift;
  final DateTime? vintageAt;
  final List<CollectionElixirButton> elixirActions;
  final Widget? artwork;

  @override
  State<_CollectionFullscreen> createState() => _CollectionFullscreenState();
}

class _CollectionFullscreenState extends State<_CollectionFullscreen> {
  late int _shift;
  DateTime? _vintageAt;
  DateTime? _acquired;
  late String? _subtitle;
  late List<CollectionElixirButton> _ownedElixirs;
  Timer? _tick;
  bool _closed = false;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _shift = widget.conditionShift;
    _vintageAt = widget.vintageAt;
    _acquired = widget.acquiredAt;
    _subtitle = widget.subtitle;
    _ownedElixirs = [...widget.elixirActions];
    widget.subtitleListenable?.addListener(_syncSubtitle);
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _syncSubtitle() {
    final next = widget.subtitleListenable?.value;
    if (!mounted || next == _subtitle) return;
    setState(() => _subtitle = next);
  }

  @override
  void dispose() {
    widget.subtitleListenable?.removeListener(_syncSubtitle);
    _tick?.cancel();
    super.dispose();
  }

  CollectionCondition? _condition(DateTime now) {
    final acquired = _acquired;
    if (acquired == null) return widget.condition;
    return collectionConditionEffective(
      acquired: acquired,
      now: now,
      shift: _shift,
      vintageAt: _vintageAt,
    );
  }

  List<CollectionElixirButton> _visibleElixirs(DateTime now) {
    final acquired = _acquired;
    if (acquired == null) {
      return [for (final b in _ownedElixirs) if (b.quantity > 0) b];
    }
    final cond = collectionConditionEffective(
      acquired: acquired,
      now: now,
      shift: _shift,
      vintageAt: _vintageAt,
    );
    return [
      for (final b in _ownedElixirs)
        if (b.quantity > 0 &&
            elixirCanApply(
              effect: b.effect,
              condition: cond,
              vintageAt: _vintageAt,
              acquired: acquired,
              now: now,
            ))
          b,
    ];
  }

  Future<void> _useElixir(CollectionElixirButton button) async {
    final next = await button.onPressed();
    if (!mounted || next == null) return;
    setState(() {
      _shift = next.shift;
      _vintageAt = next.vintageAt;
      _acquired = next.acquiredAt ?? _acquired;
      _ownedElixirs = [
        for (final b in _ownedElixirs)
          if (b.effect == button.effect) b.withQuantity(next.quantity) else b,
      ];
    });
  }

  String? _until(DateTime now, CollectionCondition? condition) {
    final acquired = _acquired;
    if (acquired == null || condition == null) return null;
    final next = nextCollectionCondition(
      acquired: acquired,
      now: now,
      shift: _shift,
      vintageAt: _vintageAt,
    );
    if (next == null) return null;
    final l10n = context.l10n;
    return l10n.collectionUntil(
      collectionConditionGenitive(l10n, next.condition),
      collectionTimeLeft(l10n, next.at.difference(now)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final condition = _condition(now);
    final until = _until(now, condition);
    final background = condition == null
        ? Colors.black
        : collectionConditionBackground(condition);
    final glow = condition == null
        ? const Color(0xFF1A1A1A)
        : collectionConditionGlow(condition);
    void close() {
      if (_closed) return;
      _closed = true;
      final nav = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nav.canPop()) nav.pop();
      });
    }

    Future<void> buy() async {
      final action = widget.onBuy;
      if (action == null || _buying) return;
      setState(() => _buying = true);
      try {
        await action();
      } finally {
        if (mounted) setState(() => _buying = false);
      }
    }

    final actions = _visibleElixirs(now);
    final hasChoices = widget.onBuy != null || actions.isNotEmpty;
    final action = widget.onBuy == null
        ? widget.bottomAction
        : GamepadBuyButton(
            onPressed: () => unawaited(buy()),
            busy: _buying,
            label: widget.buyLabel ?? context.l10n.shopBuy,
          );

    return GamepadScope(
      exclusive: true,
      onAction: (actionEvent) {
        if (actionEvent.isDirection) {
          if (hasChoices) {
            handleGamepadUiAction(context, actionEvent);
          }
          return true;
        }
        if (actionEvent == GamepadAction.confirm) {
          if (hasChoices && handleGamepadUiAction(context, actionEvent)) {
            return true;
          }
          if (widget.onBuy != null) {
            unawaited(buy());
          } else {
            close();
          }
          return true;
        }
        if (actionEvent.isScroll ||
            actionEvent == GamepadAction.triggerL ||
            actionEvent == GamepadAction.triggerR) {
          return true;
        }
        if (actionEvent == GamepadAction.shoulderL ||
            actionEvent == GamepadAction.shoulderR) {
          return false;
        }
        close();
        return true;
      },
      child: Dialog.fullscreen(
        backgroundColor: background,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.25),
              radius: 1.05,
              colors: [glow, background],
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.artwork ??
                              ShopAnimatedEmoji(
                                animatedName: widget.animatedName,
                                size: 180,
                                fallback: widget.fallback,
                                animate: true,
                              ),
                          const SizedBox(height: 20),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((_subtitle ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _subtitle!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          if (action != null) ...[
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () {},
                              child: action,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (condition != null || actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: GestureDetector(
                        onTap: () {},
                        child: Column(
                          children: [
                            if (condition != null)
                              Text(
                                collectionConditionName(
                                    context.l10n, condition),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (until != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                until,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (condition != null) ...[
                              const SizedBox(height: 12),
                              CollectionConditionScale(
                                current: condition,
                                marker: collectionConditionScaleT(
                                  condition: condition,
                                  acquired: _acquired,
                                  now: now,
                                  shift: _shift,
                                  vintageAt: _vintageAt,
                                ),
                                onDark: true,
                              ),
                            ],
                            if (actions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (var i = 0; i < actions.length; i++)
                                    GamepadBuyButton(
                                      autofocus: i == 0 && widget.onBuy == null,
                                      label: actions[i].label,
                                      onPressed: () => _useElixir(actions[i]),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Секция коллекций в карточке пользователя (по клику на аватар).
/// Загружает витрину по [userId]; если пусто — ничего не рисует.
class PeerCollectionsSection extends ConsumerWidget {
  const PeerCollectionsSection({
    super.key,
    required this.userId,
    this.topPadding = 12,
  });

  final String userId;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.trim().isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<InventoryItem>>(
      future: ref.read(shopRepositoryProvider).listCollectionsShowcase(userId),
      builder: (context, snap) {
        final items = snap.data ?? const <InventoryItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.shopCollections,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CollectionShowcaseGrid(items: items),
            ],
          ),
        );
      },
    );
  }
}

/// Одна горизонтальная полоса картинок коллекций.
///
/// Профиль и карточка пользователя листают её вбок, если иконки не влезают.
class CollectionShowcaseGrid extends StatefulWidget {
  const CollectionShowcaseGrid({
    super.key,
    required this.items,
    this.emptyText,
    this.titleOnlyOnTap = true,
  });

  final List<InventoryItem> items;
  final String? emptyText;
  final bool titleOnlyOnTap;

  static const slotWidth = 56.0;
  static const slotHeight = 64.0;
  static const emojiSize = 44.0;
  static const gap = 10.0;

  @override
  State<CollectionShowcaseGrid> createState() => _CollectionShowcaseGridState();
}

class _CollectionShowcaseGridState extends State<CollectionShowcaseGrid> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta =
        event.scrollDelta.dy != 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
    if (delta == 0) return;
    final pos = _controller.position;
    final next = (_controller.offset + delta).clamp(0.0, pos.maxScrollExtent);
    if (next == _controller.offset) return;
    _controller.jumpTo(next);
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return Text(
        widget.emptyText ?? context.l10n.shopEmpty,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return SizedBox(
      height: CollectionShowcaseGrid.slotHeight,
      width: double.infinity,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          child: GamepadNavGroup(
            name: 'collection-showcase',
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: CollectionShowcaseGrid.gap),
              itemBuilder: (context, index) {
                final it = items[index];
                return GamepadFocusBlock(
                  key: ValueKey(it.code),
                  radius: 14,
                  borderWidth: 2.4,
                  onActivate: () => _openShowcaseItem(context, it),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openShowcaseItem(context, it),
                    child: SizedBox(
                      width: CollectionShowcaseGrid.slotWidth,
                      height: CollectionShowcaseGrid.slotHeight,
                      child: Center(
                        child: ShopAnimatedEmoji(
                          animatedName: it.animatedName ?? 'sparkles',
                          size: CollectionShowcaseGrid.emojiSize,
                          fallback: it.emoji,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openShowcaseItem(BuildContext context, InventoryItem it) {
    showCollectionFullscreen(
      context,
      title: it.title,
      animatedName: it.animatedName ?? 'sparkles',
      fallback: it.emoji,
      subtitle:
          widget.titleOnlyOnTap ? null : collectionItemSubtitle(it.dailyBronze),
      acquiredAt: parseCollectionAcquiredAt(it.acquiredAt),
      conditionShift: it.conditionShift,
      vintageAt: parseCollectionAcquiredAt(it.vintageAt),
    );
  }
}
