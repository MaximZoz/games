import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_family.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

/// Кружок / капсула с подписью кнопки текущего геймпада.
class GamepadGlyph extends StatelessWidget {
  const GamepadGlyph({
    super.key,
    required this.action,
    this.size = 22,
    this.family,
  });

  final GamepadAction action;
  final double size;
  final GamepadFamily? family;

  @override
  Widget build(BuildContext context) {
    final look = gamepadButtonLook(action, family: family);
    final wide = look.label.length > 1;
    final height = size;
    final width = wide ? size * 1.45 : size;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: look.color,
        borderRadius: BorderRadius.circular(wide ? 7 : 99),
        boxShadow: [
          BoxShadow(
            color: look.color.withValues(alpha: 0.35),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        look.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: look.darkLabel ? const Color(0xFF1A1A1A) : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: wide ? size * 0.38 : size * 0.48,
          height: 1,
        ),
      ),
    );
  }
}

/// Бейдж кнопки в углу дочернего виджета, если геймпад активен.
class GamepadHinted extends StatelessWidget {
  const GamepadHinted({
    super.key,
    required this.action,
    required this.child,
    this.size = 20,
  });

  final GamepadAction action;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        GamepadService.instance.devices,
        GamepadService.instance.activityTick,
      ]),
      builder: (context, _) {
        if (!gamepadHintsWanted()) return child;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -4,
              top: -6,
              child: IgnorePointer(child: GamepadGlyph(action: action, size: size)),
            ),
          ],
        );
      },
    );
  }
}

/// Подсказка «нажми эту кнопку» рядом с текстом.
class GamepadHintLabel extends StatelessWidget {
  const GamepadHintLabel({
    super.key,
    required this.action,
    required this.text,
    this.family,
  });

  final GamepadAction action;
  final String text;
  final GamepadFamily? family;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GamepadGlyph(action: action, family: family, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

/// Нижняя полоска подсказок и бейдж на сфокусированном элементе.
class GamepadHintsOverlay extends StatefulWidget {
  const GamepadHintsOverlay({super.key});

  @override
  State<GamepadHintsOverlay> createState() => _GamepadHintsOverlayState();
}

class _GamepadHintsOverlayState extends State<GamepadHintsOverlay> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_refresh);
    GamepadService.instance.devices.addListener(_refresh);
    GamepadService.instance.activityTick.addListener(_refresh);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_refresh);
    GamepadService.instance.devices.removeListener(_refresh);
    GamepadService.instance.activityTick.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!gamepadHintsWanted()) return const SizedBox.shrink();
    if (GamepadKeyboardController.instance.visible) {
      return const SizedBox.shrink();
    }
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l10n == null) return const SizedBox.shrink();
    final family = currentGamepadFamily();
    final focusBadge = _focusBadge(context, family);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final navGap = isNarrow(context) ? 58.0 : 10.0;
    return IgnorePointer(
      child: Stack(
        children: [
          if (focusBadge != null) focusBadge,
          Positioned(
            left: 10,
            right: 10,
            bottom: bottomPad + navGap,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: AppColors.surfaceCard.withValues(alpha: 0.94),
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _legendItem(
                          GamepadAction.confirm,
                          l10n.gamepadLegendConfirm,
                          family,
                        ),
                        _legendItem(
                          GamepadAction.cancel,
                          l10n.gamepadLegendBack,
                          family,
                        ),
                        _legendItem(
                          GamepadAction.left,
                          l10n.gamepadLegendCycle,
                          family,
                        ),
                        _legendItem(
                          GamepadAction.shoulderL,
                          l10n.gamepadLegendTabs,
                          family,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    GamepadAction action,
    String text,
    GamepadFamily family,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GamepadGlyph(action: action, family: family, size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget? _focusBadge(BuildContext context, GamepadFamily family) {
    final node = FocusManager.instance.primaryFocus;
    final ctx = node?.context;
    if (ctx == null || !ctx.mounted) return null;
    if (node == FocusManager.instance.rootScope) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    return Positioned(
      left: (origin.dx + box.size.width - 10).clamp(4.0, MediaQuery.sizeOf(context).width - 28),
      top: (origin.dy - 8).clamp(4.0, MediaQuery.sizeOf(context).height - 28),
      child: GamepadGlyph(
        action: GamepadAction.confirm,
        family: family,
        size: 20,
      ),
    );
  }
}
