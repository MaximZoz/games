import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Касание чуть уменьшает кнопку, а запрос сразу заменяет её на лоадер.
///
/// [onPressed] часто объявлен как `void`, но на деле возвращает [Future]
/// (создание игры, поиск, вход в лобби). Такой future дожидаемся и держим
/// лоадер, пока он не завершится. Синхронный колбэк лоадер не показывает:
/// флаг снимается до кадра отрисовки.
class ApiActionSurface extends StatefulWidget {
  const ApiActionSurface({
    super.key,
    required this.onPressed,
    required this.builder,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final Widget Function(
    BuildContext context,
    bool showLoading,
    VoidCallback? onTap,
  ) builder;

  @override
  State<ApiActionSurface> createState() => _ApiActionSurfaceState();
}

class _ApiActionSurfaceState extends State<ApiActionSurface> {
  bool _localLoading = false;
  bool _pressed = false;

  bool get _showLoading => widget.loading || _localLoading;

  void _setPressed(bool value) {
    if (_pressed == value || _showLoading) return;
    setState(() => _pressed = value);
  }

  Future<void> _tap() async {
    final action = widget.onPressed;
    if (action == null || _showLoading) return;
    setState(() {
      _localLoading = true;
      _pressed = false;
    });
    try {
      final result = (action as dynamic).call();
      if (result is Future) await result;
    } finally {
      if (mounted) setState(() => _localLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !_showLoading;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.builder(
          context,
          _showLoading,
          enabled ? () => unawaited(_tap()) : null,
        ),
      ),
    );
  }
}

/// Цвет всплеска, чтобы касание было видно на светлой заливке кнопки.
Color get apiActionSplash => AppColors.accentStart.withValues(alpha: 0.18);
