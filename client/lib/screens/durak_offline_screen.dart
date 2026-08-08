import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_bot.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';
import 'package:multigames_client/games/durak/durak_rules.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/card_fly.dart';
import 'package:multigames_client/ui/durak/deck_pile.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

/// Оффлайн-партия «Дурак» против ботов — те же режимы, что в онлайне.
class DurakOfflineScreen extends ConsumerStatefulWidget {
  const DurakOfflineScreen({
    super.key,
    this.deckSize = 36,
    this.playerCount = 2,
    this.mode = durakModePodkidnoi,
  });

  final int deckSize;
  final int playerCount;
  final String mode;

  @override
  ConsumerState<DurakOfflineScreen> createState() => _DurakOfflineScreenState();
}

class _DurakOfflineScreenState extends ConsumerState<DurakOfflineScreen> {
  static const int _mePlayer = 0;

  late DurakGame _game;
  late List<DurakBot> _bots;
  Timer? _botTimer;
  String? _statusMessage;
  PlayingCard? _activeCard;
  final Set<PlayingCard> _selected = {};
  final GlobalKey _attackSlotKey = GlobalKey();
  final GlobalKey _defendTargetKey = GlobalKey();
  final GlobalKey _transferSlotKey = GlobalKey();

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

  int get _players => widget.playerCount.clamp(2, 4);

  void _newGame() {
    _botTimer?.cancel();
    final deck = durakClampDeckForPlayers(_players, widget.deckSize);
    _game = DurakGame.startNew(
      playerCount: _players,
      deckSize: deck,
      mode: widget.mode == durakModePerevodnoi
          ? durakModePerevodnoi
          : durakModePodkidnoi,
    );
    _bots = [
      for (var i = 1; i < _players; i++) DurakBot(index: i),
    ];
    _statusMessage = null;
    _selected.clear();
    _scheduleBot();
  }

  bool get _myTurn {
    if (_game.isOver || !_game.isAlive(_mePlayer)) return false;
    if (_game.turn == DurakTurn.defender) {
      return _game.defenderIndex == _mePlayer ||
          _game.canThrowIn(_mePlayer);
    }
    if (_game.turn == DurakTurn.throwIn ||
        _game.turn == DurakTurn.attackerFollowUp ||
        _game.turn == DurakTurn.takeFollowUp) {
      return _game.throwerIndex == _mePlayer;
    }
    return _game.attackerIndex == _mePlayer;
  }

