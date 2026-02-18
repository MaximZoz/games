import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/ui/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Назад в профиль',
        ),
        title: Text(
          'Достижения',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: SizedBox.shrink(),
        ),
      ),
    );
  }
}
