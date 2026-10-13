import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

const String dominoModeKozel = 'kozel';
const String dominoModeClassic = 'classic';
const String dominoModeSea = 'sea';

/// Пустой и неизвестный режим — «Козёл».
String dominoNormalizeMode(String? mode) {
  switch ((mode ?? '').trim().toLowerCase()) {
    case dominoModeClassic:
      return dominoModeClassic;
    case dominoModeSea:
      return dominoModeSea;
    default:
      return dominoModeKozel;
  }
}

String dominoNextMode(String? mode) {
  switch (dominoNormalizeMode(mode)) {
    case dominoModeKozel:
      return dominoModeClassic;
    case dominoModeClassic:
      return dominoModeSea;
    default:
      return dominoModeKozel;
  }
}

bool dominoIsPenaltyMode(String? mode) =>
    dominoNormalizeMode(mode) != dominoModeClassic;

String dominoModeLabel(String? mode, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  switch (dominoNormalizeMode(mode)) {
    case dominoModeClassic:
      return t.gamesDominoModeClassic;
    case dominoModeSea:
      return t.gamesDominoModeSea;
    default:
      return t.gamesDominoModeKozel;
  }
}
