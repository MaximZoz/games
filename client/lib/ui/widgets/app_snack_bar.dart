import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

enum AppSnackKind { info, success, error }

OverlayEntry? _activeSnackEntry;
Timer? _activeSnackTimer;

/// Нижний отступ над bottom nav / safe-area (AppShell рисует nav вне Scaffold).
double _snackBottomMargin(BuildContext context) {
  final media = MediaQuery.of(context);
  final safeBottom = media.viewPadding.bottom;
  final narrow = isNarrow(context);
  final landscape = media.size.width > media.size.height;
  final showBottomNav = narrow && !landscape;
  // Реальная высота бара с подписями чуть больше kBottomNavigationBarHeight.
  final navClearance = showBottomNav ? 72.0 : 0.0;
  return safeBottom + navClearance + 12;
}

/// Фирменный нижний тост поверх всего UI (включая bottom nav).
void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackKind kind = AppSnackKind.info,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  final text = message.trim();
  if (text.isEmpty) return;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    // Фоллбек, если overlay недоступен.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(16, 0, 16, _snackBottomMargin(context)),
          duration: duration,
          content: _AppSnackCard(message: text, kind: kind, icon: icon),
        ),
      );
    return;
  }

  _activeSnackTimer?.cancel();
  _activeSnackEntry?.remove();
  _activeSnackEntry = null;

  final bottom = _snackBottomMargin(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: bottom,
        child: IgnorePointer(
          ignoring: false,
          child: Center(
            child: _AppSnackCard(
              message: text,
              kind: kind,
              icon: icon,
              onDismiss: () {
                _activeSnackTimer?.cancel();
                if (_activeSnackEntry == entry) {
                  entry.remove();
                  _activeSnackEntry = null;
                }
              },
            ),
          ),
        ),
      );
    },
  );

  _activeSnackEntry = entry;
  overlay.insert(entry);
  _activeSnackTimer = Timer(duration, () {
    if (_activeSnackEntry == entry) {
      entry.remove();
      _activeSnackEntry = null;
    }
  });
}

class _AppSnackCard extends StatefulWidget {
  const _AppSnackCard({
    required this.message,
    required this.kind,
    this.icon,
    this.onDismiss,
  });

  final String message;
  final AppSnackKind kind;
  final IconData? icon;
  final VoidCallback? onDismiss;

  @override
  State<_AppSnackCard> createState() => _AppSnackCardState();
}

class _AppSnackCardState extends State<_AppSnackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _shine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _shine = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.easeInOut),
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

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Dismissible(
            key: ValueKey('app-snack-${widget.message}'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => widget.onDismiss?.call(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        style.accent.withValues(alpha: 0.95),
                        AppColors.accentEnd.withValues(
                          alpha:
                              widget.kind == AppSnackKind.error ? 0.55 : 0.95,
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
                                  alignment:
                                      Alignment(_shine.value * 2 - 1, 0),
                                  widthFactor: 0.28,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.2),
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
        ),
      ),
    );
  }
}
