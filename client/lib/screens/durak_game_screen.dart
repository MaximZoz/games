import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/games/durak/card.dart';
import 'package:multigames_client/games/durak/durak_provider.dart';
import 'package:multigames_client/games/durak/durak_repository.dart';
import 'package:multigames_client/games/games_repository.dart' show GamesException;
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/durak/card_fan.dart';
import 'package:multigames_client/ui/durak/playing_card_widget.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';
import 'package:multigames_client/ui/widgets/gradient_background.dart';

class DurakGameScreen extends ConsumerStatefulWidget {
  const DurakGameScreen({super.key, required this.gameId});
  final String gameId;

  @override
  ConsumerState<DurakGameScreen> createState() => _DurakGameScreenState();
}

class _DurakGameScreenState extends ConsumerState<DurakGameScreen> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(durakGameProvider(widget.gameId));
    } on GamesException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playMyCard(DurakGameView view, PlayingCard card) async {
    final repo = ref.read(durakRepositoryProvider);
    if (view.phase == 'defend' && view.defenderIndex == view.myIndex) {
      await _act(() => repo.move(widget.gameId, type: 'defend', card: card));
    } else if (view.attackerIndex == view.myIndex) {
      await _act(() => repo.move(widget.gameId, type: 'attack', card: card));
    }
  }

  Future<void> _take() async {
    final repo = ref.read(durakRepositoryProvider);
    await _act(() => repo.move(widget.gameId, type: 'take'));
  }

  Future<void> _bito() async {
    final repo = ref.read(durakRepositoryProvider);
    await _act(() => repo.move(widget.gameId, type: 'bito'));
  }

  Future<void> _confirmLeave() async {
    final view = ref.read(durakGameProvider(widget.gameId)).valueOrNull;
    final over = view?.isOver ?? false;
    if (over) {
      context.go('/games');
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из партии?'),
        content: const Text('Партия засчитается как поражение.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Остаться')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentStart),
            child: const Text('Сдаться'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    try {
      await ref.read(durakRepositoryProvider).forfeit(widget.gameId);
    } catch (_) {}
    if (!mounted) return;
    context.go('/games');
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(durakGameProvider(widget.gameId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : _confirmLeave,
        ),
        title: const Text('# Дурак'),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: gameAsync.when(
            data: (view) => _buildTable(view),
            loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accentStart),
            ),
            error: (e, _) => Center(
              child: Text('$e', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(DurakGameView view) {
    const cardSize = Size(64, 92);
    final myHand = _apiCardsToPlaying(
      view.hands.length > view.myIndex && view.myIndex >= 0
          ? (view.hands[view.myIndex].cards ?? const [])
          : const [],
    );
    final legal = <PlayingCard>{
      ..._apiCardsToPlaying(view.legalAttack),
      ..._apiCardsToPlaying(view.legalDefend),
    };
    final trumpCard = view.trumpCard.toPlayingCard();

    // Соперники по кругу (кроме себя).
    final opponents = <int>[];
    for (var i = 0; i < view.hands.length; i++) {
      if (i != view.myIndex) opponents.add(i);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final oi in opponents) _opponentFan(view, oi, cardSize),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _turnHint(view),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBoard(view, cardSize, trumpCard)),
          const SizedBox(height: 12),
          _actionsRow(view),
          const SizedBox(height: 8),
          CardFan(
            cards: myHand,
            cardSize: cardSize,
            legalCards: legal,
            enabled: !view.isOver && view.isMyTurn && !_busy,
            onTap: (c) => _playMyCard(view, c),
            onDrag: (c, _) => _playMyCard(view, c),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _opponentFan(DurakGameView view, int idx, Size cardSize) {
    final count = view.hands.length > idx ? view.hands[idx].count : 0;
    final playerId = view.playerIds.length > idx ? view.playerIds[idx] : '';
    final fake = List<PlayingCard>.generate(
      count.clamp(0, 8),
      (i) => PlayingCard(Rank.six, Suit.spades),
    );
    return Column(
      children: [
        Text(
          _playerLabel(playerId, idx, view),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        CardFan(
          cards: fake,
          cardSize:
              Size(cardSize.width * 0.6, cardSize.height * 0.6),
          faceDown: true,
          enabled: false,
        ),
        const SizedBox(height: 2),
        Text(
          'Карт: $count',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBoard(
    DurakGameView view,
    Size cardSize,
    PlayingCard trumpCard,
  ) {
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _deckArea(view, cardSize, trumpCard),
          const SizedBox(width: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final pair in view.table)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: cardSize.width + 10,
                        height: cardSize.height + 14,
                        child: Stack(children: [
                          PlayingCardWidget(
                            card: pair.attack.toPlayingCard(),
                            size: cardSize,
                          ),
                          if (pair.defense != null)
                            Positioned(
                              left: 10,
                              top: 14,
                              child: PlayingCardWidget(
                                card: pair.defense!.toPlayingCard(),
                                size: cardSize,
                              ),
                            ),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          _bitoStack(view.bitoCount, cardSize),
        ],
      ),
    );
  }

  Widget _deckArea(DurakGameView view, Size cardSize, PlayingCard trumpCard) {
    if (view.deckCount == 0) {
      return SizedBox(width: cardSize.width, height: cardSize.height);
    }
    return SizedBox(
      width: cardSize.width + 40,
      height: cardSize.height + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Transform.rotate(
              angle: 1.5708,
              child: PlayingCardWidget(card: trumpCard, size: cardSize),
            ),
          ),
          Positioned(
            right: 0,
            child: Stack(children: [
              for (int i = 0; i < (view.deckCount < 4 ? view.deckCount : 4); i++)
                Positioned(
                  left: i * 1.0,
                  top: i * 1.0,
                  child: CardBackWidget(size: cardSize),
                ),
            ]),
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
                '${view.deckCount}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bitoStack(int count, Size cardSize) {
    if (count == 0) {
      return SizedBox(width: cardSize.width, height: cardSize.height);
    }
    return SizedBox(
      width: cardSize.width + 16,
      height: cardSize.height + 16,
      child: Stack(alignment: Alignment.center, children: [
        for (int i = 0; i < (count < 4 ? count : 4); i++)
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
              '$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _actionsRow(DurakGameView view) {
    final iAmDefender =
        view.defenderIndex == view.myIndex && view.phase == 'defend';
    final iAmAttacker =
        view.attackerIndex == view.myIndex && view.phase == 'attack_follow';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _btn(
          label: 'Взять',
          icon: Icons.file_download_rounded,
          enabled: !view.isOver && iAmDefender && view.table.isNotEmpty && !_busy,
          onPressed: _take,
        ),
        const SizedBox(width: 16),
        _btn(
          label: 'Бито',
          icon: Icons.check_rounded,
          enabled: !view.isOver &&
              iAmAttacker &&
              view.table.isNotEmpty &&
              view.table.every((p) => p.defense != null) &&
              !_busy,
          onPressed: _bito,
        ),
      ],
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.accentStart
              : AppColors.accentStart.withValues(alpha: 0.3),
          disabledBackgroundColor:
              AppColors.accentStart.withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _turnHint(DurakGameView view) {
    if (view.isOver) {
      if (view.loserIndex == view.myIndex) return 'Вы проиграли — вы дурак';
      return 'Партия окончена';
    }
    if (view.phase == 'defend') {
      return view.defenderIndex == view.myIndex
          ? 'Отбивайтесь'
          : 'Соперник отбивается';
    }
    if (view.phase == 'attack_follow') {
      return view.attackerIndex == view.myIndex
          ? 'Подкиньте или скажите «Бито»'
          : 'Соперник подкидывает';
    }
    return view.attackerIndex == view.myIndex
        ? 'Ваш ход — атакуйте'
        : 'Атакует соперник';
  }

  String _playerLabel(String id, int idx, DurakGameView view) {
    if (idx == view.attackerIndex) return 'Атакует';
    if (idx == view.defenderIndex) return 'Защищается';
    return 'Игрок';
  }

  List<PlayingCard> _apiCardsToPlaying(List<DurakApiCard> apis) {
    return apis.map((c) => c.toPlayingCard()).toList();
  }
}
