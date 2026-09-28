import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Контейнер веток `StatefulShellRoute`: скрытая вкладка не принимает фокус.
///
/// Иначе крест на главной попадает в ListTile/поле чата из соседней ветки
/// `IndexedStack` (тот же слот, те же координаты) — кривая обводка и A
/// открывает переписку вместо магазина.
Widget gamepadShellBranchContainer(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  final current = navigationShell.currentIndex;
  return IndexedStack(
    index: current,
    children: [
      for (var i = 0; i < children.length; i++)
        _GamepadShellBranch(
          active: i == current,
          child: children[i],
        ),
    ],
  );
}

class _GamepadShellBranch extends StatelessWidget {
  const _GamepadShellBranch({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: !active,
      child: TickerMode(
        enabled: active,
        child: Offstage(
          offstage: !active,
          child: child,
        ),
      ),
    );
  }
}
