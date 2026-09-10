import 'package:flutter/widgets.dart';

/// Вставка и удаление в сфокусированном [EditableText] с геймпада.
class GamepadTextEditing {
  GamepadTextEditing._();

  static EditableTextState? currentState() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return null;
    if (ctx.widget is EditableText) {
      return ctx.findAncestorStateOfType<EditableTextState>();
    }
    return ctx.findAncestorStateOfType<EditableTextState>();
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
}
