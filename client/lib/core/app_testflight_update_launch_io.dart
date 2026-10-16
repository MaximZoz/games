import 'dart:io';

import 'package:multigames_client/core/app_testflight_update.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> supportsTestFlightUpdate() async => Platform.isIOS;

/// Как Play In-App Update: кнопка «Обновить» ведёт в установку новой сборки.
/// У Apple нет своего API установки, TestFlight открывается на странице приложения.
Future<bool> applyTestFlightUpdate(String appleId) async {
  if (!Platform.isIOS) return false;
  final primary = testFlightUpdateUri(appleId);
  final fallback = Uri.parse('itms-beta://');
  for (final uri in <Uri>[primary, if (primary != fallback) fallback]) {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return true;
    } catch (_) {}
  }
  return false;
}
