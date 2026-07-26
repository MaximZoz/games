import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

enum AppSnackKind { info, success, error }

/// Нижний отступ: над bottom nav (mobile) и home-indicator, чтобы тост не обрезался.
double _snackBottomMargin(BuildContext context) {
  final media = MediaQuery.of(context);
  final safeBottom = media.padding.bottom;
  final narrow = isNarrow(context);
  final landscape = media.size.width > media.size.height;
  // Как в AppShell: bottom nav только на узком portrait.
  final showBottomNav = narrow && !landscape;
  final navClearance =
      showBottomNav ? (kBottomNavigationBarHeight + 10) : 0.0;
  return safeBottom + navClearance + 12;
}

/// Фирменный нижний тост в цветовой гамме приложения.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackKind kind = AppSnackKind.info,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  final text = message.trim();
  if (text.isEmpty) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final bottom = _snackBottomMargin(context);

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        content: _AppSnackCard(
          message: text,
          kind: kind,
          icon: icon,
        ),
      ),
    );
}

class _AppSnackCard extends StatefulWidget {
  const _AppSnackCard({
    required this.message,
    required this.kind,
    this.icon,
  });

  final String message;
  final AppSnackKind kind;
  final IconData? icon;

  @override
  State<_AppSnackCard> createState() => _AppSnackCardState();
}

class _AppSnackCardState extends State<_AppSnackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _shine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _shine = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1, curve: Curves.easeInOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color accent, Color soft, IconData icon}) _style() {
    switch (widget.kind) {
      case AppSnackKind.success:
        return (
          accent: const Color(0xFF4F46E5),
          soft: AppColors.accentSoft,
          icon: widget.icon ?? Icons.check_rounded,
        );
      case AppSnackKind.error:
        return (
          accent: const Color(0xFFDC2626),
          soft: const Color(0xFFFEE2E2),
          icon: widget.icon ?? Icons.error_outline_rounded,
        );
      case AppSnackKind.info:
        return (
          accent: AppColors.accentStart,
          soft: AppColors.accentSoft,
          icon: widget.icon ?? Icons.info_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          // Центр — чтобы scale не «вдавливал» тост в низ экрана и не обрезал.
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.transparent,
            // Тень не клипаем родителем SnackBar.
            clipBehavior: Clip.none,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    style.accent.withValues(alpha: 0.95),
                    AppColors.accentEnd.withValues(
                      alpha: widget.kind == AppSnackKind.error ? 0.55 : 0.95,
                    ),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.accent.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.5),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Container(
                      color: AppColors.surfaceCard,
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.kind == AppSnackKind.error
                                    ? [
                                        const Color(0xFFFECACA),
                                        style.soft,
                                      ]
                                    : [
                                        style.soft,
                                        AppColors.accentEnd
                                            .withValues(alpha: 0.22),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              style.icon,
                              size: 20,
                              color: style.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shine,
                          builder: (context, _) {
                            return FractionallySizedBox(
                              alignment: Alignment(_shine.value * 2 - 1, 0),
                              widthFactor: 0.28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.22),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
