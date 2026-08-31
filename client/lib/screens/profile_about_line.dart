import 'package:flutter/material.dart';

/// «О себе»: в карточке — несколько строк, в полоске редактирования — одна.
class AboutOneLineText extends StatelessWidget {
  const AboutOneLineText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle? style;

  /// 1 — режим ввода (полоска). Больше — просмотр, текст виден целиком.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final single = maxLines <= 1;
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: !single,
      style: style,
    );
  }
}
