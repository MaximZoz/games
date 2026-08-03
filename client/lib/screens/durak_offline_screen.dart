import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_bot.dart';
import 'package:multigames_client/games/durak/durak_engine.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
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
      return _game.defenderIndex == _mePlayer;
    }
    return _game.attackerIndex == _mePlayer;
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    if (_game.isOver) return;
    if (_myTurn) return;
    _botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final acted = _bot.step(_game);
      if (!acted) {
        // Например: бот-атакующий не может ничего подкинуть — говорим «бито».
        if (_game.canAttackerSayBito) {
          _game.sayBito();
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
      } else if (_game.attackerIndex == _mePlayer) {
        _game.attack(card, playerIndex: _mePlayer);
      } else {
        return;
      }
      setState(() {});
      _scheduleBot();
    } on DurakRuleError catch (e) {
      setState(() => _statusMessage = e.message);
    }
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
        title: const Text('Дурак'),
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
                  const SizedBox(height: 12),
                  _buildActionsBar(context),
                  const SizedBox(height: 8),
                  // Мой веер.
                  CardFan(
                    cards: myHand,
                    cardSize: cardSize,
                    legalCards: legal,
                    enabled: !_game.isOver && _myTurn,
                    onTap: _onMyCardTap,
                    onDrag: (card, _) => _onMyCardTap(card),
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
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Колода слева + открытый козырь.
          _buildDeck(cardSize, openTrump),
          const SizedBox(width: 20),
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
                                card: _game.table[i].attack,
                                size: cardSize,
                              ),
                              if (_game.table[i].defense != null)
                                Positioned(
                                  left: 10,
                                  top: 14,
                                  child: PlayingCardWidget(
                                    card: _game.table[i].defense!,
                                    size: cardSize,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildBito(cardSize),
        ],
      ),
    );
  }

  Widget _buildDeck(Size cardSize, PlayingCard? openTrump) {
    // Открытый козырь горизонтально под колодой, слегка выступает.
    final n = _game.deck.length;
    if (n == 0 && openTrump == null) {
      return SizedBox(width: cardSize.width, height: cardSize.height);
    }
    return SizedBox(
      width: cardSize.width + 40,
      height: cardSize.height + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (openTrump != null && n > 0)
            Positioned(
              left: 0,
              child: Transform.rotate(
                angle: 1.5708,
                child: PlayingCardWidget(card: openTrump, size: cardSize),
              ),
            ),
          if (n > 0)
            Positioned(
              right: 0,
              child: Stack(
                children: [
                  for (int i = 0; i < (n < 4 ? n : 4); i++)
                    Positioned(
                      left: i * 1.0,
                      top: i * 1.0,
                      child: CardBackWidget(size: cardSize),
                    ),
                ],
              ),
            ),
          Positioned(
            bottom: 2,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$n',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBito(Size cardSize) {
    if (_game.bito.isEmpty) {
      return SizedBox(width: cardSize.width, height: cardSize.height);
    }
    return SizedBox(
      width: cardSize.width + 16,
      height: cardSize.height + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < (_game.bito.length < 4 ? _game.bito.length : 4); i++)
            Positioned(
              left: i * 1.2,
              top: i * 1.2,
              child: Transform.rotate(
                angle: 0.08 * (i % 2 == 0 ? 1 : -1),
                child: CardBackWidget(size: cardSize),
              ),
            ),
          Positioned(
            bottom: 2,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_game.bito.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context) {
    final canTake = !_game.isOver &&
        _game.turn == DurakTurn.defender &&
        _game.defenderIndex == _mePlayer &&
        _game.canDefenderTake;
    final canBito = !_game.isOver &&
        _game.turn == DurakTurn.attackerFollowUp &&
        _game.attackerIndex == _mePlayer &&
        _game.canAttackerSayBito;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          label: 'Взять',
          icon: Icons.file_download_rounded,
          enabled: canTake,
          onPressed: _onTake,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          label: 'Бито',
          icon: Icons.check_rounded,
          enabled: canBito,
          onPressed: _onBito,
        ),
      ],
    );
  }

  String _turnHint() {
    if (_game.isOver) {
      return _game.loserIndex == _mePlayer
          ? 'Вы проиграли — вы дурак'
          : 'Вы выиграли!';
    }
    if (_game.turn == DurakTurn.defender) {
      return _game.defenderIndex == _mePlayer
          ? 'Отбивайтесь'
          : 'Соперник отбивается';
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.accentStart
              : AppColors.accentStart.withValues(alpha: 0.3),
          disabledBackgroundColor: AppColors.accentStart.withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: Icon(icon, color: Colors.white),
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
}
