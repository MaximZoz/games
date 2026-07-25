import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void goBack() => context.pop();

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
            tooltip: 'Назад на главную',
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
      ),
    );
  }
}
