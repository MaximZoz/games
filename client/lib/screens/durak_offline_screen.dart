import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_bot.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

/// Оффлайн-партия «Дурак» против бота. MVP: 2 игрока, 36 карт, подкидной.
class DurakOfflineScreen extends ConsumerStatefulWidget {
  const DurakOfflineScreen({super.key, this.deckSize = 36});

  final int deckSize;

  @override
  ConsumerState<DurakOfflineScreen> createState() => _DurakOfflineScreenState();
}

class _DurakOfflineScreenState extends ConsumerState<DurakOfflineScreen> {
  static const int _mePlayer = 0;
  static const int _botPlayer = 1;

  late DurakGame _game;
  late DurakBot _bot;
  Timer? _botTimer;
  String? _statusMessage;
  PlayingCard? _activeCard;
  final Set<PlayingCard> _selected = {};
  final GlobalKey _attackSlotKey = GlobalKey();
  final GlobalKey _defendTargetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  void _newGame() {
    _botTimer?.cancel();
    _game = DurakGame.startNew(playerCount: 2, deckSize: widget.deckSize);
    _bot = const DurakBot(index: _botPlayer);
    _statusMessage = null;
    _scheduleBot();
  }

  bool get _myTurn {
    if (_game.isOver) return false;
    if (_game.turn == DurakTurn.defender) {
      // Можно бить или подкидывать, пока защитник бьёт.
      return _game.defenderIndex == _mePlayer ||
          _game.attackerIndex == _mePlayer;
    }
    return _game.attackerIndex == _mePlayer;
  }

