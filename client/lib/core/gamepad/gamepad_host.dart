import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_dispatcher.dart';
import 'package:multigames_client/core/gamepad/gamepad_keyboard.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';
import 'package:multigames_client/core/gamepad/gamepad_ui.dart';
import 'package:multigames_client/core/settings_provider.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/widgets/app_snack_bar.dart';

/// Слушает геймпад, отдаёт ввод партии или фокусу оболочки.
class GamepadHost extends ConsumerStatefulWidget {
  const GamepadHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GamepadHost> createState() => _GamepadHostState();
}

class _GamepadHostState extends ConsumerState<GamepadHost> {
  StreamSubscription<GamepadActionEvent>? _sub;
  final Set<String> _announced = {};

  GamepadService get _service => GamepadService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEnabled());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.devices.removeListener(_onDevices);
    _service.stop();
    super.dispose();
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
      _service.devices.removeListener(_onDevices);
      _service.stop();
      GamepadKeyboardController.instance.hide();
    }
  }

  void _listen() {
    _sub ??= _service.events.listen(_onEvent);
    _service.devices.removeListener(_onDevices);
    _service.devices.addListener(_onDevices);
  }

  void _onEvent(GamepadActionEvent event) {
    if (!mounted) return;
    if (GamepadDispatcher.dispatch(event.action)) return;
    handleGamepadUiAction(context, event.action);
  }

  void _onDevices() {
    if (!mounted) return;
    final pads = _service.devices.value;
    for (final pad in pads) {
      if (_announced.contains(pad.id)) continue;
      _announced.add(pad.id);
      final l10n = context.l10n;
      showAppSnackBar(
        context,
        message: l10n.gamepadConnectedSnack(pad.name),
        kind: AppSnackKind.success,
        icon: Icons.sports_esports_outlined,
      );
    }
    _announced.removeWhere((id) => pads.every((p) => p.id != id));
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
        return Stack(
          children: [
            widget.child,
            if (kb)
              Align(
                alignment: Alignment.bottomCenter,
                child: GamepadKeyboardPanel(
                  onClose: GamepadKeyboardController.instance.hide,
                ),
              ),
          ],
        );
      },
    );
  }
}
