import 'package:flutter/services.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';

/// Мёртвая зона стика: меньше — дребезг, больше — «тупой» стик.
const double kGamepadStickDeadzone = 0.42;

/// Стандартный W3C Gamepad mapping (Xbox / DualShock в режиме standard).
GamepadAction? gamepadActionFromStandardButton(int index) {
  switch (index) {
    case 0:
      return GamepadAction.confirm;
    case 1:
      return GamepadAction.cancel;
    case 2:
      return GamepadAction.actionX;
    case 3:
      return GamepadAction.actionY;
    case 4:
      return GamepadAction.shoulderL;
    case 5:
      return GamepadAction.shoulderR;
    case 8:
      return GamepadAction.select;
    case 9:
      return GamepadAction.menu;
    case 12:
      return GamepadAction.up;
    case 13:
      return GamepadAction.down;
    case 14:
      return GamepadAction.left;
    case 15:
      return GamepadAction.right;
    default:
      return null;
  }
}

/// Стик → одно направление (берём большую ось, без диагоналей).
///
/// [y] в стандартном mapping: отрицательный — вверх.
GamepadAction? gamepadActionFromStick({
  required double x,
  required double y,
  double deadzone = kGamepadStickDeadzone,
}) {
  final ax = x.abs();
  final ay = y.abs();
  if (ax < deadzone && ay < deadzone) return null;
  if (ax >= ay) {
    return x < 0 ? GamepadAction.left : GamepadAction.right;
  }
  return y < 0 ? GamepadAction.up : GamepadAction.down;
}

/// Настоящие кнопки геймпада, не стрелки/Enter клавиатуры.
bool isDedicatedGamepadKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.gameButtonA ||
      key == LogicalKeyboardKey.gameButtonB ||
      key == LogicalKeyboardKey.gameButtonC ||
      key == LogicalKeyboardKey.gameButtonX ||
      key == LogicalKeyboardKey.gameButtonY ||
      key == LogicalKeyboardKey.gameButtonZ ||
      key == LogicalKeyboardKey.gameButtonLeft1 ||
      key == LogicalKeyboardKey.gameButtonLeft2 ||
      key == LogicalKeyboardKey.gameButtonRight1 ||
      key == LogicalKeyboardKey.gameButtonRight2 ||
      key == LogicalKeyboardKey.gameButtonThumbLeft ||
      key == LogicalKeyboardKey.gameButtonThumbRight ||
      key == LogicalKeyboardKey.gameButtonStart ||
      key == LogicalKeyboardKey.gameButtonSelect ||
      key == LogicalKeyboardKey.gameButtonMode ||
      key == LogicalKeyboardKey.gameButton1 ||
      key == LogicalKeyboardKey.gameButton2 ||
      key == LogicalKeyboardKey.gameButton3 ||
      key == LogicalKeyboardKey.gameButton4 ||
      key == LogicalKeyboardKey.gameButton5 ||
      key == LogicalKeyboardKey.gameButton6 ||
      key == LogicalKeyboardKey.gameButton7 ||
      key == LogicalKeyboardKey.gameButton8 ||
      key == LogicalKeyboardKey.gameButton9 ||
      key == LogicalKeyboardKey.gameButton10 ||
      key == LogicalKeyboardKey.gameButton11 ||
      key == LogicalKeyboardKey.gameButton12 ||
      key == LogicalKeyboardKey.gameButton13 ||
      key == LogicalKeyboardKey.gameButton14 ||
      key == LogicalKeyboardKey.gameButton15 ||
      key == LogicalKeyboardKey.gameButton16;
}

/// Клавиши и кнопки геймпада, которые Android/десктоп шлют как [KeyEvent].
GamepadAction? gamepadActionFromKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowUp) {
    return GamepadAction.up;
  }
  if (key == LogicalKeyboardKey.arrowDown) {
    return GamepadAction.down;
  }
  if (key == LogicalKeyboardKey.arrowLeft) {
    return GamepadAction.left;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return GamepadAction.right;
  }
  if (key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA ||
      key == LogicalKeyboardKey.select) {
    return GamepadAction.confirm;
  }
  if (key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.gameButtonB ||
      key == LogicalKeyboardKey.goBack) {
    return GamepadAction.cancel;
  }
  if (key == LogicalKeyboardKey.gameButtonX) {
    return GamepadAction.actionX;
  }
  if (key == LogicalKeyboardKey.gameButtonY) {
    return GamepadAction.actionY;
  }
  if (key == LogicalKeyboardKey.gameButtonLeft1 ||
      key == LogicalKeyboardKey.gameButtonLeft2 ||
      key == LogicalKeyboardKey.gameButton5 ||
      key == LogicalKeyboardKey.pageUp) {
    return GamepadAction.shoulderL;
  }
  if (key == LogicalKeyboardKey.gameButtonRight1 ||
      key == LogicalKeyboardKey.gameButtonRight2 ||
      key == LogicalKeyboardKey.gameButton6 ||
      key == LogicalKeyboardKey.pageDown) {
    return GamepadAction.shoulderR;
  }
  if (key == LogicalKeyboardKey.gameButtonStart) {
    return GamepadAction.menu;
  }
  if (key == LogicalKeyboardKey.gameButtonSelect) {
    return GamepadAction.select;
  }
  return null;
}

/// Android [KeyEvent] keyCode → действие. Дубль HardwareKeyboard.
GamepadAction? gamepadActionFromAndroidKeyCode(int keyCode) {
  switch (keyCode) {
    case 19: // KEYCODE_DPAD_UP
      return GamepadAction.up;
    case 20: // KEYCODE_DPAD_DOWN
      return GamepadAction.down;
    case 21: // KEYCODE_DPAD_LEFT
      return GamepadAction.left;
    case 22: // KEYCODE_DPAD_RIGHT
      return GamepadAction.right;
    case 23: // KEYCODE_DPAD_CENTER
    case 66: // KEYCODE_ENTER
    case 96: // KEYCODE_BUTTON_A
      return GamepadAction.confirm;
    case 4: // KEYCODE_BACK
    case 97: // KEYCODE_BUTTON_B
      return GamepadAction.cancel;
    case 99: // KEYCODE_BUTTON_X
      return GamepadAction.actionX;
    case 100: // KEYCODE_BUTTON_Y
      return GamepadAction.actionY;
    case 102: // KEYCODE_BUTTON_L1
    case 104: // KEYCODE_BUTTON_L2
    case 192: // KEYCODE_BUTTON_5
      return GamepadAction.shoulderL;
    case 103: // KEYCODE_BUTTON_R1
    case 105: // KEYCODE_BUTTON_R2
    case 193: // KEYCODE_BUTTON_6
      return GamepadAction.shoulderR;
    case 108: // KEYCODE_BUTTON_START
      return GamepadAction.menu;
    case 109: // KEYCODE_BUTTON_SELECT
      return GamepadAction.select;
    default:
      return null;
  }
}