  bool get _botShouldAct {
    if (_game.isOver) return false;
    if (_game.turn == DurakTurn.defender) {
      return _game.defenderIndex == _botPlayer;
    }
    return _game.attackerIndex == _botPlayer;
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    if (!_botShouldAct) return;
    _botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final acted = _bot.step(_game);
      if (!acted) {
        // Например: бот-атакующий не может ничего подкинуть — говорим «бито»/«готово».
        if (_game.canAttackerSayBito) {
          _game.sayBito();
        } else if (_game.canAttackerConfirmTake) {
          _game.confirmTake();
        }
      }
      setState(() {});
      _scheduleBot();
    });
  }

  void _onMyCardTap(PlayingCard card) {
    if (_game.isOver) return;
    try {
      if (_game.turn == DurakTurn.defender &&
          _game.defenderIndex == _mePlayer) {
        _game.defend(card, playerIndex: _mePlayer);
        _selected.clear();
      } else if (_game.attackerIndex == _mePlayer) {
        final batch = _selected.length > 1 && _selected.contains(card)
            ? _selected.toList()
            : [card];
        _game.attackMany(batch, playerIndex: _mePlayer);
        _selected.clear();
      } else {
        return;
      }
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (e) {
      setState(() => _statusMessage = e.message);
    }
  }

  void _toggleSelect(PlayingCard card) {
    if (_game.isOver || _game.attackerIndex != _mePlayer) return;
    if (!_game.canAttackWith(card, _mePlayer)) return;
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else if (_selected.isEmpty || _selected.first.rank == card.rank) {
        _selected.add(card);
      } else {
        _selected
          ..clear()
          ..add(card);
      }
      _activeCard = _selected.isEmpty ? null : card;
    });
  }

  Future<bool> _onDrop(PlayingCard card, Offset global, Rect from) async {
    if (_game.isOver) return false;
    final canDefend = _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canDefendWith(card, _mePlayer);
    final canAttack = _game.attackerIndex == _mePlayer &&
        _game.canAttackWith(card, _mePlayer);
    if (!canDefend && !canAttack) return false;

    final attackRect = globalRectOf(_attackSlotKey);
    final defendRect = globalRectOf(_defendTargetKey);
    final over = (canAttack &&
            attackRect != null &&
            attackRect.inflate(28).contains(global)) ||
        (canDefend &&
            defendRect != null &&
            defendRect.inflate(28).contains(global)) ||
        from.center.dy < MediaQuery.sizeOf(context).height * 0.55;
    if (!over) return false;
    _onMyCardTap(card);
    return true;
  }

  void _onTake() {
    try {
      _game.take();
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  void _onBito() {
    try {
      _game.sayBito();
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  void _onConfirmTake() {
    try {
      _game.confirmTake();
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  void _onThrowAll() {
    try {
      _game.confirmThrowAll();
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  Set<PlayingCard> _legalForMe() {
    if (_game.isOver) return {};
    if (_game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer) {
      return _game.hands[_mePlayer]
          .where((c) => _game.canDefendWith(c, _mePlayer))
          .toSet();
    }
    if (_game.attackerIndex == _mePlayer) {
      return _game.hands[_mePlayer]
          .where((c) => _game.canAttackWith(c, _mePlayer))
          .toSet();
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    const cardSize = Size(64, 92);
    final botHand = _game.hands[_botPlayer];
    final myHand = _game.hands[_mePlayer];
    final legal = _legalForMe();
    final openTrump = _game.openTrumpCard;

    final status = _statusOverlay();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/games'),
        ),
        title: Text(context.l10n.gamesDurak),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Новая партия',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _newGame());
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Верх: рубашечный веер бота.
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: CardFan(
                      cards: botHand,
                      cardSize: Size(cardSize.width * 0.85, cardSize.height * 0.85),
                      faceDown: true,
                      invertFan: true,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _turnHint(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildTable(cardSize, openTrump),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildSideAction(),
                  ),
                  const SizedBox(height: 4),
                  // Мой веер.
                  CardFan(
                    cards: myHand,
                    cardSize: cardSize,
                    legalCards: legal,
                    selectedCards: _selected,
                    enabled: !_game.isOver && _myTurn,
                    onActiveChanged: (c) {
                      if (_activeCard == c) return;
                      setState(() => _activeCard = c);
                    },
                    onTap: _onMyCardTap,
                    onLongPress: _toggleSelect,
                    onDrop: _onDrop,
                  ),
                  const SizedBox(height: 6),
                  if (status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTable(Size cardSize, PlayingCard? openTrump) {
    final canDefend = _activeCard != null &&
        _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canDefendWith(_activeCard!, _mePlayer);
    final canAttack = _activeCard != null &&
        _game.attackerIndex == _mePlayer &&
        _game.canAttackWith(_activeCard!, _mePlayer);
    var defendIdx = -1;
    if (canDefend) {
      for (var i = 0; i < _game.table.length; i++) {
        if (_game.table[i].defense == null) {
          defendIdx = i;
          break;
        }
      }
    }

    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DurakDeckPile(
            deckCount: _game.deck.length,
            trumpCard: openTrump ?? PlayingCard(Rank.ace, _game.trump),
            trumpSuit: _game.trump,
            cardSize: cardSize,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _game.table.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: cardSize.width + 10,
                          height: cardSize.height + 14,
                          child: Stack(
                            children: [
                              PlayingCardWidget(
                                key: i == defendIdx ? _defendTargetKey : null,
                                card: _game.table[i].attack,
                                size: cardSize,
                                dropTarget: i == defendIdx,
                                elevated: true,
                              ),
                              if (_game.table[i].defense != null)
                                Positioned(
                                  left: 10,
                                  top: 14,
                                  child: PlayingCardWidget(
                                    card: _game.table[i].defense!,
                                    size: cardSize,
                                    elevated: true,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (!_game.isOver &&
                        _game.attackerIndex == _mePlayer &&
                        (_game.turn == DurakTurn.attacker ||
                            _game.turn == DurakTurn.attackerFollowUp))
                      Padding(
                        key: _attackSlotKey,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: DurakDropSlot(
                          size: cardSize,
                          active: canAttack,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DurakBitoPile(count: _game.bito.length, cardSize: cardSize),
        ],
      ),
    );
  }

  Widget _buildSideAction() {
    final canTake = !_game.isOver &&
        _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canDefenderTake;
    final canBito = !_game.isOver &&
        _game.turn == DurakTurn.attackerFollowUp &&
        _game.attackerIndex == _mePlayer &&
        _game.canAttackerSayBito;
    final canDone = !_game.isOver &&
        _game.attackerIndex == _mePlayer &&
        _game.canAttackerConfirmTake;
    final canThrowAll = !_game.isOver &&
        _game.attackerIndex == _mePlayer &&
        _game.canConfirmThrowAll;
    if (!canTake && !canBito && !canDone && !canThrowAll) {
      return const SizedBox(height: 40);
    }
    final label = canTake
        ? 'Взять'
        : canThrowAll
            ? 'Все'
            : (canDone ? 'Готово' : 'Бито');
    final onPressed = canTake
        ? _onTake
        : canThrowAll
            ? _onThrowAll
            : (canDone ? _onConfirmTake : _onBito);
    return SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(
          canTake ? Icons.file_download_rounded : Icons.check_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _turnHint() {
    if (_game.isOver) {
      if (_game.endedInDraw) return 'Ничья — оба вышли';
      return _game.loserIndex == _mePlayer
          ? 'Вы проиграли — вы дурак'
          : 'Вы выиграли!';
    }
    if (_game.turn == DurakTurn.defender) {
      return _game.defenderIndex == _mePlayer
          ? 'Отбивайтесь'
          : 'Соперник отбивается';
    }
    if (_game.turn == DurakTurn.throwIn) {
      return _game.attackerIndex == _mePlayer
          ? (_game.firstRound
              ? 'Подкиньте карты или «Все» (макс. 5 в первом отбое)'
              : 'Подкиньте карты или нажмите «Все»')
          : 'Соперник подкидывает';
    }
    if (_game.turn == DurakTurn.takeFollowUp) {
      return _game.attackerIndex == _mePlayer
          ? 'Подкиньте вдогонку или нажмите «Готово»'
          : 'Соперник может подкинуть вдогонку';
    }
    if (_game.turn == DurakTurn.attackerFollowUp) {
      return _game.attackerIndex == _mePlayer
          ? 'Подкиньте карту или скажите «Бито»'
          : 'Соперник подкидывает или говорит «Бито»';
    }
    return _game.attackerIndex == _mePlayer
        ? 'Ваш ход — атакуйте'
        : 'Атакует соперник';
  }

  String? _statusOverlay() {
    final msg = _statusMessage;
    _statusMessage = null;
    return msg;
  }
}

