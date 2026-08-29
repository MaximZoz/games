import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Цвета приложения: один светлый фон, белый в рамках/кнопках, чёрный текст.
class AppColors {
  AppColors._();

  /// Единый светлый цвет для тулбара и фона страницы.
  static const Color surfaceUnified = Color(0xFFE8ECF4);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  /// Текст везде один цвет — чёрный.
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF333333);
  static const Color accentStart = Color(0xFF6366F1);
  static const Color accentEnd = Color(0xFF8B5CF6);
  static const Color accentSoft = Color(0xFFE0E7FF);

  /// Цвета для переливающегося градиента фона/тулбара.
  static const List<Color> shimmerColors = [
    Color(0xFFE8ECF4), // голубовато-серый
    Color(0xFFE0E7FF), // лавандовый
    Color(0xFFDDE5F4), // светло-синий
    Color(0xFFEDE9FE), // фиолетовый оттенок
    Color(0xFFE8ECF4),
  ];

  /// Цвета для анимированного бордера (цикл).
  static const List<Color> borderCycle = [
    Color(0xFFA5B4FC),
    Color(0xFFC4B5FD),
    Color(0xFF93C5FD),
    Color(0xFFA5B4FC),
  ];
}

/// Градиенты (для анимированного бордера и т.п.).
class AppGradients {
  AppGradients._();

  static LinearGradient borderAt(double t) {
    const colors = AppColors.borderCycle;
    final i = (t * (colors.length - 1)).floor().clamp(0, colors.length - 2);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors[i], colors[i + 1]],
      stops: const [0.0, 1.0],
    );
  }
}

/// Радиусы и отступы.
class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double input = 12;
  static const double button = 12;
  static const double badge = 8;
}

/// Отступы.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Статус-бар / навигация Android: тот же цвет, что фон (без серого scrim).
class AppOverlays {
  AppOverlays._();

  static const SystemUiOverlayStyle systemUi = SystemUiOverlayStyle(
    statusBarColor: AppColors.surfaceUnified,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppColors.surfaceUnified,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarDividerColor: AppColors.surfaceUnified,
  );
}

/// Длительности анимаций.
class AppDurations {
  AppDurations._();

  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
}

/// Непрозрачный корень экрана.
///
/// На Android Impeller + прозрачный Scaffold / IndexedStack на кадр-два
/// показывает предыдущий route: Flutter уже снял старый слой, а новый ещё
/// не закрыл поверхность. Корень каждой страницы должен быть opaque и
/// совпадать с `android:windowBackground` (`#E8ECF4`).
class AppOpaqueSurface extends StatelessWidget {
  const AppOpaqueSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceUnified,
      child: child,
    );
  }
}
