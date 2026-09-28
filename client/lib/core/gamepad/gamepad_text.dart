import 'package:flutter/widgets.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';

/// Вставка и удаление в сфокусированном [EditableText] с геймпада.
class GamepadTextEditing {
  GamepadTextEditing._();

  static EditableTextState? currentState() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return null;
    final up = ctx.findAncestorStateOfType<EditableTextState>();
    if (up != null) return up;
    EditableTextState? down;
    void walk(Element el) {
      if (down != null) return;
      if (el is StatefulElement && el.state is EditableTextState) {
        down = el.state as EditableTextState;
        return;
      }
      el.visitChildren(walk);
    }

    ctx.visitChildElements(walk);
    return down;
  }

  static TextEditingValue? applyInsert(TextEditingValue value, String text) {
    if (text.isEmpty) return value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : start;
    final next = value.text.replaceRange(start, end, text);
    return TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  static TextEditingValue applyBackspace(TextEditingValue value) {
    final sel = value.selection;
    if (sel.isValid && !sel.isCollapsed) {
      final start = sel.start;
      final end = sel.end;
      return TextEditingValue(
        text: value.text.replaceRange(start, end, ''),
        selection: TextSelection.collapsed(offset: start),
      );
    }
    final pos = sel.isValid ? sel.start : value.text.length;
    if (pos <= 0) return value;
    return TextEditingValue(
      text: value.text.replaceRange(pos - 1, pos, ''),
      selection: TextSelection.collapsed(offset: pos - 1),
    );
  }

  static bool insert(String text) {
    final state = currentState();
    if (state == null) return false;
    final next = applyInsert(state.textEditingValue, text);
    if (next == null || next == state.textEditingValue) return false;
    state.userUpdateTextEditingValue(next, SelectionChangedCause.keyboard);
    return true;
  }

  static bool backspace() {
    final state = currentState();
    if (state == null) return false;
    final next = applyBackspace(state.textEditingValue);
    if (next == state.textEditingValue) return false;
    state.userUpdateTextEditingValue(next, SelectionChangedCause.keyboard);
    return true;
  }

  static bool moveByScroll(GamepadAction action) {
    final dx = switch (action) {
      GamepadAction.scrollLeft => -1,
      GamepadAction.scrollRight => 1,
      _ => 0,
    };
    final dy = switch (action) {
      GamepadAction.scrollUp => -1,
      GamepadAction.scrollDown => 1,
      _ => 0,
    };
    return moveCaret(dx: dx, dy: dy);
  }

  static TextEditingValue applyMove(
    TextEditingValue value, {
    int dx = 0,
    int dy = 0,
  }) {
    if (dx == 0 && dy == 0) return value;
    final sel = value.selection;
    final from = sel.isValid ? sel.extentOffset : value.text.length;
    final offset = dy != 0
        ? caretOffsetByLine(value.text, from, dy)
        : (from + dx).clamp(0, value.text.length);
    return TextEditingValue(
      text: value.text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  static int caretOffsetByLine(String text, int offset, int dy) {
    final pos = offset.clamp(0, text.length);
    final lineStart = pos == 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
    final col = pos - lineStart;
    if (dy < 0) {
      if (lineStart == 0) return 0;
      final prevEnd = lineStart - 1;
      final prevStart = prevEnd == 0 ? 0 : text.lastIndexOf('\n', prevEnd - 1) + 1;
      final prevLen = prevEnd - prevStart;
      return prevStart + (col < prevLen ? col : prevLen);
    }
    final lineEnd = text.indexOf('\n', pos);
    if (lineEnd < 0) return text.length;
    final nextStart = lineEnd + 1;
    final nextEndIdx = text.indexOf('\n', nextStart);
    final nextEnd = nextEndIdx < 0 ? text.length : nextEndIdx;
    final nextLen = nextEnd - nextStart;
    return nextStart + (col < nextLen ? col : nextLen);
  }

  static bool moveCaret({int dx = 0, int dy = 0}) {
    final state = currentState();
    if (state == null) return false;
    final next = applyMove(state.textEditingValue, dx: dx, dy: dy);
    if (next == state.textEditingValue) return false;
    state.userUpdateTextEditingValue(next, SelectionChangedCause.keyboard);
    return true;
  }
}
