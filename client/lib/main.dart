import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'src/console_log_stub.dart'
    if (dart.library.html) 'src/console_log_web.dart' as console_log;

const _serverStartUrl = 'http://localhost:8080/api/start';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  console_log.logToBrowser('main() started');

  runZonedGuarded(() {
    runApp(const MultiGamesApp());
    console_log.logToBrowser('runApp() called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      console_log.logToBrowser('first frame built');
    });
  }, (error, stack) {
    console_log.logErrorToBrowser(error, stack);
    debugPrint('MultiGames error: $error\n$stack');
  });
}

class MultiGamesApp extends StatelessWidget {
  const MultiGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiGames',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  Future<String> _fetchServerStart() async {
    final response = await http.get(Uri.parse(_serverStartUrl));
    if (response.statusCode == 200) {
      return response.body.trim();
    }
    throw Exception('Server: ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SizedBox.expand(
        child: Center(
          child: FutureBuilder<String>(
            future: _fetchServerStart(),
            builder: (context, snapshot) {
              final hasData = snapshot.hasData;
              final error = snapshot.error;
              final serverMessage = hasData ? snapshot.data! : null;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MultiGames start',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (hasData && serverMessage != null && serverMessage.isNotEmpty)
                    Text(
                      serverMessage,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[800],
                      ),
                    )
                  else if (error != null)
                    Text(
                      'Server: $error',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
