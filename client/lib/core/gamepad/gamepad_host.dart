import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_arrows.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_glyph.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/settings_provider.dart';

/// Слушает геймпад, отдаёт ввод партии или фокусу оболочки.
class GamepadHost extends ConsumerStatefulWidget {
  const GamepadHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GamepadHost> createState() => _GamepadHostState();
}

class _GamepadHostState extends ConsumerState<GamepadHost> {
  StreamSubscription<GamepadActionEvent>? _sub;

  GamepadService get _service => GamepadService.instance;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_syncKeyboard);
    _service.activityTick.addListener(_syncKeyboard);
    _service.devices.addListener(_syncKeyboard);
    // Слушаем и стартуем сразу: иначе первый кадр глотает LB/RB и крест.
    _listen();
    _service.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEnabled());
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_syncKeyboard);
    _service.activityTick.removeListener(_syncKeyboard);
    _service.devices.removeListener(_syncKeyboard);
    _sub?.cancel();
    _service.stop();
    super.dispose();
  }

  void _syncKeyboard() {
    if (!mounted) return;
    if (!ref.read(gamepadEnabledProvider)) return;
    syncGamepadKeyboardForFocus();
  }

  void _syncEnabled() {
    if (!mounted) return;
    final enabled = ref.read(gamepadEnabledProvider);
    if (enabled) {
      _listen();
      _service.start();
    } else {
      _sub?.cancel();
      _sub = null;
      _service.stop();
      GamepadKeyboardController.instance.hide();
    }
  }

  void _listen() {
    _sub ??= _service.events.listen(_onEvent);
  }

  void _onEvent(GamepadActionEvent event) {
    if (!mounted) return;
    // Диалог забирает весь ввод: B не закрывает фон, LB/RB не листают вкладки.
    if (GamepadDispatcher.hasExclusive) {
      // Стик/крест только попапу: фон (вкладки друзей) не получает жест.
      if (event.action.isScroll || event.action.isDirection) {
        GamepadDispatcher.dispatch(event.action, exclusiveOnly: true);
        return;
      }
      if (GamepadDispatcher.dispatch(event.action)) return;
      // Exclusive без обработки не глушит LB/RB.
    }
    // Любой попап без exclusive: стик/кнопка закрывает его, вкладки не листаем.
    if (isGamepadPopupOpen(context)) {
      if (event.action != GamepadAction.shoulderL &&
          event.action != GamepadAction.shoulderR) {
        dismissGamepadPopup(context);
      }
      return;
    }
    // LB/RB сразу листают вкладки — не ждут закрытия тоста/скоупа партии.
    if (event.action == GamepadAction.shoulderL ||
        event.action == GamepadAction.shoulderR) {
      if (handleGamepadUiAction(context, event.action)) return;
    }
    if (GamepadDispatcher.dispatch(event.action)) return;
    if (event.action.isScroll) {
      if (handleGamepadUiAction(context, event.action)) return;
    }
    handleGamepadUiAction(context, event.action);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(gamepadEnabledProvider, (prev, next) {
      _syncEnabled();
    });
    return ListenableBuilder(
      listenable: GamepadKeyboardController.instance,
      builder: (context, _) {
        final kb = GamepadKeyboardController.instance.visible;
        final media = MediaQuery.of(context);
        final kbInset = kb
            ? gamepadKeyboardPanelHeight(bottomSafeArea: media.padding.bottom)
            : 0.0;
        final childMedia = kbInset > 0
            ? media.copyWith(
                viewInsets: media.viewInsets.copyWith(
                  bottom: media.viewInsets.bottom > kbInset
                      ? media.viewInsets.bottom
                      : kbInset,
                ),
              )
            : media;
        return Stack(
          children: [
            MediaQuery(
              data: childMedia,
              child: Shortcuts(
                shortcuts: kb ? gamepadKeyboardTextShortcuts : const {},
                child: widget.child,
              ),
            ),
            if (!kb) const GamepadHintsOverlay(),
            if (kb)
              Align(
                alignment: Alignment.bottomCenter,
                child: GamepadKeyboardPanel(
                  onClose: dismissGamepadKeyboard,
                ),
              ),
          ],
        );
      },
    );
  }
}
