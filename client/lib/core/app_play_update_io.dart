import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Package / applicationId текущего flavor.
/// CI и локальный run передают `--dart-define=ANDROID_APPLICATION_ID=...`.
const String androidApplicationId = String.fromEnvironment(
  'ANDROID_APPLICATION_ID',
  defaultValue: 'com.zozugames.app',
);

Future<bool> supportsPlayInAppUpdate() async => Platform.isAndroid;

Future<bool> isPlayStoreUpdateAvailable() async {
  if (!Platform.isAndroid) return false;
  try {
    final info = await InAppUpdate.checkForUpdate();
    return info.updateAvailability == UpdateAvailability.updateAvailable;
  } catch (_) {
    // Sideload / эмулятор без Play / API недоступен.
    return false;
  }
}

/// Immediate → flexible → открыть страницу в Play Store.
Future<bool> applyPlayStoreUpdate() async {
  if (!Platform.isAndroid) return false;
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return await _openPlayStoreListing();
    }
    if (info.immediateUpdateAllowed) {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) return true;
    }
    if (info.flexibleUpdateAllowed) {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await InAppUpdate.completeFlexibleUpdate();
        return true;
      }
    }
  } catch (_) {}
  return _openPlayStoreListing();
}

Future<bool> _openPlayStoreListing() async {
  final id = androidApplicationId;
  final market = Uri.parse('market://details?id=$id');
  final https = Uri.parse(
    'https://play.google.com/store/apps/details?id=$id',
  );
  try {
    if (await canLaunchUrl(market)) {
      return launchUrl(market, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}
  try {
    return launchUrl(https, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
