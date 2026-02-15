import 'package:flutter/material.dart';

void main() {
  runApp(const MultiGamesApp());
}

class MultiGamesApp extends StatelessWidget {
  const MultiGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiGames',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('MultiGames — coming soon'),
        ),
      ),
    );
  }
}
