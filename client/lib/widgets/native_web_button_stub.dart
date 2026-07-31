import 'package:flutter/material.dart';

/// На не-web — обычный Flutter hit-target.
class NativeWebTapTarget extends StatelessWidget {
  const NativeWebTapTarget({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 48,
    this.style,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: style ??
                  TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// На не-web — OutlinedButton; на web — нативный <a>/<button> поверх canvas.
class NativeWebOutlinedLink extends StatelessWidget {
  const NativeWebOutlinedLink({
    super.key,
    required this.label,
    required this.href,
    this.height = 48,
    this.onBeforeNavigate,
  });

  final String label;
  final String href;
  final double height;
  final VoidCallback? onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          maximumSize: Size(double.infinity, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          onBeforeNavigate?.call();
          // Stub: навигацию делает вызывающий код через href на web.
        },
        child: Text(label),
      ),
    );
  }
}
