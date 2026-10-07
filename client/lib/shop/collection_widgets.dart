import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/animated_emoji_util.dart';
import 'package:multigames_client/shop/collection_condition.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_buy_button.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
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

/// Полноэкранный просмотр: тап вне «Купить» закрывает; крестика нет.
Future<void> showCollectionFullscreen(
  BuildContext context, {
  required String title,
  required String animatedName,
  String? fallback,
  String? subtitle,
  Widget? bottomAction,
  VoidCallback? onBuy,
  String? buyLabel,
  CollectionCondition? condition,
}) {
  final background = condition == null
      ? Colors.black
      : collectionConditionBackground(condition);
  final glow = condition == null
      ? const Color(0xFF1A1A1A)
      : collectionConditionGlow(condition);
  return showDialog<void>(
    context: context,
    barrierColor: background.withValues(alpha: 0.92),
    builder: (dialogContext) {
      var closed = false;
      void close() {
        if (closed) return;
        closed = true;
        final nav = Navigator.of(dialogContext);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (nav.canPop()) nav.pop();
        });
      }

      void buy() {
        onBuy?.call();
      }

      final action = onBuy == null
          ? bottomAction
          : GamepadBuyButton(
              onPressed: buy,
              label: buyLabel ?? context.l10n.shopBuy,
            );

      return GamepadScope(
        exclusive: true,
        onAction: (actionEvent) {
          if (actionEvent == GamepadAction.confirm) {
            if (onBuy != null) {
              buy();
            } else {
              close();
            }
            return true;
          }
          if (actionEvent.isDirection ||
              actionEvent.isScroll ||
              actionEvent == GamepadAction.triggerL ||
              actionEvent == GamepadAction.triggerR) {
            // Стики, триггеры и стрелки не трогают витрину за превью.
            return true;
          }
          if (actionEvent == GamepadAction.shoulderL ||
              actionEvent == GamepadAction.shoulderR) {
            return false;
          }
          // B, X, Y и остальные кнопки закрывают просмотр.
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
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShopAnimatedEmoji(
                        animatedName: animatedName,
                        size: 180,
                        fallback: fallback,
                        animate: true,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (condition != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          collectionConditionName(
                            dialogContext.l10n,
                            condition,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dialogContext.l10n.collectionConditionSell(
                            collectionSellPercent(condition),
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            subtitle!,
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
            ),
          ),
        ),
      );
    },
  );
}

/// Правила состояний в магазине коллекций.
class CollectionConditionNotice extends StatelessWidget {
  const CollectionConditionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.shopCollectionConditionInfo,
      style: const TextStyle(
        fontSize: 13,
        height: 1.35,
        color: AppColors.textSecondary,
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

/// Горизонтальная полоса картинок коллекций (без карточек и подписей).
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
    // Колесо мыши / трекпад → горизонтальный скролл полосы.
    final delta =
        event.scrollDelta.dy != 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
    if (delta == 0) return;
    final pos = _controller.position;
    final next = (_controller.offset + delta).clamp(0.0, pos.maxScrollExtent);
    if (next == _controller.offset) return;
    _controller.jumpTo(next);
    // Не отдаём скролл родителю (карточка профиля).
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
      height: 64,
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
              clipBehavior: Clip.none,
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final it = items[index];
                void open() => showCollectionFullscreen(
                      context,
                      title: it.title,
                      animatedName: it.animatedName ?? 'sparkles',
                      fallback: it.emoji,
                      subtitle: widget.titleOnlyOnTap
                          ? null
                          : collectionItemSubtitle(it.dailyBronze),
                      condition: collectionConditionOf(it.acquiredAt),
                    );
                return GamepadFocusBlock(
                  radius: 14,
                  borderWidth: 2.4,
                  onActivate: open,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: open,
                    child: SizedBox(
                      width: 56,
                      height: 64,
                      child: Center(
                        child: ShopAnimatedEmoji(
                          animatedName: it.animatedName ?? 'sparkles',
                          size: 44,
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
}
