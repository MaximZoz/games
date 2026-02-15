import 'dart:html' as html;

void logToBrowser(String message) {
  html.window.console.log('MultiGames: $message');
}

void logErrorToBrowser(Object error, StackTrace stack) {
  html.window.console.error('MultiGames ERROR: $error\n$stack');
}
