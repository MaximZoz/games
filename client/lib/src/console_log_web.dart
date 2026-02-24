// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void logToBrowser(String message) {
  html.window.console.log('MultiGames: $message');
}

void logErrorToBrowser(Object error, StackTrace stack) {
  html.window.console.error('MultiGames ERROR: $error\n$stack');
}
