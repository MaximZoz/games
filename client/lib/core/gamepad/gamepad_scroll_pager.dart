import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/gamepad/gamepad_visibility.dart';

/// Вертикальный список: правый стик листает экран и упирается в края.
class GamepadScrollPager extends StatefulWidget {
  const GamepadScrollPager({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<GamepadScrollPager> createState() => _GamepadScrollPagerState();
}

class _GamepadScrollPagerState extends State<GamepadScrollPager>
    implements GamepadPager {
  late final ScrollController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    GamepadPagerRegistry.register(this);
  }

  @override
  void dispose() {
    GamepadPagerRegistry.unregister(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  bool page(int delta) {
    if (!mounted || !isGamepadContextOnscreen(context)) return false;
    if (_busy) return true;
    if (!_controller.hasClients) return false;
    final position = _controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }
    final next = gamepadPageOffset(
      pixels: position.pixels,
      minExtent: position.minScrollExtent,
      maxExtent: position.maxScrollExtent,
      viewport: position.viewportDimension,
      direction: delta,
    );
    if (next == null) return false;
    unawaited(_goTo(next, delta));
    return true;
  }

  Future<void> _goTo(double next, int delta) async {
    _busy = true;
    try {
      await _controller.animateTo(
        next,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      scheduleFocusEdgeGamepadTarget(last: delta < 0);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}
