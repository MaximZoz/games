import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

/// Контент главной страницы. Тулбар (Войти/Регистрация) в [AppShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<String> _fetchServerStart() async {
    final response = await ApiClient.get(
      Uri.parse('$apiBaseUrl/api/start'),
      operation: 'HomeScreen.fetchServerStart',
    );
    if (response.statusCode == 200) {
      return response.body.trim();
    }
    throw Exception('Server: ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GradientCard(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                  'MultiGames',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    decoration: TextDecoration.none,
                  ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<String>(
                  future: _fetchServerStart(),
                  builder: (context, snapshot) {
                    final hasData = snapshot.hasData;
                    final error = snapshot.error;
                    final serverMessage = hasData ? snapshot.data! : null;

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentStart,
                        ),
                      );
                    }
                    if (hasData && serverMessage != null && serverMessage.isNotEmpty) {
                      return Text(
                        serverMessage,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }
                    if (error != null) {
                      final message = error is http.ClientException
                          ? 'Не удалось подключиться к серверу. Проверьте интернет или что сервер запущен.'
                          : 'Ошибка: $error';
                      return Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  ),
                  authState.when(
                  data: (user) {
                    if (user != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Text(
                          'Вы вошли как ${user.displayName ?? user.email}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.none,
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
          ),
        ),
    );
  }
}
