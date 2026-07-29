import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

/// Локализует служебные имена с сервера (бот / игрок по умолчанию).
String localizeDisplayName(String? name, [AppLocalizations? l10n]) {
  final t = l10n ?? LocaleService.l10n;
  final n = (name ?? '').trim();
  if (n.isEmpty) return t.commonPlayer;
  switch (n.toLowerCase()) {
    case 'бот':
    case 'bot':
      return t.gameBot;
    case 'игрок':
    case 'player':
      return t.commonPlayer;
    default:
      return n;
  }
}
