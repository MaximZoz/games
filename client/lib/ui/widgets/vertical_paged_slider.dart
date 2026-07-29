import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Вертикальный PageView с точками справа (без рамки и серой подложки).
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

class _VerticalPagedSliderState extends State<VerticalPagedSlider> {
  late final PageController _controller;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _controller,
            itemCount: widget.pageCount,
            allowImplicitScrolling: false,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            physics: const BouncingScrollPhysics(
              parent: PageScrollPhysics(),
            ),
            itemBuilder: widget.itemBuilder,
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: i == _pageIndex ? 2.5 : 1.5,
                      height: i == _pageIndex ? 12 : 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2.5),
                      decoration: BoxDecoration(
                        color: i == _pageIndex
                            ? AppColors.accentStart.withValues(alpha: 0.45)
                            : const Color(0xFF6B7280).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
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
