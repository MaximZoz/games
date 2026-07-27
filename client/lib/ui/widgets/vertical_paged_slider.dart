import 'package:flutter/material.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Вертикальный PageView с индикатором-точками справа.
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
            padding: const EdgeInsets.only(right: 10, left: 4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 8,
                      height: i == _pageIndex ? 18 : 8,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: i == _pageIndex
                            ? AppColors.accentStart
                            : AppColors.accentSoft,
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