  int? get _actingBotIndex {
    if (_game.isOver) return null;
    if (_game.turn == DurakTurn.defender) {
      if (_game.defenderIndex != _mePlayer &&
          _game.isAlive(_game.defenderIndex)) {
        return _game.defenderIndex;
      }
      if (_game.canThrowIn(_game.attackerIndex) &&
          _game.attackerIndex != _mePlayer) {
        return _game.attackerIndex;
      }
      return null;
    }
    if (_game.turn == DurakTurn.attacker) {
      return _game.attackerIndex == _mePlayer ? null : _game.attackerIndex;
    }
    if (_game.turn == DurakTurn.throwIn ||
        _game.turn == DurakTurn.attackerFollowUp ||
        _game.turn == DurakTurn.takeFollowUp) {
      return _game.throwerIndex == _mePlayer ? null : _game.throwerIndex;
    }
    return null;
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    final botIdx = _actingBotIndex;
    if (botIdx == null) return;
    _botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      DurakBot? bot;
      for (final b in _bots) {
        if (b.index == botIdx) {
          bot = b;
          break;
        }
      }
      final acted = bot?.step(_game) ?? false;
      if (!acted) {
        if (_game.canConfirmThrowAll && _game.throwerIndex == botIdx) {
          _game.confirmThrowAll(playerIndex: botIdx);
        } else if (_game.canAttackerSayBito && _game.throwerIndex == botIdx) {
          _game.sayBito(playerIndex: botIdx);
        } else if (_game.canAttackerConfirmTake &&
            _game.throwerIndex == botIdx) {
          _game.confirmTake(playerIndex: botIdx);
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
        if (_game.canTransferWith(card, _mePlayer)) {
          _game.transfer(card, playerIndex: _mePlayer);
        } else {
          _game.defend(card, playerIndex: _mePlayer);
        }
        _selected.clear();
      } else if (_game.canAttackWith(card, _mePlayer)) {
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
    if (_game.isOver || !_game.canAttackWith(card, _mePlayer)) return;
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
    final canTransfer = _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canTransferWith(card, _mePlayer);
    final canAttack = _game.canAttackWith(card, _mePlayer);
    if (!canDefend && !canAttack && !canTransfer) return false;

    final attackRect = globalRectOf(_attackSlotKey);
    final defendRect = globalRectOf(_defendTargetKey);
    final transferRect = globalRectOf(_transferSlotKey);
    final over = (canAttack &&
            attackRect != null &&
            attackRect.inflate(28).contains(global)) ||
        (canDefend &&
            defendRect != null &&
            defendRect.inflate(28).contains(global)) ||
        (canTransfer &&
            transferRect != null &&
            transferRect.inflate(28).contains(global)) ||
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
      _game.sayBito(playerIndex: _mePlayer);
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  void _onConfirmTake() {
    try {
      _game.confirmTake(playerIndex: _mePlayer);
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  void _onThrowAll() {
    try {
      _game.confirmThrowAll(playerIndex: _mePlayer);
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (_) {}
  }

  Set<PlayingCard> _legalForMe() {
    if (_game.isOver || !_game.isAlive(_mePlayer)) return {};
    final out = <PlayingCard>{};
    if (_game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer) {
      out.addAll(
        _game.hands[_mePlayer].where((c) => _game.canDefendWith(c, _mePlayer)),
      );
      out.addAll(_game.legalTransferCards(_mePlayer));
    }
    out.addAll(
      _game.hands[_mePlayer].where((c) => _game.canAttackWith(c, _mePlayer)),
    );
    return out;
  }

  @override
  Widget build(BuildContext context) {
    const cardSize = Size(64, 92);
    final myHand = _game.hands[_mePlayer];
    final legal = _legalForMe();
    final openTrump = _game.openTrumpCard;
    final status = _statusOverlay();
    final opponents = [
      for (var i = 1; i < _game.playerCount; i++) i,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/games'),
        ),
        title: Column(
          children: [
            Text(context.l10n.gamesDurak),
            Text(
              '${durakModeLabel(_game.mode, context.l10n)} · '
              '${durakDeckLabel(widget.deckSize, context.l10n)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.l10n.offlinePlayAgain,
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
                  _opponentsRow(opponents, cardSize),
                  const SizedBox(height: 6),
                  Text(
                    _turnHint(),
                    textAlign: TextAlign.center,
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
                  if (_game.isAlive(_mePlayer))
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
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        context.l10n.gameYouWon,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _opponentsRow(List<int> opponents, Size cardSize) {
    if (opponents.isEmpty) return const SizedBox.shrink();
    final fanSize = Size(cardSize.width * 0.75, cardSize.height * 0.75);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final oi in opponents)
          Expanded(
            child: Column(
              children: [
                Text(
                  context.l10n.offlineBotName(oi),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _game.throwerIndex == oi ||
                            _game.attackerIndex == oi ||
                            _game.defenderIndex == oi
                        ? AppColors.accentStart
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (_game.isFinished(oi))
                  Text(
                    context.l10n.gameYouWon,
                    style: const TextStyle(fontSize: 11),
                  )
                else
                  CardFan(
                    cards: _game.hands[oi],
                    cardSize: fanSize,
                    faceDown: true,
                    invertFan: true,
                    enabled: false,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTable(Size cardSize, PlayingCard? openTrump) {
    final canDefend = _activeCard != null &&
        _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canDefendWith(_activeCard!, _mePlayer);
    final canTransfer = _activeCard != null &&
        _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canTransferWith(_activeCard!, _mePlayer);
    final canAttack = _activeCard != null &&
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
                    if (!_game.isOver && canTransfer)
                      Padding(
                        key: _transferSlotKey,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: DurakDropSlot(
                          size: cardSize,
                          active: true,
                        ),
                      ),
                    if (!_game.isOver &&
                        _myTurn &&
                        (_game.turn == DurakTurn.attacker ||
                            _game.turn == DurakTurn.attackerFollowUp ||
                            _game.turn == DurakTurn.throwIn ||
                            _game.turn == DurakTurn.takeFollowUp ||
                            (_game.turn == DurakTurn.defender &&
                                _game.canThrowIn(_mePlayer))))
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
        _game.throwerIndex == _mePlayer &&
        _game.canAttackerSayBito;
    final canDone = !_game.isOver &&
        _game.throwerIndex == _mePlayer &&
        _game.canAttackerConfirmTake;
    final canThrowAll = !_game.isOver &&
        _game.throwerIndex == _mePlayer &&
        _game.canConfirmThrowAll;
    if (!canTake && !canBito && !canDone && !canThrowAll) {
      return const SizedBox(height: 40);
    }
    final l10n = context.l10n;
    final label = canTake
        ? l10n.durakActionTake
        : canThrowAll
            ? l10n.durakActionAll
            : (canDone ? l10n.durakActionDone : l10n.durakActionBito);
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
    final l10n = context.l10n;
    if (_game.isOver) {
      if (_game.endedInDraw) return l10n.durakHintDrawAllOut;
      return _game.loserIndex == _mePlayer
          ? l10n.durakHintYouLost
          : l10n.gameYouWon;
    }
    if (_game.isFinished(_mePlayer)) {
      return l10n.durakHintYouFinished;
    }
    if (_game.turn == DurakTurn.defender) {
      if (_game.defenderIndex == _mePlayer) {
        return _game.isPerevodnoi
            ? l10n.durakHintDefendOrTransfer
            : l10n.durakHintDefend;
      }
      return l10n.durakHintOpponentDefends;
    }
    if (_game.turn == DurakTurn.throwIn) {
      return _game.throwerIndex == _mePlayer
          ? (_game.firstRound
              ? l10n.durakHintThrowInFirst
              : l10n.durakHintThrowIn)
          : l10n.durakHintOpponentThrows;
    }
    if (_game.turn == DurakTurn.takeFollowUp) {
      return _game.throwerIndex == _mePlayer
          ? l10n.durakHintTakeFollow
          : l10n.durakHintOpponentTakeFollow;
    }
    if (_game.turn == DurakTurn.attackerFollowUp) {
      return _game.throwerIndex == _mePlayer
          ? l10n.durakHintBito
          : l10n.durakHintOpponentBito;
    }
    return _game.attackerIndex == _mePlayer
        ? l10n.durakHintYourAttack
        : l10n.durakHintOpponentAttack;
  }

  String? _statusOverlay() {
    final msg = _statusMessage;
    _statusMessage = null;
    return msg;
  }
}
