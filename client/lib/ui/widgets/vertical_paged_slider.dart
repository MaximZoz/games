import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_pager.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/gamepad/gamepad_visibility.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Вертикальный PageView с точками справа (без рамки и серой подложки).
/// На десктопе/вебе одно «щелчок» колёсика = одна страница.
class VerticalPagedSlider extends StatefulWidget {
  const VerticalPagedSlider({
    super.key,
    required this.pageCount,
    required this.itemBuilder,
  });

  final int pageCount;
  final Widget Function(BuildContext context, int page) itemBuilder;

  @override
  State<VerticalPagedSlider> createState() => _VerticalPagedSliderState();
}

class _VerticalPagedSliderState extends State<VerticalPagedSlider>
    implements GamepadPager {
  late final PageController _controller;
  int _pageIndex = 0;
  bool _wheelBusy = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    GamepadPagerRegistry.register(this);
  }

  @override
  void didUpdateWidget(covariant VerticalPagedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageCount <= 0) return;
    if (_pageIndex >= widget.pageCount) {
      _pageIndex = widget.pageCount - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(_pageIndex);
      });
    }
  }

  @override
  void dispose() {
    GamepadPagerRegistry.unregister(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  bool page(int delta) {
    if (!mounted || !isGamepadContextOnstage(context)) return false;
    final next = _pageIndex + delta;
    if (next < 0 || next >= widget.pageCount) return false;
    unawaited(_goToPage(next).then((_) {
      if (!mounted) return;
      scheduleFocusEdgeGamepadTarget(last: delta < 0);
    }));
    return true;
  }

  Future<void> _goToPage(int page) async {
    if (page < 0 || page >= widget.pageCount || page == _pageIndex) return;
    if (_wheelBusy) return;
    _wheelBusy = true;
    try {
      await _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      if (mounted) setState(() => _pageIndex = page);
      // Чуть подождать, чтобы инерция трекпада не перелистнула ещё раз.
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } finally {
      _wheelBusy = false;
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // Забираем сигнал у PageView — иначе колёсико копит пиксели (нужно ~4 щелчка).
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent) return;
      if (_wheelBusy || widget.pageCount <= 1) return;
      final dy = resolved.scrollDelta.dy;
      final dx = resolved.scrollDelta.dx;
      // Вертикальное колесо; на трекпаде иногда доминирует dy.
      final delta = dy.abs() >= dx.abs() ? dy : dx;
      if (delta.abs() < 1) return;
      unawaited(_goToPage(delta > 0 ? _pageIndex + 1 : _pageIndex - 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageCount <= 0) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _controller,
              itemCount: widget.pageCount,
              allowImplicitScrolling: false,
              onPageChanged: (i) {
                if (_pageIndex == i) return;
                setState(() => _pageIndex = i);
              },
              // Touch/drag как раньше; колесо обрабатываем сами (см. Listener).
              physics: const BouncingScrollPhysics(
                parent: PageScrollPhysics(),
              ),
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
        if (widget.pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(right: 6, left: 2),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.pageCount; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => unawaited(_goToPage(i)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: i == _pageIndex ? 2.5 : 1.5,
                          height: i == _pageIndex ? 12 : 1.5,
                          decoration: BoxDecoration(
                            color: i == _pageIndex
                                ? AppColors.accentStart.withValues(alpha: 0.45)
                                : const Color(0xFF6B7280)
                                    .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
