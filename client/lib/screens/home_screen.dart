import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<String> _fetchServerStart() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/api/start'));
    if (response.statusCode == 200) {
      return response.body.trim();
    }
    throw Exception('Server: ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('MultiGames'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          authState.when(
            data: (user) {
              if (user != null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        user.displayName ?? user.email,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                      },
                      tooltip: 'Выйти',
                    ),
                  ],
                );
              }
              return TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Войти'),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Войти'),
            ),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MultiGames',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: _fetchServerStart(),
                builder: (context, snapshot) {
                  final hasData = snapshot.hasData;
                  final error = snapshot.error;
                  final serverMessage = hasData ? snapshot.data! : null;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (hasData && serverMessage != null && serverMessage.isNotEmpty) {
                    return Text(
                      serverMessage,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[800],
                      ),
                    );
                  }
                  if (error != null) {
                    return Text(
                      'Server: $error',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 32),
              authState.when(
                data: (user) {
                  if (user != null) {
                    return Text(
                      'Вы вошли как ${user.displayName ?? user.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.push('/login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Войти'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/register'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Регистрация'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Войти'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/register'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Регистрация'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
