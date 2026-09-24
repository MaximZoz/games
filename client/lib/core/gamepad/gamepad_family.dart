import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_service.dart';

/// Семейство контроллера — от него зависят подписи и цвета кнопок.
enum GamepadFamily { xbox, playstation, nintendo }

/// Определяет семейство по имени устройства (Gamepad API / HID).
GamepadFamily gamepadFamilyFromName(String name) {
  final n = name.toLowerCase();
  if (n.contains('dualshock') ||
      n.contains('dualsense') ||
      n.contains('playstation') ||
      n.contains('sony') ||
      n.contains('ps3') ||
      n.contains('ps4') ||
      n.contains('ps5') ||
      n.contains('054c')) {
    return GamepadFamily.playstation;
  }
  if (n.contains('nintendo') ||
      n.contains('joy-con') ||
      n.contains('joycon') ||
      n.contains('pro controller') ||
      n.contains('switch') ||
      n.contains('057e')) {
    return GamepadFamily.nintendo;
  }
  return GamepadFamily.xbox;
}

GamepadFamily currentGamepadFamily() {
  final pads = GamepadService.instance.devices.value;
  if (pads.isEmpty) return GamepadFamily.xbox;
  return gamepadFamilyFromName(pads.first.name);
}

class GamepadButtonLook {
  const GamepadButtonLook({
    required this.label,
    required this.color,
    this.darkLabel = false,
  });

  final String label;
  final Color color;
  final bool darkLabel;
}

/// Внешний вид кнопки в стандартном W3C mapping (кнопка 0 = низ = confirm).
GamepadButtonLook gamepadButtonLook(
  GamepadAction action, {
  GamepadFamily? family,
}) {
  final kind = family ?? currentGamepadFamily();
  switch (kind) {
    case GamepadFamily.playstation:
      return switch (action) {
        GamepadAction.confirm =>
          const GamepadButtonLook(label: '✕', color: Color(0xFF6EA8FF)),
        GamepadAction.cancel =>
          const GamepadButtonLook(label: '○', color: Color(0xFFFF5A6A)),
        GamepadAction.actionX =>
          const GamepadButtonLook(label: '□', color: Color(0xFFFF8AD4)),
        GamepadAction.actionY =>
          const GamepadButtonLook(label: '△', color: Color(0xFF3DDC84)),
        GamepadAction.shoulderL =>
          const GamepadButtonLook(label: 'L1', color: Color(0xFF5B6478)),
        GamepadAction.shoulderR =>
          const GamepadButtonLook(label: 'R1', color: Color(0xFF5B6478)),
        GamepadAction.menu =>
          const GamepadButtonLook(label: 'OPT', color: Color(0xFF5B6478)),
        GamepadAction.select =>
          const GamepadButtonLook(label: 'SHR', color: Color(0xFF5B6478)),
        GamepadAction.up ||
        GamepadAction.down ||
        GamepadAction.left ||
        GamepadAction.right ||
        GamepadAction.scrollUp ||
        GamepadAction.scrollDown =>
          const GamepadButtonLook(label: '◆', color: Color(0xFF5B6478)),
      };
    case GamepadFamily.nintendo:
      return switch (action) {
        GamepadAction.confirm =>
          const GamepadButtonLook(label: 'B', color: Color(0xFF3EB245)),
        GamepadAction.cancel =>
          const GamepadButtonLook(label: 'A', color: Color(0xFFE33C3C)),
        GamepadAction.actionX =>
          const GamepadButtonLook(label: 'Y', color: Color(0xFFE3C13C), darkLabel: true),
        GamepadAction.actionY =>
          const GamepadButtonLook(label: 'X', color: Color(0xFF3C7BE3)),
        GamepadAction.shoulderL =>
          const GamepadButtonLook(label: 'L', color: Color(0xFF5B6478)),
        GamepadAction.shoulderR =>
          const GamepadButtonLook(label: 'R', color: Color(0xFF5B6478)),
        GamepadAction.menu =>
          const GamepadButtonLook(label: '+', color: Color(0xFF5B6478)),
        GamepadAction.select =>
          const GamepadButtonLook(label: '−', color: Color(0xFF5B6478)),
        GamepadAction.up ||
        GamepadAction.down ||
        GamepadAction.left ||
        GamepadAction.right ||
        GamepadAction.scrollUp ||
        GamepadAction.scrollDown =>
          const GamepadButtonLook(label: '+', color: Color(0xFF5B6478)),
      };
    case GamepadFamily.xbox:
      return switch (action) {
        GamepadAction.confirm =>
          const GamepadButtonLook(label: 'A', color: Color(0xFF3EB245)),
        GamepadAction.cancel =>
          const GamepadButtonLook(label: 'B', color: Color(0xFFE33C3C)),
        GamepadAction.actionX =>
          const GamepadButtonLook(label: 'X', color: Color(0xFF3C7BE3)),
        GamepadAction.actionY =>
          const GamepadButtonLook(label: 'Y', color: Color(0xFFE3C13C), darkLabel: true),
        GamepadAction.shoulderL =>
          const GamepadButtonLook(label: 'LB', color: Color(0xFF5B6478)),
        GamepadAction.shoulderR =>
          const GamepadButtonLook(label: 'RB', color: Color(0xFF5B6478)),
        GamepadAction.menu =>
          const GamepadButtonLook(label: '≡', color: Color(0xFF5B6478)),
        GamepadAction.select =>
          const GamepadButtonLook(label: '⧉', color: Color(0xFF5B6478)),
        GamepadAction.up ||
        GamepadAction.down ||
        GamepadAction.left ||
        GamepadAction.right ||
        GamepadAction.scrollUp ||
        GamepadAction.scrollDown =>
          const GamepadButtonLook(label: '+', color: Color(0xFF5B6478)),
      };
  }
}

/// Контроллер реально в списке устройств — не «недавно нажимали».
bool gamepadConnected() {
  final service = GamepadService.instance;
  return service.isRunning && service.devices.value.isNotEmpty;
}

/// Подсказки и глифы только при подключённом геймпаде.
bool gamepadHintsWanted() => gamepadConnected();
