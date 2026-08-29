import 'package:flutter/material.dart';

/// Одна строка «О себе»: если текст не влезает — многоточие, без вертикальной обрезки.
class AboutOneLineText extends StatelessWidget {
  const AboutOneLineText({
    super.key,
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: style,
    );
  }
}
