import 'package:flutter/material.dart';
import 'package:multigames_client/games/poker/poker_offline_engine.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Локализованное имя комбинации по каноническому рангу сервера (`OnePair`).
String? pokerHandRankLabel(AppLocalizations l10n, String? rank) {
  if (rank == null || rank.isEmpty) return null;
  switch (rank) {
    case 'HighCard':
      return l10n.pokerHandHighCard;
    case 'OnePair':
      return l10n.pokerHandOnePair;
    case 'TwoPair':
      return l10n.pokerHandTwoPair;
    case 'ThreeOfAKind':
      return l10n.pokerHandThreeOfAKind;
    case 'Straight':
      return l10n.pokerHandStraight;
    case 'Flush':
      return l10n.pokerHandFlush;
    case 'FullHouse':
      return l10n.pokerHandFullHouse;
    case 'FourOfAKind':
      return l10n.pokerHandFourOfAKind;
    case 'StraightFlush':
      return l10n.pokerHandStraightFlush;
    case 'RoyalFlush':
      return l10n.pokerHandRoyalFlush;
    default:
      return null;
  }
}

/// Все комбинации от старшей к младшей — для справочника.
List<PokerHandRank> pokerHandRanksStrongestFirst() {
  return PokerHandRank.values.reversed.toList(growable: false);
}

/// Справочник комбинаций: текущая рука выделена.
Future<void> showPokerCombinationsSheet({
  required BuildContext context,
  String? currentRank,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: PokerCombinationsSheet(currentRank: currentRank),
        ),
      );
    },
  );
}

class PokerCombinationsSheet extends StatelessWidget {
  const PokerCombinationsSheet({super.key, this.currentRank});

  final String? currentRank;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mine = currentRank?.trim() ?? '';
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.pokerCombinationsTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final rank in pokerHandRanksStrongestFirst())
                      _ComboRow(
                        label: pokerHandRankLabel(
                              l10n,
                              pokerHandRankName(rank),
                            ) ??
                            pokerHandRankName(rank),
                        selected: mine == pokerHandRankName(rank),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComboRow extends StatelessWidget {
  const _ComboRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accentStart.withValues(alpha: 0.16)
            : AppColors.surfaceUnified,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.accentStart
              : AppColors.accentSoft.withValues(alpha: 0.7),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_rounded,
              color: AppColors.accentStart,
              size: 20,
            ),
        ],
      ),
    );
  }
}
