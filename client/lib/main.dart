import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'src/console_log_stub.dart'
    if (dart.library.html) 'src/console_log_web.dart' as console_log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  console_log.logToBrowser('main() started');

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: MultiGamesApp(),
      ),
    );
    console_log.logToBrowser('runApp() called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      console_log.logToBrowser('first frame built');
    });
  }, (error, stack) {
    console_log.logErrorToBrowser(error, stack);
    debugPrint('MultiGames error: $error\n$stack');
  });
}

class MultiGamesApp extends ConsumerWidget {
  const MultiGamesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'MultiGames',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
