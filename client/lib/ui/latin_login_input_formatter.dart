import 'package:flutter/services.dart';

/// Разрешает только `[a-zA-Z0-9_]`. При отклонении символа вызывает [onRejected]
/// (для всплывашки «только латинские символы»).
class LatinLoginInputFormatter extends TextInputFormatter {
  LatinLoginInputFormatter({this.onRejected});

  final VoidCallback? onRejected;

  static final _allow =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'));

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final next = _allow.formatEditUpdate(oldValue, newValue);
    if (next.text != newValue.text) {
      onRejected?.call();
    }
    return next;
  }
}
