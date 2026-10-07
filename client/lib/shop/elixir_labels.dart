import 'package:multigames_client/l10n/app_localizations.dart';

const elixirEffectOrder = ['rejuvenate', 'age', 'accelerate'];

const elixirSetOrder = [
  'celebration',
  'legends',
  'nature',
  'cosmic',
  'adventure',
  'jewels',
];

String elixirGroupTitle(AppLocalizations l10n, String effect) {
  switch (effect) {
    case 'age':
      return l10n.elixirGroupAge;
    case 'accelerate':
      return l10n.elixirGroupAccelerate;
    default:
      return l10n.elixirGroupRejuvenate;
  }
}

String elixirEffectNoun(AppLocalizations l10n, String? effect) {
  switch (effect) {
    case 'age':
      return l10n.elixirEffectAge;
    case 'accelerate':
      return l10n.elixirEffectAccelerate;
    default:
      return l10n.elixirEffectRejuvenate;
  }
}

String elixirAdjective(AppLocalizations l10n, String? set) {
  switch (set) {
    case 'nature':
      return l10n.elixirAdjNature;
    case 'legends':
      return l10n.elixirAdjLegends;
    case 'cosmic':
      return l10n.elixirAdjCosmic;
    case 'adventure':
      return l10n.elixirAdjAdventure;
    case 'jewels':
      return l10n.elixirAdjJewels;
    default:
      return l10n.elixirAdjCelebration;
  }
}

String elixirTitle(AppLocalizations l10n, String? set, String? effect) {
  return l10n.elixirName(
      elixirAdjective(l10n, set), elixirEffectNoun(l10n, effect));
}

String elixirUseLabel(AppLocalizations l10n, String effect) {
  switch (effect) {
    case 'age':
      return l10n.elixirUseAge;
    case 'accelerate':
      return l10n.elixirUseAccelerate;
    default:
      return l10n.elixirUseRejuvenate;
  }
}

String elixirEffectHelp(AppLocalizations l10n, String? effect) {
  switch (effect) {
    case 'age':
      return l10n.elixirHelpAge;
    case 'accelerate':
      return l10n.elixirHelpAccelerate;
    default:
      return l10n.elixirHelpRejuvenate;
  }
}
