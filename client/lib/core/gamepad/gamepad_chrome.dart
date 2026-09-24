import 'package:flutter/widgets.dart';

/// Цели шапки: баланс (LT) и выход (RT).
enum GamepadChromeSlot { balance, logout }

class GamepadChromeRegistry {
  GamepadChromeRegistry._();

  static final Map<GamepadChromeSlot, FocusNode> _nodes = {};

  static void register(GamepadChromeSlot slot, FocusNode node) {
    _nodes[slot] = node;
  }

  static void unregister(GamepadChromeSlot slot, FocusNode node) {
    if (identical(_nodes[slot], node)) {
      _nodes.remove(slot);
    }
  }

  static bool focus(GamepadChromeSlot slot) {
    final node = _nodes[slot];
    if (node == null || !node.canRequestFocus) return false;
    node.requestFocus();
    return true;
  }

  @visibleForTesting
  static void reset() => _nodes.clear();
}
