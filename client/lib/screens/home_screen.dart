import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/utils/user_error.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';

final homeStartMessageProvider = FutureProvider.autoDispose<String>((ref) async {
  ref.keepAlive();
  final response = await ApiClient.get(
    Uri.parse('$apiBaseUrl/api/start'),
    operation: 'HomeScreen.fetchServerStart',
  );
  if (response.statusCode == 200) {
    return response.body.trim();
  }
  throw Exception('Сервер вернул ошибку: ${response.statusCode}');
});

/// Контент главной страницы. Тулбар (Войти/Регистрация) в [AppShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final serverStartAsync = ref.watch(homeStartMessageProvider);

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
                serverStartAsync.when(
                  loading: () => const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentStart,
                    ),
                  ),
                  data: (serverMessage) {
                    if (serverMessage.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      serverMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                  error: (error, _) {
                    final message = formatUserError(error, fallback: 'Не удалось загрузить данные.');
                    return Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    );
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
