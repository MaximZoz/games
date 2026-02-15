import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_config.dart';

/// Контент главной страницы. Тулбар (Войти/Регистрация) в [AppShell].
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

    return Container(
      color: const Color(0xFFF5F5F5),
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
            authState.when(
              data: (user) {
                if (user != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'Вы вошли как ${user.displayName ?? user.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
