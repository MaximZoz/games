import 'package:flutter/widgets.dart';
import 'package:multigames_client/l10n/app_localizations.dart';

export 'package:multigames_client/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
